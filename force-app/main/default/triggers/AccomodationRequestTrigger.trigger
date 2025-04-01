trigger AccomodationRequestTrigger on Accomodation_Request__c (after insert, after update) {
    List<Id> requestIds = new List<Id>();

    for (Accomodation_Request__c req : Trigger.new) {
        Accomodation_Request__c oldReq = Trigger.oldMap.get(req.Id);
        if (Trigger.isInsert || (Trigger.isUpdate && oldReq.Status__c != req.Status__c)) {
            requestIds.add(req.Id);
        }
    }

    if (!requestIds.isEmpty()) {
        List<Accomodation_Request__c> requestsToSendEmail = [
            SELECT Id, Name, toLabel(Status__c), FX_Student_Name__c, 
                   Student__r.PersonEmail  
            FROM Accomodation_Request__c
            WHERE Id IN :requestIds
        ];

        AccomodationRequestService.sendStatusUpdateEmails(requestsToSendEmail);
    }
}
