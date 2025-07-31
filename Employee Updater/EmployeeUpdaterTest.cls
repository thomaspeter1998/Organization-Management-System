@isTest
public class EmployeeUpdaterTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Organization
        Organization__c testOrg = new Organization__c(
            Name = 'Test Organization'
        );
        insert testOrg;
        
        // Create test Branches
        List<Branch__c> testBranches = new List<Branch__c>();
        for(Integer i = 1; i <= 3; i++) {
            testBranches.add(new Branch__c(
                Name = 'Test Branch ' + i,
                Location__c = 'Test Location ' + i,
                Number_of_Employees__c = i * 10,
                Organization__c = testOrg.Id
            ));
        }
        insert testBranches;
        
        // Create test Employees
        List<Employee__c> testEmployees = new List<Employee__c>();
        for(Integer i = 1; i <= 3; i++) {
            testEmployees.add(new Employee__c(
                Name = 'Test Employee ' + i,
                Position__c = 'Test Position ' + i,
                Phone_Number__c = '123-456-789' + i,
                Image__c = 'test-image-' + i + '.jpg',
                Salary__c = 50000 + (i * 1000),
                Email_Id__c = 'employee' + i + '@test.com',
                Branch__c = testBranches[0].Id
            ));
        }
        insert testEmployees;
    }
    
    @isTest
    static void testTransferEmployee_ValidTransfer() {
        // Get test data
        Employee__c originalEmployee = [SELECT Id, Name, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c, Branch__c FROM Employee__c WHERE Name = 'Test Employee 1' LIMIT 1];
        Branch__c targetBranch = [SELECT Id FROM Branch__c WHERE Name = 'Test Branch 2' LIMIT 1];
        
        // Store original values for verification
        Id originalBranchId = originalEmployee.Branch__c;
        String originalName = originalEmployee.Name;
        String originalPosition = originalEmployee.Position__c;
        
        Test.startTest();
        Id transferredEmployeeId = EmployeeUpdater.transferEmployee(originalEmployee.Id, targetBranch.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, transferredEmployeeId, 'Transferred employee ID should not be null');
        System.assertNotEquals(originalEmployee.Id, transferredEmployeeId, 'Transferred employee should have different ID');
        
        // Verify the transferred employee exists and has correct data
        Employee__c transferredEmployee = [SELECT Id, Name, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c, Branch__c FROM Employee__c WHERE Id = :transferredEmployeeId];
        
        System.assertEquals(targetBranch.Id, transferredEmployee.Branch__c, 'Transferred employee should be in target branch');
        System.assertEquals(originalName, transferredEmployee.Name, 'Name should be preserved');
        System.assertEquals(originalPosition, transferredEmployee.Position__c, 'Position should be preserved');
        System.assertEquals(originalEmployee.Phone_Number__c, transferredEmployee.Phone_Number__c, 'Phone should be preserved');
        System.assertEquals(originalEmployee.Image__c, transferredEmployee.Image__c, 'Image should be preserved');
        System.assertEquals(originalEmployee.Salary__c, transferredEmployee.Salary__c, 'Salary should be preserved');
        System.assertEquals(originalEmployee.Email_Id__c, transferredEmployee.Email_Id__c, 'Email should be preserved');
        
        // Verify original employee still exists (clone doesn't delete original)
        List<Employee__c> originalEmployees = [SELECT Id FROM Employee__c WHERE Id = :originalEmployee.Id];
        System.assertEquals(1, originalEmployees.size(), 'Original employee should still exist');
    }
    
    @isTest
    static void testTransferEmployee_SameBranch() {
        // Get test data - transfer to same branch
        Employee__c originalEmployee = [SELECT Id, Branch__c FROM Employee__c WHERE Name = 'Test Employee 1' LIMIT 1];
        
        Test.startTest();
        Id transferredEmployeeId = EmployeeUpdater.transferEmployee(originalEmployee.Id, originalEmployee.Branch__c);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, transferredEmployeeId, 'Transferred employee ID should not be null');
        System.assertNotEquals(originalEmployee.Id, transferredEmployeeId, 'Should create new employee even for same branch');
        
        // Verify the transferred employee exists in same branch
        Employee__c transferredEmployee = [SELECT Branch__c FROM Employee__c WHERE Id = :transferredEmployeeId];
        System.assertEquals(originalEmployee.Branch__c, transferredEmployee.Branch__c, 'Employee should be in same branch');
    }
    
    @isTest
    static void testTransferEmployee_InvalidEmployeeId() {
        // Get valid branch ID
        Branch__c targetBranch = [SELECT Id FROM Branch__c WHERE Name = 'Test Branch 2' LIMIT 1];
        String invalidEmployeeId = '003000000000000AAA';
        
        Test.startTest();
        try {
            Id result = EmployeeUpdater.transferEmployee(invalidEmployeeId, targetBranch.Id);
            System.assert(false, 'Should have thrown exception for invalid employee ID');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid employee ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testTransferEmployee_InvalidBranchId() {
        // Get valid employee ID
        Employee__c originalEmployee = [SELECT Id FROM Employee__c WHERE Name = 'Test Employee 1' LIMIT 1];
        String invalidBranchId = '001000000000000AAA';
        
        Test.startTest();
        try {
            Id result = EmployeeUpdater.transferEmployee(originalEmployee.Id, invalidBranchId);
            // This might succeed if branch validation is not enforced, check the result
            if (result != null) {
                Employee__c transferredEmployee = [SELECT Branch__c FROM Employee__c WHERE Id = :result];
                System.assertEquals(invalidBranchId, transferredEmployee.Branch__c, 'Branch ID should be set even if invalid');
            }
        } catch (Exception e) {
            System.assert(true, 'Exception acceptable for invalid branch ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testTransferEmployee_NullParameters() {
        Test.startTest();
        try {
            Id result = EmployeeUpdater.transferEmployee(null, null);
            System.assert(false, 'Should have thrown exception for null parameters');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for null parameters');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteEmployee_ValidEmployee() {
        // Get test employee
        Employee__c employeeToDelete = [SELECT Id FROM Employee__c WHERE Name = 'Test Employee 2' LIMIT 1];
        Id employeeId = employeeToDelete.Id;
        
        // Verify employee exists before deletion
        List<Employee__c> beforeDelete = [SELECT Id FROM Employee__c WHERE Id = :employeeId];
        System.assertEquals(1, beforeDelete.size(), 'Employee should exist before deletion');
        
        Test.startTest();
        EmployeeUpdater.deleteEmployee(employeeId);
        Test.stopTest();
        
        // Verify employee is deleted
        List<Employee__c> afterDelete = [SELECT Id FROM Employee__c WHERE Id = :employeeId];
        System.assertEquals(0, afterDelete.size(), 'Employee should be deleted');
    }
    
    @isTest
    static void testDeleteEmployee_InvalidEmployeeId() {
        String invalidEmployeeId = '003000000000000AAA';
        
        Test.startTest();
        try {
            EmployeeUpdater.deleteEmployee(invalidEmployeeId);
            // If no exception is thrown, verify no employees were affected
            List<Employee__c> allEmployees = [SELECT Id FROM Employee__c];
            System.assertEquals(3, allEmployees.size(), 'No employees should be deleted for invalid ID');
        } catch (Exception e) {
            System.assert(true, 'Exception acceptable for invalid employee ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteEmployee_NullParameter() {
        Test.startTest();
        try {
            EmployeeUpdater.deleteEmployee(null);
            // If no exception is thrown, verify no employees were affected
            List<Employee__c> allEmployees = [SELECT Id FROM Employee__c];
            System.assertEquals(3, allEmployees.size(), 'No employees should be deleted for null ID');
        } catch (Exception e) {
            System.assert(true, 'Exception acceptable for null parameter');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteEmployee_MultipleEmployees() {
        // Get multiple employees to delete
        List<Employee__c> employeesToDelete = [SELECT Id FROM Employee__c WHERE Name LIKE 'Test Employee%' ORDER BY Name];
        System.assertEquals(3, employeesToDelete.size(), 'Should have 3 test employees');
        
        Test.startTest();
        // Delete employees one by one
        for(Employee__c emp : employeesToDelete) {
            EmployeeUpdater.deleteEmployee(emp.Id);
        }
        Test.stopTest();
        
        // Verify all employees are deleted
        List<Employee__c> remainingEmployees = [SELECT Id FROM Employee__c WHERE Name LIKE 'Test Employee%'];
        System.assertEquals(0, remainingEmployees.size(), 'All test employees should be deleted');
    }
    
    @isTest
    static void testTransferEmployee_VerifyCloneFields() {
        // Get test data
        Employee__c originalEmployee = [SELECT Id, Name, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c, Branch__c FROM Employee__c WHERE Name = 'Test Employee 3' LIMIT 1];
        Branch__c targetBranch = [SELECT Id FROM Branch__c WHERE Name = 'Test Branch 3' LIMIT 1];
        
        Test.startTest();
        Id transferredEmployeeId = EmployeeUpdater.transferEmployee(originalEmployee.Id, targetBranch.Id);
        Test.stopTest();
        
        // Get transferred employee and verify all fields are cloned correctly
        Employee__c transferredEmployee = [SELECT Id, Name, Position__c, Phone_Number__c, Image__c, Salary__c, Email_Id__c, Branch__c FROM Employee__c WHERE Id = :transferredEmployeeId];
        
        // Verify the clone preserved all fields except Branch and has new ID
        System.assertNotEquals(originalEmployee.Id, transferredEmployee.Id, 'Should have new ID');
        System.assertEquals(originalEmployee.Name, transferredEmployee.Name, 'Name should match');
        System.assertEquals(originalEmployee.Position__c, transferredEmployee.Position__c, 'Position should match');
        System.assertEquals(originalEmployee.Phone_Number__c, transferredEmployee.Phone_Number__c, 'Phone should match');
        System.assertEquals(originalEmployee.Image__c, transferredEmployee.Image__c, 'Image should match');
        System.assertEquals(originalEmployee.Salary__c, transferredEmployee.Salary__c, 'Salary should match');
        System.assertEquals(originalEmployee.Email_Id__c, transferredEmployee.Email_Id__c, 'Email should match');
        System.assertEquals(targetBranch.Id, transferredEmployee.Branch__c, 'Branch should be updated');
        System.assertNotEquals(originalEmployee.Branch__c, transferredEmployee.Branch__c, 'Branch should be different from original');
    }
}