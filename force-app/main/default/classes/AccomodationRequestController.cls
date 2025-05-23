public without sharing class AccomodationRequestController {
    @AuraEnabled
    public static Id createAccommodationRequest() {
        try {
            if (!isRegistrationAvailable() || !isRequestSubmissionAvailable()) {
                throw new AccomodationRequestException('You cannot submit request at the moment.');
            }

            Contact studentContact = StudentDAO.getCurrentUserContact();

            if (studentContact == null) {
                throw new AccomodationRequestException('No associated Contact found.');
            }

            Accomodation_Request__c newRequest = new Accomodation_Request__c(
                Student_Contact__c = studentContact.Id,
                Status__c = 'Подана'
            );

            insert newRequest;

            return newRequest.Id;
        } catch (Exception e) {
            LOGGER.error('Error creating request: ' + e.getMessage());
            LOGGER.saveLog();
            throw new AccomodationRequestException('Error creating request: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Accomodation_Request__c> getStudentRequests() {
        try {
            Contact studentContact = StudentDAO.getCurrentUserContact();

            return [
                SELECT Id, Name, CreatedDate, Status__c, Room__c, Room__r.Name, Room__r.Dormitory__r.Name, Note__c, Place_Of_Settlement__c
                FROM Accomodation_Request__c
                WHERE Student_Contact__c = :studentContact.Id
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            LOGGER.error('Error fetching student requests: ' + e.getMessage());
            LOGGER.saveLog();
            throw new AccomodationRequestException('Error fetching student requests.');
        }
    }

    @AuraEnabled
    public static Boolean isRegistrationAvailable() {
        return AccomodationSettingsController.getRegistrationStatus();
    }

    @AuraEnabled
    public static Boolean isRequestSubmissionAvailable() {
        Contact studentContact = StudentDAO.getCurrentUserContact();

        List<Accomodation_Request__c> requests = [
            SELECT Id, Name, CreatedDate, Status__c, Room__c
            FROM Accomodation_Request__c
            WHERE Student_Contact__c = :studentContact.Id AND Status__c IN ('Одобрена', 'Документы приняты', 'Подана')
        ];

        if (!requests.isEmpty()) {
            return false;
        }

        return true;
    }

    @AuraEnabled
    public static void cancelRequest(Id requestId) {
        try {
            Accomodation_Request__c request = [
                SELECT Id, Status__c FROM Accomodation_Request__c WHERE Id = :requestId LIMIT 1
            ];

            if (request.Status__c == 'Отменена') {
                throw new AccomodationRequestException('Заявка уже отменена.');
            }

            if (request.Status__c != 'Подана') {
                throw new AccomodationRequestException('Заявка уже обрабатывается, для её отмены обратитесь в деканат.');
            }

            request.Status__c = 'Отменена';
            update request;
        } catch (Exception e) {
            throw new AccomodationRequestException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateAccomodationRequestRoom(Id requestId, Id roomId) {
        try {
            Contact studentContact = StudentDAO.getContactByAccomodationRequestId(requestId);
            if (studentContact == null) {
                throw new AccomodationRequestException('Student not found for the request.');
            }

            Room__c selectedRoom = [
                SELECT Id, Available_Places__c, Sex__c
                FROM Room__c
                WHERE Id = :roomId
                LIMIT 1
            ];

            if (selectedRoom.Available_Places__c == null || selectedRoom.Available_Places__c <= 0) {
                throw new AccomodationRequestException('В выбранной комнате нет свободных мест.');
            }

            if (selectedRoom.Sex__c != null && selectedRoom.Sex__c != studentContact.Sex__c) {
                throw new AccomodationRequestException('Выбранная комната не соответствует полу студента.');
            }

            Accomodation_Request__c request = [
                SELECT Id, Status__c, Room__c
                FROM Accomodation_Request__c
                WHERE Id = :requestId
                LIMIT 1
            ];

            request.Room__c = roomId;
            request.Status__c = 'Заселен';

            studentContact.Room__c = roomId;

            selectedRoom.Available_Places__c -= 1;

            update new List<SObject> { studentContact, request, selectedRoom };

        } catch (Exception e) {
            throw new AccomodationRequestException('Ошибка при заселении: ' + e.getMessage());
        }
    }

    public class AccomodationRequestWrapper {
        @AuraEnabled public List<Accomodation_Request__c> records;
        @AuraEnabled public Integer total;
    }
    
    @AuraEnabled
    public static AccomodationRequestWrapper getStudentRequestsPaginated(Integer offset, Integer pageSize) {
        try {
            Contact studentContact = StudentDAO.getCurrentUserContact();
    
            List<Accomodation_Request__c> records = [
                SELECT Id, Name, CreatedDate, Status__c, Room__c, Room__r.Name, Room__r.Dormitory__r.Name, Note__c, Place_Of_Settlement__c
                FROM Accomodation_Request__c
                WHERE Student_Contact__c = :studentContact.Id
                ORDER BY CreatedDate DESC
                LIMIT :pageSize
                OFFSET :offset
            ];
    
            Integer total = [
                SELECT COUNT()
                FROM Accomodation_Request__c
                WHERE Student_Contact__c = :studentContact.Id
            ];
    
            AccomodationRequestWrapper wrapper = new AccomodationRequestWrapper();
            wrapper.records = records;
            wrapper.total = total;
            return wrapper;
    
        } catch (Exception e) {
            throw new AccomodationRequestException('Ошибка загрузки заявок: ' + e.getMessage());
        }
    }

    public class AccomodationRequestException extends Exception {}
}