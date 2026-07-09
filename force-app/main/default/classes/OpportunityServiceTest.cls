@isTest
private class OpportunityServiceTest {
    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 50000
        );
        insert opp;
    }
    
    @isTest
    static void testOpportunityCreation() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        System.assertNotEquals(null, opp.Id, 'Opportunity should be created');
    }
    
    @isTest
    static void testOpportunityAmountValidation() {
        Opportunity opp = [SELECT Id, Amount FROM Opportunity LIMIT 1];
        System.assertEquals(50000, opp.Amount, 'Amount should match');
    }
    
    @isTest
    static void testOpportunityStageTransition() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        opp.StageName = 'Qualification';
        update opp;
        
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Qualification', updatedOpp.StageName, 'Stage should be updated');
    }
    
    @isTest
    static void testOpportunityBulkUpdate() {
        List<Opportunity> opps = new List<Opportunity>();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        for (Integer i = 0; i < 50; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 10000 + (i * 100)
            ));
        }
        insert opps;
        
        System.assertEquals(51, [SELECT COUNT() FROM Opportunity], 'Should have 51 opportunities');
    }
}
