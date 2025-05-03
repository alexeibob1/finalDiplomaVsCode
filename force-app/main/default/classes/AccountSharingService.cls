public class AccountSharingService {
    public static void shareDormitoryAccountsWithStudents(List<Contact> contacts) {
        Map<Id, Id> contactToAccount = new Map<Id, Id>();

        for (Contact c : contacts) {
            if (c.Room__r != null && c.Room__r.Dormitory__c != null) {
                contactToAccount.put(c.Id, c.Room__r.Dormitory__c);
            }
        }

        if (contactToAccount.isEmpty()) return;

        Map<Id, User> contactToUser = new Map<Id, User>();
        for (User u : [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId IN :contactToAccount.keySet()
        ]) {
            contactToUser.put(u.ContactId, u);
        }

        Set<String> existingShareKeys = new Set<String>();
        for (AccountShare existing : [
            SELECT AccountId, UserOrGroupId
            FROM AccountShare
            WHERE AccountId IN :contactToAccount.values()
            AND UserOrGroupId IN :contactToUser.values()
        ]) {
            existingShareKeys.add(existing.AccountId + ':' + existing.UserOrGroupId);
        }

        List<AccountShare> sharesToInsert = new List<AccountShare>();
        for (Id contactId : contactToAccount.keySet()) {
            User user = contactToUser.get(contactId);
            if (user == null) continue;

            String key = contactToAccount.get(contactId) + ':' + user.Id;
            if (!existingShareKeys.contains(key)) {
                sharesToInsert.add(new AccountShare(
                    AccountId = contactToAccount.get(contactId),
                    UserOrGroupId = user.Id,
                    AccountAccessLevel = 'Read',
                    OpportunityAccessLevel = 'None'
                ));
            }
        }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }

    public static void removeDormitoryAccountShares(List<Contact> contacts) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }
    
        Map<Id, User> contactToUser = new Map<Id, User>();
        for (User u : [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId IN :contactIds
        ]) {
            contactToUser.put(u.ContactId, u);
        }
    
        Set<Id> userIds = new Set<Id>();
        for (User u : contactToUser.values()) {
            userIds.add(u.Id);
        }
    
        List<AccountShare> sharesToDelete = [
            SELECT Id
            FROM AccountShare
            WHERE UserOrGroupId IN :userIds
        ];
    
        if (!sharesToDelete.isEmpty()) {
            delete sharesToDelete;
        }
    }    
}
