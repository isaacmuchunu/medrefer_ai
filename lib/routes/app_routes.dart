import 'package:flutter/material.dart';
import '../presentation/specialist_directory/specialist_directory.dart';
import '../presentation/patient_profile/patient_profile.dart';
import '../presentation/referral_tracking/referral_tracking.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/create_referral/create_referral.dart';
import '../presentation/secure_messaging/secure_messaging.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/biometrics_screen/biometrics_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/specialist_profile_screen/specialist_profile_screen.dart';
import '../presentation/document_viewer_screen/document_viewer_screen.dart';
import '../presentation/appointment_scheduling_screen/appointment_scheduling_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../presentation/logout_confirmation_screen/logout_confirmation_screen.dart';
import '../presentation/add_patient_screen/add_patient_screen.dart';
import '../presentation/chat_screen/chat_screen.dart';
import '../presentation/teleconference_call_screen/teleconference_call_screen.dart';
import '../presentation/error_offline_screen/error_offline_screen.dart';
import '../presentation/help_support_screen/help_support_screen.dart';
import '../presentation/patient_search_screen/patient_search_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/doctor_detail_screen/doctor_detail_screen.dart';
import '../presentation/pharmacy_screen/pharmacy_screen.dart';
import '../presentation/drug_detail_screen/drug_detail_screen.dart';
import '../presentation/cart_screen/cart_screen.dart';
import '../presentation/mpesa_payment_screen/mpesa_payment_screen.dart';
import '../presentation/appointment_history/appointment_history.dart';
import '../presentation/billing_payment/billing_payment.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/health_analytics/health_analytics.dart';
import '../presentation/insurance_verification/insurance_verification.dart';
import '../presentation/lab_results/lab_results.dart';
import '../presentation/prescription_management/prescription_management.dart';
import '../presentation/profile_edit/profile_edit.dart';
import '../presentation/feedback_rating/feedback_rating.dart';
import '../presentation/signup_screen/signup_screen.dart';
import '../presentation/signup_success_screen/signup_success_screen.dart';
import '../presentation/reset_password_screen/reset_password_screen.dart';
import '../presentation/verify_code_screen/verify_code_screen.dart';
import '../presentation/create_new_password_screen/create_new_password_screen.dart';
import '../presentation/top_doctors_screen/top_doctors_screen.dart';
import '../presentation/booking_screen/booking_screen.dart';
import '../presentation/booking_success_screen/booking_success_screen.dart';
import '../presentation/audio_call_screen/audio_call_screen.dart';
import '../presentation/schedule_screen/schedule_screen.dart';
import '../presentation/articles_screen/articles_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String specialistDirectory = '/specialist-directory';
  static const String patientProfile = '/patient-profile';
  static const String referralTracking = '/referral-tracking';
  static const String dashboard = '/dashboard';
  static const String dashboardScreen = '/dashboard';
  static const String createReferral = '/create-referral';
  static const String secureMessaging = '/secure-messaging';
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String biometricsScreen = '/biometrics';
  static const String settingsScreen = '/settings';
  static const String notificationsScreen = '/notifications';
  static const String specialistProfileScreen = '/specialist-profile';
  static const String documentViewerScreen = '/document-viewer';
  static const String appointmentSchedulingScreen = '/appointment-scheduling';
  static const String registrationScreen = '/registration';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String logoutConfirmationScreen = '/logout-confirmation';
  static const String addPatientScreen = '/add-patient';
  static const String chatScreen = '/chat';
  static const String teleconferenceCallScreen = '/teleconference-call';
  static const String errorOfflineScreen = '/error-offline';
  static const String helpSupportScreen = '/help-support';
  static const String patientSearchScreen = '/patient-search';
  static const String onboardingScreen = '/onboarding';
  static const String doctorDetailScreen = '/doctor-detail';
  static const String pharmacyScreen = '/pharmacy';
  static const String drugDetailScreen = '/drug-detail';
  static const String cartScreen = '/cart';
  static const String checkoutScreen = '/checkout';
  static const String mpesaPaymentScreen = '/mpesa-payment';
  static const String appointmentHistory = '/appointment-history';
  static const String billingPayment = '/billing-payment';
  static const String adminDashboard = '/admin-dashboard';
  static const String healthAnalytics = '/health-analytics';
  static const String insuranceVerification = '/insurance-verification';
  static const String labResults = '/lab-results';
  static const String prescriptionManagement = '/prescription-management';
  static const String profileEdit = '/profile-edit';
  static const String feedbackRating = '/feedback-rating';
  static const String signUpScreen = '/sign-up';
  static const String signUpSuccessScreen = '/sign-up-success';
  static const String resetPasswordScreen = '/reset-password';
  static const String verifyCodeScreen = '/verify-code';
  static const String createNewPasswordScreen = '/create-new-password';
  static const String topDoctorsScreen = '/top-doctors';
  static const String bookingScreen = '/booking';
  static const String bookingSuccessScreen = '/booking-success';
  static const String audioCallScreen = '/audio-call';
  static const String scheduleScreen = '/schedule';
  static const String articlesScreen = '/articles';
  static const String profileScreen = '/profile';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SpecialistDirectory(),
    specialistDirectory: (context) => const SpecialistDirectory(),
    patientProfile: (context) => const PatientProfile(),
    referralTracking: (context) => const ReferralTracking(),
    dashboard: (context) => const Dashboard(),
    createReferral: (context) => const CreateReferral(),
    secureMessaging: (context) => const SecureMessaging(),
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    biometricsScreen: (context) => const BiometricsScreen(),
    settingsScreen: (context) => const SettingsScreen(),
    notificationsScreen: (context) => const NotificationsScreen(),
    specialistProfileScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SpecialistProfileScreen(
        specialistId: args?['specialistId'] ?? '',
      );
    },
    documentViewerScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return DocumentViewerScreen(
        documentId: args?['documentId'] ?? '',
        patientId: args?['patientId'],
      );
    },
    appointmentSchedulingScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AppointmentSchedulingScreen(
        specialistId: args?['specialistId'],
        patientId: args?['patientId'],
      );
    },
    registrationScreen: (context) => const RegistrationScreen(),
    forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
    logoutConfirmationScreen: (context) => const LogoutConfirmationScreen(),
    addPatientScreen: (context) => const AddPatientScreen(),
    chatScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ChatScreen(
        patientId: args?['patientId'],
        specialistId: args?['specialistId'],
        conversationId: args?['conversationId'],
      );
    },
    teleconferenceCallScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return TeleconferenceCallScreen(
        callId: args?['callId'] ?? '',
        participantIds: args?['participantIds'] ?? [],
        isVideoCall: args?['isVideoCall'] ?? true,
      );
    },
    errorOfflineScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ErrorOfflineScreen(
        errorMessage: args?['errorMessage'],
        errorType: args?['errorType'],
        isOffline: args?['isOffline'] ?? false,
        onRetry: args?['onRetry'],
      );
    },
    helpSupportScreen: (context) => const HelpSupportScreen(),
    patientSearchScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PatientSearchScreen(
        isSelectionMode: args?['isSelectionMode'] ?? false,
        onPatientSelected: args?['onPatientSelected'],
      );
    },
    onboardingScreen: (context) => const OnboardingScreen(),
    doctorDetailScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return DoctorDetailScreen(
        doctor: args?['doctor'] ?? {},
      );
    },
    pharmacyScreen: (context) => const PharmacyScreen(),
    drugDetailScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return DrugDetailScreen(
        drug: args?['drug'],
      );
    },
    cartScreen: (context) => const CartScreen(),
    checkoutScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PaymentScreen(
        amount: args?['total']?.toDouble(),
        description: 'Pharmacy Order',
      );
    },
    mpesaPaymentScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MpesaPaymentScreen(
        amount: args?['amount']?.toDouble() ?? 0.0,
        description: args?['description'] ?? 'Payment',
        orderId: args?['orderId'],
      );
    },
    appointmentHistory: (context) => const AppointmentHistory(),
    billingPayment: (context) => const BillingPayment(),
    adminDashboard: (context) => const AdminDashboard(),
    healthAnalytics: (context) => const HealthAnalytics(),
    insuranceVerification: (context) => const InsuranceVerification(),
    labResults: (context) => const LabResults(),
    prescriptionManagement: (context) => const PrescriptionManagement(),
    profileEdit: (context) => const ProfileEdit(),
    feedbackRating: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final specialistId = args?['specialistId'] as String?;
      assert(specialistId != null && specialistId.isNotEmpty, 'specialistId must be a non-empty string');
      if (specialistId == null || specialistId.isEmpty) {
        // Optionally, navigate to an error screen or show a dialog
        return const Scaffold(
          body: Center(
            child: Text('Error: Missing Specialist ID'),
          ),
        );
      }
      return FeedbackRating(
        specialistId: specialistId,
      );
    },
    signUpScreen: (context) => const SignUpScreen(),
    signUpSuccessScreen: (context) => const SignUpSuccessScreen(),
    resetPasswordScreen: (context) => const ResetPasswordScreen(),
    verifyCodeScreen: (context) => const VerifyCodeScreen(),
    createNewPasswordScreen: (context) => const CreateNewPasswordScreen(),
    topDoctorsScreen: (context) => const TopDoctorsScreen(),
    bookingScreen: (context) => const BookingScreen(),
    bookingSuccessScreen: (context) => const BookingSuccessScreen(),
    audioCallScreen: (context) => const AudioCallScreen(),
    scheduleScreen: (context) => const ScheduleScreen(),
    articlesScreen: (context) => const ArticlesScreen(),
    profileScreen: (context) => const ProfileScreen(),
  };
}
