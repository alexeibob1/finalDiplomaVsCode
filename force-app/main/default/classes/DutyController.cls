public without sharing class DutyController {
    @AuraEnabled
    public static List<Month_Duty__c> getAvailableMonthDuties(Id studentAccountId, Integer pageNumber, Integer pageSize) {
        if (studentAccountId == null) return new List<Month_Duty__c>();

        // Get the student's room and floor from PersonContact
        Account student = [
            SELECT PersonContact.Room__r.Floor__c
            FROM Account
            WHERE Id = :studentAccountId
            LIMIT 1
        ];

        if (student.PersonContact == null || student.PersonContact.Room__r == null || student.PersonContact.Room__r.Floor__c == null) {
            return new List<Month_Duty__c>();
        } 

        Integer offsetVal = (pageNumber - 1) * pageSize;

        return [
            SELECT Id, Name, FX_Duty_Month__c, FX_Duty_Year__c, Duty_Month_Year__c, Floor__c, Is_Registration_Active__c
            FROM Month_Duty__c
            WHERE Floor__c = :student.PersonContact.Room__r.Floor__c
                AND Is_Registration_Active__c = true
            ORDER BY Duty_Month_Year__c DESC
            LIMIT :pageSize OFFSET :offsetVal
        ];
    }

    @AuraEnabled
    public static Integer getAvailableMonthDutiesCount(Id studentAccountId) {
        if (studentAccountId == null) {
            return 0;
        }

        Account student = [
            SELECT PersonContact.Room__r.Floor__c
            FROM Account
            WHERE Id = :studentAccountId
            LIMIT 1
        ];

        if (student.PersonContact == null || student.PersonContact.Room__r == null || student.PersonContact.Room__r.Floor__c == null) {
            return 0;
        } 

        return [
            SELECT COUNT()
            FROM Month_Duty__c
            WHERE Floor__c = :student.PersonContact.Room__r.Floor__c
                AND Is_Registration_Active__c = true
        ];
    }
}
