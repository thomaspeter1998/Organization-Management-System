@isTest
public class BranchControllerTest {
    
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
        
        // Create another organization with branches for negative testing
        Organization__c anotherOrg = new Organization__c(
            Name = 'Another Organization'
        );
        insert anotherOrg;
        
        Branch__c anotherBranch = new Branch__c(
            Name = 'Another Branch',
            Location__c = 'Another Location',
            Number_of_Employees__c = 50,
            Organization__c = anotherOrg.Id
        );
        insert anotherBranch;
    }
    
    @isTest
    static void testGetBranches_ValidOrganization() {
        // Get test organization
        Organization__c testOrg = [SELECT Id FROM Organization__c WHERE Name = 'Test Organization' LIMIT 1];
        
        Test.startTest();
        List<Branch__c> result = BranchController.getBranches(testOrg.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should return 3 branches for test organization');
        
        // Verify field access
        for(Branch__c branch : result) {
            System.assertNotEquals(null, branch.Name, 'Branch name should not be null');
            System.assertNotEquals(null, branch.Id, 'Branch Id should not be null');
            System.assertNotEquals(null, branch.Location__c, 'Branch location should not be null');
            System.assertNotEquals(null, branch.Number_of_Employees__c, 'Branch employee count should not be null');
        }
    }
    
    @isTest
    static void testGetBranches_InvalidOrganization() {
        // Use a non-existent organization ID
        String invalidOrgId = '001000000000000AAA';
        
        Test.startTest();
        List<Branch__c> result = BranchController.getBranches(invalidOrgId);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for invalid organization');
    }
    
    @isTest
    static void testGetBranches_NullParameter() {
        Test.startTest();
        List<Branch__c> result = BranchController.getBranches(null);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for null organization');
    }
    
    @isTest
    static void testGetFullBranches_ValidParameters() {
        // Get test organization and branches
        Organization__c testOrg = [SELECT Id FROM Organization__c WHERE Name = 'Test Organization' LIMIT 1];
        List<Branch__c> testBranches = [SELECT Id FROM Branch__c WHERE Organization__c = :testOrg.Id];
        
        Test.startTest();
        List<Branch__c> result = BranchController.getFullBranches(testOrg.Id, testBranches[0].Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 branches (excluding the specified branch)');
        
        // Verify excluded branch is not in results
        Set<Id> resultIds = new Set<Id>();
        for(Branch__c branch : result) {
            resultIds.add(branch.Id);
            System.assertNotEquals(null, branch.Name, 'Branch name should not be null');
            System.assertNotEquals(null, branch.Id, 'Branch Id should not be null');
        }
        System.assertEquals(false, resultIds.contains(testBranches[0].Id), 'Excluded branch should not be in results');
    }
    
    @isTest
    static void testGetFullBranches_InvalidOrganization() {
        // Get test branch for valid branch ID
        Branch__c testBranch = [SELECT Id FROM Branch__c LIMIT 1];
        String invalidOrgId = '001000000000000AAA';
        
        Test.startTest();
        List<Branch__c> result = BranchController.getFullBranches(invalidOrgId, testBranch.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for invalid organization');
    }
    
    @isTest
    static void testGetFullBranches_NullParameters() {
        Test.startTest();
        List<Branch__c> result = BranchController.getFullBranches(null, null);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for null parameters');
    }
    
    @isTest
    static void testGetFullBranches_SingleBranch() {
        // Create organization with only one branch
        Organization__c singleBranchOrg = new Organization__c(Name = 'Single Branch Org');
        insert singleBranchOrg;
        
        Branch__c singleBranch = new Branch__c(
            Name = 'Only Branch',
            Location__c = 'Only Location',
            Number_of_Employees__c = 25,
            Organization__c = singleBranchOrg.Id
        );
        insert singleBranch;
        
        Test.startTest();
        List<Branch__c> result = BranchController.getFullBranches(singleBranchOrg.Id, singleBranch.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list when only one branch exists and it is excluded');
    }
}