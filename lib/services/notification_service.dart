import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing notifications and alerts in the MedRefer AI app
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification state
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isInitialized = false;

  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load existing notifications
      await _loadNotifications();
      
      // Setup periodic cleanup
      _setupPeriodicCleanup();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('NotificationService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Add a new notification
  Future<void> addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? actionRoute,
    Map<String, dynamic>? data,
    Duration? autoRemoveAfter,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      data: data,
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    
    // Auto-remove if specified
    if (autoRemoveAfter != null) {
      Future.delayed(autoRemoveAfter, () {
        removeNotification(notification.id);
      });
    }
    
    // Trigger haptic feedback for important notifications
    if (type == NotificationType.urgent || type == NotificationType.error) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
    
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('NotificationService: Added notification - $title');
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  /// Remove a notification
  void removeNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      if (!_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get urgent notifications
  List<AppNotification> getUrgentNotifications() {
    return _notifications.where((n) => n.type == NotificationType.urgent).toList();
  }

  /// Show system notification (for urgent alerts)
  Future<void> showSystemNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    // Add to internal notifications
    await addNotification(
      title: title,
      message: message,
      type: type,
    );
    
    // In a real app, you would integrate with firebase_messaging or local_notifications
    // For now, we'll just log it
    if (kDebugMode) {
      debugPrint('System Notification: $title - $message');
    }
  }

  /// Load notifications from storage
  Future<void> _loadNotifications() async {
    // In a real app, you would load from local storage or database
    // For now, we'll start with empty notifications
    _notifications = [];
    _unreadCount = 0;
  }

  /// Setup periodic cleanup of old notifications
  void _setupPeriodicCleanup() {
    // Clean up notifications older than 30 days every hour
    Timer.periodic(const Duration(hours: 1), (timer) {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final initialCount = _notifications.length;
      
      _notifications.removeWhere((notification) => 
        notification.timestamp.isBefore(cutoffDate));
      
      if (_notifications.length != initialCount) {
        _recalculateUnreadCount();
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('NotificationService: Cleaned up ${initialCount - _notifications.length} old notifications');
        }
      }
    });
  }

  /// Recalculate unread count
  void _recalculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> sendTaskAssignment({required String assigneeId, required String taskName, required String workflowName, required String patientId, required String priority, DateTime? dueDate}) async {
    // Implement sending task assignment notification
  }

  Future<void> sendWorkflowCompletion({required String workflowName, required String patientId, required DateTime completedAt}) async {
    // Implement sending workflow completion notification
  }

  Future<void> sendWorkflowTimeout({required String workflowName, required String patientId, required DateTime dueDate}) async {
    // Implement sending workflow timeout notification
  }

  Future<void> sendCriticalFindingAlert({
    required String title,
    required String message,
    required String patientId,
    required String priority,
    required Map<String, dynamic> metadata,
  }) async {
    // Implement sending critical finding alert
  }

  Future<void> sendTaskTimeout({required String taskName, String? assignedTo, required DateTime dueDate}) async {
    // Implement sending task timeout notification
  }

  /// Send a critical alert notification
  Future<void> sendCriticalAlert({
    required String title,
    required String message,
    required String patientId,
    required double riskLevel,
  }) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.urgent,
      data: {
        'patientId': patientId,
        'riskLevel': riskLevel,
        'alertType': 'critical',
      },
    );

    // Also show system notification
    await showSystemNotification(
      title: title,
      message: message,
      type: NotificationType.urgent,
    );
  }

  /// Send a regular alert notification
  Future<void> sendAlert({
    required String title,
    required String message,
    required String patientId,
    String? priority,
    Map<String, dynamic>? metadata,
  }) async {
    // Determine notification type based on priority
    NotificationType type = NotificationType.warning;
    if (priority == 'high') {
      type = NotificationType.urgent;
    } else if (priority == 'medium') {
      type = NotificationType.warning;
    }

    await addNotification(
      title: title,
      message: message,
      type: type,
      data: {
        'patientId': patientId,
        'alertType': 'regular',
        'priority': priority,
        ...?metadata,
      },
    );
  }

  @override
  void dispose() {
    // Clean up any timers or listeners
    super.dispose();
  }
}

/// Notification types
enum NotificationType {
  info,
  success,
  warning,
  error,
  urgent,
  referral,
  referralUpdate,
  message,
  appointment,
  emergency,
}

/// App notification model
class AppNotification {
  factory AppNotification({
    required String id,
    required String title,
    required String message,
    required NotificationType type,
    required DateTime timestamp,
    bool isRead = false,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) {
    return AppNotification._internal(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead,
      actionRoute: actionRoute,
      data: data,
    );
  }
  const AppNotification._internal({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.data,
  });
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? data;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
    );
  }

  /// Get icon for notification type
  IconData get icon {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.urgent:
        return Icons.priority_high;
      case NotificationType.referral:
        return Icons.assignment_outlined;
      case NotificationType.referralUpdate:
        return Icons.assignment_turned_in;
      case NotificationType.message:
        return Icons.message_outlined;
      case NotificationType.appointment:
        return Icons.event_outlined;
    }
  }

  /// Get color for notification type
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case NotificationType.info:
        return theme.colorScheme.primary;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return theme.colorScheme.error;
      case NotificationType.urgent:
        return Colors.red;
      case NotificationType.referral:
        return theme.colorScheme.secondary;
      case NotificationType.referralUpdate:
        return theme.colorScheme.primary;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.appointment:
        return Colors.purple;
    }
    return Colors.grey;
  }
}
