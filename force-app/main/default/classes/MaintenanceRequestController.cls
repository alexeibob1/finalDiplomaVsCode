public without sharing class MaintenanceRequestController {
    public class MaintenancePayload {
        @AuraEnabled public Id roomId { get; set; }
        @AuraEnabled public Id studentId { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Id dormitoryId { get; set; }
        @AuraEnabled public String commonArea { get; set; }
    }

    @AuraEnabled
    public static Map<String, Object> getStudentContext() {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        Account student = [
            SELECT Id, PersonContact.Room__c, PersonContact.Room__r.Dormitory__c, PersonContact.Room__r.Name
            FROM Account WHERE Id = :currentUser.AccountId
        ];

        return new Map<String, Object>{
            'studentId' => student.Id,
            'roomId' => student.PersonContact.Room__c,
            'roomName' => student.PersonContact.Room__r.Name,
            'dormitoryId' => student.PersonContact.Room__r.Dormitory__c
        };
    }

    @AuraEnabled
    public static List<Room__c> getRoomsForDormitory(Id dormitoryId) {
        return [
            SELECT Id, Name
            FROM Room__c
            WHERE Dormitory__c = :dormitoryId AND Parent_Room__c != NULL
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static void createMaintenanceRequest(MaintenancePayload payload) {
        Maintenance_Request__c request = new Maintenance_Request__c();
        request.Student__c = payload.studentId;
        request.Type__c = payload.type;
        request.Description__c = payload.description;
        request.Dormitory__c = payload.dormitoryId;
        request.Status__c = 'Новая';

        if (!String.isBlank(payload.commonArea)) {
            request.Common_Area__c = payload.commonArea;
        } else {
            request.Room__c = payload.roomId;
        }

        insert request;
    }
}