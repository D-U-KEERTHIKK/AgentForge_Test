@isTest
public class TestContact {

    @isTest
    static void testCreateContact() {
        // Create a test Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        // Create a test Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            AccountId = acc.Id
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        // Verify the Contact was created
        Contact result = [
            SELECT Id, FirstName, LastName, Email, AccountId
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals('John', result.FirstName);
        System.assertEquals('Doe', result.LastName);
        System.assertEquals('john.doe@test.com', result.Email);
        System.assertEquals(acc.Id, result.AccountId);
    }
}