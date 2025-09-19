import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw BiometricException('Biometric authentication not available');
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'MedRefer AI Authentication',
            biometricHint: 'Touch sensor',
            biometricNotRecognized: 'Biometric not recognized. Try again.',
            biometricSuccess: 'Authentication successful',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Please set up biometric authentication in settings',
          ),
          const IOSAuthMessages(
            lockOut: 'Biometric authentication is disabled. Please lock and unlock your screen to enable it.',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Please set up biometric authentication in settings',
            cancelButton: 'Cancel',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        await _logBiometricEvent('authentication_success');
      } else {
        await _logBiometricEvent('authentication_failed');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.message}');
      await _logBiometricEvent('authentication_error', details: e.message);
      
      if (e.code == 'NotAvailable') {
        throw BiometricException('Biometric authentication not available');
      } else if (e.code == 'NotEnrolled') {
        throw BiometricException('No biometrics enrolled on this device');
      } else if (e.code == 'LockedOut') {
        throw BiometricException('Biometric authentication is temporarily locked');
      } else if (e.code == 'PermanentlyLockedOut') {
        throw BiometricException('Biometric authentication is permanently locked');
      }
      
      return false;
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return false;
    }
  }

  // Enable biometric login for current user
  Future<bool> enableBiometricLogin(String userId, Map<String, dynamic> userData) async {
    try {
      // First authenticate with biometrics to ensure it works
      final authenticated = await authenticate(
        reason: 'Enable biometric login for MedRefer AI',
      );

      if (authenticated) {
        // Store user data for biometric login
        await _storage.write(
          key: 'biometric_user_id',
          value: userId,
        );
        await _storage.write(
          key: 'biometric_user_data',
          value: jsonEncode(userData),
        );
        await _storage.write(
          key: 'biometric_enabled',
          value: 'true',
        );
        
        await _logBiometricEvent('biometric_login_enabled');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error enabling biometric login: $e');
      return false;
    }
  }

  // Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      await _storage.delete(key: 'biometric_user_id');
      await _storage.delete(key: 'biometric_user_data');
      await _storage.write(key: 'biometric_enabled', value: 'false');
      
      await _logBiometricEvent('biometric_login_disabled');
    } catch (e) {
      debugPrint('Error disabling biometric login: $e');
    }
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _storage.read(key: 'biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error checking biometric login status: $e');
      return false;
    }
  }

  // Get biometric capabilities description
  Future<String> getBiometricCapabilitiesDescription() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return 'No biometric authentication available';
      }
      
      final capabilities = <String>[];
      
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        capabilities.add('Fingerprint');
      }
      if (availableBiometrics.contains(BiometricType.face)) {
        capabilities.add('Face ID');
      }
      if (availableBiometrics.contains(BiometricType.iris)) {
        capabilities.add('Iris');
      }
      if (availableBiometrics.contains(BiometricType.strong)) {
        capabilities.add('Strong Biometric');
      }
      if (availableBiometrics.contains(BiometricType.weak)) {
        capabilities.add('Weak Biometric');
      }
      
      return capabilities.join(', ');
    } catch (e) {
      debugPrint('Error getting biometric capabilities: $e');
      return 'Unknown';
    }
  }

  Future<void> _logBiometricEvent(String event, {String? details}) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('Biometric Event: $event at $timestamp${details != null ? ' - $details' : ''}');
    // In production, this would log to your security audit system
  }
}

// Biometric exception
class BiometricException implements Exception {
  BiometricException(this.message);
  
  final String message;

  @override
  String toString() => 'BiometricException: $message';
}
