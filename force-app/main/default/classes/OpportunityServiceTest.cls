/**
 * @description Unit tests for OpportunityService class
 * Tests cover revenue calculations, stage transitions, and date validations
 * with both positive and negative scenarios
 */
@IsTest
private class OpportunityServiceTest {
    
    /**
     * @description Setup test data for opportunity tests
     */
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 50000
        );
        insert opp;
    }
    
    /**
     * @description Create test user with standard profile
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
     * @description Test successful opportunity creation with valid data
     */
    @IsTest
    static void testCreateOpportunitySuccess() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Test.startTest();
            Opportunity opp = new Opportunity(
                Name = 'New Opportunity',
                AccountId = testAccount.Id,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(60),
                Amount = 75000
            );
            insert opp;
            Test.stopTest();
            
            Opportunity insertedOpp = [SELECT Id, Name, Amount FROM Opportunity WHERE Name = 'New Opportunity'];
            Assert.isNotNull(insertedOpp.Id);
            Assert.areEqual('New Opportunity', insertedOpp.Name);
            Assert.areEqual(75000, insertedOpp.Amount);
        }
    }
    
    /**
     * @description Test revenue calculation for single opportunity
     */
    @IsTest
    static void testRevenueCalculationSingleOpportunity() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Opportunity opp = [SELECT Id, Amount FROM Opportunity LIMIT 1];
            
            Test.startTest();
            Decimal revenue = OpportunityService.calculateRevenue(new List<Opportunity> { opp });
            Test.stopTest();
            
            Assert.areEqual(50000, revenue);
        }
    }
    
    /**
     * @description Test revenue calculation for multiple opportunities
     */
    @IsTest
    static void testRevenueCalculationMultipleOpportunities() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            List<Opportunity> oppsToCreate = new List<Opportunity>();
            oppsToCreate.add(new Opportunity(
                Name = 'Opp 1',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 25000
            ));
            oppsToCreate.add(new Opportunity(
                Name = 'Opp 2',
                AccountId = testAccount.Id,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(45),
                Amount = 35000
            ));
            
            Test.startTest();
            insert oppsToCreate;
            List<Opportunity> allOpps = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :testAccount.Id];
            Decimal totalRevenue = OpportunityService.calculateRevenue(allOpps);
            Test.stopTest();
            
            Assert.areEqual(110000, totalRevenue);
        }
    }
    
    /**
     * @description Test revenue calculation with empty list
     */
    @IsTest
    static void testRevenueCalculationEmptyList() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Decimal revenue = OpportunityService.calculateRevenue(new List<Opportunity>());
            Test.stopTest();
            
            Assert.areEqual(0, revenue);
        }
    }
    
    /**
     * @description Test revenue calculation with null amounts
     */
    @IsTest
    static void testRevenueCalculationWithNullAmounts() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Opportunity oppNoAmount = new Opportunity(
                Name = 'No Amount Opp',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            );
            
            Test.startTest();
            insert oppNoAmount;
            List<Opportunity> opps = [SELECT Id, Amount FROM Opportunity WHERE Name = 'No Amount Opp'];
            Decimal revenue = OpportunityService.calculateRevenue(opps);
            Test.stopTest();
            
            Assert.areEqual(0, revenue);
        }
    }
    
    /**
     * @description Test valid stage transition from Prospecting to Qualification
     */
    @IsTest
    static void testValidStageTransitionProspectingToQualification() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
            opp.StageName = 'Prospecting';
            update opp;
            
            Test.startTest();
            Boolean isValid = OpportunityService.isValidStageTransition('Prospecting', 'Qualification');
            Test.stopTest();
            
            Assert.isTrue(isValid);
        }
    }
    
    /**
     * @description Test valid stage transition from Qualification to Negotiation
     */
    @IsTest
    static void testValidStageTransitionQualificationToNegotiation() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidStageTransition('Qualification', 'Negotiation/Review');
            Test.stopTest();
            
            Assert.isTrue(isValid);
        }
    }
    
    /**
     * @description Test valid stage transition from Negotiation to Closed Won
     */
    @IsTest
    static void testValidStageTransitionNegotiationToClosedWon() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidStageTransition('Negotiation/Review', 'Closed Won');
            Test.stopTest();
            
            Assert.isTrue(isValid);
        }
    }
    
    /**
     * @description Test invalid backward stage transition
     */
    @IsTest
    static void testInvalidBackwardStageTransition() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidStageTransition('Closed Won', 'Prospecting');
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test invalid lateral stage transition
     */
    @IsTest
    static void testInvalidLateralStageTransition() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidStageTransition('Qualification', 'Prospecting');
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test invalid stage transition from Closed Lost
     */
    @IsTest
    static void testInvalidTransitionFromClosedLost() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidStageTransition('Closed Lost', 'Qualification');
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test close date validation with valid future date
     */
    @IsTest
    static void testCloseDateValidationFutureDate() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Date futureDate = Date.today().addDays(30);
            
            Test.startTest();
            Boolean isValid = OpportunityService.isValidCloseDate(futureDate);
            Test.stopTest();
            
            Assert.isTrue(isValid);
        }
    }
    
    /**
     * @description Test close date validation with today's date
     */
    @IsTest
    static void testCloseDateValidationTodayDate() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Date todayDate = Date.today();
            
            Test.startTest();
            Boolean isValid = OpportunityService.isValidCloseDate(todayDate);
            Test.stopTest();
            
            Assert.isTrue(isValid);
        }
    }
    
    /**
     * @description Test close date validation with past date
     */
    @IsTest
    static void testCloseDateValidationPastDate() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Date pastDate = Date.today().addDays(-1);
            
            Test.startTest();
            Boolean isValid = OpportunityService.isValidCloseDate(pastDate);
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test close date validation with null date
     */
    @IsTest
    static void testCloseDateValidationNullDate() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidCloseDate(null);
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test updating opportunity with valid stage transition
     */
    @IsTest
    static void testUpdateOpportunityWithValidTransition() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
            
            Test.startTest();
            opp.StageName = 'Qualification';
            update opp;
            Test.stopTest();
            
            Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
            Assert.areEqual('Qualification', updatedOpp.StageName);
        }
    }
    
    /**
     * @description Test filtering opportunities by stage
     */
    @IsTest
    static void testFilterOpportunitiesByStage() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            List<Opportunity> oppsToCreate = new List<Opportunity>();
            oppsToCreate.add(new Opportunity(
                Name = 'Prospecting Opp',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 20000
            ));
            oppsToCreate.add(new Opportunity(
                Name = 'Qualification Opp',
                AccountId = testAccount.Id,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(45),
                Amount = 30000
            ));
            insert oppsToCreate;
            
            Test.startTest();
            List<Opportunity> allOpps = [SELECT Id, StageName FROM Opportunity WHERE AccountId = :testAccount.Id];
            List<Opportunity> prospectingOpps = OpportunityService.filterByStage(allOpps, 'Prospecting');
            Test.stopTest();
            
            Assert.areEqual(2, prospectingOpps.size());
        }
    }
    
    /**
     * @description Test filtering opportunities with empty result
     */
    @IsTest
    static void testFilterOpportunitiesByStageEmptyResult() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            Test.startTest();
            List<Opportunity> allOpps = [SELECT Id, StageName FROM Opportunity WHERE AccountId = :testAccount.Id];
            List<Opportunity> closedWonOpps = OpportunityService.filterByStage(allOpps, 'Closed Won');
            Test.stopTest();
            
            Assert.areEqual(0, closedWonOpps.size());
        }
    }
    
    /**
     * @description Test amount validation with positive amount
     */
    @IsTest
    static void testAmountValidationPositive() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidAmount(50000);
            Test.stopTest();
            
            Assert.isTrue(isValid);
        }
    }
    
    /**
     * @description Test amount validation with zero amount
     */
    @IsTest
    static void testAmountValidationZero() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidAmount(0);
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test amount validation with negative amount
     */
    @IsTest
    static void testAmountValidationNegative() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidAmount(-50000);
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
    
    /**
     * @description Test amount validation with null amount
     */
    @IsTest
    static void testAmountValidationNull() {
        User testUser = createTestUser();
        
        System.runAs(testUser) {
            Test.startTest();
            Boolean isValid = OpportunityService.isValidAmount(null);
            Test.stopTest();
            
            Assert.isFalse(isValid);
        }
    }
}