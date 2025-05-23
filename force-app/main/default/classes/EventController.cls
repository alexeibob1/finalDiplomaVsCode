// Apex Controller: EventController
public with sharing class EventController {
    public class EventResult {
        @AuraEnabled public List<Event__c> events {get; set; }
        @AuraEnabled public Integer total {get; set; }
        @AuraEnabled public List<Id> existingEventIds { get; set; }
    }

    @AuraEnabled
    public static EventResult getAvailableEventsForStudent(Integer pageSize, Integer pageNumber) {
        Contact student = StudentDAO.getCurrentUserContact();
        if (student == null || student.Room__r == null) {
            throw new AuraHandledException('Студент или комната не найдены.');
        }

        Integer offsetVal = (pageNumber - 1) * pageSize;

        List<Event__c> events = [
            SELECT Id, Name, Event_DateTime__c, Max_Students__c, Remaining_Spaces__c, Event_Place__c
            FROM Event__c
            WHERE Dormitory__c = :student.Room__r.Dormitory__c
              AND Event_DateTime__c > :System.now()
            ORDER BY Event_DateTime__c ASC
            LIMIT :pageSize OFFSET :offsetVal
        ];

        Integer totalCount = [
            SELECT COUNT()
            FROM Event__c
            WHERE Dormitory__c = :student.Room__r.Dormitory__c
              AND Event_DateTime__c > :System.now()
        ];

        List<Event_Request__c> studentRequests = [
            SELECT Event__c FROM Event_Request__c
            WHERE Student_Contact__c = :student.Id
        ];

        Set<Id> requestedEventIds = new Set<Id>();
        for (Event_Request__c req : studentRequests) {
            requestedEventIds.add(req.Event__c);
        }

        EventResult result = new EventResult();
        result.events = events;
        result.total = totalCount;
        result.existingEventIds = new List<Id>(requestedEventIds);
        return result;
    }

    @AuraEnabled
    public static void createEventRequest(Id eventId) {
        Contact student = StudentDAO.getCurrentUserContact();

        Boolean exists = [
            SELECT COUNT() FROM Event_Request__c
            WHERE Student_Contact__c = :student.Id AND Event__c = :eventId
        ] > 0;

        if (exists) {
            throw new AuraHandledException('Вы уже подали заявку на это мероприятие.');
        }

        Event_Request__c req = new Event_Request__c(
            Event__c = eventId,
            Student_Contact__c = student.Id
        );
        insert req;
    }

    @AuraEnabled
    public static List<Event_Request__c> getStudentEventRequests() {
        Contact student = StudentDAO.getCurrentUserContact();
        return [
            SELECT Id, Name, Event__r.Name, Event__r.Event_DateTime__c, Attended__c, Event__r.Event_Place__c
            FROM Event_Request__c
            WHERE Student_Contact__c = :student.Id AND Event__r.Event_DateTime__c > :System.now() AND Attended__c = FALSE
            ORDER BY Event__r.Event_DateTime__c ASC
        ];
    }

    @AuraEnabled
    public static void deleteEventRequest(Id requestId) {
        Event_Request__c request = [
            SELECT Id, Event__r.Event_DateTime__c
            FROM Event_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];

        DateTime eventDateTime = request.Event__r.Event_DateTime__c;
        DateTime now = System.now();

        if (eventDateTime.addDays(-1) <= now) {
            throw new AuraHandledException('Невозможно удалить заявку менее чем за сутки до начала мероприятия.');
        }

        delete request;
    }

    @AuraEnabled
    public static Map<String, Object> getAttendedEvents(Integer pageSize, Integer pageNumber) {
        Contact student = StudentDAO.getCurrentUserContact();
        
        List<Event_Request__c> attendedRequests = [
            SELECT Id, Event__r.Name, Event__r.Event_DateTime__c, Event__r.Event_Place__c
            FROM Event_Request__c
            WHERE Attended__c = true AND Student_Contact__c = :student.Id
            ORDER BY Event__r.Event_DateTime__c DESC
            LIMIT :pageSize OFFSET :((pageNumber - 1) * pageSize)
        ];

        Integer total = [
            SELECT COUNT()
            FROM Event_Request__c
            WHERE Attended__c = true AND Student_Contact__c = :student.Id
        ];

        return new Map<String, Object>{
            'events' => attendedRequests,
            'total' => total
        };
    }

}
