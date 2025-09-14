import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/core/app_export.dart';

/// Test configuration and utilities for MedRefer AI
class TestConfig {
  static const String testDatabaseName = 'test_medrefer_ai.db';
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);

  /// Setup test environment
  static Future<void> setupTestEnvironment() async {
    // Initialize test services
    await _setupTestServices();
    
    // Setup test database
    await _setupTestDatabase();
    
    // Setup test logging
    await _setupTestLogging();
  }

  /// Cleanup test environment
  static Future<void> cleanupTestEnvironment() async {
    // Cleanup test database
    await _cleanupTestDatabase();
    
    // Cleanup test services
    await _cleanupTestServices();
  }

  /// Setup test services
  static Future<void> _setupTestServices() async {
    // Initialize logging service for tests
    final loggingService = LoggingService();
    await loggingService.initialize();
    
    // Initialize validation service
    final validationService = ValidationService();
    
    // Initialize enhanced security service
    final securityService = EnhancedSecurityService();
  }

  /// Setup test database
  static Future<void> _setupTestDatabase() async {
    // Use in-memory database for tests
    // This will be handled by the test database helper
  }

  /// Setup test logging
  static Future<void> _setupTestLogging() async {
    // Configure logging for tests
    final loggingService = LoggingService();
    loggingService.info('Test environment initialized', context: 'TestSetup');
  }

  /// Cleanup test database
  static Future<void> _cleanupTestDatabase() async {
    // Cleanup test database files
    // This will be handled by the test database helper
  }

  /// Cleanup test services
  static Future<void> _cleanupTestServices() async {
    // Dispose of test services
    final loggingService = LoggingService();
    loggingService.dispose();
  }

  /// Create test user data
  static Map<String, dynamic> createTestUser({
    String email = 'test@medrefer.com',
    String password = 'TestPassword123!',
    String firstName = 'Test',
    String lastName = 'User',
    UserRole role = UserRole.doctor,
  }) {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }

  /// Create test patient data
  static Map<String, dynamic> createTestPatient({
    String name = 'Test Patient',
    int age = 30,
    String medicalRecordNumber = 'MRN123456',
    DateTime? dateOfBirth,
    String gender = 'Male',
    String bloodType = 'O+',
    String phone = '1234567890',
    String email = 'patient@example.com',
    String address = '123 Test Street, Test City',
  }) {
    return {
      'name': name,
      'age': age,
      'medical_record_number': medicalRecordNumber,
      'date_of_birth': (dateOfBirth ?? DateTime.now().subtract(Duration(days: 365 * age))).toIso8601String(),
      'gender': gender,
      'blood_type': bloodType,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  /// Create test specialist data
  static Map<String, dynamic> createTestSpecialist({
    String name = 'Dr. Test Specialist',
    String credentials = 'MD, PhD',
    String specialty = 'Cardiology',
    String hospital = 'Test Hospital',
    double rating = 4.5,
    bool isAvailable = true,
    double latitude = 0.0,
    double longitude = 0.0,
  }) {
    return {
      'name': name,
      'credentials': credentials,
      'specialty': specialty,
      'hospital': hospital,
      'rating': rating,
      'is_available': isAvailable ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create test referral data
  static Map<String, dynamic> createTestReferral({
    String patientId = 'patient_123',
    String? specialistId,
    String status = 'Pending',
    String urgency = 'Medium',
    String symptomsDescription = 'Test symptoms',
    double aiConfidence = 0.85,
    String department = 'Cardiology',
    String referringPhysician = 'Dr. Test',
  }) {
    return {
      'patient_id': patientId,
      'specialist_id': specialistId,
      'status': status,
      'urgency': urgency,
      'symptoms_description': symptomsDescription,
      'ai_confidence': aiConfidence,
      'department': department,
      'referring_physician': referringPhysician,
    };
  }

  /// Create test medical history data
  static Map<String, dynamic> createTestMedicalHistory({
    String patientId = 'patient_123',
    String type = 'Diagnosis',
    String title = 'Test Diagnosis',
    String description = 'Test medical history entry',
    DateTime? date,
    String provider = 'Dr. Test',
    String location = 'Test Hospital',
    String icd10Code = 'A00.0',
  }) {
    return {
      'patient_id': patientId,
      'type': type,
      'title': title,
      'description': description,
      'date': (date ?? DateTime.now()).toIso8601String(),
      'provider': provider,
      'location': location,
      'icd10_code': icd10Code,
    };
  }

  /// Create test medication data
  static Map<String, dynamic> createTestMedication({
    String patientId = 'patient_123',
    String name = 'Test Medication',
    String dosage = '10mg',
    String frequency = 'Twice daily',
    String type = 'Tablet',
    String status = 'Active',
    DateTime? startDate,
    DateTime? endDate,
    String prescribedBy = 'Dr. Test',
    String notes = 'Test medication notes',
  }) {
    return {
      'patient_id': patientId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'type': type,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'prescribed_by': prescribedBy,
      'notes': notes,
    };
  }

  /// Create test condition data
  static Map<String, dynamic> createTestCondition({
    String patientId = 'patient_123',
    String name = 'Test Condition',
    String severity = 'Moderate',
    String description = 'Test condition description',
    DateTime? diagnosedDate,
    String diagnosedBy = 'Dr. Test',
    String icd10Code = 'A00.0',
    bool isActive = true,
  }) {
    return {
      'patient_id': patientId,
      'name': name,
      'severity': severity,
      'description': description,
      'diagnosed_date': diagnosedDate?.toIso8601String(),
      'diagnosed_by': diagnosedBy,
      'icd10_code': icd10Code,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Create test document data
  static Map<String, dynamic> createTestDocument({
    String? patientId,
    String? referralId,
    String name = 'Test Document',
    String type = 'Lab',
    String category = 'Test Results',
    String filePath = '/test/path/document.pdf',
    String? fileUrl,
    String? thumbnailUrl,
    int fileSize = 1024,
    DateTime? uploadDate,
  }) {
    return {
      'patient_id': patientId,
      'referral_id': referralId,
      'name': name,
      'type': type,
      'category': category,
      'file_path': filePath,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'file_size': fileSize,
      'upload_date': (uploadDate ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Create test message data
  static Map<String, dynamic> createTestMessage({
    String conversationId = 'conversation_123',
    String senderId = 'sender_123',
    String senderName = 'Test Sender',
    String content = 'Test message content',
    String messageType = 'text',
    String? attachments,
    String? referralId,
    DateTime? timestamp,
    String status = 'sent',
  }) {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'message_type': messageType,
      'attachments': attachments,
      'referral_id': referralId,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'status': status,
    };
  }

  /// Create test emergency contact data
  static Map<String, dynamic> createTestEmergencyContact({
    String patientId = 'patient_123',
    String name = 'Test Emergency Contact',
    String relationship = 'Spouse',
    String phone = '1234567890',
    String? email,
    bool isPrimary = true,
  }) {
    return {
      'patient_id': patientId,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
      'is_primary': isPrimary ? 1 : 0,
    };
  }

  /// Create test vital statistics data
  static Map<String, dynamic> createTestVitalStatistics({
    String patientId = 'patient_123',
    String bloodPressure = '120/80',
    String heartRate = '72',
    String temperature = '98.6',
    String oxygenSaturation = '98%',
    double weight = 70.0,
    double height = 175.0,
    double bmi = 22.9,
    DateTime? recordedDate,
    String recordedBy = 'Dr. Test',
  }) {
    return {
      'patient_id': patientId,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'temperature': temperature,
      'oxygen_saturation': oxygenSaturation,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'recorded_date': (recordedDate ?? DateTime.now()).toIso8601String(),
      'recorded_by': recordedBy,
    };
  }

  /// Assert that a result is successful
  static void assertSuccess<T>(Result<T> result, {String? message}) {
    expect(result.isSuccess, true, reason: message ?? 'Expected result to be successful');
  }

  /// Assert that a result is an error
  static void assertError<T>(Result<T> result, {String? message}) {
    expect(result.isError, true, reason: message ?? 'Expected result to be an error');
  }

  /// Assert that a result is loading
  static void assertLoading<T>(Result<T> result, {String? message}) {
    expect(result.isLoading, true, reason: message ?? 'Expected result to be loading');
  }

  /// Assert that a result contains specific data
  static void assertData<T>(Result<T> result, T expectedData, {String? message}) {
    assertSuccess(result, message: message);
    expect(result.data, expectedData, reason: message ?? 'Expected result data to match');
  }

  /// Assert that a result contains a specific error message
  static void assertErrorMessage<T>(Result<T> result, String expectedMessage, {String? message}) {
    assertError(result, message: message);
    expect(result.errorMessage, expectedMessage, reason: message ?? 'Expected error message to match');
  }
}