@isTest
public class TestAccount {
    @isTest
    static void testCreateAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.BillingCity = 'San Francisco';
        acc.BillingCountry = 'USA';
        
        insert acc;
        
        Account retrievedAcc = [SELECT Id, Name, BillingCity FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Test Account', retrievedAcc.Name);
        System.assertEquals('San Francisco', retrievedAcc.BillingCity);
    }
    
    @isTest
    static void testUpdateAccount() {
        Account acc = new Account();
        acc.Name = 'Original Name';
        insert acc;
        
        acc.Name = 'Updated Name';
        update acc;
        
        Account retrievedAcc = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', retrievedAcc.Name);
    }
    
    @isTest
    static void testDeleteAccount() {
        Account acc = new Account();
        acc.Name = 'Account to Delete';
        insert acc;
        
        delete acc;
        
        List<Account> deletedAccounts = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, deletedAccounts.size());
    }
    
    @isTest
    static void testBulkInsertAccounts() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            accounts.add(new Account(Name = 'Bulk Account ' + i));
        }
        
        insert accounts;
        
        List<Account> insertedAccounts = [SELECT Id, Name FROM Account WHERE Name LIKE 'Bulk Account%'];
        System.assertEquals(100, insertedAccounts.size());
    }
}
