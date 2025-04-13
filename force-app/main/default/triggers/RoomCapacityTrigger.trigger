trigger RoomCapacityTrigger on Room__c (after insert, after update, after delete) {
    new RoomTriggerHandler().run();
}
