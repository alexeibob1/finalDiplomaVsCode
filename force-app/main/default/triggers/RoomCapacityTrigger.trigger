trigger RoomCapacityTrigger on Room__c (before insert, after insert, after update, after delete) {
    new RoomTriggerHandler().run();
}
