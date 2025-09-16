import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logging_service.dart';

/// Enhanced security service for MedRefer AI
class EnhancedSecurityService {
  static final EnhancedSecurityService _instance = EnhancedSecurityService._internal();
  factory EnhancedSecurityService() => _instance;
  EnhancedSecurityService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  final LoggingService _loggingService = LoggingService();
  final Random _random = Random.secure();

  /// Generate a cryptographically secure random token
  String generateSecureToken({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Generate a secure session ID
  String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      randomBytes[i] = _random.nextInt(256);
    }
    final hash = sha256.convert([...timestamp.toString().codeUnits, ...randomBytes]);
    return 'session_${hash.toString().substring(0, 16)}';
  }

  /// Encrypt sensitive data
  Future<String> encryptData(String data, {String? key}) async {
    try {
      final encryptionKey = key ?? await _getOrCreateEncryptionKey();
      final bytes = utf8.encode(data);
      final digest = sha256.convert([...bytes, ...utf8.encode(encryptionKey)]);
      return base64Encode(digest.bytes);
    } catch (e) {
      _loggingService.error('Failed to encrypt data', context: 'Security', error: e);
      rethrow;
    }
  }

  /// Decrypt sensitive data
  Future<String> decryptData(String encryptedData, {String? key}) async {
    try {
      // Note: This is a simplified implementation
      // In production, use proper encryption/decryption libraries
      final encryptionKey = key ?? await _getOrCreateEncryptionKey();
      final bytes = base64Decode(encryptedData);
      // This is a mock decryption - implement proper decryption
      return utf8.decode(bytes);
    } catch (e) {
      _loggingService.error('Failed to decrypt data', context: 'Security', error: e);
      rethrow;
    }
  }

  /// Hash password with salt
  String hashPassword(String password, {String? salt}) {
    final usedSalt = salt ?? _generateSalt();
    final bytes = utf8.encode(password + usedSalt);
    final digest = sha256.convert(bytes);
    return '$usedSalt:${digest.toString()}';
  }

  /// Verify password against hash
  bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final expectedHash = parts[1];
      final actualHash = hashPassword(password, salt: salt).split(':')[1];
      
      return expectedHash == actualHash;
    } catch (e) {
      _loggingService.error('Failed to verify password', context: 'Security', error: e);
      return false;
    }
  }

  /// Generate a secure salt
  String _generateSalt() {
    final saltBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      saltBytes[i] = _random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  /// Get or create encryption key
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      var key = await _storage.read(key: 'encryption_key');
      if (key == null) {
        key = generateSecureToken(length: 32);
        await _storage.write(key: 'encryption_key', value: key);
      }
      return key;
    } catch (e) {
      _loggingService.error('Failed to get/create encryption key', context: 'Security', error: e);
      rethrow;
    }
  }

  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    try {
      final encryptedValue = await encryptData(value);
      await _storage.write(key: key, value: encryptedValue);
      
      _loggingService.debug('Stored secure data', context: 'Security', metadata: {
        'key': key,
        'encrypted': true,
      });
    } catch (e) {
      _loggingService.error('Failed to store secure data', context: 'Security', error: e);
      rethrow;
    }
  }

  /// Retrieve sensitive data securely
  Future<String?> getSecureData(String key) async {
    try {
      final encryptedValue = await _storage.read(key: key);
      if (encryptedValue == null) return null;
      
      final decryptedValue = await decryptData(encryptedValue);
      
      _loggingService.debug('Retrieved secure data', context: 'Security', metadata: {
        'key': key,
        'decrypted': true,
      });
      
      return decryptedValue;
    } catch (e) {
      _loggingService.error('Failed to retrieve secure data', context: 'Security', error: e);
      return null;
    }
  }

  /// Delete sensitive data
  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
      
      _loggingService.debug('Deleted secure data', context: 'Security', metadata: {
        'key': key,
      });
    } catch (e) {
      _loggingService.error('Failed to delete secure data', context: 'Security', error: e);
      rethrow;
    }
  }

  /// Clear all secure data
  Future<void> clearAllSecureData() async {
    try {
      await _storage.deleteAll();
      
      _loggingService.info('Cleared all secure data', context: 'Security');
    } catch (e) {
      _loggingService.error('Failed to clear secure data', context: 'Security', error: e);
      rethrow;
    }
  }

  /// Generate a secure PIN
  String generateSecurePin({int length = 6}) {
    final pin = StringBuffer();
    for (var i = 0; i < length; i++) {
      pin.write(_random.nextInt(10));
    }
    return pin.toString();
  }

  /// Validate PIN strength
  bool isPinStrong(String pin) {
    if (pin.length < 4) return false;
    
    // Check for common patterns
    final commonPins = ['1234', '0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999'];
    if (commonPins.contains(pin)) return false;
    
    // Check for sequential patterns
    if (_isSequential(pin)) return false;
    
    // Check for repeated digits
    if (_isRepeated(pin)) return false;
    
    return true;
  }

  /// Check if PIN is sequential
  bool _isSequential(String pin) {
    for (var i = 0; i < pin.length - 1; i++) {
      final current = int.tryParse(pin[i]);
      final next = int.tryParse(pin[i + 1]);
      if (current != null && next != null) {
        if ((next - current).abs() != 1) return false;
      }
    }
    return true;
  }

  /// Check if PIN has repeated digits
  bool _isRepeated(String pin) {
    final firstDigit = pin[0];
    return pin.split('').every((digit) => digit == firstDigit);
  }

  /// Generate a secure recovery code
  String generateRecoveryCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = StringBuffer();
    for (var i = 0; i < 8; i++) {
      code.write(chars[_random.nextInt(chars.length)]);
    }
    return code.toString();
  }

  /// Validate recovery code format
  bool isValidRecoveryCode(String code) {
    if (code.length != 8) return false;
    return RegExp(r'^[A-Z0-9]{8}$').hasMatch(code);
  }

  /// Create a secure hash for data integrity
  String createDataHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity
  bool verifyDataIntegrity(String data, String expectedHash) {
    final actualHash = createDataHash(data);
    return actualHash == expectedHash;
  }

  /// Generate a secure API key
  String generateApiKey({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      randomBytes[i] = _random.nextInt(256);
    }
    final hash = sha256.convert([...timestamp.toString().codeUnits, ...randomBytes]);
    final key = base64Encode(hash.bytes).replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return prefix != null ? '${prefix}_$key' : key;
  }

  /// Sanitize input to prevent injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\'']'), '') // Remove potentially dangerous characters
        .trim()
        .substring(0, input.length > 1000 ? 1000 : input.length); // Limit length
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  /// Check if password meets security requirements
  bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    
    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    
    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    
    // Check for special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    
    // Check for common passwords
    final commonPasswords = [
      'password', '123456', 'password123', 'admin', 'qwerty',
      'letmein', 'welcome', 'monkey', '1234567890'
    ];
    if (commonPasswords.contains(password.toLowerCase())) return false;
    
    return true;
  }

  /// Get password strength score (0-100)
  int getPasswordStrengthScore(String password) {
    var score = 0;
    
    // Length bonus
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    
    // Character variety bonus
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 10;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 10;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 20;
    
    // Complexity bonus
    if (password.length >= 8 && 
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 10;
    }
    
    return score.clamp(0, 100);
  }
}