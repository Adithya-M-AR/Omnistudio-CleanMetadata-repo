global with sharing class MemberEligibilityService implements Callable {

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');

        if (action == 'checkEligibility') {
            checkEligibility(input, output);
        }
        return true;
    }

    private void checkEligibility(Map<String, Object> input, Map<String, Object> output) {
        String memberIdNumber = (String) input.get('memberIdNumber');
        String dateOfBirth = (String) input.get('dateOfBirth');

        Boolean isDuplicate = isExistingMember(memberIdNumber);
        Boolean isEligible = !isDuplicate && isPlausibleAge(dateOfBirth);

        output.put('isEligible', isEligible);
        output.put('isDuplicate', isDuplicate);
    }

    private static Boolean isExistingMember(String memberIdNumber) {
        if (String.isBlank(memberIdNumber)) {
            return false;
        }
        List<Patient_Intake__c> existing = [
            SELECT Id
            FROM Patient_Intake__c
            WHERE Member_Id_Number__c = :memberIdNumber
            LIMIT 1
        ];
        return !existing.isEmpty();
    }

    private static Boolean isPlausibleAge(String dateOfBirthString) {
        if (String.isBlank(dateOfBirthString)) {
            return false;
        }
        Date dob = parseDate(dateOfBirthString);
        if (dob == null) {
            return false;
        }
        Integer ageInYears = Date.today().year() - dob.year();
        return ageInYears >= 0 && ageInYears <= 120;
    }

    // Tries ISO format (YYYY-MM-DD) first, then falls back to DD/MM/YYYY,
    // since OmniScript Date elements can send either depending on org/user locale.
    // Returns null if neither format parses.
    private static Date parseDate(String dateString) {
        try {
            return Date.valueOf(dateString);
        } catch (Exception e) {
            // fall through to try DD/MM/YYYY
        }

        try {
            List<String> parts = dateString.split('/');
            if (parts.size() == 3) {
                Integer day = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                return Date.newInstance(year, month, day);
            }
        } catch (Exception e) {
            // not a valid DD/MM/YYYY date either
        }

        return null;
    }
}