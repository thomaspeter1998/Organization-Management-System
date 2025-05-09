public with sharing class BranchController {
    @AuraEnabled(Cacheable=true)
    public static List<Branch__c> getBranches(String Id) {
        return [SELECT Name, Id, Location__c, Number_of_Employees__c FROM Branch__c WHERE Organization__c = :Id];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Branch__c> getFullBranches(Id Id, Id branchId) {
        return [SELECT Name, Id FROM Branch__c WHERE Organization__c = :Id AND Id != :branchId];
    }
}