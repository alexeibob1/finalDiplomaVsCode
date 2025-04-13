trigger AccomodationRequestTrigger on Accomodation_Request__c (after insert, after update) {
    new AccommodationRequestTriggerHandler().run();
}
