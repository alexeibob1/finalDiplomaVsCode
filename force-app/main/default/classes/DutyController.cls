public without sharing class DutyController {
    @AuraEnabled
    public static List<Month_Duty__c> getAvailableMonthDuties(Id studentAccountId, Integer pageNumber, Integer pageSize) {
        if (studentAccountId == null) return new List<Month_Duty__c>();

        Account student = [
            SELECT PersonContact.Room__r.Floor__c
            FROM Account
            WHERE Id = :studentAccountId
            LIMIT 1
        ];

        if (student.PersonContact == null || student.PersonContact.Room__r == null || student.PersonContact.Room__r.Floor__c == null) {
            return new List<Month_Duty__c>();
        } 

        Integer offsetVal = (pageNumber - 1) * pageSize;

        return [
            SELECT Id, Name, FX_Duty_Month__c, FX_Duty_Year__c, Duty_Month_Year__c, Floor__c, Is_Registration_Active__c
            FROM Month_Duty__c
            WHERE Floor__c = :student.PersonContact.Room__r.Floor__c
                AND Is_Registration_Active__c = true
            ORDER BY Duty_Month_Year__c DESC
            LIMIT :pageSize OFFSET :offsetVal
        ];
    }

    @AuraEnabled
    public static Integer getAvailableMonthDutiesCount(Id studentAccountId) {
        if (studentAccountId == null) return 0;

        Account student = [
            SELECT PersonContact.Room__r.Floor__c
            FROM Account
            WHERE Id = :studentAccountId
            LIMIT 1
        ];

        if (student.PersonContact == null || student.PersonContact.Room__r == null || student.PersonContact.Room__r.Floor__c == null) {
            return 0;
        } 

        return [
            SELECT COUNT()
            FROM Month_Duty__c
            WHERE Floor__c = :student.PersonContact.Room__r.Floor__c
                AND Is_Registration_Active__c = true
        ];
    }

    @AuraEnabled
    public static List<Month_Duty_Shift__c> getShiftsForMonthDuty(Id monthDutyId) {
        return [
            SELECT Id, Month_Duty__c, Duty_Shift__r.Name, Duty_Shift__r.Start__c, Duty_Shift__r.Finish__c
            FROM Month_Duty_Shift__c
            WHERE Month_Duty__c = :monthDutyId
            ORDER BY Duty_Shift__r.Start__c ASC
        ];
    }

    @AuraEnabled
    public static List<Duty_Request__c> getRequestsForStudentAndMonth(Id studentId, Id monthDutyId) {
        return [
            SELECT Id, Duty_Date__c, Month_Duty_Shift__c
            FROM Duty_Request__c
            WHERE Student__c = :studentId
            AND Month_Duty__c = :monthDutyId
        ];
    }

    @AuraEnabled
    public static Duty_Request__c createDutyRequest(Id studentId, Id monthDutyId, Id monthDutyShiftId, Date dutyDate) {
        Integer countRequests = [
            SELECT COUNT()
            FROM Duty_Request__c
            WHERE Student__c = :studentId
            AND Month_Duty__c = :monthDutyId
        ];

        if (countRequests >= 5) {
            throw new AuraHandledException('Вы не можете отправить больше 5 заявок на этот месяц.');
        }

        Duty_Request__c newRequest = new Duty_Request__c(
            Student__c = studentId,
            Month_Duty__c = monthDutyId,
            Month_Duty_Shift__c = monthDutyShiftId,
            Duty_Date__c = dutyDate
        );
        insert newRequest;
        return newRequest;
    }

    @AuraEnabled
    public static List<Duty_Request__c> getStudentRequestsForMonth(Id studentId, Id monthDutyId) {
        return [
            SELECT Id, Duty_Date__c, Month_Duty_Shift__r.Duty_Shift__r.Name
            FROM Duty_Request__c
            WHERE Student__c = :studentId AND Month_Duty__c = :monthDutyId
        ];
    }

    @AuraEnabled
    public static String submitDutyRequests(Id studentId, Id monthDutyId, List<DutyRequestWrapper> requests) {
        if (studentId == null || monthDutyId == null || requests == null || requests.isEmpty()) {
            throw new AuraHandledException('Неверные входные данные.');
        }

        List<Duty_Request__c> existingRequests = [
            SELECT Id
            FROM Duty_Request__c
            WHERE Student__c = :studentId AND Month_Duty__c = :monthDutyId
        ];

        if (existingRequests.size() + requests.size() > 5) {
            throw new AuraHandledException('Вы не можете создать более 5 заявок за месяц.');
        }

        List<Duty_Request__c> toInsert = new List<Duty_Request__c>();

        for (DutyRequestWrapper drw : requests) {
            toInsert.add(new Duty_Request__c(
                Student__c = studentId,
                Month_Duty__c = monthDutyId,
                Month_Duty_Shift__c = drw.monthDutyShiftId,
                Duty_Date__c = drw.dutyDate
            ));
        }

        insert toInsert;
        return 'Заявки успешно отправлены!';
    }

    @AuraEnabled
    public static Month_Duty__c getMonthDutyById(Id monthDutyId) {
        return [
            SELECT Id, FX_Duty_Month__c, FX_Duty_Year__c, Dormitory__r.Name, Duty_Month_Year__c
            FROM Month_Duty__c
            WHERE Id = :monthDutyId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Integer getCurrentRequestCountForMonthDuty(Id studentAccountId, Id monthDutyId) {
        List<Duty_Request__c> requests = [SELECT Id 
                                          FROM Duty_Request__c 
                                          WHERE Student__c = :studentAccountId 
                                          AND Month_Duty__c = :monthDutyId];
        return requests.size();
    }

    public class DutyRequestWrapper {
        @AuraEnabled public Date dutyDate { get; set; }
        @AuraEnabled public Id monthDutyShiftId { get; set; }
    }
}