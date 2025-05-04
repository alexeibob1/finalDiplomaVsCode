public with sharing class RecalculateDutyRequestsActionController {
    @AuraEnabled
    public static void recalculateSingleStudent(Id accountId) {
        if (accountId == null) return;

        Account personAccObj = [
            SELECT Id, PersonContact.Id
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (personAccObj.PersonContact.Id == null) return;

        Id contactId = personAccObj.PersonContact.Id;

        StudyYearUtils.StudyYearRange range = StudyYearUtils.getCurrentStudyYearRange();
        Date startDate = range.startDate;
        Date endDate = range.endDate;

        Integer count = [
            SELECT COUNT()
            FROM Duty_Request__c
            WHERE Finished__c = TRUE
              AND Duty_Date__c >= :startDate
              AND Duty_Date__c <= :endDate
              AND Student_Contact__c = :contactId
        ];

        Contact contactToUpdate = new Contact(
            Id = contactId,
            Current_Study_Year_Duties__c = count
        );

        update contactToUpdate;
    }
}
