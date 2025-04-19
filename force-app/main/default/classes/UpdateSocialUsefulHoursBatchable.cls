public class UpdateSocialUsefulHoursBatchable implements Database.Batchable<sObject>, Schedulable {
    Date startDate;
    Date endDate;

    public UpdateSocialUsefulHoursBatchable() {
        Study_Year__mdt currentYear = [
            SELECT Start_Date__c, End_Date__c 
            FROM Study_Year__mdt 
            WHERE Is_Current__c = TRUE 
            LIMIT 1
        ];
        startDate = currentYear.Start_Date__c;
        endDate = currentYear.End_Date__c;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE IsPersonAccount = true
              AND PersonContact.Room__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Set<Id> personAccountIds = new Set<Id>();
        for (Account acc : scope) {
            personAccountIds.add(acc.Id);
        }

        Map<Id, Decimal> hoursPerStudent = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT Student__c Id, SUM(Hours__c) total
            FROM Social_Useful_Work__c
            WHERE Work_Date__c >= :startDate
              AND Work_Date__c <= :endDate
              AND Student__c IN :personAccountIds
            GROUP BY Student__c
        ]) {
            hoursPerStudent.put((Id) ar.get('Id'), (Decimal) ar.get('total'));
        }

        for (Account acc : scope) {
            acc.PersonContact.Current_Study_Year_Hours__c = hoursPerStudent.get(acc.Id) != null ? hoursPerStudent.get(acc.Id) : 0;
        }

        update scope;
    }

    public void finish(Database.BatchableContext bc) {}
}
