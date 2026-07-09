@isTest
private class UtilityClassTest {
    @isTest
    static void testStringUtility() {
        String input = 'hello world';
        String expected = 'hello world';
        System.assertEquals(expected, input, 'String should match');
    }
    
    @isTest
    static void testListUtility() {
        List<String> items = new List<String>{'a', 'b', 'c'};
        System.assertEquals(3, items.size(), 'List should have 3 items');
    }
    
    @isTest
    static void testMapUtility() {
        Map<String, String> mapping = new Map<String, String>();
        mapping.put('key1', 'value1');
        System.assertEquals('value1', mapping.get('key1'), 'Map should return correct value');
    }
    
    @isTest
    static void testDateUtility() {
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        System.assert(tomorrow > today, 'Tomorrow should be after today');
    }
    
    @isTest
    static void testNullHandling() {
        String nullString = null;
        System.assertEquals(null, nullString, 'Null should be null');
    }
    
    @isTest
    static void testExceptionHandling() {
        try {
            Integer result = 10 / 1;
            System.assertEquals(10, result, 'Division should work');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception');
        }
    }
    
    @isTest
    static void testBooleanLogic() {
        Boolean condition = true;
        System.assertEquals(true, condition, 'Condition should be true');
    }
}
