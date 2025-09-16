import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive error handling service for the MedRefer AI app
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Error tracking
  final List<AppError> _errorHistory = [];
  final StreamController<AppError> _errorStreamController = StreamController<AppError>.broadcast();
  
  // Configuration
  bool _isInitialized = false;
  bool _enableErrorReporting = true;
  bool _enableUserFeedback = true;
  
  // Getters
  Stream<AppError> get errorStream => _errorStreamController.stream;
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  bool get isInitialized => _isInitialized;

  /// Initialize the error handling service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up global error handlers
      _setupGlobalErrorHandlers();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('ErrorHandlingService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ErrorHandlingService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Set up global error handlers
  void _setupGlobalErrorHandlers() {
    // Handle Flutter framework errors
    FlutterError.onError = _handleFlutterError;
    
    // Handle platform errors (iOS/Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      type: ErrorType.framework,
      message: details.exception.toString(),
      stackTrace: details.stack.toString(),
      timestamp: DateTime.now(),
      severity: _determineSeverity(details.exception),
      context: 'Flutter Framework',
      userAction: _suggestUserAction(details.exception),
    );
    
    _recordError(error);
    
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handle platform-specific errors
  void _handlePlatformError(Object error, StackTrace stack) {
    final appError = AppError(
      type: ErrorType.platform,
      message: error.toString(),
      stackTrace: stack.toString(),
      timestamp: DateTime.now(),
      severity: ErrorSeverity.high,
      context: 'Platform',
      userAction: 'Please restart the app and try again.',
    );
    
    _recordError(appError);
  }

  /// Handle network errors
  Future<void> handleNetworkError(dynamic error, {String? context}) async {
    var message = 'Network connection failed';
    var userAction = 'Please check your internet connection and try again.';
    
    if (error is SocketException) {
      message = 'Unable to connect to server';
      userAction = 'Please check your internet connection.';
    } else if (error is TimeoutException) {
      message = 'Request timed out';
      userAction = 'The server is taking too long to respond. Please try again.';
    } else if (error is HttpException) {
      message = 'Server error: ${error.message}';
      userAction = 'There was a problem with the server. Please try again later.';
    }
    
    final appError = AppError(
      type: ErrorType.network,
      message: message,
      stackTrace: error.toString(),
      timestamp: DateTime.now(),
      severity: ErrorSeverity.medium,
      context: context ?? 'Network Operation',
      userAction: userAction,
    );
    
    _recordError(appError);
  }

  /// Handle database errors
  Future<void> handleDatabaseError(dynamic error, {String? context}) async {
    final appError = AppError(
      type: ErrorType.database,
      message: 'Database operation failed: ${error.toString()}',
      stackTrace: error.toString(),
      timestamp: DateTime.now(),
      severity: ErrorSeverity.high,
      context: context ?? 'Database Operation',
      userAction: 'Please restart the app. If the problem persists, contact support.',
    );
    
    _recordError(appError);
  }

  /// Handle authentication errors
  Future<void> handleAuthError(dynamic error, {String? context}) async {
    var message = 'Authentication failed';
    var userAction = 'Please check your credentials and try again.';
    
    if (error.toString().contains('invalid_credentials')) {
      message = 'Invalid username or password';
      userAction = 'Please check your credentials and try again.';
    } else if (error.toString().contains('account_locked')) {
      message = 'Account temporarily locked';
      userAction = 'Your account has been temporarily locked. Please try again later.';
    } else if (error.toString().contains('session_expired')) {
      message = 'Session expired';
      userAction = 'Your session has expired. Please log in again.';
    }
    
    final appError = AppError(
      type: ErrorType.authentication,
      message: message,
      stackTrace: error.toString(),
      timestamp: DateTime.now(),
      severity: ErrorSeverity.medium,
      context: context ?? 'Authentication',
      userAction: userAction,
    );
    
    _recordError(appError);
  }

  /// Handle validation errors
  Future<void> handleValidationError(String message, {String? context}) async {
    final appError = AppError(
      type: ErrorType.validation,
      message: message,
      stackTrace: '',
      timestamp: DateTime.now(),
      severity: ErrorSeverity.low,
      context: context ?? 'Validation',
      userAction: 'Please correct the highlighted fields and try again.',
    );
    
    _recordError(appError);
  }

  /// Handle business logic errors
  Future<void> handleBusinessError(String message, {String? context, String? userAction}) async {
    final appError = AppError(
      type: ErrorType.business,
      message: message,
      stackTrace: '',
      timestamp: DateTime.now(),
      severity: ErrorSeverity.medium,
      context: context ?? 'Business Logic',
      userAction: userAction ?? 'Please review your input and try again.',
    );
    
    _recordError(appError);
  }

  /// Record error in history and notify listeners
  void _recordError(AppError error) {
    _errorHistory.add(error);
    
    // Keep only last 100 errors
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }
    
    // Notify listeners
    _errorStreamController.add(error);
    
    // Log error
    if (kDebugMode) {
      debugPrint('ErrorHandlingService: ${error.type.name} - ${error.message}');
    }
    
    // Report error if enabled
    if (_enableErrorReporting) {
      _reportError(error);
    }
  }

  /// Report error to external service (analytics, crash reporting, etc.)
  void _reportError(AppError error) {
    // In a real app, you would send this to Firebase Crashlytics, Sentry, etc.
    if (kDebugMode) {
      debugPrint('ErrorHandlingService: Reporting error - ${error.message}');
    }
    
    // Enhanced error reporting with structured data
    _logErrorToFile(error);
    
    // Report critical errors immediately
    if (error.severity == ErrorSeverity.critical) {
      _reportCriticalError(error);
    }
  }

  /// Log error to local file for debugging
  void _logErrorToFile(AppError error) {
    try {
      final errorLog = {
        'timestamp': error.timestamp.toIso8601String(),
        'type': error.type.name,
        'severity': error.severity.name,
        'message': error.message,
        'context': error.context,
        'stackTrace': error.stackTrace,
        'userAction': error.userAction,
      };
      
      // In production, this would write to a secure log file
      if (kDebugMode) {
        debugPrint('Error Log: ${errorLog.toString()}');
      }
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Report critical errors to external services
  void _reportCriticalError(AppError error) {
    // In production, this would send to crash reporting service
    if (kDebugMode) {
      debugPrint('CRITICAL ERROR: ${error.message}');
    }
  }

  /// Determine error severity based on exception type
  ErrorSeverity _determineSeverity(dynamic exception) {
    if (exception is OutOfMemoryError || exception is StackOverflowError) {
      return ErrorSeverity.critical;
    } else if (exception is StateError || exception is ArgumentError) {
      return ErrorSeverity.high;
    } else if (exception is FormatException || exception is RangeError) {
      return ErrorSeverity.medium;
    } else {
      return ErrorSeverity.low;
    }
  }

  /// Suggest user action based on exception type
  String _suggestUserAction(dynamic exception) {
    if (exception is OutOfMemoryError) {
      return 'Please close other apps and restart this app.';
    } else if (exception is StateError) {
      return 'Please restart the app and try again.';
    } else if (exception is FormatException) {
      return 'Please check your input format and try again.';
    } else {
      return 'Please try again. If the problem persists, contact support.';
    }
  }

  /// Show error dialog to user
  Future<void> showErrorDialog(BuildContext context, AppError error) async {
    if (!_enableUserFeedback) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getErrorIcon(error.type),
                color: _getErrorColor(error.severity),
              ),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error.message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (error.userAction.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  error.userAction,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            if (error.severity == ErrorSeverity.critical)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // In a real app, you might restart the app or navigate to a safe screen
                },
                child: Text('Restart App'),
              ),
          ],
        );
      },
    );
  }

  /// Get icon for error type
  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.business:
        return Icons.business;
      case ErrorType.framework:
      case ErrorType.platform:
      default:
        return Icons.error;
    }
  }

  /// Get color for error severity
  Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return Colors.red[800]!;
      case ErrorSeverity.high:
        return Colors.red[600]!;
      case ErrorSeverity.medium:
        return Colors.orange[600]!;
      case ErrorSeverity.low:
        return Colors.yellow[700]!;
    }
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Enable/disable error reporting
  void setErrorReporting(bool enabled) {
    _enableErrorReporting = enabled;
  }

  /// Enable/disable user feedback
  void setUserFeedback(bool enabled) {
    _enableUserFeedback = enabled;
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }
}

/// Error types
enum ErrorType {
  network,
  database,
  authentication,
  validation,
  business,
  framework,
  platform,
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// App error model
class AppError {
  final ErrorType type;
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final String context;
  final String userAction;

  AppError({
    required this.type,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    required this.severity,
    required this.context,
    required this.userAction,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'context': context,
      'userAction': userAction,
    };
  }

  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      type: ErrorType.values.firstWhere((e) => e.name == json['type']),
      message: json['message'],
      stackTrace: json['stackTrace'],
      timestamp: DateTime.parse(json['timestamp']),
      severity: ErrorSeverity.values.firstWhere((e) => e.name == json['severity']),
      context: json['context'],
      userAction: json['userAction'],
    );
  }
}
