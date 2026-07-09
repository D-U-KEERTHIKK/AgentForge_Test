@isTest
private class LeadConversionTest {
    @testSetup
    static void setup() {
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john@example.com',
            Company = 'Acme Corp',
            Phone = '5551234567'
        );
        insert lead;
    }
    
    @isTest
    static void testLeadCreation() {
        Lead lead = [SELECT Id, Email FROM Lead LIMIT 1];
        System.assertNotEquals(null, lead.Id, 'Lead should be created');
        System.assertEquals('john@example.com', lead.Email, 'Email should match');
    }
    
    @isTest
    static void testLeadConversion() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess(), 'Lead conversion should succeed');
    }
    
    @isTest
    static void testLeadBulkConversion() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 50; i++) {
            leads.add(new Lead(
                FirstName = 'Lead' + i,
                LastName = 'Test',
                Email = 'lead' + i + '@example.com',
                Company = 'Company' + i
            ));
        }
        insert leads;
        
        System.assertEquals(51, [SELECT COUNT() FROM Lead], 'Should have 51 leads');
    }
    
    @isTest
    static void testLeadValidation() {
        Lead lead = new Lead(FirstName = 'Jane', LastName = 'Smith');
        insert lead;
        
        Lead insertedLead = [SELECT Id, FirstName, LastName FROM Lead WHERE FirstName = 'Jane'];
        System.assertNotEquals(null, insertedLead.Id, 'Lead should be inserted');
    }
}
