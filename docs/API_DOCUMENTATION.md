# MedRefer AI - API Documentation

## Overview

This document provides comprehensive API documentation for the MedRefer AI Flutter application. The application follows a clean architecture pattern with clear separation of concerns between the presentation, business logic, and data layers.

## Table of Contents

1. [Core Services](#core-services)
2. [Authentication Services](#authentication-services)
3. [Database Services](#database-services)
4. [Security Services](#security-services)
5. [Performance Services](#performance-services)
6. [Real-time Services](#real-time-services)
7. [Accessibility Services](#accessibility-services)
8. [Error Handling](#error-handling)
9. [Testing Framework](#testing-framework)

## Core Services

### LoggingService

Comprehensive logging service for application-wide logging with different levels and contexts.

#### Methods

```dart
// Initialize the logging service
Future<void> initialize()

// Log different levels
void info(String message, {String? context, Map<String, dynamic>? metadata})
void warning(String message, {String? context, Map<String, dynamic>? metadata})
void error(String message, {String? context, Map<String, dynamic>? metadata, Object? error, StackTrace? stackTrace})
void debug(String message, {String? context, Map<String, dynamic>? metadata})
void critical(String message, {String? context, Map<String, dynamic>? metadata, Object? error, StackTrace? stackTrace})

// Specialized logging
void userAction(String action, {String? userId, String? context, Map<String, dynamic>? metadata})
void performance(String metric, double value, {String? context, Map<String, dynamic>? metadata})
void network(String method, String url, {int? statusCode, int? responseTime, Map<String, dynamic>? metadata})
void database(String operation, String table, {String? context, Map<String, dynamic>? metadata})

// Utility methods
Future<List<LogEntry>> getLogs({DateTime? startTime, DateTime? endTime, LogLevel? minLevel, String? context})
void clearInMemoryLogs()
Future<String> exportLogs({DateTime? startTime, DateTime? endTime})
```

#### Usage Example

```dart
final loggingService = LoggingService();
await loggingService.initialize();

// Log user action
loggingService.userAction('login_attempt', userId: 'user123', metadata: {
  'timestamp': DateTime.now().toIso8601String(),
});

// Log performance metric
loggingService.performance('screen_load_time', 150.0, context: 'DashboardScreen');

// Log network request
loggingService.network('POST', '/api/patients', statusCode: 201, responseTime: 250);
```

### ErrorHandlingService

Comprehensive error handling service with structured error management and user-friendly error reporting.

#### Methods

```dart
// Initialize the service
Future<void> initialize()

// Handle different error types
Future<void> handleNetworkError(dynamic error, {String? context})
Future<void> handleDatabaseError(dynamic error, {String? context})
Future<void> handleAuthError(dynamic error, {String? context})
Future<void> handleValidationError(String message, {String? context})
Future<void> handleBusinessError(String message, {String? context, String? userAction})

// Show error dialog to user
Future<void> showErrorDialog(BuildContext context, AppError error)

// Configuration
void setErrorReporting(bool enabled)
void setUserFeedback(bool enabled)
void clearErrorHistory()
```

#### Usage Example

```dart
final errorService = ErrorHandlingService();
await errorService.initialize();

try {
  // Some operation that might fail
  await riskyOperation();
} catch (e) {
  await errorService.handleNetworkError(e, context: 'PatientSync');
}

// Show error dialog
await errorService.showErrorDialog(context, AppError(
  type: ErrorType.network,
  message: 'Failed to sync patient data',
  severity: ErrorSeverity.medium,
  context: 'PatientSync',
  userAction: 'Please check your internet connection and try again.',
));
```

## Authentication Services

### AuthService

Enhanced authentication service with security features, rate limiting, and audit logging.

#### Methods

```dart
// Initialize the service
Future<void> initialize()

// Authentication methods
Future<bool> login({required String email, required String password, bool rememberMe = false})
Future<bool> loginWithBiometrics()
Future<bool> register({required String email, required String password, required String name, required String role, String? phone, String? hospitalId})
Future<void> logout()

// Password management
Future<bool> requestPasswordReset(String email)
Future<bool> resetPassword({required String email, required String token, required String newPassword})

// Getters
User? get currentUser
bool get isAuthenticated
String? get authToken
```

#### Usage Example

```dart
final authService = AuthService();
await authService.initialize();

// Login with credentials
final success = await authService.login(
  email: 'doctor@medrefer.com',
  password: 'SecurePassword123!',
  rememberMe: true,
);

if (success) {
  print('Logged in as: ${authService.currentUser?.displayName}');
}

// Biometric login
final biometricSuccess = await authService.loginWithBiometrics();
```

### EnhancedSecurityService

Advanced security service with encryption, secure storage, and validation utilities.

#### Methods

```dart
// Token and key generation
String generateSecureToken({int length = 32})
String generateSessionId()
String generateApiKey({String? prefix})

// Data encryption/decryption
Future<String> encryptData(String data, {String? key})
Future<String> decryptData(String encryptedData, {String? key})

// Password handling
String hashPassword(String password, {String? salt})
bool verifyPassword(String password, String hash)

// Secure storage
Future<void> storeSecureData(String key, String value)
Future<String?> getSecureData(String key)
Future<void> deleteSecureData(String key)
Future<void> clearAllSecureData()

// Validation utilities
bool isValidEmail(String email)
bool isValidPhoneNumber(String phone)
bool isPasswordStrong(String password)
int getPasswordStrengthScore(String password)
String sanitizeInput(String input)
```

#### Usage Example

```dart
final securityService = EnhancedSecurityService();

// Generate secure token
final token = securityService.generateSecureToken();

// Hash password
final hashedPassword = securityService.hashPassword('userPassword');

// Store sensitive data
await securityService.storeSecureData('api_key', 'sensitive_api_key');

// Validate input
final isValid = securityService.isValidEmail('user@example.com');
```

## Database Services

### DatabaseHelper

Enhanced database helper with performance optimizations, advanced querying, and maintenance features.

#### Methods

```dart
// Basic CRUD operations
Future<String> insert(String table, Map<String, dynamic> data)
Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit, int? offset})
Future<Map<String, dynamic>?> queryById(String table, String id)
Future<int> update(String table, Map<String, dynamic> data, String id)
Future<int> delete(String table, String id)

// Advanced querying
Future<List<Map<String, dynamic>>> queryWithJoins({required String baseTable, required List<String> joinTables, required List<String> selectColumns, String? where, List<dynamic>? whereArgs, String? orderBy, int? limit, int? offset})
Future<List<Map<String, dynamic>>> fullTextSearch({required String table, required String searchTerm, List<String>? columns, int? limit})
Future<Map<String, dynamic>> paginatedQuery({required String table, String? where, List<dynamic>? whereArgs, String? orderBy, required int page, required int pageSize})

// Batch operations
Future<void> batchInsert(String table, List<Map<String, dynamic>> dataList)
Future<void> batchOperation(List<BatchOperation> operations)

// Database maintenance
Future<void> optimizeDatabase()
Future<Map<String, dynamic>> getDatabaseStats()
Future<String> backupDatabase()
Future<void> restoreDatabase(String backupPath)
```

#### Usage Example

```dart
final dbHelper = DatabaseHelper();

// Insert patient data
final patientId = await dbHelper.insert('patients', {
  'id': 'patient_123',
  'name': 'John Doe',
  'age': 35,
  'medical_record_number': 'MRN123456',
  'date_of_birth': DateTime(1988, 5, 15).toIso8601String(),
  'gender': 'Male',
});

// Query with pagination
final result = await dbHelper.paginatedQuery(
  table: 'patients',
  where: 'age > ?',
  whereArgs: [18],
  orderBy: 'name ASC',
  page: 1,
  pageSize: 20,
);

// Full-text search
final searchResults = await dbHelper.fullTextSearch(
  table: 'patients',
  searchTerm: 'John',
  columns: ['name', 'medical_record_number'],
  limit: 10,
);
```

## Security Services

### ValidationService

Comprehensive validation service for all types of user input and data validation.

#### Methods

```dart
// Email validation
Result<String> validateEmail(String email)

// Password validation
Result<String> validatePassword(String password)

// Phone number validation
Result<String> validatePhoneNumber(String phone)

// Name validation
Result<String> validateName(String name, {String fieldName = 'Name'})

// Medical data validation
Result<String> validateMedicalRecordNumber(String mrn)
Result<int> validateAge(int age)
Result<DateTime> validateDateOfBirth(DateTime dateOfBirth)
Result<String> validateIcd10Code(String code)

// Medication validation
Result<String> validateMedicationName(String name)
Result<String> validateDosage(String dosage)
Result<String> validateFrequency(String frequency)

// File validation
Result<File> validateFileSize(File file, {int maxSizeInMB = 10})
Result<File> validateFileType(File file, List<String> allowedExtensions)

// Numeric validation
Result<double> validateNumeric(String input, {String fieldName = 'Value'})
Result<double> validatePositiveNumeric(String input, {String fieldName = 'Value'})
Result<int> validateInteger(String input, {String fieldName = 'Value'})
Result<int> validatePositiveInteger(String input, {String fieldName = 'Value'})

// Multiple field validation
Result<Map<String, dynamic>> validateMultiple(Map<String, String> fields, Map<String, Result<String> Function(String)> validators)

// Input sanitization
String sanitizeInput(String input)
Result<String> validateAndSanitize(String input, {String fieldName = 'Field'})
```

#### Usage Example

```dart
final validationService = ValidationService();

// Validate email
final emailResult = validationService.validateEmail('user@example.com');
if (emailResult.isSuccess) {
  print('Valid email: ${emailResult.data}');
} else {
  print('Invalid email: ${emailResult.errorMessage}');
}

// Validate multiple fields
final fields = {
  'email': 'user@example.com',
  'password': 'SecurePass123!',
  'name': 'John Doe',
};

final validators = {
  'email': (value) => validationService.validateEmail(value),
  'password': (value) => validationService.validatePassword(value),
  'name': (value) => validationService.validateName(value),
};

final result = validationService.validateMultiple(fields, validators);
```

## Performance Services

### PerformanceService

Comprehensive performance monitoring and optimization service.

#### Methods

```dart
// Initialization
static Future<void> initialize()

// Performance monitoring
static void startMonitoring()
static void stopMonitoring()
static void trackScreenLoad(String screenName)
static void trackUserAction(String action, {Map<String, dynamic>? metadata})
static void trackNetworkRequest(String url, Duration duration, {int? statusCode})
static void trackDatabaseOperation(String operation, Duration duration, {String? table})

// Performance metrics
static Map<String, dynamic> getPerformanceMetrics()
static Map<String, dynamic> getMemoryUsage()
static Map<String, dynamic> getCpuUsage()
static void optimizePerformance()

// UI optimizations
static Widget optimizedBuilder({required Widget Function() builder, List<Object?>? dependencies})
static Widget optimizedListView({required int itemCount, required Widget Function(BuildContext, int) itemBuilder, ScrollController? controller, EdgeInsets? padding})
static Widget optimizedGridView({required int itemCount, required Widget Function(BuildContext, int) itemBuilder, required SliverGridDelegate gridDelegate, ScrollController? controller, EdgeInsets? padding})
static Widget optimizedImage({required String imageUrl, double? width, double? height, BoxFit? fit, Widget? placeholder, Widget? errorWidget})

// Utility methods
static void debounce({required String key, required VoidCallback callback, Duration delay = const Duration(milliseconds: 300)})
static void clearCaches()
```

#### Usage Example

```dart
// Initialize performance monitoring
await PerformanceService.initialize();
PerformanceService.startMonitoring();

// Track screen load
PerformanceService.trackScreenLoad('PatientListScreen');

// Track user action
PerformanceService.trackUserAction('create_patient', metadata: {
  'patient_type': 'new',
  'source': 'dashboard',
});

// Use optimized widgets
Widget build(BuildContext context) {
  return PerformanceService.optimizedListView(
    itemCount: patients.length,
    itemBuilder: (context, index) => PatientListItem(patient: patients[index]),
  );
}

// Get performance metrics
final metrics = PerformanceService.getPerformanceMetrics();
print('Jank percentage: ${metrics['jankPercentage']}%');
```

## Real-time Services

### RealtimeUpdateService

WebSocket-based real-time update service for live data synchronization.

#### Methods

```dart
// Connection management
Future<void> initialize()
Future<void> connect(String url, {String? authToken})
Future<void> disconnect()

// Subscription management
Stream<RealtimeMessage> subscribe(String channel, {Map<String, dynamic>? filters})
void unsubscribe(String channel)

// Message handling
Future<void> sendMessage(String type, Map<String, dynamic> data)

// Status and utilities
Map<String, dynamic> getConnectionStatus()
void clearHistory()
```

#### Usage Example

```dart
final realtimeService = RealtimeUpdateService();
await realtimeService.initialize();

// Connect to real-time server
await realtimeService.connect('wss://api.medrefer.com/realtime', authToken: 'user_token');

// Subscribe to patient updates
final patientStream = realtimeService.subscribe('patients', filters: {
  'hospital_id': 'hospital_123',
});

patientStream.listen((message) {
  print('Received patient update: ${message.data}');
});

// Send message
await realtimeService.sendMessage('patient_update', {
  'patient_id': 'patient_123',
  'status': 'discharged',
});
```

### OfflineSyncService

Advanced offline synchronization service with conflict resolution and intelligent retry logic.

#### Methods

```dart
// Initialization and management
Future<void> initialize()
Future<void> queueOperation(SyncOperation operation)
Future<void> queueBatch(List<SyncOperation> operations)
Future<SyncResult> performSync()

// Queue management
Future<void> clearQueue()
Future<SyncStatistics> getStatistics()

// Getters
bool get isOnline
bool get isSyncing
int get queueSize
int get pendingOperations
DateTime? get lastSyncTime
SyncMetrics get metrics
```

#### Usage Example

```dart
final syncService = OfflineSyncService();
await syncService.initialize();

// Queue a patient creation operation
final operation = SyncOperation(
  id: 'op_${DateTime.now().millisecondsSinceEpoch}',
  operationType: OperationType.create,
  entityType: 'patient',
  entityId: 'patient_123',
  data: {
    'name': 'John Doe',
    'age': 35,
    'medical_record_number': 'MRN123456',
  },
  timestamp: DateTime.now(),
  priority: SyncPriority.normal,
);

await syncService.queueOperation(operation);

// Perform sync when online
if (syncService.isOnline) {
  final result = await syncService.performSync();
  print('Sync result: ${result.success}');
}
```

## Accessibility Services

### AccessibilityService

Comprehensive accessibility service for screen reader support and accessibility features.

#### Methods

```dart
// Initialization
Future<void> initialize()

// Language management
Future<void> setPreferredLanguage(String language)

// Accessible text generation
String getAccessibleText(String text, {String? context})
String getAccessibleButtonText(String text, {String? action})
String getAccessibleFormFieldDescription(String label, {String? hint, bool isRequired = false})

// Getters
bool get isInitialized
bool get isScreenReaderEnabled
String get preferredLanguage
```

#### Usage Example

```dart
final accessibilityService = AccessibilityService();
await accessibilityService.initialize();

// Set preferred language
await accessibilityService.setPreferredLanguage('en');

// Generate accessible text
final accessibleText = accessibilityService.getAccessibleText(
  'Patient John Doe',
  context: 'Patient name',
);

// Generate accessible button text
final buttonText = accessibilityService.getAccessibleButtonText(
  'Save',
  action: 'Saves the patient information',
);
```

### InternationalizationService

Multi-language support service for internationalization.

#### Methods

```dart
// Initialization
Future<void> initialize()

// Language management
Future<void> setLanguage(String language)
Future<void> setCountry(String country)
Future<void> setLocale(Locale locale)

// Localization
String getText(String key, {Map<String, dynamic>? params})

// Utilities
List<Locale> getSupportedLocales()
bool isLanguageSupported(String language)
String getLanguageName(String languageCode)
Map<String, dynamic> getLocaleSettings()

// Getters
bool get isInitialized
String get currentLanguage
String get currentCountry
Locale get currentLocale
Map<String, String> get supportedLanguages
```

#### Usage Example

```dart
final i18nService = InternationalizationService();
await i18nService.initialize();

// Set language
await i18nService.setLanguage('es');

// Get localized text
final welcomeText = i18nService.getText('welcome_message', params: {
  'user_name': 'Dr. Smith',
});

// Check supported languages
final isSupported = i18nService.isLanguageSupported('fr');
```

## Error Handling

### Result Type

Type-safe result wrapper for handling success and error states.

#### Methods

```dart
// Factory constructors
factory Result.success(T data)
factory Result.error(String message, [Object? error, StackTrace? stackTrace])
factory Result.loading()

// State checking
bool get isSuccess
bool get isError
bool get isLoading

// Data access
T? get data
String? get errorMessage
Object? get error
StackTrace? get stackTrace

// Transformations
Result<R> map<R>(R Function(T data) transform)
R mapOr<R>(R defaultValue, R Function(T data) transform)
R mapOrElse<R>(R Function() defaultValue, R Function(T data) transform)

// Chaining
Future<Result<R>> andThen<R>(Future<Result<R>> Function(T data) operation)
Result<R> andThenSync<R>(Result<R> Function(T data) operation)

// Unwrapping
T unwrap()
T unwrapOr(T defaultValue)
T unwrapOrElse(T Function() defaultValue)

// Callbacks
Result<T> onSuccess(void Function(T data) callback)
Result<T> onError(void Function(String message, Object? error) callback)
Result<T> onLoading(void Function() callback)
```

#### Usage Example

```dart
// Create successful result
final successResult = Result.success('Hello World');

// Create error result
final errorResult = Result.error('Something went wrong');

// Transform data
final transformed = successResult.map((data) => data.toUpperCase());

// Chain operations
final chained = await successResult.andThen((data) async {
  return Result.success(data.length);
});

// Handle results
successResult.onSuccess((data) {
  print('Success: $data');
}).onError((message, error) {
  print('Error: $message');
});
```

## Testing Framework

### TestConfig

Comprehensive test configuration and utilities for unit testing.

#### Methods

```dart
// Test environment setup
static Future<void> setupTestEnvironment()
static Future<void> cleanupTestEnvironment()

// Test data creation
static Map<String, dynamic> createTestUser({String email, String password, String firstName, String lastName, UserRole role})
static Map<String, dynamic> createTestPatient({String name, int age, String medicalRecordNumber, DateTime? dateOfBirth, String gender, String bloodType, String phone, String email, String address})
static Map<String, dynamic> createTestSpecialist({String name, String credentials, String specialty, String hospital, double rating, bool isAvailable, double latitude, double longitude})
static Map<String, dynamic> createTestReferral({String patientId, String? specialistId, String status, String urgency, String symptomsDescription, double aiConfidence, String department, String referringPhysician})

// Assertion helpers
static void assertSuccess<T>(Result<T> result, {String? message})
static void assertError<T>(Result<T> result, {String? message})
static void assertLoading<T>(Result<T> result, {String? message})
static void assertData<T>(Result<T> result, T expectedData, {String? message})
static void assertErrorMessage<T>(Result<T> result, String expectedMessage, {String? message})
```

#### Usage Example

```dart
void main() {
  setUp(() async {
    await TestConfig.setupTestEnvironment();
  });

  tearDown(() async {
    await TestConfig.cleanupTestEnvironment();
  });

  test('should validate email correctly', () {
    final validationService = ValidationService();
    final result = validationService.validateEmail('test@example.com');
    
    TestConfig.assertSuccess(result);
    TestConfig.assertData(result, 'test@example.com');
  });

  test('should create test patient', () {
    final patientData = TestConfig.createTestPatient(
      name: 'Test Patient',
      age: 30,
      medicalRecordNumber: 'MRN123456',
    );
    
    expect(patientData['name'], 'Test Patient');
    expect(patientData['age'], 30);
  });
}
```

## Best Practices

### 1. Service Initialization

Always initialize services in the correct order in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services first
  await PerformanceService.initialize();
  PerformanceService.startMonitoring();
  
  final errorHandlingService = ErrorHandlingService();
  await errorHandlingService.initialize();

  final loggingService = LoggingService();
  await loggingService.initialize();

  // Initialize other services
  // ...
}
```

### 2. Error Handling

Use the Result type for type-safe error handling:

```dart
Future<Result<Patient>> createPatient(PatientData data) async {
  try {
    // Validate input
    final validationResult = validationService.validatePatientData(data);
    if (validationResult.isError) {
      return Result.error(validationResult.errorMessage!);
    }

    // Create patient
    final patient = await patientService.create(validationResult.data!);
    return Result.success(patient);
  } catch (e) {
    return Result.error('Failed to create patient', e);
  }
}
```

### 3. Performance Monitoring

Track performance metrics for critical operations:

```dart
Future<void> loadPatientList() async {
  final stopwatch = Stopwatch()..start();
  
  try {
    PerformanceService.trackUserAction('load_patient_list');
    
    final patients = await patientService.getAll();
    
    stopwatch.stop();
    PerformanceService.trackScreenLoad('PatientListScreen');
    
    loggingService.performance('patient_list_load', stopwatch.elapsedMilliseconds.toDouble());
  } catch (e) {
    await errorHandlingService.handleDatabaseError(e, context: 'PatientList');
  }
}
```

### 4. Offline Sync

Queue operations for offline sync:

```dart
Future<void> updatePatient(Patient patient) async {
  try {
    // Update locally first
    await localDatabase.updatePatient(patient);
    
    // Queue for sync
    final operation = SyncOperation(
      id: 'update_${patient.id}_${DateTime.now().millisecondsSinceEpoch}',
      operationType: OperationType.update,
      entityType: 'patient',
      entityId: patient.id,
      data: patient.toMap(),
      timestamp: DateTime.now(),
      priority: SyncPriority.normal,
    );
    
    await syncService.queueOperation(operation);
  } catch (e) {
    await errorHandlingService.handleDatabaseError(e, context: 'UpdatePatient');
  }
}
```

### 5. Real-time Updates

Subscribe to real-time updates for live data:

```dart
class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  StreamSubscription<RealtimeMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribeToUpdates();
  }

  void _subscribeToUpdates() {
    _subscription = realtimeService.subscribe('patients').listen((message) {
      if (message.type == 'patient_updated') {
        setState(() {
          // Update UI with new data
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## Conclusion

This API documentation provides comprehensive coverage of all services and utilities available in the MedRefer AI application. Each service is designed with performance, security, and maintainability in mind, following Flutter and Dart best practices.

For additional information or support, please refer to the individual service documentation or contact the development team.
