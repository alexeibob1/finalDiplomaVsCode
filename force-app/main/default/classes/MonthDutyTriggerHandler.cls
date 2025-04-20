public without sharing class MonthDutyTriggerHandler extends TriggerHandler {
    private Map<Id, Month_Duty__c> newMap;
    private Map<Id, Month_Duty__c> oldMap;
    private List<Month_Duty__c> newList;

    public MonthDutyTriggerHandler() {
        this.newMap = (Map<Id, Month_Duty__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Month_Duty__c>) Trigger.oldMap;
        this.newList = (List<Month_Duty__c>) Trigger.new;
    }

    public override void afterUpdate() {
        processDutyRequests();
    }

    public void processDutyRequests() {
        Set<Id> closedDutyIds = new Set<Id>();

        for (Month_Duty__c md : this.newList) {
            Month_Duty__c oldMd = this.oldMap.get(md.Id);
            if (oldMd.Is_Registration_Active__c && !md.Is_Registration_Active__c) {
                closedDutyIds.add(md.Id);
            }
        }

        if (!closedDutyIds.isEmpty()) {
            DutyRequestProcessor.approveFirstRequests(closedDutyIds);
        }
    }
}