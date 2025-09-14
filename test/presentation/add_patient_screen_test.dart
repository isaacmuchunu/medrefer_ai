import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/presentation/add_patient_screen/add_patient_screen.dart';
import '../../lib/database/services/data_service.dart';
import '../../lib/database/models/models.dart';

// Generate mocks
@GenerateMocks([DataService])
import 'add_patient_screen_test.mocks.dart';

void main() {
  group('AddPatientScreen Tests', () {
    late MockDataService mockDataService;

    setUp(() {
      mockDataService = MockDataService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<DataService>.value(
          value: mockDataService,
          child: const AddPatientScreen(),
        ),
      );
    }

    testWidgets('should display all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check if all tabs are present
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Medical'), findsOneWidget);

      // Check if basic info fields are present
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Medical Record Number'), findsOneWidget);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to proceed without filling required fields
      await tester.tap(find.text('Next'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter patient\'s name'), findsOneWidget);
      expect(find.text('Please enter MRN'), findsOneWidget);
    });

    testWidgets('should navigate between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill required fields in basic info
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Medical Record Number'),
        'MRN001',
      );

      // Select date of birth
      await tester.tap(find.text('Select Date of Birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Navigate to next tab
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on contact tab
      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('should save patient successfully', (WidgetTester tester) async {
      // Mock successful patient creation
      when(mockDataService.createPatient(any))
          .thenAnswer((_) async => 'patient-id-123');
      when(mockDataService.createMedicalHistory(any))
          .thenAnswer((_) async => 'history-id-123');

      await tester.pumpWidget(createTestWidget());

      // Fill all required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Medical Record Number'),
        'MRN001',
      );

      // Select date of birth
      await tester.tap(find.text('Select Date of Birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Navigate to contact tab
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Fill contact info
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '+1-555-1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Emergency Contact Name'),
        'Jane Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Emergency Contact Phone'),
        '+1-555-5678',
      );

      // Navigate to medical tab
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Navigate to final step and save
      await tester.tap(find.text('Save Patient'));
      await tester.pump();

      // Verify patient creation was called
      verify(mockDataService.createPatient(any)).called(1);
    });

    testWidgets('should handle save error gracefully', (WidgetTester tester) async {
      // Mock failed patient creation
      when(mockDataService.createPatient(any))
          .thenThrow(Exception('Database error'));

      await tester.pumpWidget(createTestWidget());

      // Fill required fields and attempt to save
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Medical Record Number'),
        'MRN001',
      );

      // Select date of birth
      await tester.tap(find.text('Select Date of Birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Navigate through tabs
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '+1-555-1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Emergency Contact Name'),
        'Jane Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Emergency Contact Phone'),
        '+1-555-5678',
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save Patient'));
      await tester.pump();

      // Should show error message
      expect(find.textContaining('Failed to add patient'), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Navigate to contact tab
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Medical Record Number'),
        'MRN001',
      );

      await tester.tap(find.text('Select Date of Birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'invalid-email',
      );

      // Try to proceed
      await tester.tap(find.text('Next'));
      await tester.pump();

      // Should show email validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should handle dropdown selections', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Test gender dropdown
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();

      // Test blood type dropdown
      await tester.tap(find.text('O+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A+').last);
      await tester.pumpAndSettle();

      // Verify selections are updated
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);
    });
  });
}
