import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:email_validator/email_validator.dart';
import '../core/result.dart';
import 'logging_service.dart';

/// Comprehensive validation service for MedRefer AI
class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  final LoggingService _loggingService = LoggingService();

  /// Validate email address
  Result<String> validateEmail(String email) {
    if (email.isEmpty) {
      return Result.error('Email is required');
    }

    if (!EmailValidator.validate(email)) {
      return Result.error('Please enter a valid email address');
    }

    if (email.length > 254) {
      return Result.error('Email address is too long');
    }

    return Result.success(email.trim().toLowerCase());
  }

  /// Validate password strength
  Result<String> validatePassword(String password) {
    if (password.isEmpty) {
      return Result.error('Password is required');
    }

    if (password.length < 8) {
      return Result.error('Password must be at least 8 characters long');
    }

    if (password.length > 128) {
      return Result.error('Password is too long');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return Result.error('Password must contain at least one uppercase letter');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return Result.error('Password must contain at least one lowercase letter');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return Result.error('Password must contain at least one number');
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return Result.error('Password must contain at least one special character');
    }

    // Check for common passwords
    final commonPasswords = [
      'password', '123456', 'password123', 'admin', 'qwerty',
      'letmein', 'welcome', 'monkey', '1234567890', 'password1'
    ];
    
    if (commonPasswords.contains(password.toLowerCase())) {
      return Result.error('Password is too common. Please choose a more secure password');
    }

    return Result.success(password);
  }

  /// Validate phone number
  Result<String> validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return Result.error('Phone number is required');
    }

    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length < 10) {
      return Result.error('Phone number must be at least 10 digits');
    }

    if (digits.length > 15) {
      return Result.error('Phone number is too long');
    }

    // Check for valid phone number patterns
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(digits)) {
      return Result.error('Please enter a valid phone number');
    }

    return Result.success(digits);
  }

  /// Validate name
  Result<String> validateName(String name, {String fieldName = 'Name'}) {
    if (name.isEmpty) {
      return Result.error('$fieldName is required');
    }

    if (name.length < 2) {
      return Result.error('$fieldName must be at least 2 characters long');
    }

    if (name.length > 50) {
      return Result.error('$fieldName is too long');
    }

    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return Result.error('$fieldName can only contain letters, spaces, hyphens, and apostrophes');
    }

    // Check for consecutive spaces
    if (name.contains('  ')) {
      return Result.error('$fieldName cannot contain consecutive spaces');
    }

    return Result.success(name.trim());
  }

  /// Validate medical record number
  Result<String> validateMedicalRecordNumber(String mrn) {
    if (mrn.isEmpty) {
      return Result.error('Medical record number is required');
    }

    if (mrn.length < 3) {
      return Result.error('Medical record number must be at least 3 characters long');
    }

    if (mrn.length > 20) {
      return Result.error('Medical record number is too long');
    }

    // Check for valid MRN format (alphanumeric with optional hyphens)
    if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(mrn)) {
      return Result.error('Medical record number can only contain letters, numbers, and hyphens');
    }

    return Result.success(mrn.toUpperCase().trim());
  }

  /// Validate age
  Result<int> validateAge(int age) {
    if (age < 0) {
      return Result.error('Age cannot be negative');
    }

    if (age > 150) {
      return Result.error('Age cannot be greater than 150');
    }

    return Result.success(age);
  }

  /// Validate date of birth
  Result<DateTime> validateDateOfBirth(DateTime dateOfBirth) {
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;

    if (dateOfBirth.isAfter(now)) {
      return Result.error('Date of birth cannot be in the future');
    }

    if (age > 150) {
      return Result.error('Date of birth is too far in the past');
    }

    if (age < 0) {
      return Result.error('Invalid date of birth');
    }

    return Result.success(dateOfBirth);
  }

  /// Validate address
  Result<String> validateAddress(String address) {
    if (address.isEmpty) {
      return Result.error('Address is required');
    }

    if (address.length < 10) {
      return Result.error('Address must be at least 10 characters long');
    }

    if (address.length > 200) {
      return Result.error('Address is too long');
    }

    return Result.success(address.trim());
  }

  /// Validate ICD-10 code
  Result<String> validateIcd10Code(String code) {
    if (code.isEmpty) {
      return Result.error('ICD-10 code is required');
    }

    // ICD-10 code format: Letter followed by 2-3 digits, optionally followed by decimal and 1-4 more characters
    if (!RegExp(r'^[A-Z]\d{2,3}(\.\d{1,4})?$').hasMatch(code.toUpperCase())) {
      return Result.error('Please enter a valid ICD-10 code (e.g., A00, B01.1, C78.01)');
    }

    return Result.success(code.toUpperCase().trim());
  }

  /// Validate medication name
  Result<String> validateMedicationName(String name) {
    if (name.isEmpty) {
      return Result.error('Medication name is required');
    }

    if (name.length < 2) {
      return Result.error('Medication name must be at least 2 characters long');
    }

    if (name.length > 100) {
      return Result.error('Medication name is too long');
    }

    return Result.success(name.trim());
  }

  /// Validate dosage
  Result<String> validateDosage(String dosage) {
    if (dosage.isEmpty) {
      return Result.error('Dosage is required');
    }

    if (dosage.length > 50) {
      return Result.error('Dosage is too long');
    }

    return Result.success(dosage.trim());
  }

  /// Validate frequency
  Result<String> validateFrequency(String frequency) {
    if (frequency.isEmpty) {
      return Result.error('Frequency is required');
    }

    if (frequency.length > 50) {
      return Result.error('Frequency is too long');
    }

    return Result.success(frequency.trim());
  }

  /// Validate file size
  Result<File> validateFileSize(File file, {int maxSizeInMB = 10}) {
    if (!file.existsSync()) {
      return Result.error('File does not exist');
    }

    final fileSizeInBytes = file.lengthSync();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;

    if (fileSizeInBytes > maxSizeInBytes) {
      return Result.error('File size cannot exceed ${maxSizeInMB}MB');
    }

    return Result.success(file);
  }

  /// Validate file type
  Result<File> validateFileType(File file, List<String> allowedExtensions) {
    if (!file.existsSync()) {
      return Result.error('File does not exist');
    }

    final fileName = file.path.split('/').last.toLowerCase();
    final hasValidExtension = allowedExtensions.any((ext) => fileName.endsWith(ext.toLowerCase()));

    if (!hasValidExtension) {
      return Result.error('File type not allowed. Allowed types: ${allowedExtensions.join(', ')}');
    }

    return Result.success(file);
  }

  /// Validate URL
  Result<String> validateUrl(String url) {
    if (url.isEmpty) {
      return Result.error('URL is required');
    }

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return Result.error('URL must start with http:// or https://');
      }
      return Result.success(url.trim());
    } catch (e) {
      return Result.error('Please enter a valid URL');
    }
  }

  /// Validate numeric input
  Result<double> validateNumeric(String input, {String fieldName = 'Value'}) {
    if (input.isEmpty) {
      return Result.error('$fieldName is required');
    }

    final value = double.tryParse(input);
    if (value == null) {
      return Result.error('$fieldName must be a valid number');
    }

    return Result.success(value);
  }

  /// Validate positive numeric input
  Result<double> validatePositiveNumeric(String input, {String fieldName = 'Value'}) {
    final numericResult = validateNumeric(input, fieldName: fieldName);
    if (numericResult.isError) {
      return numericResult;
    }

    final value = numericResult.data!;
    if (value <= 0) {
      return Result.error('$fieldName must be greater than 0');
    }

    return Result.success(value);
  }

  /// Validate integer input
  Result<int> validateInteger(String input, {String fieldName = 'Value'}) {
    if (input.isEmpty) {
      return Result.error('$fieldName is required');
    }

    final value = int.tryParse(input);
    if (value == null) {
      return Result.error('$fieldName must be a valid integer');
    }

    return Result.success(value);
  }

  /// Validate positive integer input
  Result<int> validatePositiveInteger(String input, {String fieldName = 'Value'}) {
    final integerResult = validateInteger(input, fieldName: fieldName);
    if (integerResult.isError) {
      return integerResult;
    }

    final value = integerResult.data!;
    if (value <= 0) {
      return Result.error('$fieldName must be greater than 0');
    }

    return Result.success(value);
  }

  /// Validate required field
  Result<String> validateRequired(String value, {String fieldName = 'Field'}) {
    if (value.isEmpty) {
      return Result.error('$fieldName is required');
    }

    return Result.success(value.trim());
  }

  /// Validate field length
  Result<String> validateLength(String value, {int minLength = 0, int maxLength = 255, String fieldName = 'Field'}) {
    if (value.length < minLength) {
      return Result.error('$fieldName must be at least $minLength characters long');
    }

    if (value.length > maxLength) {
      return Result.error('$fieldName cannot exceed $maxLength characters');
    }

    return Result.success(value);
  }

  /// Validate multiple fields at once
  Result<Map<String, dynamic>> validateMultiple(Map<String, String> fields, Map<String, Result<String> Function(String)> validators) {
    final results = <String, dynamic>{};
    final errors = <String>[];

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;
      final validator = validators[fieldName];

      if (validator != null) {
        final result = validator(fieldValue);
        if (result.isSuccess) {
          results[fieldName] = result.data;
        } else {
          errors.add('$fieldName: ${result.errorMessage}');
        }
      } else {
        results[fieldName] = fieldValue;
      }
    }

    if (errors.isNotEmpty) {
      return Result.error(errors.join('; '));
    }

    return Result.success(results);
  }

  /// Sanitize input to prevent XSS and injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'''[<>"']'''), '') // Remove potentially dangerous characters
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Remove javascript: protocol
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '') // Remove event handlers
        .trim();
  }

  /// Validate and sanitize input
  Result<String> validateAndSanitize(String input, {String fieldName = 'Field'}) {
    final sanitized = sanitizeInput(input);
    return validateRequired(sanitized, fieldName: fieldName);
  }

  /// Log validation error
  void _logValidationError(String field, String error) {
    _loggingService.warning('Validation error', context: 'Validation', metadata: {
      'field': field,
      'error': error,
    });
  }
}