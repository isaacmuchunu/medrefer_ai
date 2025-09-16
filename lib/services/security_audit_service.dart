import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive security audit service for HIPAA compliance and security monitoring
class SecurityAuditService {
  SecurityAuditService._internal();

  // Audit configuration
  static const String _auditLogKey = 'security_audit_logs';
  static const int _maxLogEntries = 10000;
  static const Duration _logRetentionPeriod = Duration(days: 365); // HIPAA requires 6 years, but we'll use 1 year for demo
  
  // Security monitoring
  final List<SecurityAuditLog> _auditLogs = [];
  final Map<String, int> _failedLoginAttempts = {};
  final Map<String, DateTime> _lastLoginAttempts = {};
  final Set<String> _blockedIPs = {};
  
  // Security thresholds
  static const int _maxFailedLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  // static const Duration _sessionTimeout = Duration(hours: 8);
  
  bool _isInitialized = false;
  Timer? _cleanupTimer;

  static final SecurityAuditService _instance = SecurityAuditService._internal();
  factory SecurityAuditService() => _instance;

  /// Initialize the security audit service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadAuditLogs();
      _startPeriodicCleanup();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('SecurityAuditService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecurityAuditService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Log security event for audit trail
  Future<void> logSecurityEvent({
    required SecurityEventType eventType,
    required String userId,
    required String action,
    String? resourceId,
    String? ipAddress,
    Map<String, dynamic>? metadata,
    SecurityRiskLevel riskLevel = SecurityRiskLevel.low,
  }) async {
    final auditLog = SecurityAuditLog(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      eventType: eventType,
      userId: userId,
      action: action,
      resourceId: resourceId,
      ipAddress: ipAddress ?? 'unknown',
      riskLevel: riskLevel,
      metadata: metadata ?? {},
      sessionId: _getCurrentSessionId(),
    );
    
    _auditLogs.add(auditLog);
    
    // Trigger security alerts for high-risk events
    if (riskLevel == SecurityRiskLevel.high || riskLevel == SecurityRiskLevel.critical) {
      await _triggerSecurityAlert(auditLog);
    }
    
    // Save to persistent storage
    await _saveAuditLogs();
    
    if (kDebugMode) {
      debugPrint('SecurityAudit: ${eventType.name} - $action by $userId');
    }
  }

  /// Log authentication attempt
  Future<bool> logAuthenticationAttempt({
    required String userId,
    required bool isSuccessful,
    String? ipAddress,
    String? userAgent,
  }) async {
    final ip = ipAddress ?? 'unknown';
    
    // Check if IP is blocked
    if (_blockedIPs.contains(ip)) {
      await logSecurityEvent(
        eventType: SecurityEventType.authentication,
        userId: userId,
        action: 'login_attempt_blocked_ip',
        ipAddress: ip,
        riskLevel: SecurityRiskLevel.high,
        metadata: {'reason': 'blocked_ip'},
      );
      return false;
    }
    
    if (isSuccessful) {
      // Reset failed attempts on successful login
      _failedLoginAttempts.remove(userId);
      _lastLoginAttempts[userId] = DateTime.now();
      
      await logSecurityEvent(
        eventType: SecurityEventType.authentication,
        userId: userId,
        action: 'login_success',
        ipAddress: ip,
        riskLevel: SecurityRiskLevel.low,
        metadata: {'userAgent': userAgent},
      );
      
      return true;
    } else {
      // Track failed attempts
      final failedCount = (_failedLoginAttempts[userId] ?? 0) + 1;
      _failedLoginAttempts[userId] = failedCount;
      _lastLoginAttempts[userId] = DateTime.now();
      
      final riskLevel = failedCount >= _maxFailedLoginAttempts 
          ? SecurityRiskLevel.high 
          : SecurityRiskLevel.medium;
      
      await logSecurityEvent(
        eventType: SecurityEventType.authentication,
        userId: userId,
        action: 'login_failed',
        ipAddress: ip,
        riskLevel: riskLevel,
        metadata: {
          'failedAttempts': failedCount,
          'userAgent': userAgent,
        },
      );
      
      // Block account if too many failed attempts
      if (failedCount >= _maxFailedLoginAttempts) {
        await _blockUser(userId, ip);
      }
      
      return false;
    }
  }

  /// Log data access event
  Future<void> logDataAccess({
    required String userId,
    required String resourceType,
    required String resourceId,
    required DataAccessType accessType,
    Map<String, dynamic>? metadata,
  }) async {
    await logSecurityEvent(
      eventType: SecurityEventType.dataAccess,
      userId: userId,
      action: '${accessType.name}_${resourceType}',
      resourceId: resourceId,
      riskLevel: _getDataAccessRiskLevel(resourceType, accessType),
      metadata: {
        'resourceType': resourceType,
        'accessType': accessType.name,
        ...?metadata,
      },
    );
  }

  /// Log system event
  Future<void> logSystemEvent({
    required String action,
    String? userId,
    SecurityRiskLevel riskLevel = SecurityRiskLevel.low,
    Map<String, dynamic>? metadata,
  }) async {
    await logSecurityEvent(
      eventType: SecurityEventType.system,
      userId: userId ?? 'system',
      action: action,
      riskLevel: riskLevel,
      metadata: metadata,
    );
  }

  /// Check if user is currently blocked
  bool isUserBlocked(String userId) {
    final failedCount = _failedLoginAttempts[userId] ?? 0;
    if (failedCount < _maxFailedLoginAttempts) return false;
    
    final lastAttempt = _lastLoginAttempts[userId];
    if (lastAttempt == null) return false;
    
    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    return timeSinceLastAttempt < _lockoutDuration;
  }

  /// Get security audit logs
  List<SecurityAuditLog> getAuditLogs({
    String? userId,
    SecurityEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    var logs = List<SecurityAuditLog>.from(_auditLogs);
    
    // Apply filters
    if (userId != null) {
      logs = logs.where((log) => log.userId == userId).toList();
    }
    
    if (eventType != null) {
      logs = logs.where((log) => log.eventType == eventType).toList();
    }
    
    if (startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }
    
    // Sort by timestamp (newest first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply limit
    if (limit != null && logs.length > limit) {
      logs = logs.take(limit).toList();
    }
    
    return logs;
  }

  /// Generate security report
  SecurityReport generateSecurityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final logs = getAuditLogs(startDate: start, endDate: end);
    
    final authEvents = logs.where((log) => log.eventType == SecurityEventType.authentication).length;
    final dataAccessEvents = logs.where((log) => log.eventType == SecurityEventType.dataAccess).length;
    final systemEvents = logs.where((log) => log.eventType == SecurityEventType.system).length;
    final highRiskEvents = logs.where((log) => log.riskLevel == SecurityRiskLevel.high || log.riskLevel == SecurityRiskLevel.critical).length;
    
    final failedLogins = logs.where((log) => 
      log.eventType == SecurityEventType.authentication && 
      log.action == 'login_failed'
    ).length;
    
    final uniqueUsers = logs.map((log) => log.userId).toSet().length;
    
    return SecurityReport(
      startDate: start,
      endDate: end,
      totalEvents: logs.length,
      authenticationEvents: authEvents,
      dataAccessEvents: dataAccessEvents,
      systemEvents: systemEvents,
      highRiskEvents: highRiskEvents,
      failedLoginAttempts: failedLogins,
      uniqueActiveUsers: uniqueUsers,
      blockedUsers: _failedLoginAttempts.keys.where(isUserBlocked).length,
    );
  }

  /// Block user temporarily
  Future<void> _blockUser(String userId, String ipAddress) async {
    await logSecurityEvent(
      eventType: SecurityEventType.security,
      userId: userId,
      action: 'user_blocked',
      ipAddress: ipAddress,
      riskLevel: SecurityRiskLevel.high,
      metadata: {
        'reason': 'excessive_failed_login_attempts',
        'blockDuration': _lockoutDuration.inMinutes,
      },
    );
  }

  /// Trigger security alert for high-risk events
  Future<void> _triggerSecurityAlert(SecurityAuditLog auditLog) async {
    // In production, this would send alerts to security team
    if (kDebugMode) {
      debugPrint('SECURITY ALERT: ${auditLog.eventType.name} - ${auditLog.action}');
      debugPrint('Risk Level: ${auditLog.riskLevel.name}');
      debugPrint('User: ${auditLog.userId}');
      debugPrint('Metadata: ${auditLog.metadata}');
    }
  }

  /// Get data access risk level based on resource type and access type
  SecurityRiskLevel _getDataAccessRiskLevel(String resourceType, DataAccessType accessType) {
    // High-risk resources
    if (resourceType == 'patient_medical_record' || resourceType == 'sensitive_document') {
      return accessType == DataAccessType.delete ? SecurityRiskLevel.high : SecurityRiskLevel.medium;
    }
    
    // Medium-risk resources
    if (resourceType == 'patient_profile' || resourceType == 'referral') {
      return accessType == DataAccessType.delete ? SecurityRiskLevel.medium : SecurityRiskLevel.low;
    }
    
    return SecurityRiskLevel.low;
  }

  /// Generate unique log ID
  String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return sha256.convert(utf8.encode('$timestamp$random')).toString().substring(0, 16);
  }

  /// Get current session ID (simplified)
  String _getCurrentSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Load audit logs from storage
  Future<void> _loadAuditLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_auditLogKey);
      
      if (logsJson != null) {
        final logsList = jsonDecode(logsJson) as List;
        _auditLogs.clear();
        _auditLogs.addAll(
          logsList.map((log) => SecurityAuditLog.fromJson(log)).toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecurityAudit: Error loading audit logs: $e');
      }
    }
  }

  /// Save audit logs to storage
  Future<void> _saveAuditLogs() async {
    try {
      // Keep only recent logs to prevent storage bloat
      if (_auditLogs.length > _maxLogEntries) {
        _auditLogs.removeRange(0, _auditLogs.length - _maxLogEntries);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final logsJson = jsonEncode(_auditLogs.map((log) => log.toJson()).toList());
      await prefs.setString(_auditLogKey, logsJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecurityAudit: Error saving audit logs: $e');
      }
    }
  }

  /// Start periodic cleanup of old logs
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(Duration(hours: 24), (timer) {
      _cleanupOldLogs();
    });
  }

  /// Clean up old audit logs
  void _cleanupOldLogs() {
    final cutoffDate = DateTime.now().subtract(_logRetentionPeriod);
    final initialCount = _auditLogs.length;
    
    _auditLogs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    
    if (_auditLogs.length != initialCount) {
      _saveAuditLogs();
      
      if (kDebugMode) {
        debugPrint('SecurityAudit: Cleaned up ${initialCount - _auditLogs.length} old logs');
      }
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

/// Security event types
enum SecurityEventType {
  authentication,
  dataAccess,
  system,
  security,
  compliance,
}

/// Data access types
enum DataAccessType {
  create,
  read,
  update,
  delete,
  export,
  share,
}

/// Security risk levels
enum SecurityRiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Security audit log entry
class SecurityAuditLog {
  final String id;
  final DateTime timestamp;
  final SecurityEventType eventType;
  final String userId;
  final String action;
  final String? resourceId;
  final String ipAddress;
  final SecurityRiskLevel riskLevel;
  final Map<String, dynamic> metadata;
  final String sessionId;

  SecurityAuditLog({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.userId,
    required this.action,
    this.resourceId,
    required this.ipAddress,
    required this.riskLevel,
    required this.metadata,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.name,
      'userId': userId,
      'action': action,
      'resourceId': resourceId,
      'ipAddress': ipAddress,
      'riskLevel': riskLevel.name,
      'metadata': metadata,
      'sessionId': sessionId,
    };
  }

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      eventType: SecurityEventType.values.firstWhere((e) => e.name == json['eventType']),
      userId: json['userId'],
      action: json['action'],
      resourceId: json['resourceId'],
      ipAddress: json['ipAddress'],
      riskLevel: SecurityRiskLevel.values.firstWhere((e) => e.name == json['riskLevel']),
      metadata: Map<String, dynamic>.from(json['metadata']),
      sessionId: json['sessionId'],
    );
  }
}

/// Security report
class SecurityReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalEvents;
  final int authenticationEvents;
  final int dataAccessEvents;
  final int systemEvents;
  final int highRiskEvents;
  final int failedLoginAttempts;
  final int uniqueActiveUsers;
  final int blockedUsers;

  SecurityReport({
    required this.startDate,
    required this.endDate,
    required this.totalEvents,
    required this.authenticationEvents,
    required this.dataAccessEvents,
    required this.systemEvents,
    required this.highRiskEvents,
    required this.failedLoginAttempts,
    required this.uniqueActiveUsers,
    required this.blockedUsers,
  });
}
