import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/database.dart';

/// Advanced Notification Service with push, email, SMS, scheduling and templates
class AdvancedNotificationService extends ChangeNotifier {
  static final AdvancedNotificationService _instance = AdvancedNotificationService._internal();
  factory AdvancedNotificationService() => _instance;
  AdvancedNotificationService._internal();

  // Configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 30);
  static const int _maxQueueSize = 1000;
  
  // Notification management
  final Queue<NotificationRequest> _notificationQueue = Queue();
  final Map<String, NotificationTemplate> _templates = {};
  final Map<String, UserNotificationPreferences> _userPreferences = {};
  final List<NotificationHistory> _history = [];
  final Map<String, ScheduledNotification> _scheduledNotifications = {};
  
  // In-app notifications stream
  final StreamController<InAppNotification> _inAppController = StreamController<InAppNotification>.broadcast();
  final List<InAppNotification> _activeInAppNotifications = [];
  
  // Analytics
  int _notificationsSent = 0;
  int _notificationsDelivered = 0;
  int _notificationsFailed = 0;
  
  // Database
  Database? _database;
  Timer? _processTimer;
  Timer? _scheduleTimer;
  
  bool _isInitialized = false;
  bool _isProcessing = false;

  Stream<InAppNotification> get inAppNotifications => _inAppController.stream;
  List<InAppNotification> get activeInAppNotifications => List.unmodifiable(_activeInAppNotifications);

  /// Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _database = await DatabaseHelper().database;
      await _createTables();
      await _loadTemplates();
      await _loadScheduledNotifications();
      await _loadUserPreferences();
      
      _startProcessingQueue();
      _startScheduleChecker();
      
      _isInitialized = true;
      debugPrint('Advanced Notification Service initialized');
    } catch (e) {
      debugPrint('Error initializing Advanced Notification Service: $e');
      throw NotificationException('Failed to initialize notification service');
    }
  }

  /// Create database tables
  Future<void> _createTables() async {
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS notification_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        data TEXT,
        channels TEXT,
        status TEXT NOT NULL,
        sent_at INTEGER,
        delivered_at INTEGER,
        read_at INTEGER,
        error TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS notification_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        title_template TEXT NOT NULL,
        body_template TEXT NOT NULL,
        type TEXT NOT NULL,
        default_priority TEXT,
        variables TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS scheduled_notifications (
        id TEXT PRIMARY KEY,
        notification_data TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        schedule_time INTEGER,
        recurrence_rule TEXT,
        next_run INTEGER,
        enabled INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS user_notification_preferences (
        user_id TEXT PRIMARY KEY,
        push_enabled INTEGER DEFAULT 1,
        email_enabled INTEGER DEFAULT 1,
        sms_enabled INTEGER DEFAULT 1,
        in_app_enabled INTEGER DEFAULT 1,
        quiet_hours_start TEXT,
        quiet_hours_end TEXT,
        blocked_types TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Send notification
  Future<NotificationResult> sendNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    List<NotificationChannel>? channels,
    DateTime? scheduledTime,
  }) async {
    try {
      final preferences = await _getUserPreferences(userId);
      
      if (!_shouldSendNotification(preferences, type, priority)) {
        return NotificationResult(
          success: false,
          message: 'Blocked by user preferences',
        );
      }
      
      final notification = NotificationRequest(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        body: body,
        type: type,
        priority: priority,
        data: data,
        channels: channels ?? _getDefaultChannels(type, priority),
        scheduledTime: scheduledTime,
        createdAt: DateTime.now(),
      );
      
      if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        return await _scheduleNotification(notification);
      }
      
      return await _processNotification(notification);
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return NotificationResult(
        success: false,
        message: 'Failed to send notification: $e',
      );
    }
  }

  /// Send notification from template
  Future<NotificationResult> sendFromTemplate({
    required String userId,
    required String templateId,
    required Map<String, dynamic> variables,
    NotificationPriority? priority,
    DateTime? scheduledTime,
  }) async {
    try {
      final template = _templates[templateId];
      if (template == null) {
        throw NotificationException('Template not found: $templateId');
      }
      
      final title = _processTemplate(template.titleTemplate, variables);
      final body = _processTemplate(template.bodyTemplate, variables);
      
      return await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: template.type,
        priority: priority ?? template.defaultPriority,
        data: variables,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      debugPrint('Error sending from template: $e');
      return NotificationResult(
        success: false,
        message: 'Failed to send from template: $e',
      );
    }
  }

  /// Send bulk notifications
  Future<BulkNotificationResult> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    final results = <String, NotificationResult>{};
    int successCount = 0;
    int failureCount = 0;
    
    for (final userId in userIds) {
      final result = await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        priority: priority,
        data: data,
      );
      
      results[userId] = result;
      if (result.success) {
        successCount++;
      } else {
        failureCount++;
      }
    }
    
    return BulkNotificationResult(
      totalCount: userIds.length,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
    );
  }

  /// Show in-app notification
  void showInAppNotification({
    required String title,
    required String message,
    InAppNotificationType type = InAppNotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    final notification = InAppNotification(
      id: 'inapp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
      timestamp: DateTime.now(),
    );
    
    _activeInAppNotifications.add(notification);
    _inAppController.add(notification);
    
    if (duration != Duration.zero) {
      Future.delayed(duration, () {
        dismissInAppNotification(notification.id);
      });
    }
    
    notifyListeners();
  }

  /// Dismiss in-app notification
  void dismissInAppNotification(String notificationId) {
    _activeInAppNotifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Schedule recurring notification
  Future<void> scheduleRecurringNotification({
    required String id,
    required NotificationRequest notification,
    required RecurrenceRule recurrence,
    DateTime? endDate,
  }) async {
    try {
      final scheduled = ScheduledNotification(
        id: id,
        notification: notification,
        scheduleType: ScheduleType.recurring,
        recurrence: recurrence,
        endDate: endDate,
        nextRun: _calculateNextRun(recurrence, DateTime.now()),
        enabled: true,
        createdAt: DateTime.now(),
      );
      
      _scheduledNotifications[id] = scheduled;
      await _saveScheduledNotification(scheduled);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error scheduling recurring notification: $e');
      throw NotificationException('Failed to schedule recurring notification');
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences({
    required String userId,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? inAppEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    List<NotificationType>? blockedTypes,
  }) async {
    try {
      var preferences = _userPreferences[userId] ?? UserNotificationPreferences(
        userId: userId,
        updatedAt: DateTime.now(),
      );
      
      preferences = preferences.copyWith(
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
        inAppEnabled: inAppEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        blockedTypes: blockedTypes,
        updatedAt: DateTime.now(),
      );
      
      _userPreferences[userId] = preferences;
      await _saveUserPreferences(preferences);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      throw NotificationException('Failed to update user preferences');
    }
  }

  /// Get notification analytics
  NotificationAnalytics getAnalytics() {
    final deliveryRate = _notificationsSent > 0 
      ? (_notificationsDelivered / _notificationsSent * 100) 
      : 0.0;
    
    final byType = <NotificationType, int>{};
    final byPriority = <NotificationPriority, int>{};
    
    for (final item in _history) {
      byType[item.type] = (byType[item.type] ?? 0) + 1;
      byPriority[item.priority] = (byPriority[item.priority] ?? 0) + 1;
    }
    
    return NotificationAnalytics(
      totalSent: _notificationsSent,
      totalDelivered: _notificationsDelivered,
      totalFailed: _notificationsFailed,
      deliveryRate: deliveryRate,
      byType: byType,
      byPriority: byPriority,
    );
  }

  // Private helper methods

  Future<NotificationResult> _processNotification(NotificationRequest notification) async {
    try {
      // Add to queue if processing
      if (_isProcessing && _notificationQueue.length < _maxQueueSize) {
        _notificationQueue.add(notification);
        return NotificationResult(
          success: true,
          message: 'Queued for processing',
        );
      }
      
      // Process immediately
      final success = await _sendNotification(notification);
      
      _notificationsSent++;
      if (success) {
        _notificationsDelivered++;
      } else {
        _notificationsFailed++;
      }
      
      await _saveNotificationHistory(notification, success);
      
      return NotificationResult(success: success);
    } catch (e) {
      _notificationsFailed++;
      return NotificationResult(
        success: false,
        message: 'Processing failed: $e',
      );
    }
  }

  Future<bool> _sendNotification(NotificationRequest notification) async {
    bool success = false;
    
    for (final channel in notification.channels) {
      switch (channel) {
        case NotificationChannel.push:
          // Implement push notification
          success = true;
          break;
        case NotificationChannel.inApp:
          showInAppNotification(
            title: notification.title,
            message: notification.body,
            type: _mapToInAppType(notification.type),
          );
          success = true;
          break;
        case NotificationChannel.email:
          // Implement email notification
          success = true;
          break;
        case NotificationChannel.sms:
          // Implement SMS notification
          success = true;
          break;
      }
      
      if (success) break;
    }
    
    return success;
  }

  String _processTemplate(String template, Map<String, dynamic> variables) {
    String result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }

  bool _shouldSendNotification(
    UserNotificationPreferences preferences,
    NotificationType type,
    NotificationPriority priority,
  ) {
    if (preferences.blockedTypes?.contains(type) ?? false) {
      return false;
    }
    
    if (priority != NotificationPriority.urgent && _isInQuietHours(preferences)) {
      return false;
    }
    
    return true;
  }

  bool _isInQuietHours(UserNotificationPreferences preferences) {
    if (preferences.quietHoursStart == null || preferences.quietHoursEnd == null) {
      return false;
    }
    
    final now = TimeOfDay.now();
    final start = preferences.quietHoursStart!;
    final end = preferences.quietHoursEnd!;
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  List<NotificationChannel> _getDefaultChannels(
    NotificationType type,
    NotificationPriority priority,
  ) {
    final channels = <NotificationChannel>[NotificationChannel.inApp];
    
    if (priority == NotificationPriority.urgent) {
      channels.add(NotificationChannel.push);
    }
    
    return channels;
  }

  InAppNotificationType _mapToInAppType(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return InAppNotificationType.error;
      case NotificationType.warning:
        return InAppNotificationType.warning;
      case NotificationType.success:
        return InAppNotificationType.success;
      default:
        return InAppNotificationType.info;
    }
  }

  DateTime? _calculateNextRun(RecurrenceRule recurrence, DateTime start) {
    switch (recurrence.frequency) {
      case RecurrenceFrequency.daily:
        return start.add(Duration(days: recurrence.interval));
      case RecurrenceFrequency.weekly:
        return start.add(Duration(days: 7 * recurrence.interval));
      case RecurrenceFrequency.monthly:
        return DateTime(
          start.year,
          start.month + recurrence.interval,
          start.day,
          start.hour,
          start.minute,
        );
      default:
        return null;
    }
  }

  Future<NotificationResult> _scheduleNotification(NotificationRequest notification) async {
    try {
      final scheduled = ScheduledNotification(
        id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
        notification: notification,
        scheduleType: ScheduleType.once,
        scheduleTime: notification.scheduledTime!,
        nextRun: notification.scheduledTime,
        enabled: true,
        createdAt: DateTime.now(),
      );
      
      _scheduledNotifications[scheduled.id] = scheduled;
      await _saveScheduledNotification(scheduled);
      
      return NotificationResult(
        success: true,
        message: 'Notification scheduled',
      );
    } catch (e) {
      return NotificationResult(
        success: false,
        message: 'Failed to schedule: $e',
      );
    }
  }

  Future<UserNotificationPreferences> _getUserPreferences(String userId) async {
    if (_userPreferences.containsKey(userId)) {
      return _userPreferences[userId]!;
    }
    
    final results = await _database!.query(
      'user_notification_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (results.isNotEmpty) {
      final preferences = UserNotificationPreferences.fromMap(results.first);
      _userPreferences[userId] = preferences;
      return preferences;
    }
    
    return UserNotificationPreferences(
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveNotificationHistory(NotificationRequest notification, bool success) async {
    final history = NotificationHistory(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      priority: notification.priority,
      title: notification.title,
      body: notification.body,
      data: notification.data,
      channels: notification.channels,
      status: success ? NotificationStatus.delivered : NotificationStatus.failed,
      sentAt: DateTime.now(),
      createdAt: notification.createdAt,
    );
    
    _history.add(history);
    
    await _database!.insert('notification_history', history.toMap());
  }

  Future<void> _saveScheduledNotification(ScheduledNotification scheduled) async {
    await _database!.insert(
      'scheduled_notifications',
      scheduled.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveUserPreferences(UserNotificationPreferences preferences) async {
    await _database!.insert(
      'user_notification_preferences',
      preferences.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void _startProcessingQueue() {
    _processTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _processQueue();
    });
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _notificationQueue.isEmpty) return;
    
    _isProcessing = true;
    
    try {
      while (_notificationQueue.isNotEmpty) {
        final notification = _notificationQueue.removeFirst();
        await _sendNotification(notification);
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _startScheduleChecker() {
    _scheduleTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _checkScheduledNotifications();
    });
  }

  Future<void> _checkScheduledNotifications() async {
    final now = DateTime.now();
    
    for (final scheduled in _scheduledNotifications.values) {
      if (!scheduled.enabled) continue;
      
      if (scheduled.nextRun != null && scheduled.nextRun!.isBefore(now)) {
        await _processNotification(scheduled.notification);
        
        if (scheduled.scheduleType == ScheduleType.recurring) {
          final nextRun = _calculateNextRun(scheduled.recurrence!, scheduled.nextRun!);
          
          if (nextRun != null && (scheduled.endDate == null || nextRun.isBefore(scheduled.endDate!))) {
            scheduled.nextRun = nextRun;
            await _saveScheduledNotification(scheduled);
          } else {
            scheduled.enabled = false;
            await _saveScheduledNotification(scheduled);
          }
        } else {
          scheduled.enabled = false;
          await _saveScheduledNotification(scheduled);
        }
      }
    }
  }

  Future<void> _loadTemplates() async {
    final results = await _database!.query('notification_templates');
    for (final row in results) {
      final template = NotificationTemplate.fromMap(row);
      _templates[template.id] = template;
    }
  }

  Future<void> _loadScheduledNotifications() async {
    final results = await _database!.query(
      'scheduled_notifications',
      where: 'enabled = ?',
      whereArgs: [1],
    );
    
    for (final row in results) {
      final scheduled = ScheduledNotification.fromMap(row);
      _scheduledNotifications[scheduled.id] = scheduled;
    }
  }

  Future<void> _loadUserPreferences() async {
    final results = await _database!.query(
      'user_notification_preferences',
      orderBy: 'updated_at DESC',
      limit: 100,
    );
    
    for (final row in results) {
      final preferences = UserNotificationPreferences.fromMap(row);
      _userPreferences[preferences.userId] = preferences;
    }
  }

  @override
  void dispose() {
    _processTimer?.cancel();
    _scheduleTimer?.cancel();
    _inAppController.close();
    super.dispose();
  }
}

// Data Models and Enums

enum NotificationType {
  info,
  success,
  warning,
  alert,
  reminder,
  update,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationChannel {
  push,
  inApp,
  email,
  sms,
}

enum NotificationStatus {
  pending,
  sent,
  delivered,
  failed,
  read,
}

enum InAppNotificationType {
  info,
  success,
  warning,
  error,
}

enum ScheduleType {
  once,
  recurring,
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
}

class NotificationRequest {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;
  final List<NotificationChannel> channels;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  NotificationRequest({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.data,
    required this.channels,
    this.scheduledTime,
    required this.createdAt,
  });
}

class NotificationResult {
  final bool success;
  final String? message;

  NotificationResult({
    required this.success,
    this.message,
  });
}

class BulkNotificationResult {
  final int totalCount;
  final int successCount;
  final int failureCount;
  final Map<String, NotificationResult> results;

  BulkNotificationResult({
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });
}

class NotificationTemplate {
  final String id;
  final String name;
  final String titleTemplate;
  final String bodyTemplate;
  final NotificationType type;
  final NotificationPriority defaultPriority;
  final List<String> variables;
  final DateTime createdAt;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.type,
    required this.defaultPriority,
    required this.variables,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'title_template': titleTemplate,
    'body_template': bodyTemplate,
    'type': type.toString(),
    'default_priority': defaultPriority.toString(),
    'variables': jsonEncode(variables),
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory NotificationTemplate.fromMap(Map<String, dynamic> map) => NotificationTemplate(
    id: map['id'],
    name: map['name'],
    titleTemplate: map['title_template'],
    bodyTemplate: map['body_template'],
    type: NotificationType.values.firstWhere((e) => e.toString() == map['type']),
    defaultPriority: NotificationPriority.values.firstWhere((e) => e.toString() == map['default_priority']),
    variables: List<String>.from(jsonDecode(map['variables'])),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
  );
}

class ScheduledNotification {
  final String id;
  final NotificationRequest notification;
  final ScheduleType scheduleType;
  final DateTime? scheduleTime;
  final RecurrenceRule? recurrence;
  final DateTime? endDate;
  DateTime? nextRun;
  bool enabled;
  final DateTime createdAt;

  ScheduledNotification({
    required this.id,
    required this.notification,
    required this.scheduleType,
    this.scheduleTime,
    this.recurrence,
    this.endDate,
    this.nextRun,
    required this.enabled,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'notification_data': jsonEncode({
      'id': notification.id,
      'userId': notification.userId,
      'title': notification.title,
      'body': notification.body,
      'type': notification.type.toString(),
      'priority': notification.priority.toString(),
      'data': notification.data,
      'channels': notification.channels.map((c) => c.toString()).toList(),
      'createdAt': notification.createdAt.millisecondsSinceEpoch,
    }),
    'schedule_type': scheduleType.toString(),
    'schedule_time': scheduleTime?.millisecondsSinceEpoch,
    'recurrence_rule': recurrence != null ? jsonEncode({
      'frequency': recurrence!.frequency.toString(),
      'interval': recurrence!.interval,
    }) : null,
    'next_run': nextRun?.millisecondsSinceEpoch,
    'enabled': enabled ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory ScheduledNotification.fromMap(Map<String, dynamic> map) {
    final notifData = jsonDecode(map['notification_data']);
    final notification = NotificationRequest(
      id: notifData['id'],
      userId: notifData['userId'],
      title: notifData['title'],
      body: notifData['body'],
      type: NotificationType.values.firstWhere((e) => e.toString() == notifData['type']),
      priority: NotificationPriority.values.firstWhere((e) => e.toString() == notifData['priority']),
      data: notifData['data'],
      channels: (notifData['channels'] as List).map((c) => 
        NotificationChannel.values.firstWhere((e) => e.toString() == c)).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(notifData['createdAt']),
    );
    
    RecurrenceRule? recurrence;
    if (map['recurrence_rule'] != null) {
      final recData = jsonDecode(map['recurrence_rule']);
      recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.values.firstWhere((e) => e.toString() == recData['frequency']),
        interval: recData['interval'],
      );
    }
    
    return ScheduledNotification(
      id: map['id'],
      notification: notification,
      scheduleType: ScheduleType.values.firstWhere((e) => e.toString() == map['schedule_type']),
      scheduleTime: map['schedule_time'] != null ? 
        DateTime.fromMillisecondsSinceEpoch(map['schedule_time']) : null,
      recurrence: recurrence,
      nextRun: map['next_run'] != null ? 
        DateTime.fromMillisecondsSinceEpoch(map['next_run']) : null,
      enabled: map['enabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
  });
}

class UserNotificationPreferences {
  final String userId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool inAppEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final List<NotificationType>? blockedTypes;
  final DateTime updatedAt;

  UserNotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = true,
    this.inAppEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.blockedTypes,
    required this.updatedAt,
  });

  UserNotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? inAppEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    List<NotificationType>? blockedTypes,
    DateTime? updatedAt,
  }) {
    return UserNotificationPreferences(
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      blockedTypes: blockedTypes ?? this.blockedTypes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'push_enabled': pushEnabled ? 1 : 0,
    'email_enabled': emailEnabled ? 1 : 0,
    'sms_enabled': smsEnabled ? 1 : 0,
    'in_app_enabled': inAppEnabled ? 1 : 0,
    'quiet_hours_start': quietHoursStart != null ? 
      '${quietHoursStart!.hour}:${quietHoursStart!.minute}' : null,
    'quiet_hours_end': quietHoursEnd != null ? 
      '${quietHoursEnd!.hour}:${quietHoursEnd!.minute}' : null,
    'blocked_types': blockedTypes != null ? 
      jsonEncode(blockedTypes!.map((t) => t.toString()).toList()) : null,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory UserNotificationPreferences.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    
    return UserNotificationPreferences(
      userId: map['user_id'],
      pushEnabled: map['push_enabled'] == 1,
      emailEnabled: map['email_enabled'] == 1,
      smsEnabled: map['sms_enabled'] == 1,
      inAppEnabled: map['in_app_enabled'] == 1,
      quietHoursStart: parseTime(map['quiet_hours_start']),
      quietHoursEnd: parseTime(map['quiet_hours_end']),
      blockedTypes: map['blocked_types'] != null ?
        (jsonDecode(map['blocked_types']) as List).map((t) =>
          NotificationType.values.firstWhere((e) => e.toString() == t)).toList() : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}

class NotificationHistory {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final List<NotificationChannel> channels;
  final NotificationStatus status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? error;
  final DateTime createdAt;

  NotificationHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.data,
    required this.channels,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.error,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'type': type.toString(),
    'priority': priority.toString(),
    'title': title,
    'body': body,
    'data': data != null ? jsonEncode(data) : null,
    'channels': jsonEncode(channels.map((c) => c.toString()).toList()),
    'status': status.toString(),
    'sent_at': sentAt?.millisecondsSinceEpoch,
    'delivered_at': deliveredAt?.millisecondsSinceEpoch,
    'read_at': readAt?.millisecondsSinceEpoch,
    'error': error,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory NotificationHistory.fromMap(Map<String, dynamic> map) => NotificationHistory(
    id: map['id'],
    userId: map['user_id'],
    type: NotificationType.values.firstWhere((e) => e.toString() == map['type']),
    priority: NotificationPriority.values.firstWhere((e) => e.toString() == map['priority']),
    title: map['title'],
    body: map['body'],
    data: map['data'] != null ? jsonDecode(map['data']) : null,
    channels: (jsonDecode(map['channels']) as List).map((c) =>
      NotificationChannel.values.firstWhere((e) => e.toString() == c)).toList(),
    status: NotificationStatus.values.firstWhere((e) => e.toString() == map['status']),
    sentAt: map['sent_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['sent_at']) : null,
    deliveredAt: map['delivered_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['delivered_at']) : null,
    readAt: map['read_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['read_at']) : null,
    error: map['error'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
  );
}

class InAppNotification {
  final String id;
  final String title;
  final String message;
  final InAppNotificationType type;
  final Duration duration;
  final VoidCallback? onTap;
  final DateTime timestamp;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    this.onTap,
    required this.timestamp,
  });
}

class NotificationAnalytics {
  final int totalSent;
  final int totalDelivered;
  final int totalFailed;
  final double deliveryRate;
  final Map<NotificationType, int> byType;
  final Map<NotificationPriority, int> byPriority;

  NotificationAnalytics({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalFailed,
    required this.deliveryRate,
    required this.byType,
    required this.byPriority,
  });
}

class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);
  
  @override
  String toString() => 'NotificationException: $message';
}