public without sharing class AccomodationRequestController {
    @AuraEnabled
    public static Id createAccommodationRequest() {
        try {
            if (!isRegistrationAvailable() || !isRequestSubmissionAvailable()) {
                throw new AccomodationRequestException('You cannot submit request at the moment.');
            }

            Account studentAccount = StudentDAO.getCurrentUserAccount();

            if (studentAccount == null) {
                throw new AccomodationRequestException('No associated Person Account found.');
            }

            Accomodation_Request__c newRequest = new Accomodation_Request__c(
                Student__c = studentAccount.Id,
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
            Account studentAccount = StudentDAO.getCurrentUserAccount();

            return [
                SELECT Id, Name, CreatedDate, toLabel(Status__c), Room__c
                FROM Accomodation_Request__c
                WHERE Student__c = :studentAccount.Id
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
        Account studentAccount = StudentDAO.getCurrentUserAccount();

        List<Accomodation_Request__c> requests = [
            SELECT Id, Name, CreatedDate, Status__c, Room__c
            FROM Accomodation_Request__c
            WHERE Student__c = :studentAccount.Id AND Status__c IN ('Одобрена', 'Документы приняты', 'Подана')
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

            if (request.Status__c == 'Подана') {
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
            Account studentAccount = StudentDAO.getAccountByAccomodationRequestId(requestId);
            if (studentAccount == null) {
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

            if (selectedRoom.Sex__c != null && selectedRoom.Sex__c != studentAccount.PersonContact.Sex__c) {
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

            Contact studentContact = [
                SELECT Id, Room__c
                FROM Contact
                WHERE AccountId = :studentAccount.Id
                LIMIT 1
            ];
            studentContact.Room__c = roomId;

            selectedRoom.Available_Places__c -= 1;

            update new List<SObject> { request, studentContact, selectedRoom };

        } catch (Exception e) {
            throw new AccomodationRequestException('Ошибка при заселении: ' + e.getMessage());
        }
    }

    public class AccomodationRequestException extends Exception {}
}