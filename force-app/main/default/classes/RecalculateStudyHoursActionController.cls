public with sharing class RecalculateStudyHoursActionController {
    @AuraEnabled
    public static void recalculateSingleStudent(Id accountId) {
        if (accountId == null) {
            return;
        }

        Account personAccObj = [
            SELECT Id, PersonContact.Id, PersonContact.Current_Study_Year_Hours__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (personAccObj.PersonContact.Id == null) {
            return;
        }

        Id contactId = personAccObj.PersonContact.Id;

        StudyYearUtils.StudyYearRange range = StudyYearUtils.getCurrentStudyYearRange();
        Date startDate = range.startDate;
        Date endDate = range.endDate;

        AggregateResult[] results = [
            SELECT Student_Contact__c Id, SUM(Hours__c) total 
            FROM Social_Useful_Work__c 
            WHERE Work_Date__c >= :startDate 
              AND Work_Date__c <= :endDate 
              AND Student_Contact__c = :contactId
            GROUP BY Student_Contact__c
        ];

        Decimal total = 0;
        if (!results.isEmpty()) {
            total = (Decimal) results[0].get('total');
        }

        personAccObj.PersonContact.Current_Study_Year_Hours__c = total;

        update personAccObj.PersonContact;
    }
}
