public without sharing class RoomTriggerHandler extends TriggerHandler {
    private Map<Id, Room__c> newMap;
    private Map<Id, Room__c> oldMap;
    private List<Room__c> newList;

    public RoomTriggerHandler() {
        this.newMap = (Map<Id, Room__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Room__c>) Trigger.oldMap;
        this.newList = (List<Room__c>) Trigger.new;
    }

    public override void afterInsert() {
        updateParentRoomCapacityAndAvailability(this.newMap.values());
    }

    public override void afterUpdate() {
        updateParentRoomCapacityAndAvailability(this.newMap.values());
    }

    public override void afterDelete() {
        updateParentRoomCapacityAndAvailability(this.oldMap.values());
    }

    public override void beforeInsert() {
        initializeAvailablePlaces(this.newList);
    }

    private void initializeAvailablePlaces(List<Room__c> rooms) {
        List<Room__c> toUpdate = new List<Room__c>();
        for (Room__c room : rooms) {
            if (room.Available_Places__c == null || room.Available_Places__c < 0) {
                room.Available_Places__c = room.Capacity__c;
            }
        }
    }

    private void updateParentRoomCapacityAndAvailability(List<Room__c> rooms) {
        Set<Id> parentRoomIds = new Set<Id>();
        
        for (Room__c room : rooms) {
            if (room.Parent_Room__c != null) {
                parentRoomIds.add(room.Parent_Room__c);
            }
        }

        if (parentRoomIds.isEmpty()) return;

        List<Room__c> parentRooms = [SELECT Id, Capacity__c, Available_Places__c FROM Room__c WHERE Id IN :parentRoomIds];

        Map<Id, Decimal> capacityMap = new Map<Id, Decimal>();
        Map<Id, Decimal> availableMap = new Map<Id, Decimal>();

        // Aggregate SUM of capacity and available places from child rooms
        for (AggregateResult ar : [
            SELECT Parent_Room__c, SUM(Capacity__c) totalCapacity, SUM(Available_Places__c) totalAvailable
            FROM Room__c
            WHERE Parent_Room__c IN :parentRoomIds
            GROUP BY Parent_Room__c
        ]) {
            Id parentId = (Id) ar.get('Parent_Room__c');
            capacityMap.put(parentId, (Decimal) ar.get('totalCapacity'));
            availableMap.put(parentId, (Decimal) ar.get('totalAvailable'));
        }

        List<Room__c> toUpdate = new List<Room__c>();
        for (Room__c parent : parentRooms) {
            Room__c updated = new Room__c(Id = parent.Id);
            updated.Capacity__c = capacityMap.get(parent.Id) != null ? capacityMap.get(parent.Id) : 0;
            updated.Available_Places__c = availableMap.get(parent.Id) != null ? availableMap.get(parent.Id) : 0;
            toUpdate.add(updated);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
