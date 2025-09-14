import 'package:medrefer_ai/core/app_export.dart';

/// Notification model for managing all types of notifications
class NotificationModel extends BaseModel {
  final String id;
  final String title;
  final String body;
  final String type; // info, warning, error, success, urgent
  final String category; // system, referral, appointment, payment, security
  final String priority; // low, medium, high, critical
  final String? userId;
  final String? organizationId;
  final Map<String, dynamic> data;
  final List<String> channels; // push, email, sms, in_app
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
  final String? actionUrl;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    required this.priority,
    this.userId,
    this.organizationId,
    this.data = const {},
    this.channels = const ['in_app'],
    this.isRead = false,
    this.isArchived = false,
    required this.createdAt,
    this.scheduledFor,
    this.expiresAt,
    this.actionUrl,
    this.imageUrl,
    this.metadata = const {},
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'priority': priority,
      'user_id': userId,
      'organization_id': organizationId,
      'data': jsonEncode(data),
      'channels': jsonEncode(channels),
      'is_read': isRead ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'action_url': actionUrl,
      'image_url': imageUrl,
      'metadata': jsonEncode(metadata),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info',
      category: map['category'] ?? 'system',
      priority: map['priority'] ?? 'medium',
      userId: map['user_id'],
      organizationId: map['organization_id'],
      data: map['data'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['data'])) 
          : {},
      channels: map['channels'] != null 
          ? List<String>.from(jsonDecode(map['channels'])) 
          : ['in_app'],
      isRead: (map['is_read'] ?? 0) == 1,
      isArchived: (map['is_archived'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      scheduledFor: map['scheduled_for'] != null 
          ? DateTime.parse(map['scheduled_for']) 
          : null,
      expiresAt: map['expires_at'] != null 
          ? DateTime.parse(map['expires_at']) 
          : null,
      actionUrl: map['action_url'],
      imageUrl: map['image_url'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? category,
    String? priority,
    String? userId,
    String? organizationId,
    Map<String, dynamic>? data,
    List<String>? channels,
    bool? isRead,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    String? actionUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      data: data ?? this.data,
      channels: channels ?? this.channels,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      expiresAt: expiresAt ?? this.expiresAt,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Notification template model
class NotificationTemplate extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final String category;
  final String titleTemplate;
  final String bodyTemplate;
  final List<String> defaultChannels;
  final String defaultPriority;
  final Map<String, dynamic> defaultData;
  final Map<String, dynamic> variables;
  final bool isActive;
  final String? userId;
  final String? organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.defaultChannels,
    required this.defaultPriority,
    this.defaultData = const {},
    this.variables = const {},
    this.isActive = true,
    this.userId,
    this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'category': category,
      'title_template': titleTemplate,
      'body_template': bodyTemplate,
      'default_channels': jsonEncode(defaultChannels),
      'default_priority': defaultPriority,
      'default_data': jsonEncode(defaultData),
      'variables': jsonEncode(variables),
      'is_active': isActive ? 1 : 0,
      'user_id': userId,
      'organization_id': organizationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotificationTemplate.fromMap(Map<String, dynamic> map) {
    return NotificationTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'info',
      category: map['category'] ?? 'system',
      titleTemplate: map['title_template'] ?? '',
      bodyTemplate: map['body_template'] ?? '',
      defaultChannels: map['default_channels'] != null 
          ? List<String>.from(jsonDecode(map['default_channels'])) 
          : ['in_app'],
      defaultPriority: map['default_priority'] ?? 'medium',
      defaultData: map['default_data'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['default_data'])) 
          : {},
      variables: map['variables'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['variables'])) 
          : {},
      isActive: (map['is_active'] ?? 1) == 1,
      userId: map['user_id'],
      organizationId: map['organization_id'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Notification preferences model
class NotificationPreferences extends BaseModel {
  final String id;
  final String userId;
  final String? organizationId;
  final Map<String, bool> channelPreferences;
  final Map<String, bool> categoryPreferences;
  final Map<String, bool> typePreferences;
  final bool enablePush;
  final bool enableEmail;
  final bool enableSMS;
  final bool enableInApp;
  final bool enableScheduledNotifications;
  final String quietHoursStart;
  final String quietHoursEnd;
  final List<String> quietDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    this.organizationId,
    this.channelPreferences = const {},
    this.categoryPreferences = const {},
    this.typePreferences = const {},
    this.enablePush = true,
    this.enableEmail = true,
    this.enableSMS = false,
    this.enableInApp = true,
    this.enableScheduledNotifications = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietDays = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'organization_id': organizationId,
      'channel_preferences': jsonEncode(channelPreferences),
      'category_preferences': jsonEncode(categoryPreferences),
      'type_preferences': jsonEncode(typePreferences),
      'enable_push': enablePush ? 1 : 0,
      'enable_email': enableEmail ? 1 : 0,
      'enable_sms': enableSMS ? 1 : 0,
      'enable_in_app': enableInApp ? 1 : 0,
      'enable_scheduled_notifications': enableScheduledNotifications ? 1 : 0,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'quiet_days': jsonEncode(quietDays),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      organizationId: map['organization_id'],
      channelPreferences: map['channel_preferences'] != null 
          ? Map<String, bool>.from(jsonDecode(map['channel_preferences'])) 
          : {},
      categoryPreferences: map['category_preferences'] != null 
          ? Map<String, bool>.from(jsonDecode(map['category_preferences'])) 
          : {},
      typePreferences: map['type_preferences'] != null 
          ? Map<String, bool>.from(jsonDecode(map['type_preferences'])) 
          : {},
      enablePush: (map['enable_push'] ?? 1) == 1,
      enableEmail: (map['enable_email'] ?? 1) == 1,
      enableSMS: (map['enable_sms'] ?? 0) == 1,
      enableInApp: (map['enable_in_app'] ?? 1) == 1,
      enableScheduledNotifications: (map['enable_scheduled_notifications'] ?? 1) == 1,
      quietHoursStart: map['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: map['quiet_hours_end'] ?? '08:00',
      quietDays: map['quiet_days'] != null 
          ? List<String>.from(jsonDecode(map['quiet_days'])) 
          : [],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Notification delivery status model
class NotificationDelivery extends BaseModel {
  final String id;
  final String notificationId;
  final String channel;
  final String status; // pending, sent, delivered, failed, bounced
  final String? recipient;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final String? errorMessage;
  final Map<String, dynamic> deliveryData;
  final DateTime createdAt;

  NotificationDelivery({
    required this.id,
    required this.notificationId,
    required this.channel,
    required this.status,
    this.recipient,
    this.sentAt,
    this.deliveredAt,
    this.failedAt,
    this.errorMessage,
    this.deliveryData = const {},
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_id': notificationId,
      'channel': channel,
      'status': status,
      'recipient': recipient,
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'failed_at': failedAt?.toIso8601String(),
      'error_message': errorMessage,
      'delivery_data': jsonEncode(deliveryData),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationDelivery.fromMap(Map<String, dynamic> map) {
    return NotificationDelivery(
      id: map['id'] ?? '',
      notificationId: map['notification_id'] ?? '',
      channel: map['channel'] ?? '',
      status: map['status'] ?? 'pending',
      recipient: map['recipient'],
      sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
      deliveredAt: map['delivered_at'] != null ? DateTime.parse(map['delivered_at']) : null,
      failedAt: map['failed_at'] != null ? DateTime.parse(map['failed_at']) : null,
      errorMessage: map['error_message'],
      deliveryData: map['delivery_data'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['delivery_data'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}