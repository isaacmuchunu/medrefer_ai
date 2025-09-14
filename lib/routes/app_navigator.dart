import 'package:flutter/material.dart';
import 'app_routes.dart';

/// A utility class to centralize navigation and argument packaging.
/// This helps ensure that all arguments for a given route are correctly typed
/// and packaged, reducing the risk of runtime errors from incorrect casts
/// or missing arguments.
class AppNavigator {
  final BuildContext context;

  AppNavigator.of(this.context);

  Future<T?>? toSpecialistProfile(String specialistId) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.specialistProfileScreen,
      arguments: {'specialistId': specialistId},
    );
  }

  Future<T?>? toDocumentViewer(String documentId, {String? patientId}) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.documentViewerScreen,
      arguments: {'documentId': documentId, 'patientId': patientId},
    );
  }

  Future<T?>? toAppointmentScheduling({String? specialistId, String? patientId}) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.appointmentSchedulingScreen,
      arguments: {'specialistId': specialistId, 'patientId': patientI d},
    );
  }

  Future<T?>? toChat({String? patientId, String? specialistId, String? conversationId}) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.chatScreen,
      arguments: {
        'patientId': patientId,
        'specialistId': specialistId,
        'conversationId': conversationId,
      },
    );
  }

  Future<T?>? toTeleconference({
    required String callId,
    required List<String> participantIds,
    bool isVideoCall = true,
  }) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.teleconferenceCallScreen,
      arguments: {
        'callId': callId,
        'participantIds': participantIds,
        'isVideoCall': isVideoCall,
      },
    );
  }

  Future<T?>? toErrorScreen({
    String? errorMessage,
    dynamic errorType,
    bool isOffline = false,
    VoidCallback? onRetry,
  }) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.errorOfflineScreen,
      arguments: {
        'errorMessage': errorMessage,
        'errorType': errorType,
        'isOffline': isOffline,
        'onRetry': onRetry,
      },
    );
  }

  Future<T?>? toPatientSearch({
    bool isSelectionMode = false,
    Function(String)? onPatientSelected,
  }) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.patientSearchScreen,
      arguments: {
        'isSelectionMode': isSelectionMode,
        'onPatientSelected': onPatientSelected,
      },
    );
  }

  Future<T?>? toDoctorDetail(Map<String, dynamic> doctor) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.doctorDetailScreen,
      arguments: {'doctor': doctor},
    );
  }

  Future<T?>? toDrugDetail(dynamic drug) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.drugDetailScreen,
      arguments: {'drug': drug},
    );
  }

  Future<T?>? toCheckout(double total) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.checkoutScreen,
      arguments: {'total': total},
    );
  }

  Future<T?>? toMpesaPayment({
    required double amount,
    required String description,
    String? orderId,
  }) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.mpesaPaymentScreen,
      arguments: {
        'amount': amount,
        'description': description,
        'orderId': orderId,
      },
    );
  }

  Future<T?>? toFeedbackRating(String specialistId) {
    return Navigator.pushNamed<T>(
      context,
      AppRoutes.feedbackRating,
      arguments: {'specialistId': specialistId},
    );
  }
}
