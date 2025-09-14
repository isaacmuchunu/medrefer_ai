import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/presentation/error_offline_screen/error_offline_screen.dart';

void main() {
  group('ErrorOfflineScreen Tests', () {
    Widget createTestWidget({
      String? errorMessage,
      String? errorType,
      bool isOffline = false,
      VoidCallback? onRetry,
    }) {
      return MaterialApp(
        home: ErrorOfflineScreen(
          errorMessage: errorMessage,
          errorType: errorType,
          isOffline: isOffline,
          onRetry: onRetry,
        ),
      );
    }

    testWidgets('should display offline state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Should show offline icon and message
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('You\'re Offline'), findsOneWidget);
      expect(find.textContaining('Check your internet connection'), findsOneWidget);
      expect(find.text('Check Connection'), findsOneWidget);
    });

    testWidgets('should display error state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        errorMessage: 'Something went wrong',
        isOffline: false,
      ));
      await tester.pumpAndSettle();

      // Should show error icon and message
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should display queued actions when offline', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Should show queued actions section
      expect(find.text('Queued Actions'), findsOneWidget);
      expect(find.textContaining('actions waiting to sync'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('should handle retry button tap', (WidgetTester tester) async {
      bool retryCallbackCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onRetry: () {
          retryCallbackCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retrying...'), findsOneWidget);

      // Wait for retry to complete
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Callback should have been called
      expect(retryCallbackCalled, isTrue);
    });

    testWidgets('should show queued actions dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Tap view queued actions
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      // Should show bottom sheet with queued actions
      expect(find.text('Queued Actions'), findsWidgets);
      expect(find.text('Create Referral'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should navigate to settings', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap settings button
      await tester.tap(find.text('Settings'));
      await tester.pump();

      // Should attempt to navigate to settings
      // (In a real test, you would verify navigation)
    });

    testWidgets('should navigate to home', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap home button
      await tester.tap(find.text('Home'));
      await tester.pump();

      // Should attempt to navigate to home
      // (In a real test, you would verify navigation)
    });

    testWidgets('should display help section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Should show help section
      expect(find.text('Need Help?'), findsOneWidget);
      expect(find.textContaining('You can still view cached data'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('Help Center'), findsOneWidget);
    });

    testWidgets('should handle contact support tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap contact support
      await tester.tap(find.text('Contact Support'));
      await tester.pump();

      // Should show snackbar
      expect(find.text('Opening support chat...'), findsOneWidget);
    });

    testWidgets('should handle help center tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap help center
      await tester.tap(find.text('Help Center'));
      await tester.pump();

      // Should show snackbar
      expect(find.text('Opening help center...'), findsOneWidget);
    });

    testWidgets('should display custom error message', (WidgetTester tester) async {
      const customError = 'Custom error message';
      
      await tester.pumpWidget(createTestWidget(
        errorMessage: customError,
        isOffline: false,
      ));
      await tester.pumpAndSettle();

      // Should show custom error message
      expect(find.text(customError), findsOneWidget);
    });

    testWidgets('should handle retry without callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Check Connection'));
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retrying...'), findsOneWidget);

      // Wait for retry to complete
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should show connection result (mocked)
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should animate pulse effect', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have animated container with pulse effect
      expect(find.byType(AnimatedBuilder), findsOneWidget);
      
      // Advance animation
      await tester.pump(Duration(seconds: 1));
      
      // Animation should be running
      expect(find.byType(Transform), findsOneWidget);
    });

    testWidgets('should slide in content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should have slide transition
      expect(find.byType(SlideTransition), findsOneWidget);
      
      await tester.pumpAndSettle();
      
      // Content should be visible after animation
      expect(find.text('Something Went Wrong'), findsOneWidget);
    });

    testWidgets('should handle different error types', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        errorType: 'NetworkError',
        errorMessage: 'Network connection failed',
      ));
      await tester.pumpAndSettle();

      // Should display error information
      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('should close queued actions dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Open queued actions dialog
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Create Referral'), findsNothing);
    });
  });
}
