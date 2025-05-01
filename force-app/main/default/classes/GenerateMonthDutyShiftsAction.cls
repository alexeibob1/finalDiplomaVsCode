public with sharing class GenerateMonthDutyShiftsAction {
    public class Input {
        @InvocableVariable(required=true)
        public Id monthDutyId;
        
        @InvocableVariable(required=true)
        public List<Id> dutyShiftIds;
    }

    @InvocableMethod(label='Generate Month Duty Shifts' description='Creates Month_Duty_Shift__c records for given Month_Duty__c and Duty_Shift__c IDs')
    public static void generate(List<Input> inputs) {
        List<Month_Duty_Shift__c> junctionsToInsert = new List<Month_Duty_Shift__c>();
        
        for (Input input : inputs) {
            if (input.monthDutyId == null || input.dutyShiftIds == null || input.dutyShiftIds.isEmpty()) {
                continue;
            }
            
            for (Id shiftId : input.dutyShiftIds) {
                Month_Duty_Shift__c junction = new Month_Duty_Shift__c();
                junction.Month_Duty__c = input.monthDutyId;
                junction.Duty_Shift__c = shiftId;
                junctionsToInsert.add(junction);
            }
        }
        
        if (!junctionsToInsert.isEmpty()) {
            insert junctionsToInsert;
        }
    }
}
