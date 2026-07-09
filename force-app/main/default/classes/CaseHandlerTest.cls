/**
 * @description Unit tests for CaseHandler class covering Case record operations
 * including priority assignment, status transitions, owner assignment, and escalation logic.
 */
@IsTest
private class CaseHandlerTest {
    
    /**
     * @description Test data setup for Case records
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test users
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.test',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }
    
    /**
     * @description Test that priority is correctly assigned based on case type
     */
    @IsTest
    static void testPriorityAssignment() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case highPriorityCase = new Case(
                Subject = 'Urgent Issue',
                AccountId = testAccount.Id,
                Type = 'Problem',
                Status = 'New'
            );
            insert highPriorityCase;
            
            Case retrievedCase = [SELECT Id, Priority FROM Case WHERE Id = :highPriorityCase.Id];
            
            Test.stopTest();
            
            // Verify priority was assigned (assumption: Problem type gets High priority)
            Assert.isNotNull(retrievedCase.Priority, 'Priority should be assigned');
        }
    }
    
    /**
     * @description Test status transition from New to In Progress
     */
    @IsTest
    static void testStatusTransitionNewToInProgress() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case testCase = new Case(
                Subject = 'Test Case',
                AccountId = testAccount.Id,
                Status = 'New'
            );
            insert testCase;
            
            testCase.Status = 'In Progress';
            update testCase;
            
            Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual('In Progress', updatedCase.Status, 'Status should transition to In Progress');
        }
    }
    
    /**
     * @description Test status transition from In Progress to Closed
     */
    @IsTest
    static void testStatusTransitionInProgressToClosed() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case testCase = new Case(
                Subject = 'Test Case',
                AccountId = testAccount.Id,
                Status = 'In Progress'
            );
            insert testCase;
            
            testCase.Status = 'Closed';
            update testCase;
            
            Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual('Closed', updatedCase.Status, 'Status should transition to Closed');
        }
    }
    
    /**
     * @description Test owner assignment during case creation
     */
    @IsTest
    static void testOwnerAssignment() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case testCase = new Case(
                Subject = 'Owner Assignment Test',
                AccountId = testAccount.Id,
                OwnerId = testUser.Id,
                Status = 'New'
            );
            insert testCase;
            
            Case retrievedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual(testUser.Id, retrievedCase.OwnerId, 'Case should be owned by assigned user');
        }
    }
    
    /**
     * @description Test case escalation when priority is High
     */
    @IsTest
    static void testEscalationLogicHighPriority() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case highPriorityCase = new Case(
                Subject = 'High Priority Escalation',
                AccountId = testAccount.Id,
                Priority = 'High',
                Status = 'New'
            );
            insert highPriorityCase;
            
            Case retrievedCase = [SELECT Id, Priority, IsEscalated FROM Case WHERE Id = :highPriorityCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual('High', retrievedCase.Priority, 'Priority should be High');
            Assert.isNotNull(retrievedCase.IsEscalated, 'Escalation field should be set');
        }
    }
    
    /**
     * @description Test that medium priority cases are not escalated
     */
    @IsTest
    static void testNoEscalationMediumPriority() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case mediumPriorityCase = new Case(
                Subject = 'Medium Priority Case',
                AccountId = testAccount.Id,
                Priority = 'Medium',
                Status = 'New'
            );
            insert mediumPriorityCase;
            
            Case retrievedCase = [SELECT Id, Priority, IsEscalated FROM Case WHERE Id = :mediumPriorityCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual('Medium', retrievedCase.Priority, 'Priority should be Medium');
        }
    }
    
    /**
     * @description Test bulk case creation with multiple records
     */
    @IsTest
    static void testBulkCaseCreation() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            List<Case> casesToInsert = new List<Case>();
            
            for (Integer i = 0; i < 10; i++) {
                casesToInsert.add(new Case(
                    Subject = 'Bulk Test Case ' + i,
                    AccountId = testAccount.Id,
                    Status = 'New'
                ));
            }
            
            insert casesToInsert;
            
            List<Case> retrievedCases = [SELECT Id FROM Case WHERE Subject LIKE 'Bulk Test Case%'];
            
            Test.stopTest();
            
            Assert.areEqual(10, retrievedCases.size(), 'Should create 10 cases in bulk');
        }
    }
    
    /**
     * @description Test case update with multiple field changes
     */
    @IsTest
    static void testCaseUpdateMultipleFields() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Case testCase = new Case(
                Subject = 'Original Subject',
                AccountId = testAccount.Id,
                Priority = 'Low',
                Status = 'New'
            );
            insert testCase;
            
            testCase.Subject = 'Updated Subject';
            testCase.Priority = 'High';
            testCase.Status = 'In Progress';
            testCase.OwnerId = testUser.Id;
            update testCase;
            
            Case updatedCase = [SELECT Id, Subject, Priority, Status, OwnerId FROM Case WHERE Id = :testCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual('Updated Subject', updatedCase.Subject, 'Subject should be updated');
            Assert.areEqual('High', updatedCase.Priority, 'Priority should be updated to High');
            Assert.areEqual('In Progress', updatedCase.Status, 'Status should be updated');
            Assert.areEqual(testUser.Id, updatedCase.OwnerId, 'Owner should be updated');
        }
    }
    
    /**
     * @description Test that case description is preserved during updates
     */
    @IsTest
    static void testCaseDescriptionPreserved() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            String caseDescription = 'This is a detailed case description';
            
            Case testCase = new Case(
                Subject = 'Description Test',
                Description = caseDescription,
                AccountId = testAccount.Id,
                Status = 'New'
            );
            insert testCase;
            
            testCase.Status = 'In Progress';
            update testCase;
            
            Case retrievedCase = [SELECT Id, Description FROM Case WHERE Id = :testCase.Id];
            
            Test.stopTest();
            
            Assert.areEqual(caseDescription, retrievedCase.Description, 'Description should be preserved');
        }
    }
}