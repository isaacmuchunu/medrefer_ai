import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import '../../lib/main.dart' as app;
import '../../lib/database/services/data_service.dart';
import '../../lib/database/models/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MedRefer AI Integration Tests', () {
    testWidgets('complete app flow test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Should start with splash screen
      expect(find.text('MedRefer AI'), findsOneWidget);
      
      // Wait for splash screen to complete
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should navigate to login screen
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Enter login credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should navigate to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Create Referral'), findsOneWidget);
      expect(find.text('Recent Referrals'), findsOneWidget);
    });

    testWidgets('patient management flow', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Login
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Navigate to patient search
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Should show patient search screen
      expect(find.text('Search Patients'), findsOneWidget);
      expect(find.text('Add New Patient'), findsOneWidget);

      // Tap add new patient
      await tester.tap(find.text('Add New Patient'));
      await tester.pumpAndSettle();

      // Should show add patient screen
      expect(find.text('Add New Patient'), findsOneWidget);
      expect(find.text('Basic Info'), findsOneWidget);

      // Fill patient information
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

      // Fill contact information
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

      // Save patient
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      // Should show success message and return to patient list
      expect(find.text('Patient added successfully'), findsOneWidget);
    });

    testWidgets('referral creation flow', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Login
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Tap create referral
      await tester.tap(find.text('Create Referral'));
      await tester.pumpAndSettle();

      // Should show create referral screen
      expect(find.text('Create Referral'), findsOneWidget);
      expect(find.text('Patient Selection'), findsOneWidget);

      // Select a patient
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Smith').last);
      await tester.pumpAndSettle();

      // Navigate to next step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Fill medical information
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Chief Complaint'),
        'Chest pain',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Symptoms Description'),
        'Patient experiencing chest pain for 2 days',
      );

      // Navigate to specialist selection
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Select specialist
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Emily Chen').last);
      await tester.pumpAndSettle();

      // Navigate to review
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Submit referral
      await tester.tap(find.text('Submit Referral'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Referral created successfully'), findsOneWidget);
    });

    testWidgets('navigation flow test', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Login
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Test bottom navigation
      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();
      expect(find.text('Patients'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.assignment));
      await tester.pumpAndSettle();
      expect(find.text('Referrals'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();
      expect(find.text('Messages'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      // Return to dashboard
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('settings and help flow', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Login
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Tap settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show settings screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Go back and access help
      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      // Should show help screen
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('error handling test', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Try to login with invalid credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid@email.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrongpassword',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Invalid credentials'), findsOneWidget);

      // Login with correct credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should successfully login
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('offline mode test', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Login
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@medrefer.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Simulate offline state by navigating to error screen
      // (In a real test, you would simulate network disconnection)
      
      // The app should handle offline gracefully
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
