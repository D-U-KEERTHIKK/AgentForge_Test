@isTest
private class ContactManagerTest {
    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact contact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane@example.com',
            AccountId = acc.Id,
            Phone = '5559876543'
        );
        insert contact;
    }
    
    @isTest
    static void testContactCreation() {
        Contact contact = [SELECT Id, Email FROM Contact LIMIT 1];
        System.assertNotEquals(null, contact.Id, 'Contact should be created');
        System.assertEquals('jane@example.com', contact.Email, 'Email should match');
    }
    
    @isTest
    static void testContactUpdate() {
        Contact contact = [SELECT Id, Phone FROM Contact LIMIT 1];
        contact.Phone = '5551111111';
        update contact;
        
        Contact updatedContact = [SELECT Phone FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('5551111111', updatedContact.Phone, 'Phone should be updated');
    }
    
    @isTest
    static void testContactRelationship() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        System.assertNotEquals(null, contact.AccountId, 'Contact should be related to Account');
    }
    
    @isTest
    static void testContactBulkInsert() {
        List<Contact> contacts = new List<Contact>();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        for (Integer i = 0; i < 50; i++) {
            contacts.add(new Contact(
                FirstName = 'Contact' + i,
                LastName = 'Test',
                Email = 'contact' + i + '@example.com',
                AccountId = acc.Id
            ));
        }
        insert contacts;
        
        System.assertEquals(51, [SELECT COUNT() FROM Contact], 'Should have 51 contacts');
    }
}
