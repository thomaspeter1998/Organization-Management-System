public with sharing class EmployeeUpdater {
    @AuraEnabled
    public static Id transferEmployee(Id employeeId, Id newBranchId) {
        Employee__c oldEmployee = [
            SELECT Name, Id, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c, Branch__c 
            FROM Employee__c 
            WHERE Id = :employeeId
        ];
        System.debug(oldEmployee);
        System.debug('abc');

        Employee__c transferredEmployee = oldEmployee.clone(false, true, false, false);
        transferredEmployee.Branch__c = newBranchId;

        insert transferredEmployee;
        System.debug(transferredEmployee);
        return transferredEmployee.Id;
    } 

    @AuraEnabled
    public static void deleteEmployee(Id employeeId) {
        delete [
            SELECT Name, Id, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c, Branch__c 
            FROM Employee__c 
            WHERE Id = :employeeId
        ];
    }
}