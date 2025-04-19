public with sharing class RecalculateStudyHoursActionController {
    @AuraEnabled
    public static void recalculateSingleStudent(Id accountId) {
        if (accountId == null) return;

        Study_Year__mdt year = [
            SELECT Start_Date__c, End_Date__c 
            FROM Study_Year__mdt 
            WHERE Is_Current__c = TRUE 
            LIMIT 1
        ];

        Date startDate = year.Start_Date__c;
        Date endDate = year.End_Date__c;

        AggregateResult[] results = [
            SELECT Student__c Id, SUM(Hours__c) total 
            FROM Social_Useful_Work__c 
            WHERE Work_Date__c >= :startDate 
              AND Work_Date__c <= :endDate 
              AND Student__c = :accountId
            GROUP BY Student__c
        ];

        Decimal total = 0;
        if (!results.isEmpty()) {
            total = (Decimal) results[0].get('total');
        }

        Account acc = [
            SELECT Id, PersonContact.Current_Study_Year_Hours__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        acc.PersonContact.Current_Study_Year_Hours__c = total;

        update acc.PersonContact;
    }
}
