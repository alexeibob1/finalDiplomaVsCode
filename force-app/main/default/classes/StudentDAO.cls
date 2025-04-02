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
}