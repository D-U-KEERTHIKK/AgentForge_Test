@isTest
public class TestOpportunity {
    @isTest
    static void testCreateOpportunity() {
        Account acc = new Account(Name = 'Opportunity Account');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today().addMonths(3);
        opp.Amount = 50000;
        
        insert opp;
        
        Opportunity retrievedOpp = [SELECT Id, Name, StageName, Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Test Opportunity', retrievedOpp.Name);
        System.assertEquals('Prospecting', retrievedOpp.StageName);
        System.assertEquals(50000, retrievedOpp.Amount);
    }
    
    @isTest
    static void testOpportunityStageProgression() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Stage Test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today().addMonths(2);
        insert opp;
        
        opp.StageName = 'Qualification';
        update opp;
        
        Opportunity retrievedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Qualification', retrievedOpp.StageName);
    }
    
    @isTest
    static void testOpportunityAmountCalculation() {
        Account acc = new Account(Name = 'Amount Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Amount Test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Negotiation/Review';
        opp.CloseDate = System.today().addMonths(1);
        opp.Amount = 100000;
        insert opp;
        
        Opportunity retrievedOpp = [SELECT Id, Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(100000, retrievedOpp.Amount);
        System.assert(retrievedOpp.Amount > 0);
    }
    
    @isTest
    static void testOpportunityClosure() {
        Account acc = new Account(Name = 'Closure Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Closure Test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = System.today();
        opp.Amount = 75000;
        insert opp;
        
        Opportunity retrievedOpp = [SELECT Id, StageName, Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', retrievedOpp.StageName);
        System.assertEquals(75000, retrievedOpp.Amount);
    }
    
    @isTest
    static void testBulkOpportunityCreation() {
        Account acc = new Account(Name = 'Bulk Opp Account');
        insert acc;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 25; i++) {
            opportunities.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addMonths(6),
                Amount = 10000 * (i + 1)
            ));
        }
        
        insert opportunities;
        
        List<Opportunity> insertedOpps = [SELECT Id FROM Opportunity WHERE Name LIKE 'Bulk Opp%'];
        System.assertEquals(25, insertedOpps.size());
    }
}
