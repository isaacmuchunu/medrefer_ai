import 'dart:async';
import 'dart:math';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/database/models/notification_models.dart';

/// Advanced Notification Service for enterprise-level notifications
class AdvancedNotificationService extends ChangeNotifier {
  static final AdvancedNotificationService _instance = AdvancedNotificationService._internal();
  factory AdvancedNotificationService() => _instance;
  AdvancedNotificationService._internal();

  late LoggingService _loggingService;
  final List<NotificationModel> _notifications = [];
  final Map<String, NotificationPreferences> _userPreferences = {};
  Timer? _schedulerTimer;
  Timer? _cleanupTimer;

  // Delivery tracking
  final Map<String, NotificationDelivery> _deliveryStatus = {};
  int _totalSent = 0;
  int _totalDelivered = 0;
  int _totalFailed = 0;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      _loggingService = LoggingService();
      
      // Start scheduler for scheduled notifications
      _startScheduler();
      
      // Start cleanup timer for expired notifications
      _startCleanupTimer();
      
      // Load user preferences
      await _loadUserPreferences();
      
      _loggingService.info('Advanced Notification Service initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize Advanced Notification Service', error: e);
      rethrow;
    }
  }

  /// Start scheduler for scheduled notifications
  void _startScheduler() {
    _schedulerTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _processScheduledNotifications();
    });
  }

  /// Start cleanup timer for expired notifications
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(hours: 1), (_) {
      _cleanupExpiredNotifications();
    });
  }

  /// Send notification
  Future<String> sendNotification({
    required String title,
    required String body,
    String type = 'info',
    String category = 'system',
    String priority = 'medium',
    String? userId,
    String? organizationId,
    Map<String, dynamic>? data,
    List<String>? channels,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    String? actionUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notificationId = _generateId();
      
      // Get user preferences if userId is provided
      final preferences = userId != null ? _userPreferences[userId] : null;
      
      // Determine channels based on preferences
      final notificationChannels = channels ?? _getDefaultChannels(preferences, priority);
      
      // Check if notification should be sent based on preferences and quiet hours
      if (!_shouldSendNotification(preferences, priority, scheduledFor)) {
        _loggingService.debug('Notification skipped due to user preferences', 
          context: 'Notifications', metadata: {'user_id': userId, 'priority': priority});
        return notificationId;
      }

      final notification = NotificationModel(
        id: notificationId,
        title: title,
        body: body,
        type: type,
        category: category,
        priority: priority,
        userId: userId,
        organizationId: organizationId,
        data: data ?? {},
        channels: notificationChannels,
        createdAt: DateTime.now(),
        scheduledFor: scheduledFor,
        expiresAt: expiresAt,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
        metadata: metadata ?? {},
      );

      // Add to notifications list
      _notifications.add(notification);

      // Send through configured channels
      await _sendThroughChannels(notification, notificationChannels);

      _loggingService.info('Notification sent', context: 'Notifications', metadata: {
        'notification_id': notificationId,
        'channels': notificationChannels,
        'user_id': userId,
      });

      notifyListeners();
      return notificationId;
    } catch (e) {
      _loggingService.error('Failed to send notification', error: e);
      rethrow;
    }
  }

  /// Send notification using template
  Future<String> sendTemplateNotification({
    required String templateId,
    String? userId,
    String? organizationId,
    Map<String, dynamic>? variables,
    List<String>? channels,
    DateTime? scheduledFor,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // In a real implementation, you would fetch the template from database
      final template = _getTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      // Replace variables in template
      final title = _replaceTemplateVariables(template.titleTemplate, variables ?? {});
      final body = _replaceTemplateVariables(template.bodyTemplate, variables ?? {});

      return await sendNotification(
        title: title,
        body: body,
        type: template.type,
        category: template.category,
        priority: template.defaultPriority,
        userId: userId,
        organizationId: organizationId,
        data: {...template.defaultData, ...?additionalData},
        channels: channels ?? template.defaultChannels,
        scheduledFor: scheduledFor,
      );
    } catch (e) {
      _loggingService.error('Failed to send template notification', error: e);
      rethrow;
    }
  }

  /// Send bulk notifications
  Future<List<String>> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'info',
    String category = 'system',
    String priority = 'medium',
    Map<String, dynamic>? data,
    List<String>? channels,
    DateTime? scheduledFor,
  }) async {
    final notificationIds = <String>[];
    
    for (final userId in userIds) {
      try {
        final id = await sendNotification(
          title: title,
          body: body,
          type: type,
          category: category,
          priority: priority,
          userId: userId,
          data: data,
          channels: channels,
          scheduledFor: scheduledFor,
        );
        notificationIds.add(id);
      } catch (e) {
        _loggingService.error('Failed to send bulk notification to user $userId', error: e);
      }
    }

    _loggingService.info('Bulk notifications sent', context: 'Notifications', metadata: {
      'total_users': userIds.length,
      'successful': notificationIds.length,
    });

    return notificationIds;
  }

  /// Get notifications for user
  List<NotificationModel> getUserNotifications(
    String userId, {
    bool includeArchived = false,
    String? category,
    String? type,
    int limit = 50,
  }) {
    return _notifications
        .where((notification) {
          if (notification.userId != userId && notification.userId != null) return false;
          if (!includeArchived && notification.isArchived) return false;
          if (category != null && notification.category != category) return false;
          if (type != null && notification.type != type) return false;
          if (notification.expiresAt != null && notification.expiresAt!.isBefore(DateTime.now())) {
            return false;
          }
          return true;
        })
        .take(limit)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      
      _loggingService.debug('Notification marked as read', 
        context: 'Notifications', metadata: {'notification_id': notificationId});
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isArchived: true);
      notifyListeners();
      
      _loggingService.debug('Notification archived', 
        context: 'Notifications', metadata: {'notification_id': notificationId});
    }
  }

  /// Get unread count for user
  int getUnreadCount(String userId) {
    return _notifications.where((notification) {
      return notification.userId == userId && 
             !notification.isRead && 
             !notification.isArchived &&
             (notification.expiresAt == null || notification.expiresAt!.isAfter(DateTime.now()));
    }).length;
  }

  /// Update user notification preferences
  Future<void> updateUserPreferences(NotificationPreferences preferences) async {
    _userPreferences[preferences.userId] = preferences;
    
    _loggingService.info('User notification preferences updated', 
      context: 'Notifications', metadata: {'user_id': preferences.userId});
  }

  /// Get user notification preferences
  NotificationPreferences? getUserPreferences(String userId) {
    return _userPreferences[userId];
  }

  /// Process scheduled notifications
  Future<void> _processScheduledNotifications() async {
    final now = DateTime.now();
    
    for (final notification in _notifications) {
      if (notification.scheduledFor != null && 
          notification.scheduledFor!.isBefore(now) &&
          !_deliveryStatus.containsKey(notification.id)) {
        
        await _sendThroughChannels(notification, notification.channels);
      }
    }
  }

  /// Cleanup expired notifications
  void _cleanupExpiredNotifications() {
    final now = DateTime.now();
    final initialCount = _notifications.length;
    
    _notifications.removeWhere((notification) {
      return notification.expiresAt != null && notification.expiresAt!.isBefore(now);
    });

    final removedCount = initialCount - _notifications.length;
    if (removedCount > 0) {
      _loggingService.debug('Cleaned up expired notifications', 
        context: 'Notifications', metadata: {'removed_count': removedCount});
    }
  }

  /// Send notification through channels
  Future<void> _sendThroughChannels(NotificationModel notification, List<String> channels) async {
    for (final channel in channels) {
      try {
        await _sendThroughChannel(notification, channel);
      } catch (e) {
        _loggingService.error('Failed to send notification through channel $channel', error: e);
        _trackDelivery(notification.id, channel, 'failed', errorMessage: e.toString());
      }
    }
  }

  /// Send notification through specific channel
  Future<void> _sendThroughChannel(NotificationModel notification, String channel) async {
    switch (channel) {
      case 'push':
        await _sendPushNotification(notification);
        break;
      case 'email':
        await _sendEmailNotification(notification);
        break;
      case 'sms':
        await _sendSMSNotification(notification);
        break;
      case 'in_app':
        await _sendInAppNotification(notification);
        break;
      default:
        _loggingService.warning('Unknown notification channel: $channel');
    }
  }

  /// Send push notification
  Future<void> _sendPushNotification(NotificationModel notification) async {
    // In a real implementation, you would integrate with Firebase Cloud Messaging
    _loggingService.debug('Sending push notification', 
      context: 'Notifications', metadata: {'notification_id': notification.id});
    
    // Simulate sending
    await Future.delayed(Duration(milliseconds: 100));
    _trackDelivery(notification.id, 'push', 'sent');
    _totalSent++;
  }

  /// Send email notification
  Future<void> _sendEmailNotification(NotificationModel notification) async {
    // In a real implementation, you would integrate with email service
    _loggingService.debug('Sending email notification', 
      context: 'Notifications', metadata: {'notification_id': notification.id});
    
    // Simulate sending
    await Future.delayed(Duration(milliseconds: 200));
    _trackDelivery(notification.id, 'email', 'sent');
    _totalSent++;
  }

  /// Send SMS notification
  Future<void> _sendSMSNotification(NotificationModel notification) async {
    // In a real implementation, you would integrate with SMS service
    _loggingService.debug('Sending SMS notification', 
      context: 'Notifications', metadata: {'notification_id': notification.id});
    
    // Simulate sending
    await Future.delayed(Duration(milliseconds: 150));
    _trackDelivery(notification.id, 'sms', 'sent');
    _totalSent++;
  }

  /// Send in-app notification
  Future<void> _sendInAppNotification(NotificationModel notification) async {
    // In-app notifications are handled by the UI
    _trackDelivery(notification.id, 'in_app', 'delivered');
    _totalDelivered++;
  }

  /// Track notification delivery
  void _trackDelivery(String notificationId, String channel, String status, {String? errorMessage}) {
    final delivery = NotificationDelivery(
      id: _generateId(),
      notificationId: notificationId,
      channel: channel,
      status: status,
      sentAt: status == 'sent' ? DateTime.now() : null,
      deliveredAt: status == 'delivered' ? DateTime.now() : null,
      failedAt: status == 'failed' ? DateTime.now() : null,
      errorMessage: errorMessage,
      createdAt: DateTime.now(),
    );

    _deliveryStatus['${notificationId}_$channel'] = delivery;

    if (status == 'delivered') {
      _totalDelivered++;
    } else if (status == 'failed') {
      _totalFailed++;
    }
  }

  /// Get default channels based on preferences and priority
  List<String> _getDefaultChannels(NotificationPreferences? preferences, String priority) {
    if (preferences == null) {
      return ['in_app'];
    }

    final channels = <String>[];
    
    if (preferences.enableInApp) channels.add('in_app');
    if (preferences.enablePush && (priority == 'high' || priority == 'critical')) channels.add('push');
    if (preferences.enableEmail && (priority == 'medium' || priority == 'high' || priority == 'critical')) channels.add('email');
    if (preferences.enableSMS && priority == 'critical') channels.add('sms');

    return channels.isEmpty ? ['in_app'] : channels;
  }

  /// Check if notification should be sent based on preferences
  bool _shouldSendNotification(NotificationPreferences? preferences, String priority, DateTime? scheduledFor) {
    if (preferences == null) return true;

    // Check quiet hours
    if (scheduledFor == null && _isQuietHours(preferences)) {
      return priority == 'critical';
    }

    // Check category preferences
    // Check type preferences
    // Check channel preferences

    return true;
  }

  /// Check if current time is within quiet hours
  bool _isQuietHours(NotificationPreferences preferences) {
    final now = DateTime.now();
    final currentDay = now.weekday.toString();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Check if current day is in quiet days
    if (preferences.quietDays.contains(currentDay)) {
      return true;
    }

    // Check if current time is within quiet hours
    return _isTimeInRange(currentTime, preferences.quietHoursStart, preferences.quietHoursEnd);
  }

  /// Check if time is within range
  bool _isTimeInRange(String time, String start, String end) {
    final timeMinutes = _timeToMinutes(time);
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);

    if (startMinutes <= endMinutes) {
      return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }
  }

  /// Convert time string to minutes
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    // In a real implementation, you would load from database
    // For now, we'll create default preferences
  }

  /// Get template by ID
  NotificationTemplate? _getTemplate(String templateId) {
    // In a real implementation, you would fetch from database
    return null;
  }

  /// Replace template variables
  String _replaceTemplateVariables(String template, Map<String, dynamic> variables) {
    var result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  /// Get notification statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_notifications': _notifications.length,
      'unread_notifications': _notifications.where((n) => !n.isRead).length,
      'archived_notifications': _notifications.where((n) => n.isArchived).length,
      'total_sent': _totalSent,
      'total_delivered': _totalDelivered,
      'total_failed': _totalFailed,
      'delivery_rate': _totalSent > 0 ? (_totalDelivered / _totalSent) * 100 : 0.0,
    };
  }

  /// Dispose resources
  @override
  void dispose() {
    _schedulerTimer?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }
}