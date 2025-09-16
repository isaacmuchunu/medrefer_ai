import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Comprehensive logging service for the MedRefer AI app
class LoggingService {
  factory LoggingService() => _instance;
  LoggingService._internal();

  static final LoggingService _instance = LoggingService._internal();

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
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        _logDirectory = '${appDir.path}/logs';
        
        // Create log directory if it doesn't exist
        final logDir = Directory(_logDirectory!);
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }
        
        // Clean up old log files
        await _cleanupOldLogs();
      }
      
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

  /// Log a message with a specific level
  void log(LogLevel level, String message, {
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

    // Write to file (asynchronously)
    _writeToFile(entry);
    
    // Also print to console in debug mode
    if (kDebugMode) {
      _printToConsole(entry);
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

  /// Write a log entry to the current log file
  Future<void> _writeToFile(LogEntry entry) async {
    if (kIsWeb || _logDirectory == null) return;

    final logFile = File('$_logDirectory/medrefer.log');
    
    try {
      await logFile.writeAsString('${entry.toFileFormat()}\n', mode: FileMode.append, flush: true);
      
      // Check if log rotation is needed
      final fileSize = await logFile.length();
      if (fileSize > _maxLogFileSize) {
        await _rotateLogs();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LoggingService: Failed to write to log file: $e');
      }
    }
  }

  /// Rotate log files
  Future<void> _rotateLogs() async {
    if (kIsWeb || _logDirectory == null) return;

    final logDirectory = Directory(_logDirectory!);
    // 1. Delete the oldest log file if we've reached the max
    final oldLog = File('$logDirectory/medrefer.log.$_maxLogFiles');
    if (await oldLog.exists()) {
      await oldLog.delete();
    }
    
    // 2. Shift remaining log files
    for (int i = _maxLogFiles - 1; i > 0; i--) {
      final currentLog = File('$logDirectory/medrefer.log.$i');
      if (await currentLog.exists()) {
        await currentLog.rename('$logDirectory/medrefer.log.${i + 1}');
      }
    }
    
    // 3. Rename the current log file
    final currentLog = File('$logDirectory/medrefer.log');
    if (await currentLog.exists()) {
      await currentLog.rename('$logDirectory/medrefer.log.1');
    }
    
    // 4. Create a new empty log file
    await currentLog.create();
  }

  /// Clean up old log files on startup
  Future<void> _cleanupOldLogs() async {
    if (kIsWeb || _logDirectory == null) return;

    final logDirectory = Directory(_logDirectory!);
    final files = await logDirectory.list().toList();
    
    final logFiles = files
        .whereType<File>()
        .where((file) => file.path.contains('medrefer.log'))
        .toList();
        
    logFiles.sort((a, b) {
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    });
    
    if (logFiles.length > _maxLogFiles) {
      for (int i = _maxLogFiles; i < logFiles.length; i++) {
        await logFiles[i].delete();
      }
    }
  }

  /// Export logs to a single file
  Future<File?> exportLogs() async {
    if (kIsWeb || _logDirectory == null) return null;

    final exportFile = File('$_logDirectory/exported_logs_${DateTime.now().toIso8601String()}.txt');
    final allLogs = StringBuffer();
    
    // Combine all existing log files
    final logDirectory = Directory(_logDirectory!);
    final logFiles = (await logDirectory.list().toList())
        .whereType<File>()
        .where((file) => file.path.contains('medrefer.log'))
        .toList();
        
    logFiles.sort((a, b) => a.path.compareTo(b.path));
    
    for (final file in logFiles) {
      allLogs.writeln('--- START OF ${file.path} ---');
      allLogs.writeln(await file.readAsString());
      allLogs.writeln('--- END OF ${file.path} ---\n');
    }
    
    await exportFile.writeAsString(allLogs.toString());
    return exportFile;
  }

  /// Dispose of the service resources
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

  /// Convert log entry to a format suitable for file writing
  String toFileFormat() {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.write('"timestamp": "${timestamp.toIso8601String()}", ');
    buffer.write('"level": "${level.name}", ');
    buffer.write('"context": "$context", ');
    buffer.write('"message": "$message", ');
    buffer.write('"metadata": ${jsonEncode(metadata)}');
    if (error != null) {
      buffer.write(', "error": "$error"');
    }
    if (stackTrace != null) {
      buffer.write(', "stackTrace": "$stackTrace"');
    }
    buffer.write(']');
    return buffer.toString();
  }
}