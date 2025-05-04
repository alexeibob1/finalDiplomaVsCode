public class UpdateStudyDutyCountBatchable implements Database.Batchable<sObject>, Schedulable {
    Date startDate;
    Date endDate;

    public UpdateStudyDutyCountBatchable() {
        StudyYearUtils.StudyYearRange range = StudyYearUtils.getCurrentStudyYearRange();
        startDate = range.startDate;
        endDate = range.endDate;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Contact
            WHERE Room__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : scope) {
            contactIds.add(c.Id);
        }

        Map<Id, Integer> dutyCountPerStudent = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Student_Contact__c Id, COUNT(Id) total
            FROM Duty_Request__c
            WHERE Finished__c = TRUE
              AND Duty_Date__c >= :startDate
              AND Duty_Date__c <= :endDate
              AND Student_Contact__c IN :contactIds
            GROUP BY Student_Contact__c
        ]) {
            dutyCountPerStudent.put((Id) ar.get('Id'), (Integer) ar.get('total'));
        }

        for (Contact c : scope) {
            c.Current_Study_Year_Duties__c = dutyCountPerStudent.get(c.Id) != null ? dutyCountPerStudent.get(c.Id) : 0;
        }

        update scope;
    }

    public void finish(Database.BatchableContext bc) {}
}
