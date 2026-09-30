@isTest
private class MemberEligibilityServiceTest {

    @TestSetup
    static void setupData() {
        insert new Patient_Intake__c(
            First_Name__c = 'Existing',
            Last_Name__c = 'Member',
            Member_Id_number__c = 'M-TEST-DUP',
            Name = 'Existing Member'
        );
    }

    @isTest
    static void testEligibleNewMemberIsoDate() {
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => 'M-TEST-NEW',
            'dateOfBirth' => '1990-06-22'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        Object result = service.call('checkEligibility', args);
        Test.stopTest();

        System.assertEquals(true, result, 'call() should return true');
        System.assertEquals(true, output.get('isEligible'), 'New member with valid ISO DOB should be eligible');
        System.assertEquals(false, output.get('isDuplicate'), 'New member ID should not be a duplicate');
    }

    @isTest
    static void testEligibleNewMemberDdMmYyyyDate() {
        // Regression test for the real bug found during org testing: OmniScript sent
        // DOB as DD/MM/YYYY (locale format) instead of ISO, causing false ineligibility.
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => 'M-TEST-DDMMYYYY',
            'dateOfBirth' => '10/12/1956'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        service.call('checkEligibility', args);
        Test.stopTest();

        System.assertEquals(true, output.get('isEligible'), 'DD/MM/YYYY formatted DOB should now parse correctly and be eligible');
        System.assertEquals(false, output.get('isDuplicate'), 'New member ID should not be a duplicate');
    }

    @isTest
    static void testDuplicateMemberIsIneligible() {
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => 'M-TEST-DUP',
            'dateOfBirth' => '1990-06-22'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        service.call('checkEligibility', args);
        Test.stopTest();

        System.assertEquals(true, output.get('isDuplicate'), 'Existing member ID should be flagged as duplicate');
        System.assertEquals(false, output.get('isEligible'), 'A duplicate should never be eligible');
    }

    @isTest
    static void testBlankMemberIdIsNotDuplicateButIsIneligible() {
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => '',
            'dateOfBirth' => '1990-06-22'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        service.call('checkEligibility', args);
        Test.stopTest();

        System.assertEquals(false, output.get('isDuplicate'), 'Blank member ID should not match anything');
        System.assertEquals(true, output.get('isEligible'), 'Blank ID with a valid DOB is still considered eligible under current logic');
    }

    @isTest
    static void testInvalidDateOfBirthIsIneligible() {
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => 'M-TEST-BADDOB',
            'dateOfBirth' => 'not-a-real-date'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        service.call('checkEligibility', args);
        Test.stopTest();

        System.assertEquals(false, output.get('isEligible'), 'An unparseable DOB should never be eligible, in either format');
        System.assertEquals(false, output.get('isDuplicate'), 'This member ID is new, so not a duplicate');
    }

    @isTest
    static void testBlankDateOfBirthIsIneligible() {
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => 'M-TEST-NODOB',
            'dateOfBirth' => ''
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        service.call('checkEligibility', args);
        Test.stopTest();

        System.assertEquals(false, output.get('isEligible'), 'A blank DOB should never be eligible');
    }

    @isTest
    static void testUnrecognizedActionIsANoOp() {
        MemberEligibilityService service = new MemberEligibilityService();

        Map<String, Object> input = new Map<String, Object>{
            'memberIdNumber' => 'M-TEST-NEW',
            'dateOfBirth' => '1990-06-22'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output
        };

        Test.startTest();
        Object result = service.call('someOtherAction', args);
        Test.stopTest();

        System.assertEquals(true, result, 'call() always returns true regardless of action');
        System.assertEquals(0, output.size(), 'Output map should be untouched for an unrecognized action');
    }
}