public with sharing class StudyYearUtils {
    public class StudyYearRange {
        public Date startDate;
        public Date endDate;
        public StudyYearRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }

    public static StudyYearRange getCurrentStudyYearRange() {
        Study_Year__mdt currentYear = [
            SELECT Start_Date__c, End_Date__c 
            FROM Study_Year__mdt 
            WHERE Is_Current__c = TRUE 
            LIMIT 1
        ];

        return new StudyYearRange(currentYear.Start_Date__c, currentYear.End_Date__c);
    }
}
