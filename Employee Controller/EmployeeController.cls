public with sharing class EmployeeController {
    @AuraEnabled(cacheable=true)
    public static List<Branch__c> employeeBranchSelector() {
        return [SELECT Id, Name FROM Branch__c];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Employee__c> getEmployees(String Id) {
        return [SELECT Name, Id, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c 
            FROM Employee__c 
            WHERE Branch__c = :Id
        ];
    }

    @AuraEnabled(cacheable=true)
    public static String getLatestContentVersionId(String contentDocumentId) {
        List<ContentVersion> latestVersions = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];
        return latestVersions.isEmpty() ? null : latestVersions[0].Id;
    }

}