import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/services/auth_service.dart';
import 'package:medrefer_ai/database/models/user.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    group('Login', () {
      test('should login with valid credentials', () async {
        final result = await authService.login(
          email: 'doctor@medrefer.com',
          password: 'Doctor123!',
        );
        
        expect(result, true);
        expect(authService.isAuthenticated, true);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, 'doctor@medrefer.com');
        expect(authService.currentUser!.role, UserRole.doctor);
      });

      test('should fail login with invalid credentials', () async {
        final result = await authService.login(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        );
        
        expect(result, false);
        expect(authService.isAuthenticated, false);
        expect(authService.currentUser, isNull);
      });

      test('should fail login with empty credentials', () async {
        final result = await authService.login(
          email: '',
          password: '',
        );
        
        expect(result, false);
        expect(authService.isAuthenticated, false);
      });

      test('should determine user role from email', () {
        expect(authService._determineUserRole('admin@medrefer.com'), UserRole.admin);
        expect(authService._determineUserRole('doctor@medrefer.com'), UserRole.doctor);
        expect(authService._determineUserRole('specialist@medrefer.com'), UserRole.specialist);
        expect(authService._determineUserRole('nurse@medrefer.com'), UserRole.nurse);
        expect(authService._determineUserRole('pharmacist@medrefer.com'), UserRole.pharmacist);
        expect(authService._determineUserRole('patient@medrefer.com'), UserRole.patient);
      });
    });

    group('Registration', () {
      test('should register new user with valid data', () async {
        final result = await authService.register(
          email: 'newuser@medrefer.com',
          password: 'NewUser123!',
          name: 'New User',
          role: 'doctor',
        );
        
        expect(result, true);
      });

      test('should fail registration with invalid password', () async {
        final result = await authService.register(
          email: 'newuser@medrefer.com',
          password: 'weak',
          name: 'New User',
          role: 'doctor',
        );
        
        expect(result, false);
      });

      test('should fail registration with empty fields', () async {
        final result = await authService.register(
          email: '',
          password: '',
          name: '',
          role: '',
        );
        
        expect(result, false);
      });

      test('should parse user role correctly', () {
        expect(authService._parseUserRole('doctor'), UserRole.doctor);
        expect(authService._parseUserRole('physician'), UserRole.doctor);
        expect(authService._parseUserRole('specialist'), UserRole.specialist);
        expect(authService._parseUserRole('nurse'), UserRole.nurse);
        expect(authService._parseUserRole('pharmacist'), UserRole.pharmacist);
        expect(authService._parseUserRole('admin'), UserRole.admin);
        expect(authService._parseUserRole('administrator'), UserRole.admin);
        expect(authService._parseUserRole('superadmin'), UserRole.superAdmin);
        expect(authService._parseUserRole('patient'), UserRole.patient);
        expect(authService._parseUserRole('unknown'), UserRole.patient);
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
          expect(authService._isValidPassword(password), true);
        }
      });

      test('should reject weak passwords', () {
        final weakPasswords = [
          '123456', // No uppercase, lowercase, special char
          'password', // No uppercase, number, special char
          'Password', // No number, special char
          'Password123', // No special char
          'PASSWORD123!', // No lowercase
          'password123!', // No uppercase
        ];

        for (final password in weakPasswords) {
          expect(authService._isValidPassword(password), false);
        }
      });
    });

    group('Password Hashing', () {
      test('should hash passwords consistently', () {
        final password = 'TestPassword123!';
        final hash1 = authService._hashPassword(password);
        final hash2 = authService._hashPassword(password);
        
        // Hashes should be different due to salt
        expect(hash1, isNot(equals(hash2)));
        
        // But both should be valid hashes
        expect(hash1, isA<String>());
        expect(hash2, isA<String>());
        expect(hash1.length, greaterThan(20));
        expect(hash2.length, greaterThan(20));
      });

      test('should generate different salts', () {
        final salt1 = authService._generateSalt();
        final salt2 = authService._generateSalt();
        
        expect(salt1, isNot(equals(salt2)));
        expect(salt1, isA<String>());
        expect(salt2, isA<String>());
      });
    });

    group('Token Generation', () {
      test('should generate unique auth tokens', () {
        final token1 = authService._generateAuthToken();
        final token2 = authService._generateAuthToken();
        
        expect(token1, isNot(equals(token2)));
        expect(token1, isA<String>());
        expect(token2, isA<String>());
        expect(token1.startsWith('auth_'), true);
        expect(token2.startsWith('auth_'), true);
      });
    });

    group('Name Extraction', () {
      test('should extract names from email addresses', () {
        expect(authService._extractNameFromEmail('john.doe@example.com'), 'John Doe');
        expect(authService._extractNameFromEmail('maryjane@example.com'), 'Maryjane');
        expect(authService._extractNameFromEmail('dr.smith@example.com'), 'Dr Smith');
      });
    });

    group('Logout', () {
      test('should logout successfully', () async {
        // First login
        await authService.login(
          email: 'doctor@medrefer.com',
          password: 'Doctor123!',
        );
        
        expect(authService.isAuthenticated, true);
        
        // Then logout
        await authService.logout();
        
        expect(authService.isAuthenticated, false);
        expect(authService.currentUser, isNull);
        expect(authService.authToken, isNull);
      });
    });

    group('Password Reset', () {
      test('should request password reset for valid email', () async {
        final result = await authService.requestPasswordReset('doctor@medrefer.com');
        expect(result, true);
      });

      test('should fail password reset for invalid email', () async {
        final result = await authService.requestPasswordReset('nonexistent@example.com');
        expect(result, false);
      });

      test('should fail password reset for empty email', () async {
        final result = await authService.requestPasswordReset('');
        expect(result, false);
      });

      test('should validate reset token format', () {
        expect(authService._validateResetToken('doctor@medrefer.com', '123456'), true);
        expect(authService._validateResetToken('doctor@medrefer.com', '12345'), false);
        expect(authService._validateResetToken('doctor@medrefer.com', 'abcdef'), false);
        expect(authService._validateResetToken('doctor@medrefer.com', ''), false);
      });

      test('should reset password with valid token', () async {
        final result = await authService.resetPassword(
          email: 'doctor@medrefer.com',
          token: '123456',
          newPassword: 'NewPassword123!',
        );
        
        expect(result, true);
      });

      test('should fail password reset with invalid token', () async {
        final result = await authService.resetPassword(
          email: 'doctor@medrefer.com',
          token: 'invalid',
          newPassword: 'NewPassword123!',
        );
        
        expect(result, false);
      });

      test('should fail password reset with weak password', () async {
        final result = await authService.resetPassword(
          email: 'doctor@medrefer.com',
          token: '123456',
          newPassword: 'weak',
        );
        
        expect(result, false);
      });
    });

    group('Biometric Login', () {
      test('should fail biometric login without stored data', () async {
        final result = await authService.loginWithBiometrics();
        expect(result, false);
      });
    });

    group('User Existence Check', () {
      test('should check if user exists', () async {
        final exists = await authService._userExists('doctor@medrefer.com');
        expect(exists, true);
        
        final notExists = await authService._userExists('nonexistent@example.com');
        expect(notExists, false);
      });
    });

    group('Credential Validation', () {
      test('should validate credentials correctly', () {
        final validEmail = 'doctor@medrefer.com';
        final validPassword = 'Doctor123!';
        final hashedPassword = authService._hashPassword(validPassword);
        
        expect(authService._validateCredentials(validEmail, hashedPassword), true);
        expect(authService._validateCredentials(validEmail, 'wronghash'), false);
        expect(authService._validateCredentials('wrong@email.com', hashedPassword), false);
      });
    });
  });
}