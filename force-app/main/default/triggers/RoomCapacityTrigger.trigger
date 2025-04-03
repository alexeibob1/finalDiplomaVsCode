trigger RoomCapacityTrigger on Room__c (after insert, after update, after delete) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        RoomTriggerHandler.updateParentRoomCapacity(Trigger.new);
    }
    
    if (Trigger.isDelete) {
        RoomTriggerHandler.updateParentRoomCapacity(Trigger.old);
    }
}
