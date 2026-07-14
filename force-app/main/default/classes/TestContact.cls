@isTest
public class TestContact {
    @isTest
    static void testCreateContact() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'Doe';
        con.Email = 'john.doe@example.com';
        con.AccountId = acc.Id;
        
        insert con;
        
        Contact retrievedCon = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :con.Id];
        System.assertEquals('John', retrievedCon.FirstName);
        System.assertEquals('Doe', retrievedCon.LastName);
        System.assertEquals('john.doe@example.com', retrievedCon.Email);
    }
    
    @isTest
    static void testContactEmailValidation() {
        Contact con = new Contact();
        con.FirstName = 'Jane';
        con.LastName = 'Smith';
        con.Email = 'invalid-email';
        
        insert con;
        
        Contact retrievedCon = [SELECT Id, Email FROM Contact WHERE Id = :con.Id];
        System.assertNotEquals(null, retrievedCon.Email);
    }
    
    @isTest
    static void testContactAccountRelationship() {
        Account acc = new Account(Name = 'Parent Account');
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Related';
        con.LastName = 'Contact';
        con.AccountId = acc.Id;
        insert con;
        
        Contact retrievedCon = [SELECT Id, AccountId FROM Contact WHERE Id = :con.Id];
        System.assertEquals(acc.Id, retrievedCon.AccountId);
    }
    
    @isTest
    static void testUpdateContact() {
        Contact con = new Contact();
        con.FirstName = 'Initial';
        con.LastName = 'Name';
        insert con;
        
        con.Email = 'updated@example.com';
        update con;
        
        Contact retrievedCon = [SELECT Id, Email FROM Contact WHERE Id = :con.Id];
        System.assertEquals('updated@example.com', retrievedCon.Email);
    }
    
    @isTest
    static void testBulkContactCreation() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 50; i++) {
            contacts.add(new Contact(FirstName = 'Bulk', LastName = 'Contact ' + i));
        }
        
        insert contacts;
        
        List<Contact> insertedContacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%'];
        System.assertEquals(50, insertedContacts.size());
    }
}
