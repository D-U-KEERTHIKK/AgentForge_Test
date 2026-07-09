/**
 * @description Unit tests for Contact record management including CRUD operations,
 * email validation, phone number validation, and relationship tests with Account.
 */
@IsTest
private class ContactManagerTest {

    /**
     * @description Test setup to create test data.
     */
    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '555-123-4567',
            AccountId = testAccount.Id
        ));
        contacts.add(new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@example.com',
            Phone = '555-987-6543',
            AccountId = testAccount.Id
        ));
        insert contacts;
    }

    /**
     * @description Helper method to create a test user.
     * @return User The created test user.
     */
    private static User createTestUser() {
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        return testUser;
    }

    /**
     * @description Test creating a new Contact with valid data.
     */
    @IsTest
    static void testCreateContactWithValidData() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Contact newContact = new Contact(
            FirstName = 'Alice',
            LastName = 'Johnson',
            Email = 'alice.johnson@example.com',
            Phone = '555-111-2222',
            AccountId = testAccount.Id
        );

        Test.startTest();
        System.runAs(testUser) {
            insert newContact;
        }
        Test.stopTest();

        Contact insertedContact = [
            SELECT Id, FirstName, LastName, Email, Phone, AccountId
            FROM Contact
            WHERE Id = :newContact.Id
        ];

        Assert.isNotNull(insertedContact.Id);
        Assert.areEqual('Alice', insertedContact.FirstName);
        Assert.areEqual('Johnson', insertedContact.LastName);
        Assert.areEqual('alice.johnson@example.com', insertedContact.Email);
        Assert.areEqual('555-111-2222', insertedContact.Phone);
        Assert.areEqual(testAccount.Id, insertedContact.AccountId);
    }

    /**
     * @description Test creating a Contact without required AccountId.
     */
    @IsTest
    static void testCreateContactWithoutAccount() {
        User testUser = createTestUser();

        Contact contactWithoutAccount = new Contact(
            FirstName = 'Bob',
            LastName = 'Wilson',
            Email = 'bob.wilson@example.com'
        );

        Test.startTest();
        System.runAs(testUser) {
            insert contactWithoutAccount;
        }
        Test.stopTest();

        Contact insertedContact = [
            SELECT Id, FirstName, LastName, AccountId
            FROM Contact
            WHERE Id = :contactWithoutAccount.Id
        ];

        Assert.isNotNull(insertedContact.Id);
        Assert.isNull(insertedContact.AccountId);
    }

    /**
     * @description Test reading Contact records.
     */
    @IsTest
    static void testReadContacts() {
        User testUser = createTestUser();

        Test.startTest();
        System.runAs(testUser) {
            List<Contact> contacts = [
                SELECT Id, FirstName, LastName, Email, Phone, AccountId
                FROM Contact
                ORDER BY LastName
            ];

            Assert.areEqual(2, contacts.size());
            Assert.areEqual('Doe', contacts[0].LastName);
            Assert.areEqual('Smith', contacts[1].LastName);
        }
        Test.stopTest();
    }

    /**
     * @description Test updating Contact email address.
     */
    @IsTest
    static void testUpdateContactEmail() {
        User testUser = createTestUser();
        Contact contactToUpdate = [SELECT Id, Email FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        String originalEmail = contactToUpdate.Email;

        Test.startTest();
        System.runAs(testUser) {
            contactToUpdate.Email = 'john.doe.new@example.com';
            update contactToUpdate;
        }
        Test.stopTest();

        Contact updatedContact = [SELECT Id, Email FROM Contact WHERE Id = :contactToUpdate.Id];

        Assert.areNotEqual(originalEmail, updatedContact.Email);
        Assert.areEqual('john.doe.new@example.com', updatedContact.Email);
    }

    /**
     * @description Test updating Contact phone number.
     */
    @IsTest
    static void testUpdateContactPhone() {
        User testUser = createTestUser();
        Contact contactToUpdate = [SELECT Id, Phone FROM Contact WHERE LastName = 'Smith' LIMIT 1];
        String originalPhone = contactToUpdate.Phone;

        Test.startTest();
        System.runAs(testUser) {
            contactToUpdate.Phone = '555-999-8888';
            update contactToUpdate;
        }
        Test.stopTest();

        Contact updatedContact = [SELECT Id, Phone FROM Contact WHERE Id = :contactToUpdate.Id];

        Assert.areNotEqual(originalPhone, updatedContact.Phone);
        Assert.areEqual('555-999-8888', updatedContact.Phone);
    }

    /**
     * @description Test deleting a Contact.
     */
    @IsTest
    static void testDeleteContact() {
        User testUser = createTestUser();
        Contact contactToDelete = [SELECT Id FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        Id contactIdToDelete = contactToDelete.Id;

        Test.startTest();
        System.runAs(testUser) {
            delete contactToDelete;
        }
        Test.stopTest();

        List<Contact> deletedContacts = [SELECT Id FROM Contact WHERE Id = :contactIdToDelete];

        Assert.areEqual(0, deletedContacts.size());
    }

    /**
     * @description Test upserting a Contact (insert scenario).
     */
    @IsTest
    static void testUpsertContactInsert() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Contact newContact = new Contact(
            FirstName = 'Charlie',
            LastName = 'Brown',
            Email = 'charlie.brown@example.com',
            Phone = '555-444-5555',
            AccountId = testAccount.Id
        );

        Test.startTest();
        System.runAs(testUser) {
            upsert newContact;
        }
        Test.stopTest();

        Contact upsertedContact = [
            SELECT Id, FirstName, LastName, Email
            FROM Contact
            WHERE Email = 'charlie.brown@example.com'
        ];

        Assert.isNotNull(upsertedContact.Id);
        Assert.areEqual('Charlie', upsertedContact.FirstName);
    }

    /**
     * @description Test upserting a Contact (update scenario).
     */
    @IsTest
    static void testUpsertContactUpdate() {
        User testUser = createTestUser();
        Contact contactToUpsert = [SELECT Id, FirstName FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        contactToUpsert.FirstName = 'Jonathan';

        Test.startTest();
        System.runAs(testUser) {
            upsert contactToUpsert;
        }
        Test.stopTest();

        Contact upsertedContact = [SELECT Id, FirstName FROM Contact WHERE Id = :contactToUpsert.Id];

        Assert.areEqual('Jonathan', upsertedContact.FirstName);
    }

    /**
     * @description Test valid email addresses.
     */
    @IsTest
    static void testValidEmailAddresses() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        List<String> validEmails = new List<String>{
            'test@example.com',
            'user.name@example.co.uk',
            'test123@example.org',
            'test+tag@example.com'
        };

        Test.startTest();
        System.runAs(testUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < validEmails.size(); i++) {
                contactsToInsert.add(new Contact(
                    FirstName = 'TestFirst' + i,
                    LastName = 'TestLast' + i,
                    Email = validEmails[i],
                    AccountId = testAccount.Id
                ));
            }
            insert contactsToInsert;
        }
        Test.stopTest();

        List<Contact> insertedContacts = [
            SELECT Email FROM Contact WHERE Email IN :validEmails
        ];

        Assert.areEqual(validEmails.size(), insertedContacts.size());
    }

    /**
     * @description Test Contact with invalid email format.
     */
    @IsTest
    static void testInvalidEmailFormat() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Contact invalidEmailContact = new Contact(
            FirstName = 'Invalid',
            LastName = 'Email',
            Email = 'not-an-email',
            AccountId = testAccount.Id
        );

        Test.startTest();
        System.runAs(testUser) {
            try {
                insert invalidEmailContact;
                Assert.fail('Expected email validation error');
            } catch (DmlException e) {
                Assert.isTrue(e.getMessage().contains('INVALID_EMAIL_ADDRESS'));
            }
        }
        Test.stopTest();
    }

    /**
     * @description Test valid phone number formats.
     */
    @IsTest
    static void testValidPhoneNumbers() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        List<String> validPhones = new List<String>{
            '555-123-4567',
            '(555) 123-4567',
            '+1-555-123-4567',
            '5551234567'
        };

        Test.startTest();
        System.runAs(testUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < validPhones.size(); i++) {
                contactsToInsert.add(new Contact(
                    FirstName = 'PhoneTest' + i,
                    LastName = 'PhoneLast' + i,
                    Phone = validPhones[i],
                    AccountId = testAccount.Id
                ));
            }
            insert contactsToInsert;
        }
        Test.stopTest();

        List<Contact> insertedContacts = [
            SELECT Phone FROM Contact WHERE Phone IN :validPhones
        ];

        Assert.areEqual(validPhones.size(), insertedContacts.size());
    }

    /**
     * @description Test Contact relationship with Account.
     */
    @IsTest
    static void testContactAccountRelationship() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            List<Contact> relatedContacts = [
                SELECT Id, FirstName, LastName, AccountId, Account.Name
                FROM Contact
                WHERE AccountId = :testAccount.Id
            ];

            Assert.areEqual(2, relatedContacts.size());
            for (Contact contact : relatedContacts) {
                Assert.areEqual(testAccount.Id, contact.AccountId);
                Assert.areEqual(testAccount.Name, contact.Account.Name);
            }
        }
        Test.stopTest();
    }

    /**
     * @description Test reassigning Contact to a different Account.
     */
    @IsTest
    static void testReassignContactToAnotherAccount() {
        User testUser = createTestUser();

        Account account2 = new Account(Name = 'Test Account 2');
        insert account2;

        Contact contactToReassign = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        Id originalAccountId = contactToReassign.AccountId;

        Test.startTest();
        System.runAs(testUser) {
            contactToReassign.AccountId = account2.Id;
            update contactToReassign;
        }
        Test.stopTest();

        Contact reassignedContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactToReassign.Id];

        Assert.areNotEqual(originalAccountId, reassignedContact.AccountId);
        Assert.areEqual(account2.Id, reassignedContact.AccountId);
    }

    /**
     * @description Test bulk contact operations.
     */
    @IsTest
    static void testBulkContactOperations() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 100; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Bulk' + i,
                LastName = 'Contact' + i,
                Email = 'bulk' + i + '@example.com',
                Phone = '555-' + String.valueOf(i).leftPad(3, '0') + '-0000',
                AccountId = testAccount.Id
            ));
        }

        Test.startTest();
        System.runAs(testUser) {
            insert bulkContacts;
        }
        Test.stopTest();

        List<Contact> insertedBulkContacts = [
            SELECT Id FROM Contact WHERE FirstName LIKE 'Bulk%'
        ];

        Assert.areEqual(100, insertedBulkContacts.size());
    }

    /**
     * @description Test Contact query with Account information.
     */
    @IsTest
    static void testContactQueryWithAccountInfo() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            List<Contact> contactsWithAccount = [
                SELECT Id, FirstName, LastName, Email, Phone, AccountId, Account.Name
                FROM Contact
                WHERE AccountId = :testAccount.Id
                ORDER BY LastName
            ];

            Assert.areEqual(2, contactsWithAccount.size());
            Assert.isNotNull(contactsWithAccount[0].Account);
            Assert.areEqual(testAccount.Name, contactsWithAccount[0].Account.Name);
        }
        Test.stopTest();
    }

    /**
     * @description Test updating multiple Contacts at once.
     */
    @IsTest
    static void testBulkUpdateContacts() {
        User testUser = createTestUser();
        List<Contact> contactsToUpdate = [SELECT Id, Phone FROM Contact];

        Test.startTest();
        System.runAs(testUser) {
            for (Contact contact : contactsToUpdate) {
                contact.Phone = '555-000-0000';
            }
            update contactsToUpdate;
        }
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT Id, Phone FROM Contact];

        for (Contact contact : updatedContacts) {
            Assert.areEqual('555-000-0000', contact.Phone);
        }
    }

    /**
     * @description Test deleting multiple Contacts at once.
     */
    @IsTest
    static void testBulkDeleteContacts() {
        User testUser = createTestUser();
        List<Contact> contactsToDelete = [SELECT Id FROM Contact];

        Test.startTest();
        System.runAs(testUser) {
            delete contactsToDelete;
        }
        Test.stopTest();

        List<Contact> remainingContacts = [SELECT Id FROM Contact];

        Assert.areEqual(0, remainingContacts.size());
    }
}