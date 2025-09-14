# MedRefer AI - Development Guide

## Overview

This guide provides comprehensive information for developers working on the MedRefer AI Flutter application. It covers architecture, coding standards, development workflow, and best practices.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Coding Standards](#coding-standards)
4. [Development Workflow](#development-workflow)
5. [Testing Guidelines](#testing-guidelines)
6. [Performance Guidelines](#performance-guidelines)
7. [Security Guidelines](#security-guidelines)
8. [Deployment Guidelines](#deployment-guidelines)
9. [Troubleshooting](#troubleshooting)

## Architecture Overview

### Clean Architecture

The MedRefer AI application follows Clean Architecture principles with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Services     │    │    Database     │
│                 │    │                 │    │                 │
│ • Screens       │◄──►│ • Auth Service  │◄──►│ • SQLite        │
│ • Widgets       │    │ • Data Service  │    │ • Models        │
│ • Controllers   │    │ • Sync Service  │    │ • DAOs          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Directory Structure

```
lib/
├── config/                 # Configuration files
├── core/                   # Core utilities and services
│   ├── app_export.dart     # Central exports
│   ├── performance/        # Performance optimization
│   ├── realtime/           # Real-time data services
│   └── search/             # Search functionality
├── database/               # Data layer
│   ├── dao/                # Data Access Objects
│   ├── models/             # Data models
│   ├── services/           # Database services
│   ├── database.dart       # Database exports
│   └── database_helper.dart # SQLite helper
├── presentation/           # UI layer (40+ screens)
├── routes/                 # Navigation and routing
├── services/               # Business logic services
├── theme/                  # UI theming
├── widgets/                # Reusable UI components
└── main.dart               # Application entry point
```

### Key Design Patterns

1. **Singleton Pattern**: Used for services that need global access
2. **Repository Pattern**: Used for data access abstraction
3. **Observer Pattern**: Used for state management with ChangeNotifier
4. **Factory Pattern**: Used for creating complex objects
5. **Strategy Pattern**: Used for different algorithms (e.g., conflict resolution)

## Development Environment Setup

### Prerequisites

- **Flutter SDK**: ^3.6.0
- **Dart SDK**: ^3.6.0
- **Android Studio** / **VS Code** with Flutter extensions
- **Android SDK** (API level 21+) / **Xcode** (iOS 12.0+)
- **Git** for version control

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/medrefer_ai.git
   cd medrefer_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment configuration**
   Create a `.env` file in the project root:
   ```env
   # Database Configuration
   DATABASE_URL=your_database_url

   # M-Pesa Configuration (Sandbox)
   MPESA_CONSUMER_KEY=your_mpesa_consumer_key
   MPESA_CONSUMER_SECRET=your_mpesa_consumer_secret
   MPESA_SHORTCODE=174379
   MPESA_PASSKEY=your_mpesa_passkey

   # Supabase Configuration
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### IDE Configuration

#### VS Code Settings

Create `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 120,
  "editor.rulers": [120],
  "editor.formatOnSave": true,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true
}
```

#### Android Studio Settings

1. Install Flutter and Dart plugins
2. Configure Flutter SDK path
3. Enable Dart analysis server
4. Set up code formatting rules

## Coding Standards

### Dart Style Guide

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

1. **Naming Conventions**
   - Use `camelCase` for variables, functions, and methods
   - Use `PascalCase` for classes and enums
   - Use `snake_case` for file names
   - Use `SCREAMING_SNAKE_CASE` for constants

2. **Code Organization**
   - One class per file
   - Group imports: dart, flutter, packages, local
   - Use meaningful names
   - Keep functions small and focused

3. **Documentation**
   - Document all public APIs
   - Use `///` for documentation comments
   - Include examples for complex functions

### Example Code Structure

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../database/models/patient.dart';

/// Service for managing patient data operations
class PatientService extends ChangeNotifier {
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LoggingService _loggingService = LoggingService();

  List<Patient> _patients = [];
  bool _isLoading = false;

  // Getters
  List<Patient> get patients => List.unmodifiable(_patients);
  bool get isLoading => _isLoading;

  /// Load all patients from database
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _loggingService.info('Loading patients', context: 'PatientService');
      
      final results = await _dbHelper.query('patients');
      _patients = results.map((data) => Patient.fromMap(data)).toList();
      
      _loggingService.info('Loaded ${_patients.length} patients', context: 'PatientService');
    } catch (e) {
      _loggingService.error('Failed to load patients', context: 'PatientService', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new patient
  Future<Result<Patient>> createPatient(PatientData data) async {
    try {
      // Validate input
      final validationResult = _validatePatientData(data);
      if (validationResult.isError) {
        return Result.error(validationResult.errorMessage!);
      }

      // Create patient
      final patient = Patient.fromData(validationResult.data!);
      final patientId = await _dbHelper.insert('patients', patient.toMap());
      
      _patients.add(patient);
      notifyListeners();
      
      _loggingService.userAction('create_patient', metadata: {
        'patient_id': patientId,
        'patient_name': patient.name,
      });

      return Result.success(patient);
    } catch (e) {
      _loggingService.error('Failed to create patient', context: 'PatientService', error: e);
      return Result.error('Failed to create patient: $e');
    }
  }

  /// Validate patient data
  Result<PatientData> _validatePatientData(PatientData data) {
    final validationService = ValidationService();
    
    // Validate name
    final nameResult = validationService.validateName(data.name);
    if (nameResult.isError) {
      return Result.error(nameResult.errorMessage!);
    }

    // Validate age
    final ageResult = validationService.validateAge(data.age);
    if (ageResult.isError) {
      return Result.error(ageResult.errorMessage!);
    }

    // Validate medical record number
    final mrnResult = validationService.validateMedicalRecordNumber(data.medicalRecordNumber);
    if (mrnResult.isError) {
      return Result.error(mrnResult.errorMessage!);
    }

    return Result.success(data);
  }
}
```

## Development Workflow

### Git Workflow

1. **Branch Naming**
   - `feature/feature-name` for new features
   - `bugfix/bug-description` for bug fixes
   - `hotfix/critical-fix` for critical fixes
   - `refactor/refactor-description` for refactoring

2. **Commit Messages**
   ```
   type(scope): description

   [optional body]

   [optional footer]
   ```

   Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

   Example:
   ```
   feat(patient): add patient search functionality

   - Implement search by name, MRN, and phone number
   - Add search filters for age and gender
   - Include performance optimizations for large datasets
   ```

3. **Pull Request Process**
   - Create feature branch from `main`
   - Implement changes with tests
   - Update documentation if needed
   - Create pull request with detailed description
   - Request code review from team members
   - Merge after approval and CI passes

### Code Review Checklist

- [ ] Code follows style guide
- [ ] Functions are small and focused
- [ ] Error handling is comprehensive
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] Performance implications considered
- [ ] Security implications reviewed
- [ ] Accessibility requirements met

## Testing Guidelines

### Test Structure

```
test/
├── core/                   # Core functionality tests
├── services/               # Service layer tests
├── database/               # Database tests
├── presentation/           # Widget tests
├── integration/            # Integration tests
└── test_config.dart        # Test configuration
```

### Unit Testing

```dart
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
        ];

        for (final email in invalidEmails) {
          final result = validationService.validateEmail(email);
          expect(result.isError, true);
          expect(result.errorMessage, isNotNull);
        }
      });
    });
  });
}
```

### Widget Testing

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/presentation/patient_list_screen/patient_list_screen.dart';

void main() {
  group('PatientListScreen', () {
    testWidgets('should display patient list', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(MaterialApp(home: PatientListScreen()));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify patient list is displayed
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Patient List'), findsOneWidget);
    });

    testWidgets('should show loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PatientListScreen()));

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

### Integration Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medrefer_ai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Patient Management Flow', () {
    testWidgets('should create and view patient', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to add patient screen
      await tester.tap(find.text('Add Patient'));
      await tester.pumpAndSettle();

      // Fill patient form
      await tester.enterText(find.byKey(Key('name_field')), 'John Doe');
      await tester.enterText(find.byKey(Key('age_field')), '35');
      await tester.enterText(find.byKey(Key('mrn_field')), 'MRN123456');

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify patient was created
      expect(find.text('Patient created successfully'), findsOneWidget);
    });
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/validation_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run tests in watch mode
flutter test --watch
```

## Performance Guidelines

### Memory Management

1. **Dispose Resources**
   ```dart
   class MyWidget extends StatefulWidget {
     @override
     _MyWidgetState createState() => _MyWidgetState();
   }

   class _MyWidgetState extends State<MyWidget> {
     StreamSubscription? _subscription;
     Timer? _timer;

     @override
     void initState() {
       super.initState();
       _subscription = someStream.listen(_handleData);
       _timer = Timer.periodic(Duration(seconds: 1), _updateUI);
     }

     @override
     void dispose() {
       _subscription?.cancel();
       _timer?.cancel();
       super.dispose();
     }
   }
   ```

2. **Use const Constructors**
   ```dart
   // Good
   const Text('Hello World')

   // Avoid
   Text('Hello World')
   ```

3. **Optimize Images**
   ```dart
   // Use optimized image widget
   PerformanceService.optimizedImage(
     imageUrl: 'https://example.com/image.jpg',
     width: 100,
     height: 100,
     fit: BoxFit.cover,
   )
   ```

### List Performance

1. **Use ListView.builder for Large Lists**
   ```dart
   ListView.builder(
     itemCount: items.length,
     itemBuilder: (context, index) => ListTile(
       title: Text(items[index].name),
     ),
   )
   ```

2. **Implement Pagination**
   ```dart
   Future<void> loadMoreItems() async {
     if (_isLoading || _hasReachedMax) return;
     
     _isLoading = true;
     final newItems = await _loadItems(_currentPage + 1);
     
     setState(() {
       _items.addAll(newItems);
       _currentPage++;
       _isLoading = false;
     });
   }
   ```

### Database Performance

1. **Use Indexes**
   ```dart
   // Create indexes for frequently queried columns
   await db.execute('CREATE INDEX idx_patients_name ON patients(name)');
   await db.execute('CREATE INDEX idx_patients_mrn ON patients(medical_record_number)');
   ```

2. **Batch Operations**
   ```dart
   // Use batch operations for multiple inserts
   final batch = db.batch();
   for (final patient in patients) {
     batch.insert('patients', patient.toMap());
   }
   await batch.commit();
   ```

3. **Use Transactions**
   ```dart
   await db.transaction((txn) async {
     await txn.insert('patients', patientData);
     await txn.insert('medical_history', historyData);
   });
   ```

## Security Guidelines

### Data Protection

1. **Encrypt Sensitive Data**
   ```dart
   final securityService = EnhancedSecurityService();
   final encryptedData = await securityService.encryptData(sensitiveData);
   await securityService.storeSecureData('key', encryptedData);
   ```

2. **Validate All Input**
   ```dart
   final validationService = ValidationService();
   final result = validationService.validateEmail(email);
   if (result.isError) {
     throw ValidationException(result.errorMessage!);
   }
   ```

3. **Use Secure Storage**
   ```dart
   const storage = FlutterSecureStorage(
     aOptions: AndroidOptions(
       encryptedSharedPreferences: true,
     ),
     iOptions: IOSOptions(
       accessibility: KeychainAccessibility.first_unlock_this_device,
     ),
   );
   ```

### Authentication

1. **Implement Rate Limiting**
   ```dart
   class AuthService {
     int _failedAttempts = 0;
     DateTime? _lastFailedAttempt;

     bool _isRateLimited() {
       if (_lastFailedAttempt == null) return false;
       final timeSinceLastAttempt = DateTime.now().difference(_lastFailedAttempt!);
       return timeSinceLastAttempt.inMinutes < 5 && _failedAttempts >= 3;
     }
   }
   ```

2. **Use Strong Passwords**
   ```dart
   bool _isValidPassword(String password) {
     return password.length >= 8 &&
            RegExp(r'[A-Z]').hasMatch(password) &&
            RegExp(r'[a-z]').hasMatch(password) &&
            RegExp(r'[0-9]').hasMatch(password) &&
            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
   }
   ```

### Network Security

1. **Use HTTPS**
   ```dart
   final dio = Dio();
   dio.options.baseUrl = 'https://api.medrefer.com';
   dio.options.connectTimeout = Duration(seconds: 30);
   dio.options.receiveTimeout = Duration(seconds: 30);
   ```

2. **Implement Certificate Pinning**
   ```dart
   (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
     client.badCertificateCallback = (cert, host, port) {
       // Implement certificate pinning logic
       return _isValidCertificate(cert, host);
     };
     return client;
   };
   ```

## Deployment Guidelines

### Build Configuration

1. **Environment-specific Builds**
   ```bash
   # Development
   flutter build apk --debug --dart-define=ENVIRONMENT=development

   # Staging
   flutter build apk --release --dart-define=ENVIRONMENT=staging

   # Production
   flutter build apk --release --dart-define=ENVIRONMENT=production
   ```

2. **Code Obfuscation**
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=debug-info
   ```

### App Store Deployment

1. **Android (Google Play)**
   ```bash
   # Build app bundle
   flutter build appbundle --release

   # Sign the bundle
   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore release-key.keystore app-release.aab alias_name
   ```

2. **iOS (App Store)**
   ```bash
   # Build for iOS
   flutter build ios --release

   # Archive in Xcode
   # Upload to App Store Connect
   ```

### CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.6.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter test --coverage

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.6.0'
      - run: flutter pub get
      - run: flutter build apk --release
```

## Troubleshooting

### Common Issues

1. **Build Failures**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter build apk
   ```

2. **Dependency Conflicts**
   ```bash
   # Check dependency tree
   flutter pub deps

   # Resolve conflicts
   flutter pub upgrade
   ```

3. **Performance Issues**
   ```bash
   # Profile the app
   flutter run --profile

   # Analyze performance
   flutter run --trace-startup
   ```

### Debug Tools

1. **Flutter Inspector**
   - Use VS Code Flutter extension
   - Inspect widget tree
   - Debug layout issues

2. **Performance Overlay**
   ```dart
   MaterialApp(
     showPerformanceOverlay: true,
     // ... other properties
   )
   ```

3. **Debug Logging**
   ```dart
   if (kDebugMode) {
     debugPrint('Debug message: $data');
   }
   ```

### Getting Help

1. **Documentation**
   - Flutter documentation
   - Dart documentation
   - Project-specific docs

2. **Community**
   - Flutter Discord
   - Stack Overflow
   - GitHub Issues

3. **Team Support**
   - Internal Slack channels
   - Code review sessions
   - Pair programming

## Conclusion

This development guide provides comprehensive information for working with the MedRefer AI application. Follow these guidelines to ensure code quality, performance, and maintainability.

For additional information or support, please refer to the API documentation or contact the development team.
