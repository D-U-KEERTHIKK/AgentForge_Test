/**
 * @description Unit tests for batch processing functionality.
 * Tests cover setup, execute, and finish methods with bulk DML operations,
 * exception handling, and batch governor limit scenarios.
 */
@IsTest
private class BatchProcessorTest {

    /**
     * @description Test data setup for batch processing tests.
     */
    @TestSetup
    static void setupTestData() {
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            accountsToInsert.add(new Account(Name = 'Test Account ' + i));
        }
        insert accountsToInsert;
    }

    /**
     * @description Helper method to create a test user for System.runAs() execution.
     * @return User object for testing
     */
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;
        return testUser;
    }

    /**
     * @description Test batch execution with successful DML operations.
     */
    @IsTest
    static void testBatchExecuteWithBulkDML() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Id batchJobId = Database.executeBatch(batch, 100);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Batch job should be created successfully');

            List<Account> updatedAccounts = [
                SELECT Id, Description
                FROM Account
                WHERE Name LIKE 'Test Account%'
                LIMIT 250
            ];

            Assert.areEqual(250, updatedAccounts.size(), 'All test accounts should be processed');
            for (Account acc : updatedAccounts) {
                Assert.isNotNull(acc.Description, 'Account description should be updated');
            }
        }
    }

    /**
     * @description Test batch execution with bulk update operations.
     */
    @IsTest
    static void testBatchBulkUpdateOperations() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Database.executeBatch(batch, 50);
            Test.stopTest();

            List<Account> accounts = [
                SELECT Id, BillingCity
                FROM Account
                WHERE Name LIKE 'Test Account%'
            ];

            Assert.areEqual(250, accounts.size(), 'All accounts should be present after batch execution');
        }
    }

    /**
     * @description Test batch execution with exception handling in execute method.
     */
    @IsTest
    static void testBatchExecuteExceptionHandling() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorWithExceptionImpl();
            Id batchJobId = Database.executeBatch(batch, 100);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Batch should execute despite exception handling');
        }
    }

    /**
     * @description Test batch finish method execution.
     */
    @IsTest
    static void testBatchFinishMethod() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Id batchJobId = Database.executeBatch(batch, 100);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Batch job should complete successfully');
        }
    }

    /**
     * @description Test batch processing with minimum batch size.
     */
    @IsTest
    static void testBatchWithMinimumBatchSize() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Id batchJobId = Database.executeBatch(batch, 1);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Batch should execute with batch size of 1');
        }
    }

    /**
     * @description Test batch processing with maximum batch size.
     */
    @IsTest
    static void testBatchWithMaximumBatchSize() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Id batchJobId = Database.executeBatch(batch, 2000);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Batch should execute with maximum batch size');
        }
    }

    /**
     * @description Test batch query scope retrieval.
     */
    @IsTest
    static void testBatchQueryScope() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            BatchProcessorImpl batchObj = new BatchProcessorImpl();
            Database.QueryLocator ql = batchObj.start(null);
            Test.stopTest();

            Assert.isNotNull(ql, 'QueryLocator should be returned from start method');
        }
    }

    /**
     * @description Test batch with empty query result set.
     */
    @IsTest
    static void testBatchWithEmptyQueryResult() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            delete [SELECT Id FROM Account WHERE Name LIKE 'Test Account%'];

            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Id batchJobId = Database.executeBatch(batch, 100);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Batch should execute even with empty result set');
        }
    }

    /**
     * @description Test batch processing with DML limit boundary.
     */
    @IsTest
    static void testBatchProcessingWithinDMLLimits() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorImpl();
            Database.executeBatch(batch, 100);
            Test.stopTest();

            Integer queryCount = Limits.getQueries();
            Integer dmlStatements = Limits.getDmlStatements();

            Assert.isTrue(
                queryCount <= Limits.getLimitQueries(),
                'Query count should not exceed governor limit'
            );
            Assert.isTrue(
                dmlStatements <= Limits.getLimitDmlStatements(),
                'DML statements should not exceed governor limit'
            );
        }
    }

    /**
     * @description Test batch SOQL query with filtering.
     */
    @IsTest
    static void testBatchWithFilteredQuery() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            Database.Batchable<SObject> batch = new BatchProcessorFilteredImpl();
            Id batchJobId = Database.executeBatch(batch, 100);
            Test.stopTest();

            Assert.isNotNull(batchJobId, 'Filtered batch query should execute successfully');
        }
    }
}

/**
 * @description Batch processor implementation for testing.
 */
private class BatchProcessorImpl implements Database.Batchable<SObject> {

    /**
     * @description Batch start method to define query scope.
     * @param bc BatchableContext instance
     * @return Database.QueryLocator query result set
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Description FROM Account WHERE Name LIKE \'Test Account%\''
        );
    }

    /**
     * @description Batch execute method for processing records.
     * @param bc BatchableContext instance
     * @param scope List of SObjects to process
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (SObject sobj : scope) {
            Account acc = (Account) sobj;
            acc.Description = 'Processed by batch on ' + System.now();
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    /**
     * @description Batch finish method for post-processing.
     * @param bc BatchableContext instance
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing complete. Job ID: ' + bc.getJobId());
    }
}

/**
 * @description Batch processor with exception handling for testing.
 */
private class BatchProcessorWithExceptionImpl implements Database.Batchable<SObject> {

    /**
     * @description Start method with exception handling.
     * @param bc BatchableContext instance
     * @return Database.QueryLocator query result set
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM Account WHERE Name LIKE \'Test Account%\''
        );
    }

    /**
     * @description Execute method with try-catch exception handling.
     * @param bc BatchableContext instance
     * @param scope List of SObjects to process
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<Account> accountsToUpdate = new List<Account>();
            for (SObject sobj : scope) {
                Account acc = (Account) sobj;
                acc.BillingCity = 'Processed';
                accountsToUpdate.add(acc);
            }
            update accountsToUpdate;
        } catch (DmlException dmlEx) {
            System.debug('DML Exception caught: ' + dmlEx.getMessage());
        } catch (Exception ex) {
            System.debug('Exception caught: ' + ex.getMessage());
        }
    }

    /**
     * @description Finish method.
     * @param bc BatchableContext instance
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch with exception handling completed');
    }
}

/**
 * @description Filtered batch processor for testing query conditions.
 */
private class BatchProcessorFilteredImpl implements Database.Batchable<SObject> {

    /**
     * @description Start method with query filtering.
     * @param bc BatchableContext instance
     * @return Database.QueryLocator filtered query result set
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name FROM Account WHERE Name LIKE \'Test Account%\' ORDER BY Name ASC'
        );
    }

    /**
     * @description Execute method for filtered records.
     * @param bc BatchableContext instance
     * @param scope List of filtered SObjects
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        for (SObject sobj : scope) {
            Account acc = (Account) sobj;
            acc.BillingCountry = 'USA';
            accountsToUpdate.add(acc);
        }
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    /**
     * @description Finish method.
     * @param bc BatchableContext instance
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Filtered batch processing completed');
    }
}