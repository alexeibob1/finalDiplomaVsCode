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
        handleSettledStatus();
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

    private void handleSettledStatus() {
        List<Accomodation_Request__c> newlySettled = new List<Accomodation_Request__c>();
    
        for (Accomodation_Request__c req : this.newList) {
            Accomodation_Request__c oldReq = this.oldMap.get(req.Id);
    
            if (
                req.Status__c == 'Заселен' &&
                oldReq.Status__c != 'Заселен' &&
                req.Room__c != null &&
                req.Student__c != null
            ) {
                newlySettled.add(req);
            }
        }
    
        if (newlySettled.isEmpty()) {
            return;
        }

        Set<Id> newlySettledRoomsIds = new Set<Id>();
        Set<Id> newlySettledStudentIds = new Set<Id>();
        for (Accomodation_Request__c req : newlySettled) {
            newlySettledRoomsIds.add(req.Room__c);
            newlySettledStudentIds.add(req.Student__c);
        }
    
        Map<Id, Room__c> rooms = new Map<Id, Room__c>([
            SELECT Id, Sex__c, Parent_Room__c, Available_Places__c
            FROM Room__c
            WHERE Id IN :newlySettledRoomsIds
        ]);
    
        Map<Id, Account> students = new Map<Id, Account>([
            SELECT Id, PersonContact.Sex__c
            FROM Account
            WHERE Id IN :newlySettledStudentIds
        ]);
    
        List<Room__c> roomsToUpdate = new List<Room__c>();
    
        for (Accomodation_Request__c req : newlySettled) {
            Room__c room = rooms.get(req.Room__c);
            Account student = students.get(req.Student__c);
            String studentSex = student.PersonContact.Sex__c;
    
            // Check if room already has a sex assigned
            if (room.Sex__c == null) {
                // Count how many students are already assigned (should be 0 for first settlement)
                Integer currentOccupants = [
                    SELECT COUNT()
                    FROM Accomodation_Request__c
                    WHERE Room__c = :room.Id AND Status__c = 'Заселен'
                ];
    
                if (currentOccupants == 1) { // only this one student
                    // Set room.sex, parent.sex, and all child rooms.sex
                    room.Sex__c = studentSex;
                    roomsToUpdate.add(room);
    
                    if (room.Parent_Room__c != null) {
                        Room__c parent = [
                            SELECT Id
                            FROM Room__c
                            WHERE Id = :room.Parent_Room__c
                            LIMIT 1
                        ];
                        parent.Sex__c = studentSex;
                        roomsToUpdate.add(parent);
    
                        List<Room__c> siblings = [
                            SELECT Id
                            FROM Room__c
                            WHERE Parent_Room__c = :room.Parent_Room__c AND Id != :room.Id
                        ];
                        for (Room__c sibling : siblings) {
                            sibling.Sex__c = studentSex;
                            roomsToUpdate.add(sibling);
                        }
                    }
                }
            }
        }
    
        if (!roomsToUpdate.isEmpty()) {
            update roomsToUpdate;
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
            SELECT Id, Available_Places__c, Parent_Room__c
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

        Set<Id> parentRoomIdsToClear = new Set<Id>();
        List<Room__c> allRoomsToClearSex = new List<Room__c>();

        for (Room__c room : roomsToUpdate.values()) {
            Integer stillOccupied = [
                SELECT COUNT()
                FROM Accomodation_Request__c
                WHERE Room__c = :room.Id AND Status__c = 'Заселен'
            ];

            if (stillOccupied == 0) {
                // Clear sex on this room
                room.Sex__c = null;
                allRoomsToClearSex.add(room);

                if (room.Parent_Room__c != null) {
                    parentRoomIdsToClear.add(room.Parent_Room__c);
                }
            }
        }

        if (!parentRoomIdsToClear.isEmpty()) {
            List<Room__c> parentAndChildren = [
                SELECT Id
                FROM Room__c
                WHERE Id IN :parentRoomIdsToClear OR Parent_Room__c IN :parentRoomIdsToClear
            ];
            for (Room__c r : parentAndChildren) {
                r.Sex__c = null;
                allRoomsToClearSex.add(r);
            }
        }

        if (!allRoomsToClearSex.isEmpty()) {
            update allRoomsToClearSex;
        }
    }
}