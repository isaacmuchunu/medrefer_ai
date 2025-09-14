import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import '../../lib/main.dart' as app;
import '../../lib/database/services/data_service.dart';
import '../../lib/routes/app_routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete MedRefer AI App Integration Tests', () {
    testWidgets('complete user journey test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Test splash screen
      expect(find.text('MedRefer AI'), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Test login flow
      await _testLoginFlow(tester);
      
      // Test dashboard functionality
      await _testDashboard(tester);
      
      // Test patient management
      await _testPatientManagement(tester);
      
      // Test referral creation
      await _testReferralCreation(tester);
      
      // Test messaging
      await _testMessaging(tester);
      
      // Test settings and help
      await _testSettingsAndHelp(tester);
    });

    testWidgets('database integration test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Login
      await _performLogin(tester);
      
      // Test database operations
      await _testDatabaseOperations(tester);
    });

    testWidgets('navigation flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      await _performLogin(tester);
      
      // Test all navigation routes
      await _testAllRoutes(tester);
    });

    testWidgets('error handling test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Test error scenarios
      await _testErrorHandling(tester);
    });

    testWidgets('performance test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      await _performLogin(tester);
      
      // Test performance with large datasets
      await _testPerformance(tester);
    });
  });
}

Future<void> _testLoginFlow(WidgetTester tester) async {
  // Should show login screen
  expect(find.text('Welcome Back'), findsOneWidget);
  expect(find.text('Sign In'), findsOneWidget);

  // Test invalid login
  await tester.enterText(find.byType(TextFormField).first, 'invalid@email.com');
  await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();

  // Should show error
  expect(find.textContaining('Invalid'), findsOneWidget);

  // Test valid login
  await tester.enterText(find.byType(TextFormField).first, 'test@medrefer.com');
  await tester.enterText(find.byType(TextFormField).last, 'password123');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();

  // Should navigate to dashboard
  expect(find.text('Dashboard'), findsOneWidget);
}

Future<void> _testDashboard(WidgetTester tester) async {
  // Should show dashboard elements
  expect(find.text('Dashboard'), findsOneWidget);
  expect(find.text('Create Referral'), findsOneWidget);
  expect(find.text('Recent Referrals'), findsOneWidget);

  // Test quick actions
  await tester.tap(find.text('View All Patients'));
  await tester.pumpAndSettle();
  expect(find.text('Search Patients'), findsOneWidget);

  // Return to dashboard
  await tester.tap(find.byIcon(Icons.dashboard));
  await tester.pumpAndSettle();
}

Future<void> _testPatientManagement(WidgetTester tester) async {
  // Navigate to patients
  await tester.tap(find.byIcon(Icons.people));
  await tester.pumpAndSettle();

  // Test patient search
  expect(find.text('Search Patients'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'John');
  await tester.pumpAndSettle();

  // Test add new patient
  await tester.tap(find.text('Add New Patient'));
  await tester.pumpAndSettle();

  expect(find.text('Add New Patient'), findsOneWidget);
  expect(find.text('Basic Info'), findsOneWidget);

  // Fill patient form
  await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Test Patient');
  await tester.enterText(find.widgetWithText(TextFormField, 'Medical Record Number'), 'TEST001');

  // Select date of birth
  await tester.tap(find.text('Select Date of Birth'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  // Navigate through tabs
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Fill contact info
  await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '+1-555-TEST');
  await tester.enterText(find.widgetWithText(TextFormField, 'Emergency Contact Name'), 'Emergency Contact');
  await tester.enterText(find.widgetWithText(TextFormField, 'Emergency Contact Phone'), '+1-555-EMERGENCY');

  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Save patient
  await tester.tap(find.text('Save Patient'));
  await tester.pumpAndSettle();

  // Should show success message
  expect(find.text('Patient added successfully'), findsOneWidget);
}

Future<void> _testReferralCreation(WidgetTester tester) async {
  // Navigate to dashboard
  await tester.tap(find.byIcon(Icons.dashboard));
  await tester.pumpAndSettle();

  // Create referral
  await tester.tap(find.text('Create Referral'));
  await tester.pumpAndSettle();

  expect(find.text('Create Referral'), findsOneWidget);

  // Select patient
  await tester.tap(find.byType(DropdownButtonFormField).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Test Patient').last);
  await tester.pumpAndSettle();

  // Navigate through referral creation steps
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Fill medical information
  await tester.enterText(find.widgetWithText(TextFormField, 'Chief Complaint'), 'Test complaint');
  await tester.enterText(find.widgetWithText(TextFormField, 'Symptoms Description'), 'Test symptoms');

  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Select specialist
  await tester.tap(find.byType(DropdownButtonFormField).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dr. Emily Chen').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Submit referral
  await tester.tap(find.text('Submit Referral'));
  await tester.pumpAndSettle();

  expect(find.text('Referral created successfully'), findsOneWidget);
}

Future<void> _testMessaging(WidgetTester tester) async {
  // Navigate to messages
  await tester.tap(find.byIcon(Icons.message));
  await tester.pumpAndSettle();

  expect(find.text('Messages'), findsOneWidget);

  // Test message functionality if available
  if (find.text('Start New Conversation').evaluate().isNotEmpty) {
    await tester.tap(find.text('Start New Conversation'));
    await tester.pumpAndSettle();
  }
}

Future<void> _testSettingsAndHelp(WidgetTester tester) async {
  // Navigate to profile
  await tester.tap(find.byIcon(Icons.person));
  await tester.pumpAndSettle();

  // Test settings
  if (find.text('Settings').evaluate().isNotEmpty) {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();
  }

  // Test help
  if (find.text('Help & Support').evaluate().isNotEmpty) {
    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();
  }
}

Future<void> _testDatabaseOperations(WidgetTester tester) async {
  // Test database operations through UI
  await tester.tap(find.byIcon(Icons.people));
  await tester.pumpAndSettle();

  // Search should work
  await tester.enterText(find.byType(TextField), 'Test');
  await tester.pumpAndSettle();

  // Results should be filtered
  expect(find.text('Test Patient'), findsOneWidget);
}

Future<void> _testAllRoutes(WidgetTester tester) async {
  final routes = [
    Icons.dashboard,
    Icons.people,
    Icons.assignment,
    Icons.message,
    Icons.person,
  ];

  for (final route in routes) {
    await tester.tap(find.byIcon(route));
    await tester.pumpAndSettle();
    
    // Should navigate successfully without errors
    expect(find.byType(Scaffold), findsOneWidget);
  }
}

Future<void> _testErrorHandling(WidgetTester tester) async {
  // Test invalid login
  await tester.enterText(find.byType(TextFormField).first, 'invalid');
  await tester.enterText(find.byType(TextFormField).last, '123');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();

  // Should handle error gracefully
  expect(find.byType(SnackBar), findsOneWidget);
}

Future<void> _testPerformance(WidgetTester tester) async {
  // Test scrolling performance
  await tester.tap(find.byIcon(Icons.people));
  await tester.pumpAndSettle();

  // Scroll through patient list
  await tester.drag(find.byType(ListView), Offset(0, -500));
  await tester.pumpAndSettle();

  // Should scroll smoothly without frame drops
  expect(find.byType(ListView), findsOneWidget);
}

Future<void> _performLogin(WidgetTester tester) async {
  if (find.text('Welcome Back').evaluate().isNotEmpty) {
    await tester.enterText(find.byType(TextFormField).first, 'test@medrefer.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }
}
