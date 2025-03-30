public with sharing class AccomodationRequestController {
    @AuraEnabled
    public static Id createAccommodationRequest() {
        try {
            if (!isRegistrationAvailable() || !isRequestSubmissionAvailable()) {
                throw new AccomodationRequestException('You cannot submit request at the moment.');
            }

            Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
            if (contactId == null) {
                throw new AccomodationRequestException('Contact not found for the logged-in user.');
            }

            Account studentAccount = [SELECT Id FROM Account WHERE PersonContactId = :contactId LIMIT 1];

            if (studentAccount == null) {
                throw new AccomodationRequestException('No associated Person Account found.');
            }

            Accomodation_Request__c newRequest = new Accomodation_Request__c(
                Student__c = studentAccount.Id,
                Status__c = 'Submitted'
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
            Account studentAccount = getStudentAccount();

            return [
                SELECT Id, Name, CreatedDate, toLabel(Status__c), Room__c
                FROM Accomodation_Request__c
                WHERE Student__c = :studentAccount.Id
                ORDER BY CreatedDate DESC
            ];

            // return [
            //     SELECT Id, Name, CreatedDate, toLabel(Status__c), Room__c
            //     FROM Accomodation_Request__c
            //     ORDER BY CreatedDate DESC
            // ];
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
        Account studentAccount = getStudentAccount();

        List<Accomodation_Request__c> requests = [
            SELECT Id, Name, CreatedDate, Status__c, Room__c
            FROM Accomodation_Request__c
            WHERE Student__c = :studentAccount.Id AND Status__c IN ('Approved', 'Documents_Accepted', 'Submitted')
        ];

        if (!requests.isEmpty()) {
            return false;
        }

        return true;
    }

    public static Account getStudentAccount() {
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        if (contactId == null) {
            throw new AccomodationRequestException('Contact not found for the logged-in user.');
        }

        Account studentAccount = [SELECT Id FROM Account WHERE PersonContactId = :contactId LIMIT 1];
        if (studentAccount == null) {
            throw new AccomodationRequestException('No associated Person Account found.');
        }

        return studentAccount;
    }

    public class AccomodationRequestException extends Exception {}
}
