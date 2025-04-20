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
        Contact student = StudentDAO.getCurrentUserContact();
        return new Map<String, Object>{
            'studentId' => student.Id,
            'roomId' => student.Room__c,
            'roomName' => student.Room__r.Name,
            'dormitoryId' => student.Room__r.Dormitory__c
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
        request.Student_Contact__c = payload.studentId;
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

    @AuraEnabled
    public static List<Maintenance_Request__c> getStudentMaintenanceRequests() {
        Id studentId = StudentDAO.getCurrentUserContact().Id;
        return [
            SELECT Id, Name, CreatedDate, Location__c, Status__c
            FROM Maintenance_Request__c
            WHERE Student_Contact__c = :studentId
            ORDER BY CreatedDate DESC
        ];
    }
}