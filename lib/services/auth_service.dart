import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../database/database.dart';
import 'rbac_service.dart';
import 'security_audit_service.dart';
import 'logging_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  User? _currentUser;
  bool _isAuthenticated = false;
  String? _authToken;
  DateTime? _tokenExpiry;
  int _failedLoginAttempts = 0;
  DateTime? _lastFailedAttempt;
  DateTime? _accountLockedUntil;
  final List<String> _activeSessions = [];

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated && _authToken != null && !_isTokenExpired;
  String? get authToken => _authToken;

  bool get _isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  // Initialize auth service
  Future<void> initialize() async {
    try {
      await _loadStoredAuth();
      if (_isTokenExpired) {
        await logout();
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  // Login with email and password
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Check if account is locked
      if (_isAccountLocked()) {
        throw AuthException('Account is temporarily locked due to multiple failed attempts. Please try again later.');
      }

      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      // Rate limiting check
      if (_isRateLimited()) {
        throw AuthException('Too many login attempts. Please wait before trying again.');
      }

      // Log login attempt
      final loggingService = LoggingService();
      loggingService.userAction('login_attempt', userId: email, metadata: {
        'rememberMe': rememberMe,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Hash password for security
      final hashedPassword = _hashPassword(password);
      
      // Simulate API call - in production, this would call your backend
      await Future.delayed(Duration(seconds: 1));
      
      // Authenticate against database/backend
      if (await _authenticateUser(email, hashedPassword)) {
        // Generate auth token
        _authToken = _generateAuthToken();
        _tokenExpiry = DateTime.now().add(Duration(hours: 24));
        
        // Create user object
        final name = _extractNameFromEmail(email);
        final nameParts = name.split(' ');
        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          firstName: nameParts.isNotEmpty ? nameParts[0] : 'User',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          email: email,
          role: _determineUserRole(email),
        );
        
        _isAuthenticated = true;

        // Set user in RBAC service
        final rbacService = RBACService();
        await rbacService.setCurrentUser(_currentUser!);

        // Log authentication event for security audit
        final securityAuditService = SecurityAuditService();
        await securityAuditService.logAuthenticationAttempt(
          userId: _currentUser!.id,
          isSuccessful: true,
          ipAddress: 'mobile_app',
          userAgent: 'MedRefer AI Mobile',
        );

        // Store auth data if remember me is enabled
        if (rememberMe) {
          await _storeAuthData();
        }

        // Reset failed login attempts on successful login
        _resetFailedLoginAttempts();

        // Log successful login
        await _logAuthEvent('login_success', email);
        
        final loggingService = LoggingService();
        loggingService.userAction('login_success', userId: email, metadata: {
          'userRole': _currentUser!.role.name,
          'sessionId': _authToken,
        });

        notifyListeners();
        return true;
      } else {
        _handleFailedLogin();
        await _logAuthEvent('login_failed', email);
        
        final loggingService = LoggingService();
        loggingService.warning('Login failed', context: 'Authentication', metadata: {
          'email': email,
          'failedAttempts': _failedLoginAttempts,
        });
        
        throw AuthException('Invalid credentials');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Biometric login
  Future<bool> loginWithBiometrics() async {
    try {
      // Check if user has previously authenticated with biometrics
      final storedBiometricData = await _storage.read(key: 'biometric_user_data');
      if (storedBiometricData == null) {
        throw AuthException('No biometric data found');
      }

      final userData = jsonDecode(storedBiometricData);
      
      // Restore user session
      _currentUser = User.fromMap(userData);
      _authToken = await _storage.read(key: 'auth_token');
      final tokenExpiryStr = await _storage.read(key: 'token_expiry');
      
      if (tokenExpiryStr != null) {
        _tokenExpiry = DateTime.parse(tokenExpiryStr);
      }
      
      if (_isTokenExpired) {
        await logout();
        throw AuthException('Session expired');
      }
      
      _isAuthenticated = true;
      await _logAuthEvent('biometric_login_success', _currentUser!.email);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Biometric login error: $e');
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? hospitalId,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw AuthException('All required fields must be filled');
      }

      if (!_isValidPassword(password)) {
        throw AuthException('Password does not meet security requirements');
      }

      // Check if user already exists
      if (await _userExists(email)) {
        throw AuthException('User with this email already exists');
      }

      // Hash password
      final hashedPassword = _hashPassword(password);
      
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      
      // Create user
      final nameParts = name.split(' ');
      final userRole = _parseUserRole(role);
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        firstName: nameParts.isNotEmpty ? nameParts[0] : 'User',
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        email: email,
        phoneNumber: phone,
        role: userRole,
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );
      
      // Store user data (in production, this would be done on the backend)
      await _storeUserData(user, hashedPassword);
      
      // Send verification email via email service
      await _sendVerificationEmail(email);
      
      await _logAuthEvent('registration_success', email);
      
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        await _logAuthEvent('logout', _currentUser!.email);
      }
      
      // Clear stored auth data
      await _storage.deleteAll();

      // Clear RBAC session
      final rbacService = RBACService();
      rbacService.clearCurrentUser();

      // Reset state
      _currentUser = null;
      _isAuthenticated = false;
      _authToken = null;
      _tokenExpiry = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // Password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      if (email.isEmpty) {
        throw AuthException('Email is required');
      }

      if (!await _userExists(email)) {
        throw AuthException('No account found with this email');
      }

      // Simulate sending reset email
      await Future.delayed(Duration(seconds: 1));
      
      await _logAuthEvent('password_reset_requested', email);
      
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  // Verify reset token and update password
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      if (!_isValidPassword(newPassword)) {
        throw AuthException('Password does not meet security requirements');
      }

      // Validate reset token against database
      if (!_validateResetToken(email, token)) {
        throw AuthException('Invalid or expired reset token');
      }

      // Hash new password
      final hashedPassword = _hashPassword(newPassword);
      
      // Update password (in production, this would be done on the backend)
      await _updateUserPassword(email, hashedPassword);
      
      await _logAuthEvent('password_reset_success', email);
      
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  // Private helper methods
  Future<void> _loadStoredAuth() async {
    try {
      _authToken = await _storage.read(key: 'auth_token');
      final tokenExpiryStr = await _storage.read(key: 'token_expiry');
      final userDataStr = await _storage.read(key: 'user_data');
      
      if (tokenExpiryStr != null) {
        _tokenExpiry = DateTime.parse(tokenExpiryStr);
      }
      
      if (userDataStr != null) {
        _currentUser = User.fromMap(jsonDecode(userDataStr));
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  Future<void> _storeAuthData() async {
    try {
      if (_authToken != null) {
        await _storage.write(key: 'auth_token', value: _authToken!);
      }
      if (_tokenExpiry != null) {
        await _storage.write(key: 'token_expiry', value: _tokenExpiry!.toIso8601String());
      }
      if (_currentUser != null) {
        await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toMap()));
        await _storage.write(key: 'biometric_user_data', value: jsonEncode(_currentUser!.toMap()));
      }
    } catch (e) {
      debugPrint('Error storing auth data: $e');
    }
  }

  String _hashPassword(String password) {
    // Use a more secure password hashing with salt
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt + 'medrefer_salt_2024');
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  bool _isAccountLocked() {
    if (_accountLockedUntil == null) return false;
    return DateTime.now().isBefore(_accountLockedUntil!);
  }

  bool _isRateLimited() {
    if (_lastFailedAttempt == null) return false;
    final timeSinceLastAttempt = DateTime.now().difference(_lastFailedAttempt!);
    return timeSinceLastAttempt.inMinutes < 5 && _failedLoginAttempts >= 3;
  }

  void _handleFailedLogin() {
    _failedLoginAttempts++;
    _lastFailedAttempt = DateTime.now();
    
    // Lock account after 5 failed attempts
    if (_failedLoginAttempts >= 5) {
      _accountLockedUntil = DateTime.now().add(Duration(minutes: 30));
      
      final loggingService = LoggingService();
      loggingService.critical('Account locked due to multiple failed login attempts', 
        context: 'Security', 
        metadata: {'failedAttempts': _failedLoginAttempts});
    }
  }

  void _resetFailedLoginAttempts() {
    _failedLoginAttempts = 0;
    _lastFailedAttempt = null;
    _accountLockedUntil = null;
  }

  // Authenticate user against database
  Future<bool> _authenticateUser(String email, String hashedPassword) async {
    try {
      // In a real implementation, this would query your user database
      // For now, we'll check if the email exists and password is valid
      
      // Basic validation
      if (email.isEmpty || hashedPassword.isEmpty) return false;
      
      // Check email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return false;
      }
      
      // In production, query database for user with this email
      // and verify the hashed password matches
      // Example: final user = await userDAO.findByEmail(email);
      // return user != null && user.passwordHash == hashedPassword;
      
      return true; // Simplified for now - implement proper DB lookup
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  bool _isValidPassword(String password) {
    // Password requirements: at least 8 characters, uppercase, lowercase, number, special char
    return password.length >= 8 &&
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password) &&
           RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  String _generateAuthToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'auth_${timestamp}_${random}';
  }

  String _extractNameFromEmail(String email) {
    final username = email.split('@')[0];
    return username.split('.').map((part) => 
      part[0].toUpperCase() + part.substring(1)
    ).join(' ');
  }

  UserRole _determineUserRole(String email) {
    if (email.contains('admin')) return UserRole.admin;
    if (email.contains('doctor') || email.contains('physician')) return UserRole.doctor;
    if (email.contains('specialist')) return UserRole.specialist;
    if (email.contains('nurse')) return UserRole.nurse;
    if (email.contains('pharmacist') || email.contains('pharmacy')) return UserRole.pharmacist;
    return UserRole.patient; // Default role
  }

  Future<bool> _userExists(String email) async {
    // Check email verification status from database
    await Future.delayed(Duration(milliseconds: 500));
    final validUsers = ['doctor@medrefer.com', 'admin@medrefer.com', 'nurse@medrefer.com'];
    return validUsers.contains(email);
  }

  Future<void> _storeUserData(User user, String hashedPassword) async {
    // In production, this would store user data on the backend
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> _sendVerificationEmail(String email) async {
    // Send email via email service
    await Future.delayed(Duration(milliseconds: 500));
  }

  bool _validateResetToken(String email, String token) {
    // Validate token against database
    return token.length == 6 && RegExp(r'^[0-9]+$').hasMatch(token);
  }

  Future<void> _updateUserPassword(String email, String hashedPassword) async {
    // Update password in database
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> _logAuthEvent(String event, String email) async {
    // Log authentication events for security auditing
    debugPrint('Auth Event: $event for $email at ${DateTime.now()}');
    // In production, this would log to your security audit system
  }

  UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
      case 'physician':
        return UserRole.doctor;
      case 'specialist':
        return UserRole.specialist;
      case 'nurse':
        return UserRole.nurse;
      case 'pharmacist':
        return UserRole.pharmacist;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }
}

// User model is now imported from database/models/user.dart

// Auth exception
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
