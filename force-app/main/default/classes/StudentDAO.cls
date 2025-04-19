public without sharing class StudentDAO {
    public static Contact getContactById(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, Sex__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        if (!contacts.isEmpty()) {
            return contacts[0];
        }

        return null;
    }

    @AuraEnabled
    public static Contact getContactByAccomodationRequestId(Id requestId) {
        List<Contact> contacts = [
            SELECT Id, Sex__c
            FROM Contact
            WHERE Id IN (SELECT Student_Contact__c FROM Accomodation_Request__c WHERE Id = :requestId)
            LIMIT 1
        ];

        if (!contacts.isEmpty()) {
            return contacts[0];
        }

        return null;
    }

    @AuraEnabled
    public static Contact getCurrentUserContact() {
        try {
            Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;

            if (contactId == null) {
                throw new AuraHandledException('Contact not found for the current user.');
            }

            Contact studentContact = [
                SELECT Id,
                    Sex__c, Room__c, Room__r.Floor__c,
                    Room__r.Name, Room__r.Dormitory__c
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];

            return studentContact;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve student contact: ' + e.getMessage());
        }
    }
}