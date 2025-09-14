import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive logging service for the MedRefer AI app
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // Configuration
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxLogFiles = 5;
  static const int _maxInMemoryLogs = 1000;
  
  // State
  final List<LogEntry> _inMemoryLogs = [];
  final StreamController<LogEntry> _logStreamController = StreamController<LogEntry>.broadcast();
  bool _isInitialized = false;
  String? _logDirectory;
  
  // Getters
  Stream<LogEntry> get logStream => _logStreamController.stream;
  List<LogEntry> get recentLogs => List.unmodifiable(_inMemoryLogs);
  bool get isInitialized => _isInitialized;

  /// Initialize the logging service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get log directory
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = '${appDir.path}/logs';
      
      // Create log directory if it doesn't exist
      final logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Clean up old log files
      await _cleanupOldLogs();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('LoggingService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LoggingService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Log an info message
  void info(String message, {String? context, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, context: context, metadata: metadata);
  }

  /// Log a warning message
  void warning(String message, {String? context, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warning, message, context: context, metadata: metadata);
  }

  /// Log an error message
  void error(String message, {String? context, Map<String, dynamic>? metadata, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, context: context, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message (only in debug mode)
  void debug(String message, {String? context, Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, context: context, metadata: metadata);
    }
  }

  /// Log a critical message
  void critical(String message, {String? context, Map<String, dynamic>? metadata, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, context: context, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  /// Log user actions for audit trail
  void userAction(String action, {String? userId, String? context, Map<String, dynamic>? metadata}) {
    final auditMetadata = {
      'action': action,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };
    
    _log(LogLevel.info, 'User Action: $action', context: context ?? 'UserAction', metadata: auditMetadata);
  }

  /// Log performance metrics
  void performance(String metric, double value, {String? context, Map<String, dynamic>? metadata}) {
    final perfMetadata = {
      'metric': metric,
      'value': value,
      'unit': 'ms',
      ...?metadata,
    };
    
    _log(LogLevel.info, 'Performance: $metric = ${value}ms', context: context ?? 'Performance', metadata: perfMetadata);
  }

  /// Log network requests
  void network(String method, String url, {int? statusCode, int? responseTime, Map<String, dynamic>? metadata}) {
    final networkMetadata = {
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'responseTime': responseTime,
      ...?metadata,
    };
    
    _log(LogLevel.info, 'Network: $method $url', context: 'Network', metadata: networkMetadata);
  }

  /// Log database operations
  void database(String operation, String table, {String? context, Map<String, dynamic>? metadata}) {
    final dbMetadata = {
      'operation': operation,
      'table': table,
      ...?metadata,
    };
    
    _log(LogLevel.debug, 'Database: $operation on $table', context: context ?? 'Database', metadata: dbMetadata);
  }

  /// Internal logging method
  void _log(LogLevel level, String message, {
    String? context,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isInitialized) {
      debugPrint('LoggingService: Not initialized, logging: $message');
      return;
    }

    final logEntry = LogEntry(
      level: level,
      message: message,
      context: context ?? 'General',
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    // Add to in-memory logs
    _inMemoryLogs.add(logEntry);
    if (_inMemoryLogs.length > _maxInMemoryLogs) {
      _inMemoryLogs.removeAt(0);
    }

    // Notify listeners
    _logStreamController.add(logEntry);

    // Print to console in debug mode
    if (kDebugMode) {
      _printToConsole(logEntry);
    }

    // Write to file for important logs
    if (level.index >= LogLevel.warning.index) {
      _writeToFile(logEntry);
    }
  }

  /// Print log entry to console
  void _printToConsole(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.name.toUpperCase().padRight(8);
    final context = entry.context.padRight(15);
    
    debugPrint('[$timestamp] $level [$context] ${entry.message}');
    
    if (entry.error != null) {
      debugPrint('  Error: ${entry.error}');
    }
    
    if (entry.metadata.isNotEmpty) {
      debugPrint('  Metadata: ${jsonEncode(entry.metadata)}');
    }
  }

  /// Write log entry to file
  Future<void> _writeToFile(LogEntry entry) async {
    try {
      if (_logDirectory == null) return;
      
      final logFile = File('$_logDirectory/app_${DateTime.now().toIso8601String().split('T')[0]}.log');
      final logLine = '${entry.toJson()}\n';
      
      await logFile.writeAsString(logLine, mode: FileMode.append);
      
      // Check file size and rotate if necessary
      final fileSize = await logFile.length();
      if (fileSize > _maxLogFileSize) {
        await _rotateLogFile(logFile);
      }
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }

  /// Rotate log file when it gets too large
  Future<void> _rotateLogFile(File logFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotatedFile = File('${logFile.path}.$timestamp');
      await logFile.rename(rotatedFile.path);
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  /// Clean up old log files
  Future<void> _cleanupOldLogs() async {
    try {
      if (_logDirectory == null) return;
      
      final logDir = Directory(_logDirectory!);
      final logFiles = await logDir.list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();
      
      // Sort by modification time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Remove old files if we have too many
      if (logFiles.length > _maxLogFiles) {
        for (int i = _maxLogFiles; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old logs: $e');
    }
  }

  /// Get logs for a specific time range
  Future<List<LogEntry>> getLogs({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? minLevel,
    String? context,
  }) async {
    List<LogEntry> filteredLogs = List.from(_inMemoryLogs);
    
    if (startTime != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isAfter(startTime)).toList();
    }
    
    if (endTime != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isBefore(endTime)).toList();
    }
    
    if (minLevel != null) {
      filteredLogs = filteredLogs.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    if (context != null) {
      filteredLogs = filteredLogs.where((log) => log.context == context).toList();
    }
    
    return filteredLogs;
  }

  /// Clear in-memory logs
  void clearInMemoryLogs() {
    _inMemoryLogs.clear();
  }

  /// Export logs to JSON
  Future<String> exportLogs({DateTime? startTime, DateTime? endTime}) async {
    final logs = await getLogs(startTime: startTime, endTime: endTime);
    final logData = logs.map((log) => log.toJson()).toList();
    return jsonEncode(logData);
  }

  /// Dispose resources
  void dispose() {
    _logStreamController.close();
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final String context;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    required this.context,
    required this.timestamp,
    required this.metadata,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      context: json['context'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      error: json['error'],
      stackTrace: json['stackTrace'],
    );
  }
}