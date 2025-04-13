public without sharing class RoomTriggerHandler extends TriggerHandler {
    private Map<Id, Room__c> newMap;
    private Map<Id, Room__c> oldMap;

    public RoomTriggerHandler() {
        this.newMap = (Map<Id, Room__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Room__c>) Trigger.oldMap;
    }

    public override void afterUpdate() {
        this.updateParentRoomCapacity(this.newMap.values());
    }

    public override void afterInsert() {
        this.updateParentRoomCapacity(this.newMap.values());
    }

    public override void afterDelete() {
        this.updateParentRoomCapacity(this.oldMap.values());
    }

    public void updateParentRoomCapacity(List<Room__c> rooms) {
        Set<Id> parentRoomIds = new Set<Id>();
        
        for (Room__c room : rooms) {
            if (room.Parent_Room__c != null) {
                parentRoomIds.add(room.Parent_Room__c);
            }
        }
    
        if (parentRoomIds.isEmpty()) {
            return;
        }
    
        List<Room__c> parentRooms = [SELECT Id, Capacity__c FROM Room__c WHERE Id IN :parentRoomIds];
    
        Map<Id, Decimal> capacityMap = new Map<Id, Decimal>();
        
        for (AggregateResult ar : [
            SELECT Parent_Room__c, SUM(Capacity__c) TotalCapacity 
            FROM Room__c 
            WHERE Parent_Room__c IN :parentRoomIds 
            GROUP BY Parent_Room__c
        ]) {
            capacityMap.put((Id) ar.get('Parent_Room__c'), (Decimal) ar.get('TotalCapacity'));
        }
    
        List<Room__c> updates = new List<Room__c>();
        for (Room__c parentRoom : parentRooms) {
            parentRoom.Capacity__c = capacityMap.containsKey(parentRoom.Id) ? capacityMap.get(parentRoom.Id) : 0;
            updates.add(parentRoom);
        }
    
        if (!updates.isEmpty()) {
            update updates;
        }
    }
}