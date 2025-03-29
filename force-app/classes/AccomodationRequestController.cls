public with sharing class AccomodationRequestController {
    @AuraEnabled
    public static Id createAccommodationRequest() {
        try {
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

    public class AccomodationRequestException extends Exception {}
}
