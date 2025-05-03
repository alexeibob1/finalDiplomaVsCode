public with sharing class SocialUsefulWorkController {
    public class PaginatedWorkResult {
        @AuraEnabled 
        public List<Social_Useful_Work__c> records { get; set; }

        @AuraEnabled 
        public Integer totalRecords { get; set; }
    }

    @AuraEnabled
    public static PaginatedWorkResult getWorkRecordsForCurrentStudent(Integer pageSize, Integer pageNumber) {
        if (pageSize == null || pageNumber == null || pageSize <= 0 || pageNumber < 0) {
            throw new AuraHandledException('Invalid pagination parameters.');
        }

        Contact student = StudentDAO.getCurrentUserContact();
        if (student == null) {
            throw new AuraHandledException('Current student not found.');
        }

        StudyYearUtils.StudyYearRange range = StudyYearUtils.getCurrentStudyYearRange();

        Integer offset = pageNumber * pageSize;

        System.debug('offset ' + offset);
        System.debug('student ' + student.Id);
        System.debug('range ' + range);

        List<Social_Useful_Work__c> records = [
            SELECT Id, Hours__c, Work_Type__c, Work_Date__c
            FROM Social_Useful_Work__c
            WHERE Student_Contact__c = :student.Id
              AND Work_Date__c >= :range.startDate
              AND Work_Date__c <= :range.endDate
            ORDER BY Work_Date__c DESC
            LIMIT :pageSize
            OFFSET :offset
        ];

        Integer total = [
            SELECT COUNT()
            FROM Social_Useful_Work__c
            WHERE Student_Contact__c = :student.Id
              AND Work_Date__c >= :range.startDate
              AND Work_Date__c <= :range.endDate
        ];

        PaginatedWorkResult result = new PaginatedWorkResult();
        result.records = records;
        result.totalRecords = total;

        System.debug(result);

        return result;
    }
}
