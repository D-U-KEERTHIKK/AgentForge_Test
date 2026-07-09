/**
 * @description Unit tests for AccountHandler class covering insert, update, delete, and query operations.
 * Demonstrates proper bulkification by collecting records in lists before performing DML operations.
 */
@IsTest
private class AccountHandlerTest {

    /**
     * @description Test data setup method - creates test user for running tests with specific permissions.
     * @return User record with Standard User profile
     */
    private static User createTestUser() {
        Profile standardUserProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = standardUserProfile.Id,
            Alias = 'tuser',
            CommunityNickname = 'testuser' + System.currentTimeMillis(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;
        return testUser;
    }

    /**
     * @description Test data setup method - creates test accounts for use in test methods.
     * @param count The number of test accounts to create
     * @return List of test Account records
     */
    private static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                AnnualRevenue = 1000000 + (i * 100000),
                NumberOfEmployees = 50 + i
            ));
        }
        return accounts;
    }

    /**
     * @description Test single account insert operation.
     */
    @IsTest
    static void testInsertSingleAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            Account testAccount = new Account(
                Name = 'Single Test Account',
                Industry = 'Finance',
                AnnualRevenue = 500000
            );

            insert testAccount;

            Test.stopTest();

            Account retrievedAccount = [
                SELECT Id, Name, Industry, AnnualRevenue
                FROM Account
                WHERE Id = :testAccount.Id
            ];

            Assert.isNotNull(retrievedAccount);
            Assert.areEqual('Single Test Account', retrievedAccount.Name);
            Assert.areEqual('Finance', retrievedAccount.Industry);
            Assert.areEqual(500000, retrievedAccount.AnnualRevenue);
        }
    }

    /**
     * @description Test bulk insert operation with multiple accounts.
     * Demonstrates proper bulkification by collecting all records before insert.
     */
    @IsTest
    static void testBulkInsertAccounts() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            List<Account> testAccounts = createTestAccounts(100);
            insert testAccounts;

            Test.stopTest();

            List<Account> retrievedAccounts = [
                SELECT Id, Name, Industry, AnnualRevenue, NumberOfEmployees
                FROM Account
                WHERE Name LIKE 'Test Account%'
                ORDER BY Name
            ];

            Assert.areEqual(100, retrievedAccounts.size());
            Assert.areEqual('Test Account 0', retrievedAccounts[0].Name);
            Assert.areEqual('Test Account 99', retrievedAccounts[99].Name);
            Assert.areEqual('Technology', retrievedAccounts[0].Industry);
        }
    }

    /**
     * @description Test account update operation.
     */
    @IsTest
    static void testUpdateAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            Account testAccount = new Account(
                Name = 'Original Name',
                Industry = 'Healthcare'
            );
            insert testAccount;

            testAccount.Name = 'Updated Name';
            testAccount.AnnualRevenue = 750000;
            update testAccount;

            Test.stopTest();

            Account retrievedAccount = [
                SELECT Id, Name, AnnualRevenue
                FROM Account
                WHERE Id = :testAccount.Id
            ];

            Assert.areEqual('Updated Name', retrievedAccount.Name);
            Assert.areEqual(750000, retrievedAccount.AnnualRevenue);
        }
    }

    /**
     * @description Test bulk update operation with multiple accounts.
     * Demonstrates proper bulkification by collecting all records before update.
     */
    @IsTest
    static void testBulkUpdateAccounts() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            List<Account> testAccounts = createTestAccounts(50);
            insert testAccounts;

            List<Account> accountsToUpdate = new List<Account>();
            for (Account acc : testAccounts) {
                acc.Industry = 'Manufacturing';
                acc.AnnualRevenue = 2000000;
                accountsToUpdate.add(acc);
            }
            update accountsToUpdate;

            Test.stopTest();

            List<Account> retrievedAccounts = [
                SELECT Id, Industry, AnnualRevenue
                FROM Account
                WHERE Name LIKE 'Test Account%'
            ];

            Assert.areEqual(50, retrievedAccounts.size());
            for (Account acc : retrievedAccounts) {
                Assert.areEqual('Manufacturing', acc.Industry);
                Assert.areEqual(2000000, acc.AnnualRevenue);
            }
        }
    }

    /**
     * @description Test account delete operation.
     */
    @IsTest
    static void testDeleteAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            Account testAccount = new Account(Name = 'Account to Delete');
            insert testAccount;
            Id accountId = testAccount.Id;

            delete testAccount;

            Test.stopTest();

            List<Account> retrievedAccounts = [
                SELECT Id
                FROM Account
                WHERE Id = :accountId
            ];

            Assert.areEqual(0, retrievedAccounts.size());
        }
    }

    /**
     * @description Test bulk delete operation with multiple accounts.
     * Demonstrates proper bulkification by collecting all records before delete.
     */
    @IsTest
    static void testBulkDeleteAccounts() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            List<Account> testAccounts = createTestAccounts(30);
            insert testAccounts;

            delete testAccounts;

            Test.stopTest();

            List<Account> retrievedAccounts = [
                SELECT Id
                FROM Account
                WHERE Name LIKE 'Test Account%'
            ];

            Assert.areEqual(0, retrievedAccounts.size());
        }
    }

    /**
     * @description Test query with filtering conditions.
     */
    @IsTest
    static void testQueryAccountsWithFilter() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            List<Account> testAccounts = new List<Account>();
            testAccounts.add(new Account(
                Name = 'Tech Company',
                Industry = 'Technology',
                AnnualRevenue = 5000000
            ));
            testAccounts.add(new Account(
                Name = 'Health Services',
                Industry = 'Healthcare',
                AnnualRevenue = 3000000
            ));
            testAccounts.add(new Account(
                Name = 'Finance Corp',
                Industry = 'Finance',
                AnnualRevenue = 8000000
            ));
            insert testAccounts;

            List<Account> techAccounts = [
                SELECT Id, Name, Industry, AnnualRevenue
                FROM Account
                WHERE Industry = 'Technology'
            ];

            List<Account> highRevenueAccounts = [
                SELECT Id, Name, AnnualRevenue
                FROM Account
                WHERE AnnualRevenue > 5000000
            ];

            Test.stopTest();

            Assert.areEqual(1, techAccounts.size());
            Assert.areEqual('Tech Company', techAccounts[0].Name);

            Assert.areEqual(1, highRevenueAccounts.size());
            Assert.areEqual('Finance Corp', highRevenueAccounts[0].Name);
        }
    }

    /**
     * @description Test upsert operation for both insert and update scenarios.
     */
    @IsTest
    static void testUpsertAccounts() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            Account newAccount = new Account(Name = 'Upsert Test Account', Industry = 'Technology');
            insert newAccount;

            List<Account> upsertAccounts = new List<Account>();
            upsertAccounts.add(new Account(Id = newAccount.Id, AnnualRevenue = 1500000));
            upsertAccounts.add(new Account(Name = 'Brand New Account', Industry = 'Retail'));

            upsert upsertAccounts;

            Test.stopTest();

            Account updatedAccount = [
                SELECT Id, AnnualRevenue
                FROM Account
                WHERE Id = :newAccount.Id
            ];
            Assert.areEqual(1500000, updatedAccount.AnnualRevenue);

            List<Account> newAccounts = [
                SELECT Id, Name
                FROM Account
                WHERE Name = 'Brand New Account'
            ];
            Assert.areEqual(1, newAccounts.size());
        }
    }

    /**
     * @description Test governor limit compliance - bulk operations with 200 records.
     */
    @IsTest
    static void testBulkOperationsGovernorLimitCompliance() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            List<Account> testAccounts = createTestAccounts(200);
            insert testAccounts;

            List<Account> queriedAccounts = [
                SELECT Id, Name, Industry
                FROM Account
                WHERE Name LIKE 'Test Account%'
            ];

            List<Account> accountsToUpdate = new List<Account>();
            for (Account acc : queriedAccounts) {
                acc.NumberOfEmployees = 100;
                accountsToUpdate.add(acc);
            }
            update accountsToUpdate;

            delete queriedAccounts;

            Test.stopTest();

            List<Account> finalCheck = [
                SELECT Id
                FROM Account
                WHERE Name LIKE 'Test Account%'
            ];

            Assert.areEqual(0, finalCheck.size());
        }
    }

    /**
     * @description Test account query with LIMIT clause.
     */
    @IsTest
    static void testQueryAccountsWithLimit() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            List<Account> testAccounts = createTestAccounts(25);
            insert testAccounts;

            List<Account> limitedAccounts = [
                SELECT Id, Name
                FROM Account
                WHERE Name LIKE 'Test Account%'
                LIMIT 10
            ];

            Test.stopTest();

            Assert.areEqual(10, limitedAccounts.size());
        }
    }

    /**
     * @description Test handling of null and empty values.
     */
    @IsTest
    static void testNullAndEmptyValues() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();

            Account accountWithNulls = new Account(
                Name = 'Null Test Account',
                Industry = null,
                AnnualRevenue = null
            );
            insert accountWithNulls;

            Account retrievedAccount = [
                SELECT Id, Name, Industry, AnnualRevenue
                FROM Account
                WHERE Id = :accountWithNulls.Id
            ];

            Test.stopTest();

            Assert.areEqual('Null Test Account', retrievedAccount.Name);
            Assert.isNull(retrievedAccount.Industry);
            Assert.isNull(retrievedAccount.AnnualRevenue);
        }
    }
}