public without sharing class StudentDAO {
    public static Account getAccountById(Id accountId) {
        List<Account> accounts = [
            SELECT Id, PersonContact.Sex__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (!accounts.isEmpty()) {
            return accounts[0];
        }

        return null;
    }

    @AuraEnabled
    public static Account getAccountByAccomodationRequestId(Id requestId) {
        List<Account> accounts = [
            SELECT Id, PersonContact.Sex__c
            FROM Account
            WHERE Id IN (SELECT Student__c FROM Accomodation_Request__c WHERE Id = :requestId)
            LIMIT 1
        ];

        if (!accounts.isEmpty()) {
            return accounts[0];
        }

        return null;
    }

    @AuraEnabled
public static Account getCurrentUserAccount() {
    try {
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;

        if (contactId == null) {
            throw new AuraHandledException('Contact not found for the current user.');
        }

        Account studentAccount = [
            SELECT Id, PersonContact.Sex__c, PersonContact.Room__c, PersonContact.Room__r.Floor__c
            FROM Account
            WHERE PersonContactId = :contactId
            LIMIT 1
        ];

        return studentAccount;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to retrieve student account: ' + e.getMessage());
    }
}
}