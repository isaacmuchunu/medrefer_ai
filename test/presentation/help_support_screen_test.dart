import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/presentation/help_support_screen/help_support_screen.dart';

void main() {
  group('HelpSupportScreen Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: const HelpSupportScreen(),
      );
    }

    testWidgets('should display all tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check if all tabs are present
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Tutorials'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Feedback'), findsOneWidget);
    });

    testWidgets('should display FAQ search and list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should be on FAQ tab by default
      expect(find.text('Search FAQs...'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsWidgets);
      
      // Check for some FAQ items
      expect(find.textContaining('How do I create a new referral?'), findsOneWidget);
      expect(find.textContaining('How can I track the status'), findsOneWidget);
    });

    testWidgets('should filter FAQs based on search', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'referral');
      await tester.pump();

      // Should show filtered results
      expect(find.textContaining('referral'), findsWidgets);
      
      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Should show all FAQs again
      expect(find.byType(ExpansionTile), findsWidgets);
    });

    testWidgets('should expand FAQ items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on first FAQ item
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();

      // Should show expanded content
      expect(find.textContaining('To create a new referral'), findsOneWidget);
    });

    testWidgets('should display tutorials tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to tutorials tab
      await tester.tap(find.text('Tutorials'));
      await tester.pumpAndSettle();

      // Should show tutorial items
      expect(find.text('Getting Started with MedRefer AI'), findsOneWidget);
      expect(find.text('Creating Your First Referral'), findsOneWidget);
      expect(find.text('Using Secure Messaging'), findsOneWidget);
      expect(find.text('Video Conferencing Features'), findsOneWidget);
    });

    testWidgets('should handle tutorial item tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to tutorials tab
      await tester.tap(find.text('Tutorials'));
      await tester.pumpAndSettle();

      // Tap on first tutorial
      await tester.tap(find.text('Getting Started with MedRefer AI'));
      await tester.pump();

      // Should show snackbar
      expect(find.textContaining('Playing tutorial'), findsOneWidget);
    });

    testWidgets('should display contact tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to contact tab
      await tester.tap(find.text('Contact'));
      await tester.pumpAndSettle();

      // Should show contact options
      expect(find.text('Get in Touch'), findsOneWidget);
      expect(find.text('Live Chat'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('Phone Support'), findsOneWidget);
      expect(find.text('Submit Ticket'), findsOneWidget);
    });

    testWidgets('should handle contact option taps', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to contact tab
      await tester.tap(find.text('Contact'));
      await tester.pumpAndSettle();

      // Test live chat
      await tester.tap(find.text('Live Chat'));
      await tester.pump();
      expect(find.text('Starting live chat...'), findsOneWidget);

      // Test email support
      await tester.tap(find.text('Email Support'));
      await tester.pump();
      expect(find.text('Opening email client...'), findsOneWidget);

      // Test phone support
      await tester.tap(find.text('Phone Support'));
      await tester.pump();
      expect(find.text('Calling support: +1-800-MEDREFER'), findsOneWidget);
    });

    testWidgets('should display app information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to contact tab
      await tester.tap(find.text('Contact'));
      await tester.pumpAndSettle();

      // Should show app information
      expect(find.text('App Information'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('should display feedback tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to feedback tab
      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();

      // Should show feedback form
      expect(find.text('We Value Your Feedback'), findsOneWidget);
      expect(find.text('Your Feedback'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);
    });

    testWidgets('should handle feedback submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to feedback tab
      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();

      // Enter feedback
      await tester.enterText(
        find.byType(TextField),
        'This is my feedback about the app',
      );

      // Submit feedback
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump();

      // Should show success message
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
    });

    testWidgets('should validate empty feedback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to feedback tab
      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();

      // Try to submit without entering feedback
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump();

      // Should show validation message
      expect(find.text('Please enter your feedback'), findsOneWidget);
    });

    testWidgets('should display quick actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to feedback tab
      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();

      // Should show quick actions
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Rate App'), findsOneWidget);
      expect(find.text('Report Bug'), findsOneWidget);
      expect(find.text('Suggest Feature'), findsOneWidget);
      expect(find.text('Share App'), findsOneWidget);
    });

    testWidgets('should handle quick action taps', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to feedback tab
      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();

      // Test rate app
      await tester.tap(find.text('Rate App'));
      await tester.pump();
      expect(find.text('Opening app store for rating...'), findsOneWidget);

      // Test report bug
      await tester.tap(find.text('Report Bug'));
      await tester.pump();
      expect(find.text('Opening bug report form...'), findsOneWidget);

      // Test suggest feature
      await tester.tap(find.text('Suggest Feature'));
      await tester.pump();
      expect(find.text('Opening feature suggestion form...'), findsOneWidget);

      // Test share app
      await tester.tap(find.text('Share App'));
      await tester.pump();
      expect(find.text('Opening share dialog...'), findsOneWidget);
    });

    testWidgets('should show no results when FAQ search has no matches', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search term with no matches
      await tester.enterText(find.byType(TextField), 'nonexistentterm');
      await tester.pump();

      // Should show no results message
      expect(find.text('No FAQs found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should display FAQ categories', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show category badges
      expect(find.text('Referrals'), findsWidgets);
      expect(find.text('Communication'), findsWidgets);
      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('should handle tab navigation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate through all tabs
      await tester.tap(find.text('Tutorials'));
      await tester.pumpAndSettle();
      expect(find.text('Getting Started with MedRefer AI'), findsOneWidget);

      await tester.tap(find.text('Contact'));
      await tester.pumpAndSettle();
      expect(find.text('Get in Touch'), findsOneWidget);

      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();
      expect(find.text('We Value Your Feedback'), findsOneWidget);

      await tester.tap(find.text('FAQ'));
      await tester.pumpAndSettle();
      expect(find.text('Search FAQs...'), findsOneWidget);
    });
  });
}
