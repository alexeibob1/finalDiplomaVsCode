public without sharing class RoomTriggerHandler {
    public static void updateParentRoomCapacity(List<Room__c> rooms) {
        Set<Id> parentRoomIds = new Set<Id>();
        
        for (Room__c room : rooms) {
            if (room.Parent_Room__c != null) {
                parentRoomIds.add(room.Parent_Room__c);
            }
        }
    
        if (parentRoomIds.isEmpty()) {
            return;
        }
    
        // Query parent rooms
        List<Room__c> parentRooms = [SELECT Id, Capacity__c FROM Room__c WHERE Id IN :parentRoomIds];
    
        // Query child rooms and calculate new capacities
        Map<Id, Decimal> capacityMap = new Map<Id, Decimal>();
        
        for (AggregateResult ar : [
            SELECT Parent_Room__c, SUM(Capacity__c) TotalCapacity 
            FROM Room__c 
            WHERE Parent_Room__c IN :parentRoomIds 
            GROUP BY Parent_Room__c
        ]) {
            capacityMap.put((Id) ar.get('Parent_Room__c'), (Decimal) ar.get('TotalCapacity'));
        }
    
        // Update parent rooms
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