public class DutyRequestProcessor {
    public static void approveFirstRequests(Set<Id> monthDutyIds) {
        List<Duty_Request__c> requests = [
            SELECT Id, Duty_Date__c, Month_Duty_Shift__c, CreatedDate
            FROM Duty_Request__c
            WHERE Month_Duty__c IN :monthDutyIds
            ORDER BY Duty_Date__c, Month_Duty_Shift__c, CreatedDate
        ];

        Map<String, Duty_Request__c> earliestRequests = new Map<String, Duty_Request__c>();

        for (Duty_Request__c req : requests) {
            String key = req.Duty_Date__c + '-' + req.Month_Duty_Shift__c;

            if (!earliestRequests.containsKey(key)) {
                earliestRequests.put(key, req);
            }
        }

        // Update the approved flag
        for (Duty_Request__c req : earliestRequests.values()) {
            req.Approved__c = true;
        }

        if (!earliestRequests.isEmpty()) {
            update earliestRequests.values();
        }
    }
}