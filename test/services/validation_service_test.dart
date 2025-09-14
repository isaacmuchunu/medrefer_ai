import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/services/validation_service.dart';
import 'package:medrefer_ai/core/result.dart';

void main() {
  group('ValidationService', () {
    late ValidationService validationService;

    setUp(() {
      validationService = ValidationService();
    });

    group('Email Validation', () {
      test('should validate correct email addresses', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
          'test123@test-domain.com',
        ];

        for (final email in validEmails) {
          final result = validationService.validateEmail(email);
          expect(result.isSuccess, true);
          expect(result.data, email.toLowerCase().trim());
        }
      });

      test('should reject invalid email addresses', () {
        final invalidEmails = [
          '',
          'invalid-email',
          '@example.com',
          'test@',
          'test..test@example.com',
          'test@example',
          'test@.com',
        ];

        for (final email in invalidEmails) {
          final result = validationService.validateEmail(email);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Password Validation', () {
      test('should validate strong passwords', () {
        final strongPasswords = [
          'Password123!',
          'MySecure@Pass1',
          'Complex#Pass2024',
        ];

        for (final password in strongPasswords) {
          final result = validationService.validatePassword(password);
          expect(result.isSuccess, true);
          expect(result.data, password);
        }
      });

      test('should reject weak passwords', () {
        final weakPasswords = [
          '',
          '123456',
          'password',
          'Password',
          'Password123',
          'PASSWORD123!',
          'password123!',
        ];

        for (final password in weakPasswords) {
          final result = validationService.validatePassword(password);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Phone Number Validation', () {
      test('should validate correct phone numbers', () {
        final validPhones = [
          '1234567890',
          '+1234567890',
          '(123) 456-7890',
          '123-456-7890',
          '+1 (123) 456-7890',
        ];

        for (final phone in validPhones) {
          final result = validationService.validatePhoneNumber(phone);
          expect(result.isSuccess, true);
          expect(result.data, isA<String>());
        }
      });

      test('should reject invalid phone numbers', () {
        final invalidPhones = [
          '',
          '123',
          '12345678901234567890', // Too long
          'abc-def-ghij',
        ];

        for (final phone in invalidPhones) {
          final result = validationService.validatePhoneNumber(phone);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Name Validation', () {
      test('should validate correct names', () {
        final validNames = [
          'John Doe',
          'Mary-Jane Smith',
          "O'Connor",
          'José María',
          'Jean-Pierre',
        ];

        for (final name in validNames) {
          final result = validationService.validateName(name);
          expect(result.isSuccess, true);
          expect(result.data, name.trim());
        }
      });

      test('should reject invalid names', () {
        final invalidNames = [
          '',
          'A', // Too short
          'John123', // Contains numbers
          'John@Doe', // Contains special characters
          'John  Doe', // Consecutive spaces
        ];

        for (final name in invalidNames) {
          final result = validationService.validateName(name);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Medical Record Number Validation', () {
      test('should validate correct MRNs', () {
        final validMRNs = [
          'MRN123',
          'ABC-123',
          '123456',
          'MRN-ABC-123',
        ];

        for (final mrn in validMRNs) {
          final result = validationService.validateMedicalRecordNumber(mrn);
          expect(result.isSuccess, true);
          expect(result.data, mrn.toUpperCase().trim());
        }
      });

      test('should reject invalid MRNs', () {
        final invalidMRNs = [
          '',
          'AB', // Too short
          'MRN@123', // Invalid characters
          'MRN 123', // Spaces not allowed
        ];

        for (final mrn in invalidMRNs) {
          final result = validationService.validateMedicalRecordNumber(mrn);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Age Validation', () {
      test('should validate correct ages', () {
        final validAges = [0, 25, 65, 100, 150];

        for (final age in validAges) {
          final result = validationService.validateAge(age);
          expect(result.isSuccess, true);
          expect(result.data, age);
        }
      });

      test('should reject invalid ages', () {
        final invalidAges = [-1, 151, -10];

        for (final age in invalidAges) {
          final result = validationService.validateAge(age);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Date of Birth Validation', () {
      test('should validate correct dates of birth', () {
        final now = DateTime.now();
        final validDates = [
          now.subtract(Duration(days: 365 * 25)), // 25 years ago
          now.subtract(Duration(days: 365 * 65)), // 65 years ago
          DateTime(1990, 1, 1),
        ];

        for (final date in validDates) {
          final result = validationService.validateDateOfBirth(date);
          expect(result.isSuccess, true);
          expect(result.data, date);
        }
      });

      test('should reject invalid dates of birth', () {
        final now = DateTime.now();
        final invalidDates = [
          now.add(Duration(days: 1)), // Future date
          now.subtract(Duration(days: 365 * 200)), // Too old
        ];

        for (final date in invalidDates) {
          final result = validationService.validateDateOfBirth(date);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('ICD-10 Code Validation', () {
      test('should validate correct ICD-10 codes', () {
        final validCodes = [
          'A00',
          'B01',
          'C78.01',
          'Z99.9',
          'A00.0',
        ];

        for (final code in validCodes) {
          final result = validationService.validateIcd10Code(code);
          expect(result.isSuccess, true);
          expect(result.data, code.toUpperCase().trim());
        }
      });

      test('should reject invalid ICD-10 codes', () {
        final invalidCodes = [
          '',
          'A',
          'A0',
          'A0000',
          'A00.00000',
          '1A00',
        ];

        for (final code in invalidCodes) {
          final result = validationService.validateIcd10Code(code);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Numeric Validation', () {
      test('should validate correct numeric inputs', () {
        final validInputs = ['0', '123', '123.45', '-123.45'];

        for (final input in validInputs) {
          final result = validationService.validateNumeric(input);
          expect(result.isSuccess, true);
          expect(result.data, isA<double>());
        }
      });

      test('should reject invalid numeric inputs', () {
        final invalidInputs = ['', 'abc', '12.34.56', '12a34'];

        for (final input in invalidInputs) {
          final result = validationService.validateNumeric(input);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Positive Numeric Validation', () {
      test('should validate positive numeric inputs', () {
        final validInputs = ['1', '123', '123.45'];

        for (final input in validInputs) {
          final result = validationService.validatePositiveNumeric(input);
          expect(result.isSuccess, true);
          expect(result.data, isA<double>());
          expect(result.data, greaterThan(0));
        }
      });

      test('should reject non-positive numeric inputs', () {
        final invalidInputs = ['0', '-123', '-123.45'];

        for (final input in invalidInputs) {
          final result = validationService.validatePositiveNumeric(input);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });

    group('Multiple Field Validation', () {
      test('should validate multiple fields successfully', () {
        final fields = {
          'email': 'test@example.com',
          'password': 'Password123!',
          'name': 'John Doe',
        };

        final validators = {
          'email': (value) => validationService.validateEmail(value),
          'password': (value) => validationService.validatePassword(value),
          'name': (value) => validationService.validateName(value),
        };

        final result = validationService.validateMultiple(fields, validators);
        expect(result.isSuccess, true);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!['email'], 'test@example.com');
        expect(result.data!['password'], 'Password123!');
        expect(result.data!['name'], 'John Doe');
      });

      test('should return errors for invalid fields', () {
        final fields = {
          'email': 'invalid-email',
          'password': 'weak',
          'name': 'John Doe',
        };

        final validators = {
          'email': (value) => validationService.validateEmail(value),
          'password': (value) => validationService.validatePassword(value),
          'name': (value) => validationService.validateName(value),
        };

        final result = validationService.validateMultiple(fields, validators);
        expect(result.isError, true);
        expect(result.errorMessage, contains('email:'));
        expect(result.errorMessage, contains('password:'));
        expect(result.errorMessage, isNot(contains('name:')));
      });
    });

    group('Input Sanitization', () {
      test('should sanitize dangerous input', () {
        final dangerousInputs = [
          '<script>alert("xss")</script>',
          'javascript:alert("xss")',
          'onclick="alert(\'xss\')"',
          'normal text',
        ];

        final expectedOutputs = [
          'alert("xss")',
          'alert("xss")',
          '',
          'normal text',
        ];

        for (int i = 0; i < dangerousInputs.length; i++) {
          final sanitized = validationService.sanitizeInput(dangerousInputs[i]);
          expect(sanitized, expectedOutputs[i]);
        }
      });
    });
  });
}