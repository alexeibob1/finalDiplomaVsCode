public with sharing class RoomSelectionController {
    @AuraEnabled
    public static List<Room__c> getAvailableRooms(String studentGender, Integer pageNumber, Integer pageSize) {
        Integer offset = (pageNumber - 1) * pageSize;

        Map<Id, Room__c> childRooms = new Map<Id, Room__c>([
            SELECT Id, Name, Available_Places__c, Capacity__c, Sex__c, Dormitory__r.Name, Parent_Room__c 
            FROM Room__c 
            WHERE Parent_Room__c != NULL 
            AND (Sex__c = :studentGender OR Sex__c = NULL) 
            AND Available_Places__c > 0
            ORDER BY Available_Places__c ASC
            LIMIT :pageSize OFFSET :offset
        ]);

        Set<Id> parentRoomsIds = new Set<Id>();
        for (Room__c childRoom : childRooms.values()) {
            parentRoomsIds.add(childRoom.Parent_Room__c);
        }

        Integer remaining = pageSize - childRooms.keySet().size();
        List<Room__c> parentRooms = new List<Room__c>();
        if (remaining > 0) {
            parentRooms = [
                SELECT Id, Name, Available_Places__c, Capacity__c, Sex__c, Dormitory__r.Name 
                FROM Room__c 
                WHERE Parent_Room__c = NULL 
                AND Id NOT IN :parentRoomsIds
                AND (Sex__c = :studentGender OR Sex__c = NULL) 
                AND Available_Places__c > 0
                ORDER BY Available_Places__c ASC
                LIMIT :remaining OFFSET :offset
            ];
        }

        List<Room__c> availableRooms = new List<Room__c>();
        availableRooms.addAll(childRooms.values());
        availableRooms.addAll(parentRooms);

        return availableRooms;
    }

    @AuraEnabled
    public static Integer getTotalRoomsCount(String studentGender) {
        Integer count = [
            SELECT COUNT()
            FROM Room__c
            WHERE (Sex__c = :studentGender OR Sex__c = NULL)
            AND Available_Places__c > 0
        ];
        return count;
    }
}