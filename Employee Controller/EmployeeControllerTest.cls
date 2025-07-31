@isTest
public class EmployeeControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Organization
        Organization__c testOrg = new Organization__c(
            Name = 'Test Organization'
        );
        insert testOrg;
        
        // Create test Branches
        List<Branch__c> testBranches = new List<Branch__c>();
        for(Integer i = 1; i <= 2; i++) {
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
        
        // Create employees for second branch
        Employee__c employee4 = new Employee__c(
            Name = 'Test Employee 4',
            Position__c = 'Test Position 4',
            Phone_Number__c = '123-456-7894',
            Image__c = 'test-image-4.jpg',
            Salary__c = 54000,
            Email_Id__c = 'employee4@test.com',
            Branch__c = testBranches[1].Id
        );
        insert employee4;
        
        // Create test ContentDocument and ContentVersion for file testing
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test document content'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Create additional version for the same document
        ContentVersion testContentVersion2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        ContentVersion newVersion = new ContentVersion(
            ContentDocumentId = testContentVersion2.ContentDocumentId,
            Title = 'Test Document v2',
            PathOnClient = 'TestDocument_v2.pdf',
            VersionData = Blob.valueOf('Test document content version 2'),
            IsMajorVersion = true
        );
        insert newVersion;
    }
    
    @isTest
    static void testEmployeeBranchSelector_ValidData() {
        Test.startTest();
        List<Branch__c> result = EmployeeController.employeeBranchSelector();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return all branches');
        
        // Verify field access
        for(Branch__c branch : result) {
            System.assertNotEquals(null, branch.Id, 'Branch Id should not be null');
            System.assertNotEquals(null, branch.Name, 'Branch Name should not be null');
        }
    }
    
    @isTest
    static void testEmployeeBranchSelector_NoBranches() {
        // Delete all test data
        delete [SELECT Id FROM Employee__c];
        delete [SELECT Id FROM Branch__c];
        delete [SELECT Id FROM Organization__c];
        
        Test.startTest();
        List<Branch__c> result = EmployeeController.employeeBranchSelector();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list when no branches exist');
    }
    
    @isTest
    static void testGetEmployees_ValidBranch() {
        // Get test branch
        Branch__c testBranch = [SELECT Id FROM Branch__c WHERE Name = 'Test Branch 1' LIMIT 1];
        
        Test.startTest();
        List<Employee__c> result = EmployeeController.getEmployees(testBranch.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should return 3 employees for test branch 1');
        
        // Verify field access
        for(Employee__c employee : result) {
            System.assertNotEquals(null, employee.Name, 'Employee name should not be null');
            System.assertNotEquals(null, employee.Id, 'Employee Id should not be null');
            System.assertNotEquals(null, employee.Position__c, 'Employee position should not be null');
            System.assertNotEquals(null, employee.Phone_Number__c, 'Employee phone should not be null');
            System.assertNotEquals(null, employee.Image__c, 'Employee image should not be null');
            System.assertNotEquals(null, employee.Salary__c, 'Employee salary should not be null');
            System.assertNotEquals(null, employee.Email_Id__c, 'Employee email should not be null');
        }
    }
    
    @isTest
    static void testGetEmployees_BranchWithOneEmployee() {
        // Get test branch 2 which has only one employee
        Branch__c testBranch = [SELECT Id FROM Branch__c WHERE Name = 'Test Branch 2' LIMIT 1];
        
        Test.startTest();
        List<Employee__c> result = EmployeeController.getEmployees(testBranch.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return 1 employee for test branch 2');
        System.assertEquals('Test Employee 4', result[0].Name, 'Should return the correct employee');
    }
    
    @isTest
    static void testGetEmployees_InvalidBranch() {
        // Use a non-existent branch ID
        String invalidBranchId = '001000000000000AAA';
        
        Test.startTest();
        List<Employee__c> result = EmployeeController.getEmployees(invalidBranchId);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for invalid branch');
    }
    
    @isTest
    static void testGetEmployees_NullParameter() {
        Test.startTest();
        List<Employee__c> result = EmployeeController.getEmployees(null);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for null branch');
    }
    
    @isTest
    static void testGetEmployees_BranchWithNoEmployees() {
        // Create a branch with no employees
        Organization__c testOrg = [SELECT Id FROM Organization__c LIMIT 1];
        Branch__c emptyBranch = new Branch__c(
            Name = 'Empty Branch',
            Location__c = 'Empty Location',
            Number_of_Employees__c = 0,
            Organization__c = testOrg.Id
        );
        insert emptyBranch;
        
        Test.startTest();
        List<Employee__c> result = EmployeeController.getEmployees(emptyBranch.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for branch with no employees');
    }
    
    @isTest
    static void testGetLatestContentVersionId_ValidDocument() {
        // Get the content document ID
        ContentVersion testCV = [SELECT ContentDocumentId FROM ContentVersion ORDER BY VersionNumber DESC LIMIT 1];
        
        Test.startTest();
        String result = EmployeeController.getLatestContentVersionId(testCV.ContentDocumentId);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals('', result, 'Result should not be empty');
        
        // Verify it returns the latest version
        ContentVersion latestVersion = [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :testCV.ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1];
        System.assertEquals(latestVersion.Id, result, 'Should return the latest version ID');
    }
    
    @isTest
    static void testGetLatestContentVersionId_InvalidDocument() {
        // Use a non-existent content document ID
        String invalidDocId = '069000000000000AAA';
        
        Test.startTest();
        String result = EmployeeController.getLatestContentVersionId(invalidDocId);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(null, result, 'Should return null for invalid document ID');
    }
    
    @isTest
    static void testGetLatestContentVersionId_NullParameter() {
        Test.startTest();
        String result = EmployeeController.getLatestContentVersionId(null);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(null, result, 'Should return null for null document ID');
    }
    
    @isTest
    static void testGetLatestContentVersionId_SingleVersion() {
        // Create a document with only one version
        ContentVersion singleVersion = new ContentVersion(
            Title = 'Single Version Document',
            PathOnClient = 'SingleVersionDoc.pdf',
            VersionData = Blob.valueOf('Single version content'),
            IsMajorVersion = true
        );
        insert singleVersion;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :singleVersion.Id];
        
        Test.startTest();
        String result = EmployeeController.getLatestContentVersionId(insertedCV.ContentDocumentId);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(singleVersion.Id, result, 'Should return the single version ID');
    }
}