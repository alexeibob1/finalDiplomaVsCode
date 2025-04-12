trigger AccomodationRequestTrigger on Accomodation_Request__c (after insert, after update) {
    List<Id> requestIds = new List<Id>();

    for (Accomodation_Request__c req : Trigger.new) {
        Accomodation_Request__c oldReq = Trigger.oldMap?.get(req.Id);
        if (Trigger.isInsert || (Trigger.isUpdate && oldReq.Status__c != req.Status__c)) {
            requestIds.add(req.Id);
        }
    }

    System.debug('requests Ids: ' + requestIds);

    if (!requestIds.isEmpty()) {
        AccomodationRequestService.sendStatusUpdateEmailsAsync(requestIds);
    }
}
