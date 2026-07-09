/**
 * @description Test class for utility and helper methods covering string manipulation,
 * list operations, date calculations, and error handling.
 * @group Tests
 */
@IsTest
private class UtilityClassTest {
    
    /**
     * @description Test setup to create test user
     */
    @TestSetup
    static void setupTestData() {
        // Create test user for runAs context
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.now().getTime() + '@example.com'
        );
        insert testUser;
    }
    
    /**
     * @description Test string manipulation utilities
     */
    @IsTest
    static void testStringManipulation() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            // Test capitalize string
            String input = 'hello world';
            String result = UtilityClassStub.capitalize(input);
            Assert.areEqual('Hello world', result);
            
            // Test with empty string
            String emptyResult = UtilityClassStub.capitalize('');
            Assert.areEqual('', emptyResult);
            
            // Test with single character
            String singleChar = UtilityClassStub.capitalize('a');
            Assert.areEqual('A', singleChar);
        }
    }
    
    /**
     * @description Test string trimming and whitespace handling
     */
    @IsTest
    static void testStringTrimming() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            String input = '  test string  ';
            String result = UtilityClassStub.trimWhitespace(input);
            Assert.areEqual('test string', result);
            
            // Test with no whitespace
            String noSpace = UtilityClassStub.trimWhitespace('test');
            Assert.areEqual('test', noSpace);
            
            // Test with null
            String nullResult = UtilityClassStub.trimWhitespace(null);
            Assert.isNull(nullResult);
        }
    }
    
    /**
     * @description Test string validation utilities
     */
    @IsTest
    static void testStringValidation() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            // Test isValidEmail
            Boolean validEmail = UtilityClassStub.isValidEmail('test@example.com');
            Assert.isTrue(validEmail);
            
            Boolean invalidEmail = UtilityClassStub.isValidEmail('invalid.email');
            Assert.isFalse(invalidEmail);
            
            Boolean emptyEmail = UtilityClassStub.isValidEmail('');
            Assert.isFalse(emptyEmail);
        }
    }
    
    /**
     * @description Test list operations - filtering
     */
    @IsTest
    static void testListFiltering() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            List<Integer> numbers = new List<Integer> { 1, 2, 3, 4, 5, 6 };
            List<Integer> evenNumbers = UtilityClassStub.filterEvenNumbers(numbers);
            
            Assert.areEqual(3, evenNumbers.size());
            Assert.isTrue(evenNumbers.contains(2));
            Assert.isTrue(evenNumbers.contains(4));
            Assert.isTrue(evenNumbers.contains(6));
        }
    }
    
    /**
     * @description Test list operations - removal of duplicates
     */
    @IsTest
    static void testRemoveDuplicates() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            List<String> items = new List<String> { 'apple', 'banana', 'apple', 'cherry', 'banana' };
            List<String> uniqueItems = UtilityClassStub.removeDuplicates(items);
            
            Assert.areEqual(3, uniqueItems.size());
            Assert.isTrue(uniqueItems.contains('apple'));
            Assert.isTrue(uniqueItems.contains('banana'));
            Assert.isTrue(uniqueItems.contains('cherry'));
        }
    }
    
    /**
     * @description Test list operations - null and empty list handling
     */
    @IsTest
    static void testListOperationsWithEmptyAndNull() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            // Test with empty list
            List<String> emptyList = new List<String>();
            List<String> emptyResult = UtilityClassStub.removeDuplicates(emptyList);
            Assert.areEqual(0, emptyResult.size());
            
            // Test with null list
            List<String> nullResult = UtilityClassStub.removeDuplicates(null);
            Assert.isNull(nullResult);
        }
    }
    
    /**
     * @description Test date calculation utilities
     */
    @IsTest
    static void testDateCalculations() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Date testDate = Date.newInstance(2024, 1, 15);
            
            // Test adding days
            Date futureDate = UtilityClassStub.addDays(testDate, 10);
            Assert.areEqual(Date.newInstance(2024, 1, 25), futureDate);
            
            // Test subtracting days
            Date pastDate = UtilityClassStub.addDays(testDate, -5);
            Assert.areEqual(Date.newInstance(2024, 1, 10), pastDate);
        }
    }
    
    /**
     * @description Test date difference calculations
     */
    @IsTest
    static void testDateDifference() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Date startDate = Date.newInstance(2024, 1, 1);
            Date endDate = Date.newInstance(2024, 1, 31);
            
            Integer daysDifference = UtilityClassStub.daysBetween(startDate, endDate);
            Assert.areEqual(30, daysDifference);
        }
    }
    
    /**
     * @description Test date difference with same dates
     */
    @IsTest
    static void testDateDifferenceWithSameDates() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Date testDate = Date.newInstance(2024, 1, 15);
            Integer difference = UtilityClassStub.daysBetween(testDate, testDate);
            Assert.areEqual(0, difference);
        }
    }
    
    /**
     * @description Test leap year detection
     */
    @IsTest
    static void testLeapYearDetection() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Boolean isLeap2024 = UtilityClassStub.isLeapYear(2024);
            Assert.isTrue(isLeap2024);
            
            Boolean isLeap2023 = UtilityClassStub.isLeapYear(2023);
            Assert.isFalse(isLeap2023);
            
            Boolean isLeap2000 = UtilityClassStub.isLeapYear(2000);
            Assert.isTrue(isLeap2000);
        }
    }
    
    /**
     * @description Test error handling - null pointer handling
     */
    @IsTest
    static void testNullPointerHandling() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            String result = UtilityClassStub.safeToString(null);
            Assert.areEqual('', result);
            
            String nonNullResult = UtilityClassStub.safeToString('test');
            Assert.areEqual('test', nonNullResult);
        }
    }
    
    /**
     * @description Test error handling - safe list access
     */
    @IsTest
    static void testSafeListAccess() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            List<String> items = new List<String> { 'first', 'second', 'third' };
            
            // Valid index
            String firstItem = UtilityClassStub.safeListGet(items, 0);
            Assert.areEqual('first', firstItem);
            
            // Out of bounds index
            String outOfBounds = UtilityClassStub.safeListGet(items, 10);
            Assert.isNull(outOfBounds);
            
            // Null list
            String nullListResult = UtilityClassStub.safeListGet(null, 0);
            Assert.isNull(nullListResult);
        }
    }
    
    /**
     * @description Test error handling - safe integer conversion
     */
    @IsTest
    static void testSafeIntegerConversion() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Integer validInt = UtilityClassStub.safeParseInt('123');
            Assert.areEqual(123, validInt);
            
            Integer invalidInt = UtilityClassStub.safeParseInt('not a number');
            Assert.areEqual(0, invalidInt);
            
            Integer nullInt = UtilityClassStub.safeParseInt(null);
            Assert.areEqual(0, nullInt);
        }
    }
    
    /**
     * @description Test error handling - safe decimal conversion
     */
    @IsTest
    static void testSafeDecimalConversion() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Decimal validDecimal = UtilityClassStub.safeParseDecimal('123.45');
            Assert.areEqual(123.45, validDecimal);
            
            Decimal invalidDecimal = UtilityClassStub.safeParseDecimal('invalid');
            Assert.areEqual(0.0, invalidDecimal);
            
            Decimal nullDecimal = UtilityClassStub.safeParseDecimal(null);
            Assert.areEqual(0.0, nullDecimal);
        }
    }
    
    /**
     * @description Test map operations - value retrieval
     */
    @IsTest
    static void testMapValueRetrieval() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Map<String, String> testMap = new Map<String, String>();
            testMap.put('key1', 'value1');
            testMap.put('key2', 'value2');
            
            String value = UtilityClassStub.safeMapGet(testMap, 'key1');
            Assert.areEqual('value1', value);
            
            String missingKey = UtilityClassStub.safeMapGet(testMap, 'missing');
            Assert.isNull(missingKey);
        }
    }
    
    /**
     * @description Test number rounding utility
     */
    @IsTest
    static void testNumberRounding() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Decimal decimalValue = 123.4567;
            Decimal rounded = UtilityClassStub.roundDecimal(decimalValue, 2);
            Assert.areEqual(123.46, rounded);
            
            Decimal roundedToZero = UtilityClassStub.roundDecimal(decimalValue, 0);
            Assert.areEqual(123, roundedToZero);
        }
    }
    
    /**
     * @description Test percentage calculation
     */
    @IsTest
    static void testPercentageCalculation() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Decimal percentage = UtilityClassStub.calculatePercentage(50, 200);
            Assert.areEqual(25.0, percentage);
            
            Decimal zeroPercentage = UtilityClassStub.calculatePercentage(0, 100);
            Assert.areEqual(0.0, zeroPercentage);
        }
    }
    
    /**
     * @description Test division by zero handling
     */
    @IsTest
    static void testDivisionByZeroHandling() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Decimal result = UtilityClassStub.calculatePercentage(50, 0);
            Assert.areEqual(0.0, result);
        }
    }
    
    /**
     * @description Test bulk test data creation
     */
    @IsTest
    static void testBulkDataCreation() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            List<Account> accounts = UtilityClassStub.createTestAccounts(5);
            Test.stopTest();
            
            Assert.areEqual(5, accounts.size());
            for (Account acc : accounts) {
                Assert.isNotNull(acc.Name);
                Assert.isTrue(acc.Name.startsWithIgnoreCase('Test Account'));
            }
        }
    }
    
    /**
     * @description Test string repeat utility
     */
    @IsTest
    static void testStringRepeat() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            String repeated = UtilityClassStub.repeatString('ab', 3);
            Assert.areEqual('ababab', repeated);
            
            String singleRepeat = UtilityClassStub.repeatString('x', 1);
            Assert.areEqual('x', singleRepeat);
            
            String zeroRepeat = UtilityClassStub.repeatString('test', 0);
            Assert.areEqual('', zeroRepeat);
        }
    }
    
    /**
     * @description Test string contains case-insensitive utility
     */
    @IsTest
    static void testContainsCaseInsensitive() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        
        System.runAs(testUser) {
            Boolean contains = UtilityClassStub.containsCaseInsensitive('Hello World', 'hello');
            Assert.isTrue(contains);
            
            Boolean doesNotContain = UtilityClassStub.containsCaseInsensitive('Hello World', 'xyz');
            Assert.isFalse(doesNotContain);
            
            Boolean nullCheck = UtilityClassStub.containsCaseInsensitive(null, 'test');
            Assert.isFalse(nullCheck);
        }
    }
}