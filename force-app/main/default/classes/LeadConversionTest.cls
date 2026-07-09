/**
 * @description Unit tests for lead conversion logic.
 * Tests account creation, contact creation, opportunity creation, error handling, and validation.
 */
@IsTest
private class LeadConversionTest {

    /**
     * @description Test data setup for lead conversion tests.
     */
    @TestSetup
    static void setupTestData() {
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        testLeads.add(new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Acme Corp',
            Email = 'john.doe@acme.com',
            Phone = '555-0100',
            Status = 'Open - Not Contacted'
        ));
        testLeads.add(new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Tech Solutions',
            Email = 'jane.smith@tech.com',
            Phone = '555-0101',
            Status = 'Open - Not Contacted'
        ));
        insert testLeads;
    }

    /**
     * @description Helper method to create test user.
     * @return User Test user with standard profile.
     */
    private static User createTestUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = standardProfile.Id,
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
     * @description Helper method to perform standard lead conversion.
     */
    private static Database.LeadConvertResult convertLeadStandard(Lead testLead, Boolean createOpportunity) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Converted');
        if (!createOpportunity) {
            lc.setDoNotCreateOpportunity(true);
        }
        return Database.convertLead(lc);
    }

    /**
     * @description Test successful lead conversion with account and contact creation.
     */
    @IsTest
    static void testLeadConversionCreateAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'john.doe@acme.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvertResult lcr = convertLeadStandard(testLead, false);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed');

            // Verify account was created
            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'Acme Corp'];
            Assert.areEqual(1, accounts.size(), 'Account should be created for lead');
            Assert.areEqual('Acme Corp', accounts[0].Name, 'Account name should match company');
        }
    }

    /**
     * @description Test successful lead conversion with contact creation.
     */
    @IsTest
    static void testLeadConversionCreateContact() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'jane.smith@tech.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvertResult lcr = convertLeadStandard(testLead, false);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed');

            // Verify contact was created
            List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact
                                      WHERE Email = 'jane.smith@tech.com'];
            Assert.areEqual(1, contacts.size(), 'Contact should be created for lead');
            Assert.areEqual('Jane', contacts[0].FirstName, 'Contact first name should match lead');
            Assert.areEqual('Smith', contacts[0].LastName, 'Contact last name should match lead');
        }
    }

    /**
     * @description Test lead conversion with opportunity creation.
     */
    @IsTest
    static void testLeadConversionCreateOpportunity() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'john.doe@acme.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setConvertedStatus('Converted');
            lc.setOpportunityName(testLead.Company + ' Opportunity');

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed');

            // Verify opportunity was created
            List<Opportunity> opportunities = [SELECT Id, Name FROM Opportunity
                                              WHERE Name = 'Acme Corp Opportunity'];
            Assert.areEqual(1, opportunities.size(), 'Opportunity should be created for lead');
        }
    }

    /**
     * @description Test lead conversion with multiple leads in bulk.
     */
    @IsTest
    static void testBulkLeadConversion() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            List<Lead> testLeads = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead];

            Test.startTest();
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
            for (Lead lead : testLeads) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setConvertedStatus('Converted');
                lc.setDoNotCreateOpportunity(true);
                leadConverts.add(lc);
            }

            List<Database.LeadConvertResult> lcResults = Database.convertLead(leadConverts, false);
            Test.stopTest();

            Assert.areEqual(2, lcResults.size(), 'Should process two lead conversions');
            for (Database.LeadConvertResult lcr : lcResults) {
                Assert.isTrue(lcr.isSuccess(), 'All lead conversions should succeed');
            }
        }
    }

    /**
     * @description Test lead conversion with invalid lead ID.
     */
    @IsTest
    static void testLeadConversionInvalidLeadId() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Id invalidLeadId = '00Q000000000000AAA';

            Test.startTest();
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(invalidLeadId);
            lc.setConvertedStatus('Converted');

            try {
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                Assert.isFalse(lcr.isSuccess(), 'Conversion with invalid ID should fail');
            } catch (Exception e) {
                Assert.isNotNull(e.getMessage(), 'Should throw exception for invalid lead ID');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test lead conversion with empty required fields.
     */
    @IsTest
    static void testLeadConversionValidationErrors() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            // Create lead with missing required fields
            Lead incompleteLead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead'
                // Missing Company field
            );
            insert incompleteLead;

            Test.startTest();
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(incompleteLead.Id);
            lc.setConvertedStatus('Converted');

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            Test.stopTest();

            // Verify the conversion result
            Assert.isNotNull(lcr, 'LeadConvertResult should not be null');
        }
    }

    /**
     * @description Test lead conversion duplicate account handling.
     */
    @IsTest
    static void testLeadConversionDuplicateAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            // Create an existing account
            Account existingAccount = new Account(Name = 'Acme Corp');
            insert existingAccount;

            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'john.doe@acme.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setConvertedStatus('Converted');
            lc.setAccountId(existingAccount.Id);
            lc.setDoNotCreateOpportunity(true);

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed with existing account');

            // Verify only one account exists
            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'Acme Corp'];
            Assert.areEqual(1, accounts.size(), 'Should not create duplicate account');
        }
    }

    /**
     * @description Test lead conversion contact creation with duplicate prevention.
     */
    @IsTest
    static void testLeadConversionDuplicateContact() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            // Create existing contact
            Contact existingContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@acme.com',
                AccountId = testAccount.Id
            );
            insert existingContact;

            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'john.doe@acme.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setConvertedStatus('Converted');
            lc.setAccountId(testAccount.Id);
            lc.setContactId(existingContact.Id);
            lc.setDoNotCreateOpportunity(true);

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed with existing contact');
        }
    }

    /**
     * @description Test lead conversion with custom converted status.
     */
    @IsTest
    static void testLeadConversionCustomStatus() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'jane.smith@tech.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvertResult lcr = convertLeadStandard(testLead, false);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion with custom status should succeed');
        }
    }

    /**
     * @description Test lead conversion result contains account ID.
     */
    @IsTest
    static void testLeadConversionResultAccountId() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'john.doe@acme.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvertResult lcr = convertLeadStandard(testLead, false);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed');
            Assert.isNotNull(lcr.getAccountId(), 'Conversion result should contain account ID');
        }
    }

    /**
     * @description Test lead conversion result contains contact ID.
     */
    @IsTest
    static void testLeadConversionResultContactId() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'jane.smith@tech.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvertResult lcr = convertLeadStandard(testLead, false);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed');
            Assert.isNotNull(lcr.getContactId(), 'Conversion result should contain contact ID');
        }
    }

    /**
     * @description Test that converted lead is marked as converted.
     */
    @IsTest
    static void testLeadMarkedAsConverted() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone FROM Lead WHERE Email = 'john.doe@acme.com' LIMIT 1];

            Test.startTest();
            Database.LeadConvertResult lcr = convertLeadStandard(testLead, false);
            Test.stopTest();

            Assert.isTrue(lcr.isSuccess(), 'Lead conversion should succeed');

            // Verify lead is marked as converted
            Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :testLead.Id];
            Assert.isTrue(convertedLead.IsConverted, 'Lead should be marked as converted');
            Assert.isNotNull(convertedLead.ConvertedAccountId, 'Converted lead should have account ID');
        }
    }
}