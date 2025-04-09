public without sharing class MaintenanceRequestController {
    
    @AuraEnabled
    public static Map<String, Object> getStudentContext() {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        Account student = [
            SELECT Id, PersonContact.Room__c, PersonContact.Room__r.Dormitory__c
            FROM Account WHERE Id = :currentUser.AccountId
        ];

        return new Map<String, Object>{
            'studentId' => student.Id,
            'roomId' => student.PersonContact.Room__c,
            'dormitoryId' => student.PersonContact.Room__r.Dormitory__c
        };
    }

    @AuraEnabled
    public static List<Room__c> getRoomsForDormitory(Id dormitoryId, String gender) {
        return [
            SELECT Id, Name
            FROM Room__c
            WHERE Dormitory__c = :dormitoryId
              AND Parent_Room__c != NULL
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static void createMaintenanceRequest(
        Id roomId,
        Id studentId,
        String description,
        String type,
        Id dormitoryId,
        String commonArea
    ) {
        Maintenance_Request__c request = new Maintenance_Request__c();
        request.Student__c = studentId;
        request.Type__c = type;
        request.Description__c = description;
        request.Dormitory__c = dormitoryId;
        request.Status__c = 'Новая';

        if (!String.isBlank(commonArea)) {
            request.Common_Area__c = commonArea;
        } else {
            request.Room__c = roomId;
        }

        insert request;
    }
}
