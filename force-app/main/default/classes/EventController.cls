public without sharing class EventController {
    @AuraEnabled
    public static List<Event__c> getAvailableDormitoryEvents() {
        Contact studentContact = StudentDAO.getCurrentUserContact();
        //TODO add filtering by study year as with ОПТ
        List<Event__c> dormitoryEvents = [
            SELECT Id, Name, Event_DateTime__c, Max_Students__c, Event_Place__c, Dormitory__c
            FROM Event__c
            WHERE Dormitory__c = :studentContact.Room__r.Dormitory__c
        ];

        return dormitoryEvents;
    }

    @AuraEnabled
    public static List<Event_Request__c> getStudentEventRequests() {
        Contact studentContact = StudentDAO.getCurrentUserContact();

        List<Event_Request__c> studentRequests = [
            SELECT Id, Name,
                Event__r.Name, Event__r.Event_DateTime__c
            FROM Event_Request__c
            WHERE Student_Contact__c = :studentContact.Id
        ];

        return studentRequests;
    }
}