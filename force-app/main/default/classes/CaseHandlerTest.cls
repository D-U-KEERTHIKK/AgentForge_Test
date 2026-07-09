@isTest
private class CaseHandlerTest {
    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Case caseRecord = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Priority = 'Medium',
            AccountId = acc.Id,
            Origin = 'Phone'
        );
        insert caseRecord;
    }
    
    @isTest
    static void testCaseCreation() {
        Case caseRecord = [SELECT Id, Subject FROM Case LIMIT 1];
        System.assertNotEquals(null, caseRecord.Id, 'Case should be created');
        System.assertEquals('Test Case', caseRecord.Subject, 'Subject should match');
    }
    
    @isTest
    static void testCasePriorityUpdate() {
        Case caseRecord = [SELECT Id, Priority FROM Case LIMIT 1];
        caseRecord.Priority = 'High';
        update caseRecord;
        
        Case updatedCase = [SELECT Priority FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('High', updatedCase.Priority, 'Priority should be updated');
    }
    
    @isTest
    static void testCaseStatusTransition() {
        Case caseRecord = [SELECT Id, Status FROM Case LIMIT 1];
        caseRecord.Status = 'In Progress';
        update caseRecord;
        
        Case updatedCase = [SELECT Status FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('In Progress', updatedCase.Status, 'Status should be updated');
    }
    
    @isTest
    static void testCaseEscalation() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        caseRecord.IsClosed = false;
        caseRecord.Priority = 'Critical';
        update caseRecord;
        
        Case escalatedCase = [SELECT Priority FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('Critical', escalatedCase.Priority, 'Case should be escalated');
    }
}
