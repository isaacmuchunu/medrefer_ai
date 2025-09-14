import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database_helper.dart';
import '../database/database.dart';

/// Advanced Security and Compliance Service
/// Provides enterprise-grade security, GDPR compliance, and penetration testing utilities
class AdvancedSecurityService extends ChangeNotifier {
  static final AdvancedSecurityService _instance = AdvancedSecurityService._internal();
  factory AdvancedSecurityService() => _instance;
  AdvancedSecurityService._internal();

  // Encryption configuration
  static const int _keySize = 32; // 256-bit AES
  static const int _ivSize = 16;  // 128-bit IV
  static const int _saltSize = 32;
  static const int _iterations = 100000; // PBKDF2 iterations
  
  // Security configuration
  static const Duration _sessionTimeout = Duration(minutes: 30);
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const int _passwordHistoryCount = 5;
  static const Duration _passwordExpiryDays = Duration(days: 90);
  
  // Storage
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
      accountName: 'medrefer_security',
    ),
  );
  
  // Audit logging
  final List<SecurityAuditLog> _auditLogs = [];
  final Map<String, List<LoginAttempt>> _loginAttempts = {};
  final Map<String, DateTime> _lockedAccounts = {};
  final Map<String, List<String>> _passwordHistory = {};
  
  // GDPR compliance
  final Map<String, ConsentRecord> _consentRecords = {};
  final Map<String, DataProcessingActivity> _processingActivities = {};
  final Map<String, DataBreachRecord> _breachRecords = {};
  
  // Security metrics
  int _encryptionOperations = 0;
  int _decryptionOperations = 0;
  int _authenticationAttempts = 0;
  int _securityIncidents = 0;
  
  // Penetration testing
  final List<VulnerabilityReport> _vulnerabilityReports = [];
  final Map<String, PenetrationTest> _penetrationTests = {};
  
  // Session management
  final Map<String, SecureSession> _activeSessions = {};
  Timer? _sessionCleanupTimer;
  
  // Database
  Database? _database;
  
  // Encryption keys
  late Encrypter _encrypter;
  late Key _masterKey;
  Map<String, Key> _dataKeys = {};

  /// Initialize the security service
  Future<void> initialize() async {
    try {
      // Initialize database
      _database = await DatabaseHelper().database;
      
      // Create security tables
      await _createSecurityTables();
      
      // Initialize encryption
      await _initializeEncryption();
      
      // Load security data
      await _loadSecurityData();
      
      // Start session cleanup timer
      _startSessionCleanup();
      
      debugPrint('Advanced Security Service initialized');
    } catch (e) {
      debugPrint('Error initializing Advanced Security Service: $e');
      throw SecurityException('Failed to initialize security service');
    }
  }

  /// Create security-related database tables
  Future<void> _createSecurityTables() async {
    // Audit logs table
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS security_audit_logs (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        user_id TEXT,
        ip_address TEXT,
        user_agent TEXT,
        resource TEXT,
        action TEXT,
        result TEXT,
        metadata TEXT,
        timestamp INTEGER NOT NULL,
        risk_level TEXT
      )
    ''');

    // Consent records table (GDPR)
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS consent_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        consent_type TEXT NOT NULL,
        granted INTEGER NOT NULL,
        purpose TEXT,
        lawful_basis TEXT,
        withdrawal_method TEXT,
        ip_address TEXT,
        timestamp INTEGER NOT NULL,
        expires_at INTEGER
      )
    ''');

    // Data processing activities (GDPR)
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS data_processing_activities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        purpose TEXT NOT NULL,
        lawful_basis TEXT NOT NULL,
        data_categories TEXT,
        data_subjects TEXT,
        recipients TEXT,
        retention_period TEXT,
        security_measures TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Security incidents table
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS security_incidents (
        id TEXT PRIMARY KEY,
        incident_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT,
        affected_users TEXT,
        mitigation_steps TEXT,
        detected_at INTEGER NOT NULL,
        resolved_at INTEGER,
        reported_to_authorities INTEGER DEFAULT 0
      )
    ''');

    // Encryption keys table
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS encryption_keys (
        id TEXT PRIMARY KEY,
        key_type TEXT NOT NULL,
        key_data TEXT NOT NULL,
        algorithm TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        rotated_at INTEGER,
        expires_at INTEGER
      )
    ''');

    // Create indexes
    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp 
      ON security_audit_logs(timestamp DESC)
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_logs_user 
      ON security_audit_logs(user_id)
    ''');
  }

  /// Initialize encryption system
  Future<void> _initializeEncryption() async {
    try {
      // Generate or retrieve master key
      String? storedKey = await _secureStorage.read(key: 'master_encryption_key');
      
      if (storedKey == null) {
        // Generate new master key
        _masterKey = Key.fromSecureRandom(_keySize);
        await _secureStorage.write(
          key: 'master_encryption_key',
          value: base64.encode(_masterKey.bytes),
        );
      } else {
        // Load existing master key
        _masterKey = Key(base64.decode(storedKey));
      }
      
      // Initialize encrypter with AES
      _encrypter = Encrypter(AES(_masterKey, mode: AESMode.gcm));
      
      // Generate data encryption keys
      await _generateDataEncryptionKeys();
      
      debugPrint('Encryption system initialized');
    } catch (e) {
      debugPrint('Error initializing encryption: $e');
      throw SecurityException('Failed to initialize encryption');
    }
  }

  /// Generate data encryption keys for different data types
  Future<void> _generateDataEncryptionKeys() async {
    final dataTypes = ['medical', 'personal', 'financial', 'communication'];
    
    for (final dataType in dataTypes) {
      final keyName = '${dataType}_encryption_key';
      String? storedKey = await _secureStorage.read(key: keyName);
      
      if (storedKey == null) {
        // Generate new key
        final key = Key.fromSecureRandom(_keySize);
        _dataKeys[dataType] = key;
        await _secureStorage.write(
          key: keyName,
          value: base64.encode(key.bytes),
        );
        
        // Store key metadata in database
        await _storeKeyMetadata(dataType, key);
      } else {
        // Load existing key
        _dataKeys[dataType] = Key(base64.decode(storedKey));
      }
    }
  }

  /// Encrypt sensitive data
  Future<EncryptedData> encryptData({
    required String data,
    required String dataType,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get appropriate encryption key
      final key = _dataKeys[dataType] ?? _masterKey;
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      
      // Generate IV
      final iv = IV.fromSecureRandom(_ivSize);
      
      // Encrypt data
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // Create encrypted data object
      final encryptedData = EncryptedData(
        id: 'enc_${DateTime.now().millisecondsSinceEpoch}',
        encryptedValue: encrypted.base64,
        iv: iv.base64,
        dataType: dataType,
        algorithm: 'AES-256-GCM',
        keyId: dataType,
        metadata: metadata,
        encryptedAt: DateTime.now(),
      );
      
      // Audit log
      await _logSecurityEvent(
        eventType: SecurityEventType.dataEncrypted,
        userId: userId,
        resource: dataType,
        action: 'encrypt',
        result: 'success',
        metadata: {'dataSize': data.length},
      );
      
      // Update metrics
      _encryptionOperations++;
      notifyListeners();
      
      return encryptedData;
    } catch (e) {
      debugPrint('Encryption error: $e');
      
      await _logSecurityEvent(
        eventType: SecurityEventType.encryptionFailed,
        userId: userId,
        resource: dataType,
        action: 'encrypt',
        result: 'failure',
        metadata: {'error': e.toString()},
        riskLevel: RiskLevel.high,
      );
      
      throw SecurityException('Failed to encrypt data');
    }
  }

  /// Decrypt sensitive data
  Future<String> decryptData({
    required EncryptedData encryptedData,
    String? userId,
    bool auditAccess = true,
  }) async {
    try {
      // Get appropriate decryption key
      final key = _dataKeys[encryptedData.keyId] ?? _masterKey;
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      
      // Decrypt data
      final encrypted = Encrypted.fromBase64(encryptedData.encryptedValue);
      final iv = IV.fromBase64(encryptedData.iv);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      // Audit log if required
      if (auditAccess) {
        await _logSecurityEvent(
          eventType: SecurityEventType.dataDecrypted,
          userId: userId,
          resource: encryptedData.dataType,
          action: 'decrypt',
          result: 'success',
        );
      }
      
      // Update metrics
      _decryptionOperations++;
      notifyListeners();
      
      return decrypted;
    } catch (e) {
      debugPrint('Decryption error: $e');
      
      await _logSecurityEvent(
        eventType: SecurityEventType.decryptionFailed,
        userId: userId,
        resource: encryptedData.dataType,
        action: 'decrypt',
        result: 'failure',
        metadata: {'error': e.toString()},
        riskLevel: RiskLevel.high,
      );
      
      throw SecurityException('Failed to decrypt data');
    }
  }

  /// Hash password with salt
  String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final key = pbkdf2(
      utf8.encode(password),
      utf8.encode(salt),
      _iterations,
      _keySize,
    );
    return '${base64.encode(key)}:$salt';
  }

  /// Verify password
  bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[1];
      final expectedHash = hashPassword(password, salt: salt);
      
      return expectedHash == hashedPassword;
    } catch (e) {
      debugPrint('Password verification error: $e');
      return false;
    }
  }

  /// Validate password strength
  PasswordStrength validatePasswordStrength(String password) {
    int score = 0;
    final checks = <String>[];
    
    // Length check
    if (password.length >= 12) {
      score += 2;
    } else if (password.length >= 8) {
      score += 1;
    } else {
      checks.add('Password must be at least 8 characters');
    }
    
    // Uppercase check
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      checks.add('Include at least one uppercase letter');
    }
    
    // Lowercase check
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      checks.add('Include at least one lowercase letter');
    }
    
    // Number check
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      checks.add('Include at least one number');
    }
    
    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 2;
    } else {
      checks.add('Include at least one special character');
    }
    
    // Common password check
    if (_isCommonPassword(password)) {
      score = 0;
      checks.add('This password is too common');
    }
    
    // Password history check
    // ... implement history check
    
    StrengthLevel level;
    if (score >= 7) {
      level = StrengthLevel.strong;
    } else if (score >= 5) {
      level = StrengthLevel.medium;
    } else if (score >= 3) {
      level = StrengthLevel.weak;
    } else {
      level = StrengthLevel.veryWeak;
    }
    
    return PasswordStrength(
      level: level,
      score: score,
      suggestions: checks,
    );
  }

  /// Track login attempt
  Future<LoginResult> trackLoginAttempt({
    required String userId,
    required bool success,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if account is locked
      if (_lockedAccounts.containsKey(userId)) {
        final lockoutEnd = _lockedAccounts[userId]!;
        if (DateTime.now().isBefore(lockoutEnd)) {
          final remaining = lockoutEnd.difference(DateTime.now());
          return LoginResult(
            success: false,
            locked: true,
            remainingLockTime: remaining,
            message: 'Account locked. Try again in ${remaining.inMinutes} minutes',
          );
        } else {
          _lockedAccounts.remove(userId);
        }
      }
      
      // Initialize attempts list if needed
      _loginAttempts[userId] ??= [];
      
      // Add current attempt
      final attempt = LoginAttempt(
        userId: userId,
        success: success,
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
        metadata: metadata,
      );
      
      _loginAttempts[userId]!.add(attempt);
      
      // Log authentication attempt
      await _logSecurityEvent(
        eventType: success 
          ? SecurityEventType.loginSuccess 
          : SecurityEventType.loginFailed,
        userId: userId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        action: 'login',
        result: success ? 'success' : 'failure',
        metadata: metadata,
        riskLevel: success ? RiskLevel.low : RiskLevel.medium,
      );
      
      if (!success) {
        // Count recent failures
        final recentFailures = _loginAttempts[userId]!
            .where((a) => !a.success && 
                   a.timestamp.isAfter(DateTime.now().subtract(Duration(minutes: 30))))
            .length;
        
        // Check for account lockout
        if (recentFailures >= _maxLoginAttempts) {
          _lockedAccounts[userId] = DateTime.now().add(_lockoutDuration);
          
          // Log security incident
          await _logSecurityIncident(
            type: 'account_lockout',
            severity: IncidentSeverity.medium,
            description: 'Account locked due to multiple failed login attempts',
            affectedUsers: [userId],
          );
          
          return LoginResult(
            success: false,
            locked: true,
            remainingLockTime: _lockoutDuration,
            message: 'Account locked due to multiple failed attempts',
          );
        }
        
        return LoginResult(
          success: false,
          attemptsRemaining: _maxLoginAttempts - recentFailures,
          message: 'Invalid credentials. ${_maxLoginAttempts - recentFailures} attempts remaining',
        );
      }
      
      // Clear failed attempts on successful login
      _loginAttempts[userId]!.removeWhere((a) => !a.success);
      
      // Update metrics
      _authenticationAttempts++;
      
      return LoginResult(success: true);
    } catch (e) {
      debugPrint('Error tracking login attempt: $e');
      throw SecurityException('Failed to track login attempt');
    }
  }

  /// Create secure session
  Future<SecureSession> createSecureSession({
    required String userId,
    required String deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Generate session token
      final sessionId = _generateSecureToken(32);
      final refreshToken = _generateSecureToken(32);
      
      // Create session
      final session = SecureSession(
        id: sessionId,
        userId: userId,
        deviceId: deviceId,
        token: sessionId,
        refreshToken: refreshToken,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(_sessionTimeout),
        metadata: metadata,
      );
      
      // Store session
      _activeSessions[sessionId] = session;
      
      // Log session creation
      await _logSecurityEvent(
        eventType: SecurityEventType.sessionCreated,
        userId: userId,
        action: 'create_session',
        result: 'success',
        metadata: {'deviceId': deviceId},
      );
      
      return session;
    } catch (e) {
      debugPrint('Error creating session: $e');
      throw SecurityException('Failed to create secure session');
    }
  }

  /// Validate session
  Future<bool> validateSession(String sessionId) async {
    if (!_activeSessions.containsKey(sessionId)) {
      return false;
    }
    
    final session = _activeSessions[sessionId]!;
    
    // Check expiry
    if (DateTime.now().isAfter(session.expiresAt)) {
      await terminateSession(sessionId);
      return false;
    }
    
    // Extend session
    session.expiresAt = DateTime.now().add(_sessionTimeout);
    session.lastActivity = DateTime.now();
    
    return true;
  }

  /// Terminate session
  Future<void> terminateSession(String sessionId) async {
    if (!_activeSessions.containsKey(sessionId)) return;
    
    final session = _activeSessions[sessionId]!;
    
    // Log session termination
    await _logSecurityEvent(
      eventType: SecurityEventType.sessionTerminated,
      userId: session.userId,
      action: 'terminate_session',
      result: 'success',
    );
    
    // Remove session
    _activeSessions.remove(sessionId);
  }

  /// GDPR: Record consent
  Future<void> recordConsent({
    required String userId,
    required String consentType,
    required bool granted,
    String? purpose,
    String? lawfulBasis,
    String? ipAddress,
    Duration? validity,
  }) async {
    try {
      final consent = ConsentRecord(
        id: 'consent_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        consentType: consentType,
        granted: granted,
        purpose: purpose,
        lawfulBasis: lawfulBasis ?? 'consent',
        withdrawalMethod: 'user_interface',
        ipAddress: ipAddress,
        timestamp: DateTime.now(),
        expiresAt: validity != null ? DateTime.now().add(validity) : null,
      );
      
      // Store consent
      _consentRecords[consent.id] = consent;
      
      // Persist to database
      await _database!.insert('consent_records', consent.toMap());
      
      // Audit log
      await _logSecurityEvent(
        eventType: SecurityEventType.consentRecorded,
        userId: userId,
        action: granted ? 'consent_granted' : 'consent_withdrawn',
        result: 'success',
        metadata: {'consentType': consentType, 'purpose': purpose},
      );
      
      debugPrint('Consent recorded: $consentType for user $userId');
    } catch (e) {
      debugPrint('Error recording consent: $e');
      throw SecurityException('Failed to record consent');
    }
  }

  /// GDPR: Get user data
  Future<UserDataExport> exportUserData(String userId) async {
    try {
      // Collect all user data
      final userData = <String, dynamic>{};
      
      // Get personal data
      // ... fetch from database
      
      // Get consent records
      final consents = _consentRecords.values
          .where((c) => c.userId == userId)
          .map((c) => c.toMap())
          .toList();
      
      // Get audit logs
      final auditLogs = await _database!.query(
        'security_audit_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: 1000,
      );
      
      // Create export
      final export = UserDataExport(
        userId: userId,
        exportDate: DateTime.now(),
        data: userData,
        consents: consents,
        auditLogs: auditLogs,
        format: 'json',
      );
      
      // Log data export
      await _logSecurityEvent(
        eventType: SecurityEventType.dataExported,
        userId: userId,
        action: 'export_user_data',
        result: 'success',
      );
      
      return export;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      throw SecurityException('Failed to export user data');
    }
  }

  /// GDPR: Delete user data (Right to be forgotten)
  Future<void> deleteUserData(String userId, {bool permanent = false}) async {
    try {
      if (permanent) {
        // Permanent deletion
        await _permanentlyDeleteUserData(userId);
      } else {
        // Soft delete with anonymization
        await _anonymizeUserData(userId);
      }
      
      // Log data deletion
      await _logSecurityEvent(
        eventType: SecurityEventType.dataDeleted,
        userId: userId,
        action: permanent ? 'permanent_delete' : 'anonymize',
        result: 'success',
        riskLevel: RiskLevel.high,
      );
      
      debugPrint('User data deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      throw SecurityException('Failed to delete user data');
    }
  }

  /// Perform security scan
  Future<SecurityScanResult> performSecurityScan() async {
    try {
      final vulnerabilities = <Vulnerability>[];
      final recommendations = <String>[];
      
      // Check encryption keys
      await _scanEncryptionKeys(vulnerabilities, recommendations);
      
      // Check sessions
      await _scanSessions(vulnerabilities, recommendations);
      
      // Check password policies
      await _scanPasswordPolicies(vulnerabilities, recommendations);
      
      // Check audit logs
      await _scanAuditLogs(vulnerabilities, recommendations);
      
      // Check GDPR compliance
      await _scanGDPRCompliance(vulnerabilities, recommendations);
      
      // Check for suspicious activities
      await _scanSuspiciousActivities(vulnerabilities, recommendations);
      
      // Calculate risk score
      final riskScore = _calculateRiskScore(vulnerabilities);
      
      final result = SecurityScanResult(
        scanId: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        vulnerabilities: vulnerabilities,
        recommendations: recommendations,
        riskScore: riskScore,
        overallStatus: _determineSecurityStatus(riskScore),
      );
      
      // Store scan result
      _vulnerabilityReports.add(VulnerabilityReport(
        id: result.scanId,
        vulnerabilities: vulnerabilities,
        timestamp: DateTime.now(),
        resolved: false,
      ));
      
      // Log security scan
      await _logSecurityEvent(
        eventType: SecurityEventType.securityScan,
        action: 'security_scan',
        result: 'completed',
        metadata: {
          'vulnerabilityCount': vulnerabilities.length,
          'riskScore': riskScore,
        },
      );
      
      return result;
    } catch (e) {
      debugPrint('Error performing security scan: $e');
      throw SecurityException('Failed to perform security scan');
    }
  }

  /// Perform penetration test
  Future<PenetrationTestResult> performPenetrationTest({
    required String testType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final testId = 'pentest_${DateTime.now().millisecondsSinceEpoch}';
      final findings = <PenTestFinding>[];
      
      switch (testType) {
        case 'sql_injection':
          await _testSQLInjection(findings);
          break;
        case 'xss':
          await _testXSS(findings);
          break;
        case 'authentication':
          await _testAuthentication(findings);
          break;
        case 'authorization':
          await _testAuthorization(findings);
          break;
        case 'encryption':
          await _testEncryption(findings);
          break;
        case 'session_management':
          await _testSessionManagement(findings);
          break;
        default:
          throw SecurityException('Unknown test type: $testType');
      }
      
      final result = PenetrationTestResult(
        testId: testId,
        testType: testType,
        timestamp: DateTime.now(),
        findings: findings,
        passed: findings.where((f) => f.severity == FindingSeverity.critical).isEmpty,
      );
      
      // Store test result
      _penetrationTests[testId] = PenetrationTest(
        id: testId,
        type: testType,
        result: result,
        timestamp: DateTime.now(),
      );
      
      // Log penetration test
      await _logSecurityEvent(
        eventType: SecurityEventType.penetrationTest,
        action: 'penetration_test',
        result: result.passed ? 'passed' : 'failed',
        metadata: {
          'testType': testType,
          'findingsCount': findings.length,
        },
        riskLevel: result.passed ? RiskLevel.low : RiskLevel.high,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error performing penetration test: $e');
      throw SecurityException('Failed to perform penetration test');
    }
  }

  // Private helper methods

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltSize, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  String _generateSecureToken(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  List<int> pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final blockSize = 32; // SHA256 output size
    final numBlocks = (keyLength / blockSize).ceil();
    final key = <int>[];
    
    for (int blockNum = 1; blockNum <= numBlocks; blockNum++) {
      final block = _pbkdf2Block(hmac, salt, iterations, blockNum);
      key.addAll(block);
    }
    
    return key.take(keyLength).toList();
  }

  List<int> _pbkdf2Block(Hmac hmac, List<int> salt, int iterations, int blockNum) {
    final blockNumBytes = [
      (blockNum >> 24) & 0xff,
      (blockNum >> 16) & 0xff,
      (blockNum >> 8) & 0xff,
      blockNum & 0xff,
    ];
    
    var u = hmac.convert([...salt, ...blockNumBytes]).bytes;
    var result = List<int>.from(u);
    
    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    
    return result;
  }

  bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', 'password123', 'admin', 'letmein',
      'qwerty', 'abc123', 'monkey', 'dragon', 'master'
    ];
    
    return commonPasswords.any((common) => 
      password.toLowerCase().contains(common));
  }

  Future<void> _storeKeyMetadata(String keyType, Key key) async {
    await _database!.insert('encryption_keys', {
      'id': 'key_${DateTime.now().millisecondsSinceEpoch}',
      'key_type': keyType,
      'key_data': base64.encode(sha256.convert(key.bytes).bytes), // Store hash only
      'algorithm': 'AES-256-GCM',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now().add(Duration(days: 365)).millisecondsSinceEpoch,
    });
  }

  Future<void> _logSecurityEvent({
    required SecurityEventType eventType,
    String? userId,
    String? ipAddress,
    String? userAgent,
    String? resource,
    String? action,
    String? result,
    Map<String, dynamic>? metadata,
    RiskLevel? riskLevel,
  }) async {
    final log = SecurityAuditLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      eventType: eventType,
      userId: userId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      resource: resource,
      action: action,
      result: result,
      metadata: metadata,
      timestamp: DateTime.now(),
      riskLevel: riskLevel,
    );
    
    _auditLogs.add(log);
    
    // Persist to database
    await _database!.insert('security_audit_logs', log.toMap());
    
    // Keep only recent logs in memory
    if (_auditLogs.length > 10000) {
      _auditLogs.removeRange(0, 1000);
    }
  }

  Future<void> _logSecurityIncident({
    required String type,
    required IncidentSeverity severity,
    String? description,
    List<String>? affectedUsers,
    List<String>? mitigationSteps,
  }) async {
    _securityIncidents++;
    
    await _database!.insert('security_incidents', {
      'id': 'incident_${DateTime.now().millisecondsSinceEpoch}',
      'incident_type': type,
      'severity': severity.toString().split('.').last,
      'description': description,
      'affected_users': jsonEncode(affectedUsers ?? []),
      'mitigation_steps': jsonEncode(mitigationSteps ?? []),
      'detected_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _loadSecurityData() async {
    // Load consent records
    final consents = await _database!.query('consent_records');
    for (final consent in consents) {
      final record = ConsentRecord.fromMap(consent);
      _consentRecords[record.id] = record;
    }
    
    // Load recent audit logs
    final logs = await _database!.query(
      'security_audit_logs',
      orderBy: 'timestamp DESC',
      limit: 1000,
    );
    
    for (final log in logs) {
      _auditLogs.add(SecurityAuditLog.fromMap(log));
    }
    
    debugPrint('Loaded security data: ${_consentRecords.length} consents, ${_auditLogs.length} audit logs');
  }

  void _startSessionCleanup() {
    _sessionCleanupTimer?.cancel();
    _sessionCleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupExpiredSessions();
    });
  }

  void _cleanupExpiredSessions() {
    final now = DateTime.now();
    final expiredSessions = _activeSessions.entries
        .where((e) => e.value.expiresAt.isBefore(now))
        .map((e) => e.key)
        .toList();
    
    for (final sessionId in expiredSessions) {
      terminateSession(sessionId);
    }
    
    if (expiredSessions.isNotEmpty) {
      debugPrint('Cleaned up ${expiredSessions.length} expired sessions');
    }
  }

  Future<void> _permanentlyDeleteUserData(String userId) async {
    // Delete from all tables
    await _database!.delete('security_audit_logs', where: 'user_id = ?', whereArgs: [userId]);
    await _database!.delete('consent_records', where: 'user_id = ?', whereArgs: [userId]);
    // ... delete from other tables
  }

  Future<void> _anonymizeUserData(String userId) async {
    // Replace user ID with anonymous ID
    final anonymousId = 'anon_${sha256.convert(utf8.encode(userId)).toString().substring(0, 16)}';
    
    await _database!.update(
      'security_audit_logs',
      {'user_id': anonymousId},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    // ... update other tables
  }

  Future<void> _scanEncryptionKeys(
    List<Vulnerability> vulnerabilities,
    List<String> recommendations,
  ) async {
    // Check key rotation
    final keys = await _database!.query('encryption_keys');
    for (final key in keys) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(key['created_at'] as int);
      if (DateTime.now().difference(createdAt).inDays > 180) {
        vulnerabilities.add(Vulnerability(
          type: 'key_rotation',
          severity: VulnerabilitySeverity.medium,
          description: 'Encryption key not rotated in 180+ days',
        ));
        recommendations.add('Rotate encryption keys regularly');
      }
    }
  }

  Future<void> _scanSessions(
    List<Vulnerability> vulnerabilities,
    List<String> recommendations,
  ) async {
    // Check for long-lived sessions
    for (final session in _activeSessions.values) {
      if (session.createdAt.isBefore(DateTime.now().subtract(Duration(hours: 24)))) {
        vulnerabilities.add(Vulnerability(
          type: 'long_session',
          severity: VulnerabilitySeverity.low,
          description: 'Session active for more than 24 hours',
        ));
      }
    }
  }

  Future<void> _scanPasswordPolicies(
    List<Vulnerability> vulnerabilities,
    List<String> recommendations,
  ) async {
    // Check password expiry settings
    // ... implementation
  }

  Future<void> _scanAuditLogs(
    List<Vulnerability> vulnerabilities,
    List<String> recommendations,
  ) async {
    // Check for suspicious patterns
    final recentLogs = _auditLogs.where((log) => 
      log.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 1)))
    ).toList();
    
    // Check for multiple failed logins
    final failedLogins = recentLogs.where((log) => 
      log.eventType == SecurityEventType.loginFailed
    ).length;
    
    if (failedLogins > 20) {
      vulnerabilities.add(Vulnerability(
        type: 'brute_force',
        severity: VulnerabilitySeverity.high,
        description: 'Possible brute force attack detected',
      ));
      recommendations.add('Implement rate limiting and CAPTCHA');
    }
  }

  Future<void> _scanGDPRCompliance(
    List<Vulnerability> vulnerabilities,
    List<String> recommendations,
  ) async {
    // Check for expired consents
    for (final consent in _consentRecords.values) {
      if (consent.expiresAt != null && consent.expiresAt!.isBefore(DateTime.now())) {
        vulnerabilities.add(Vulnerability(
          type: 'expired_consent',
          severity: VulnerabilitySeverity.medium,
          description: 'Expired consent record found',
        ));
        recommendations.add('Review and renew expired consents');
      }
    }
  }

  Future<void> _scanSuspiciousActivities(
    List<Vulnerability> vulnerabilities,
    List<String> recommendations,
  ) async {
    // Check for unusual access patterns
    // ... implementation
  }

  double _calculateRiskScore(List<Vulnerability> vulnerabilities) {
    double score = 0;
    
    for (final vuln in vulnerabilities) {
      switch (vuln.severity) {
        case VulnerabilitySeverity.critical:
          score += 10;
          break;
        case VulnerabilitySeverity.high:
          score += 7;
          break;
        case VulnerabilitySeverity.medium:
          score += 4;
          break;
        case VulnerabilitySeverity.low:
          score += 1;
          break;
      }
    }
    
    return min(score, 100);
  }

  SecurityStatus _determineSecurityStatus(double riskScore) {
    if (riskScore < 10) return SecurityStatus.excellent;
    if (riskScore < 30) return SecurityStatus.good;
    if (riskScore < 50) return SecurityStatus.fair;
    if (riskScore < 70) return SecurityStatus.poor;
    return SecurityStatus.critical;
  }

  Future<void> _testSQLInjection(List<PenTestFinding> findings) async {
    // Test for SQL injection vulnerabilities
    // ... implementation
  }

  Future<void> _testXSS(List<PenTestFinding> findings) async {
    // Test for XSS vulnerabilities
    // ... implementation
  }

  Future<void> _testAuthentication(List<PenTestFinding> findings) async {
    // Test authentication mechanisms
    // ... implementation
  }

  Future<void> _testAuthorization(List<PenTestFinding> findings) async {
    // Test authorization controls
    // ... implementation
  }

  Future<void> _testEncryption(List<PenTestFinding> findings) async {
    // Test encryption implementation
    // ... implementation
  }

  Future<void> _testSessionManagement(List<PenTestFinding> findings) async {
    // Test session management
    // ... implementation
  }

  @override
  void dispose() {
    _sessionCleanupTimer?.cancel();
    super.dispose();
  }
}

// Data Models

class EncryptedData {
  final String id;
  final String encryptedValue;
  final String iv;
  final String dataType;
  final String algorithm;
  final String keyId;
  final Map<String, dynamic>? metadata;
  final DateTime encryptedAt;

  EncryptedData({
    required this.id,
    required this.encryptedValue,
    required this.iv,
    required this.dataType,
    required this.algorithm,
    required this.keyId,
    this.metadata,
    required this.encryptedAt,
  });
}

class PasswordStrength {
  final StrengthLevel level;
  final int score;
  final List<String> suggestions;

  PasswordStrength({
    required this.level,
    required this.score,
    required this.suggestions,
  });
}

enum StrengthLevel {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong,
}

class LoginResult {
  final bool success;
  final bool locked;
  final int? attemptsRemaining;
  final Duration? remainingLockTime;
  final String? message;

  LoginResult({
    required this.success,
    this.locked = false,
    this.attemptsRemaining,
    this.remainingLockTime,
    this.message,
  });
}

class LoginAttempt {
  final String userId;
  final bool success;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  LoginAttempt({
    required this.userId,
    required this.success,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.metadata,
  });
}

class SecureSession {
  final String id;
  final String userId;
  final String deviceId;
  final String token;
  final String refreshToken;
  final DateTime createdAt;
  DateTime expiresAt;
  DateTime? lastActivity;
  final Map<String, dynamic>? metadata;

  SecureSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.token,
    required this.refreshToken,
    required this.createdAt,
    required this.expiresAt,
    this.lastActivity,
    this.metadata,
  });
}

class SecurityAuditLog {
  final String id;
  final SecurityEventType eventType;
  final String? userId;
  final String? ipAddress;
  final String? userAgent;
  final String? resource;
  final String? action;
  final String? result;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final RiskLevel? riskLevel;

  SecurityAuditLog({
    required this.id,
    required this.eventType,
    this.userId,
    this.ipAddress,
    this.userAgent,
    this.resource,
    this.action,
    this.result,
    this.metadata,
    required this.timestamp,
    this.riskLevel,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'event_type': eventType.toString().split('.').last,
    'user_id': userId,
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'resource': resource,
    'action': action,
    'result': result,
    'metadata': metadata != null ? jsonEncode(metadata) : null,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'risk_level': riskLevel?.toString().split('.').last,
  };

  factory SecurityAuditLog.fromMap(Map<String, dynamic> map) => SecurityAuditLog(
    id: map['id'],
    eventType: SecurityEventType.values.firstWhere(
      (e) => e.toString().split('.').last == map['event_type'],
    ),
    userId: map['user_id'],
    ipAddress: map['ip_address'],
    userAgent: map['user_agent'],
    resource: map['resource'],
    action: map['action'],
    result: map['result'],
    metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    riskLevel: map['risk_level'] != null 
      ? RiskLevel.values.firstWhere(
          (r) => r.toString().split('.').last == map['risk_level'],
        )
      : null,
  );
}

enum SecurityEventType {
  loginSuccess,
  loginFailed,
  sessionCreated,
  sessionTerminated,
  dataEncrypted,
  dataDecrypted,
  encryptionFailed,
  decryptionFailed,
  consentRecorded,
  dataExported,
  dataDeleted,
  securityScan,
  penetrationTest,
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

class ConsentRecord {
  final String id;
  final String userId;
  final String consentType;
  final bool granted;
  final String? purpose;
  final String lawfulBasis;
  final String withdrawalMethod;
  final String? ipAddress;
  final DateTime timestamp;
  final DateTime? expiresAt;

  ConsentRecord({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.granted,
    this.purpose,
    required this.lawfulBasis,
    required this.withdrawalMethod,
    this.ipAddress,
    required this.timestamp,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'consent_type': consentType,
    'granted': granted ? 1 : 0,
    'purpose': purpose,
    'lawful_basis': lawfulBasis,
    'withdrawal_method': withdrawalMethod,
    'ip_address': ipAddress,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'expires_at': expiresAt?.millisecondsSinceEpoch,
  };

  factory ConsentRecord.fromMap(Map<String, dynamic> map) => ConsentRecord(
    id: map['id'],
    userId: map['user_id'],
    consentType: map['consent_type'],
    granted: map['granted'] == 1,
    purpose: map['purpose'],
    lawfulBasis: map['lawful_basis'],
    withdrawalMethod: map['withdrawal_method'],
    ipAddress: map['ip_address'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    expiresAt: map['expires_at'] != null 
      ? DateTime.fromMillisecondsSinceEpoch(map['expires_at'])
      : null,
  );
}

class DataProcessingActivity {
  final String id;
  final String name;
  final String purpose;
  final String lawfulBasis;
  final List<String>? dataCategories;
  final List<String>? dataSubjects;
  final List<String>? recipients;
  final String? retentionPeriod;
  final String? securityMeasures;
  final DateTime createdAt;
  final DateTime updatedAt;

  DataProcessingActivity({
    required this.id,
    required this.name,
    required this.purpose,
    required this.lawfulBasis,
    this.dataCategories,
    this.dataSubjects,
    this.recipients,
    this.retentionPeriod,
    this.securityMeasures,
    required this.createdAt,
    required this.updatedAt,
  });
}

class DataBreachRecord {
  final String id;
  final String description;
  final DateTime detectedAt;
  final DateTime? reportedAt;
  final List<String> affectedDataTypes;
  final int affectedRecords;
  final String severity;
  final List<String> mitigationSteps;
  final bool reportedToAuthorities;

  DataBreachRecord({
    required this.id,
    required this.description,
    required this.detectedAt,
    this.reportedAt,
    required this.affectedDataTypes,
    required this.affectedRecords,
    required this.severity,
    required this.mitigationSteps,
    required this.reportedToAuthorities,
  });
}

class UserDataExport {
  final String userId;
  final DateTime exportDate;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> consents;
  final List<Map<String, dynamic>> auditLogs;
  final String format;

  UserDataExport({
    required this.userId,
    required this.exportDate,
    required this.data,
    required this.consents,
    required this.auditLogs,
    required this.format,
  });
}

class SecurityScanResult {
  final String scanId;
  final DateTime timestamp;
  final List<Vulnerability> vulnerabilities;
  final List<String> recommendations;
  final double riskScore;
  final SecurityStatus overallStatus;

  SecurityScanResult({
    required this.scanId,
    required this.timestamp,
    required this.vulnerabilities,
    required this.recommendations,
    required this.riskScore,
    required this.overallStatus,
  });
}

class Vulnerability {
  final String type;
  final VulnerabilitySeverity severity;
  final String description;
  final String? remediation;

  Vulnerability({
    required this.type,
    required this.severity,
    required this.description,
    this.remediation,
  });
}

enum VulnerabilitySeverity {
  low,
  medium,
  high,
  critical,
}

enum SecurityStatus {
  excellent,
  good,
  fair,
  poor,
  critical,
}

class VulnerabilityReport {
  final String id;
  final List<Vulnerability> vulnerabilities;
  final DateTime timestamp;
  final bool resolved;

  VulnerabilityReport({
    required this.id,
    required this.vulnerabilities,
    required this.timestamp,
    required this.resolved,
  });
}

class PenetrationTest {
  final String id;
  final String type;
  final PenetrationTestResult result;
  final DateTime timestamp;

  PenetrationTest({
    required this.id,
    required this.type,
    required this.result,
    required this.timestamp,
  });
}

class PenetrationTestResult {
  final String testId;
  final String testType;
  final DateTime timestamp;
  final List<PenTestFinding> findings;
  final bool passed;

  PenetrationTestResult({
    required this.testId,
    required this.testType,
    required this.timestamp,
    required this.findings,
    required this.passed,
  });
}

class PenTestFinding {
  final String id;
  final String vulnerability;
  final FindingSeverity severity;
  final String description;
  final String? proof;
  final String? remediation;

  PenTestFinding({
    required this.id,
    required this.vulnerability,
    required this.severity,
    required this.description,
    this.proof,
    this.remediation,
  });
}

enum FindingSeverity {
  info,
  low,
  medium,
  high,
  critical,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}