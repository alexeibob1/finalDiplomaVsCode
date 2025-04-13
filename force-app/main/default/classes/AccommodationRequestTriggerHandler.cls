public without sharing class AccommodationRequestTriggerHandler extends TriggerHandler {
    private Map<Id, Accomodation_Request__c> newMap;
    private Map<Id, Accomodation_Request__c> oldMap;
    private List<Accomodation_Request__c> newList;

    public AccommodationRequestTriggerHandler() {
        this.newMap = (Map<Id, Accomodation_Request__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Accomodation_Request__c>) Trigger.oldMap;
        this.newList = (List<Accomodation_Request__c>) Trigger.new;
    }

    public override void afterInsert() {
        //sendStatusChangeEmails(this.newList);
    }

    public override void afterUpdate() {
        //sendStatusChangeEmails(this.newList);
        handleEvictedStatus();
    }

    public void sendStatusChangeEmails(List<Accomodation_Request__c> requests) {
        List<Id> requestIds = new List<Id>();

        for (Accomodation_Request__c req : requests) {
            Accomodation_Request__c oldReq = this.oldMap?.get(req.Id);
            if (oldReq == null || (oldReq != null && oldReq.Status__c != req.Status__c)) {
                requestIds.add(req.Id);
            }
        }

        if (!requestIds.isEmpty()) {
            AccomodationRequestService.sendStatusUpdateEmailsAsync(requestIds);
        }
    }

    private void handleEvictedStatus() {
        List<Accomodation_Request__c> requestsToProcess = new List<Accomodation_Request__c>();
        System.debug('1');
        
        for (Accomodation_Request__c req : this.newList) {
            Accomodation_Request__c oldReq = this.oldMap.get(req.Id);
            System.debug('3');
            
            if (
                req.Status__c == 'Выселен' &&
                oldReq.Status__c != 'Выселен' &&
                req.Room__c != null
            ) {
                requestsToProcess.add(req);
            }
        }
    
        if (requestsToProcess.isEmpty()) {
            System.debug('2');
            return;
        }
    
        Map<Id, Room__c> roomsToUpdate = new Map<Id, Room__c>();
        Set<Id> studentIds = new Set<Id>();
    
        for (Accomodation_Request__c req : requestsToProcess) {
            if (req.Room__c != null) {
                System.debug('4');
                roomsToUpdate.put(req.Room__c, null);
            }
            if (req.Student__c != null) {
                System.debug('5');
                studentIds.add(req.Student__c);
            }
        }
    
        for (Room__c room : [
            SELECT Id, Available_Places__c
            FROM Room__c
            WHERE Id IN :roomsToUpdate.keySet()
        ]) {
            room.Available_Places__c = (room.Available_Places__c != null ? room.Available_Places__c : 0) + 1;
            roomsToUpdate.put(room.Id, room);
        }
    
        List<Account> studentsToUpdate = [
            SELECT Id, PersonContactId, PersonContact.Room__c
            FROM Account
            WHERE Id IN :studentIds
        ];
    
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Account acc : studentsToUpdate) {
            if (acc.PersonContactId != null) {
                contactsToUpdate.add(new Contact(
                    Id = acc.PersonContactId,
                    Room__c = null
                ));
            }
        }
    
        if (!contactsToUpdate.isEmpty()) {
            System.debug('6');
            update contactsToUpdate;
        }
    
        if (!roomsToUpdate.isEmpty()) {
            System.debug('7');
            update roomsToUpdate.values();
        }
    }
}