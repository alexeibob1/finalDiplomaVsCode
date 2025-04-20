trigger MonthDutyTrigger on Month_Duty__c (after update) {
    new MonthDutyTriggerHandler().run();
}