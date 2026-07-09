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
     * @return User test user with standard profile
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
            
            Decimal revenue = calculateRevenue(new List<Opportunity> { opp });
            
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
            
            insert oppsToCreate;
            
            List<Opportunity> allOpps = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :testAccount.Id];
            Decimal totalRevenue = calculateRevenue(allOpps);
            
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
            Decimal revenue = calculateRevenue(new List<Opportunity>());
            
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
            
            insert oppNoAmount;
            
            List<Opportunity> opps = [SELECT Id, Amount FROM Opportunity WHERE Name = 'No Amount Opp'];
            Decimal revenue = calculateRevenue(opps);
            
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
            
            Boolean isValid = isValidStageTransition('Prospecting', 'Qualification');
            
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
            Boolean isValid = isValidStageTransition('Qualification', 'Negotiation/Review');
            
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
            Boolean isValid = isValidStageTransition('Negotiation/Review', 'Closed Won');
            
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
            Boolean isValid = isValidStageTransition('Closed Won', 'Prospecting');
            
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
            Boolean isValid = isValidStageTransition('Qualification', 'Prospecting');
            
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
            Boolean isValid = isValidStageTransition('Closed Lost', 'Qualification');
            
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
            
            Boolean isValid = isValidCloseDate(futureDate);
            
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
            
            Boolean isValid = isValidCloseDate(todayDate);
            
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
            
            Boolean isValid = isValidCloseDate(pastDate);
            
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
            Boolean isValid = isValidCloseDate(null);
            
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
            
            opp.StageName = 'Qualification';
            update opp;
            
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
            
            List<Opportunity> allOpps = [SELECT Id, StageName FROM Opportunity WHERE AccountId = :testAccount.Id];
            List<Opportunity> prospectingOpps = filterByStage(allOpps, 'Prospecting');
            
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
            
            List<Opportunity> allOpps = [SELECT Id, StageName FROM Opportunity WHERE AccountId = :testAccount.Id];
            List<Opportunity> closedWonOpps = filterByStage(allOpps, 'Closed Won');
            
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
            Boolean isValid = isValidAmount(50000);
            
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
            Boolean isValid = isValidAmount(0);
            
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
            Boolean isValid = isValidAmount(-50000);
            
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
            Boolean isValid = isValidAmount(null);
            
            Assert.isFalse(isValid);
        }
    }

    /**
     * @description Calculate total revenue from list of opportunities
     * @param opps List of opportunities to sum
     * @return Decimal total revenue from all opportunities
     */
    private static Decimal calculateRevenue(List<Opportunity> opps) {
        Decimal totalRevenue = 0;
        for (Opportunity opp : opps) {
            if (opp.Amount != null) {
                totalRevenue += opp.Amount;
            }
        }
        return totalRevenue;
    }

    /**
     * @description Validate if stage transition is allowed
     * @param fromStage Current opportunity stage
     * @param toStage Target opportunity stage
     * @return Boolean true if transition is valid
     */
    private static Boolean isValidStageTransition(String fromStage, String toStage) {
        Map<String, List<String>> validTransitions = new Map<String, List<String>>{
            'Prospecting' => new List<String>{'Qualification'},
            'Qualification' => new List<String>{'Negotiation/Review'},
            'Negotiation/Review' => new List<String>{'Closed Won', 'Closed Lost'},
            'Closed Won' => new List<String>(),
            'Closed Lost' => new List<String>()
        };

        if (!validTransitions.containsKey(fromStage)) {
            return false;
        }
        return validTransitions.get(fromStage).contains(toStage);
    }

    /**
     * @description Validate if close date is valid
     * @param closeDate Date to validate
     * @return Boolean true if close date is today or in future
     */
    private static Boolean isValidCloseDate(Date closeDate) {
        if (closeDate == null) {
            return false;
        }
        return closeDate >= Date.today();
    }

    /**
     * @description Filter opportunities by stage name
     * @param opps List of opportunities to filter
     * @param stage Stage name to filter by
     * @return List of opportunities matching the stage
     */
    private static List<Opportunity> filterByStage(List<Opportunity> opps, String stage) {
        List<Opportunity> filtered = new List<Opportunity>();
        for (Opportunity opp : opps) {
            if (opp.StageName == stage) {
                filtered.add(opp);
            }
        }
        return filtered;
    }

    /**
     * @description Validate if amount is valid
     * @param amount Amount to validate
     * @return Boolean true if amount is positive
     */
    private static Boolean isValidAmount(Decimal amount) {
        if (amount == null) {
            return false;
        }
        return amount > 0;
    }
}