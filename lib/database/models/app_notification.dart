import 'base_model.dart';

enum AppNotificationType { referralUpdate, message, emergency, appointment, system }
enum AppNotificationPriority { low, medium, high, critical }

class AppNotificationModel extends BaseModel {
  final String title;
  final String message;
  final AppNotificationType type;
  final AppNotificationPriority priority;
  final String? userId;
  final String? actionRoute;
  final Map<String, dynamic> data;
  final bool isRead;

  AppNotificationModel({
    super.id,
    required this.title,
    required this.message,
    this.type = AppNotificationType.system,
    this.priority = AppNotificationPriority.medium,
    this.userId,
    this.actionRoute,
    this.data = const {},
    this.isRead = false,
    super.createdAt,
    super.updatedAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: AppNotificationType.values.firstWhere((e) => e.name == map['type'], orElse: () => AppNotificationType.system),
      priority: AppNotificationPriority.values.firstWhere((e) => e.name == map['priority'], orElse: () => AppNotificationPriority.medium),
      userId: map['user_id'],
      actionRoute: map['action_route'],
      data: const {},
      isRead: (map['is_read'] ?? 0) == 1,
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'user_id': userId,
      'action_route': actionRoute,
      'is_read': isRead ? 1 : 0,
    });
    return map;
  }
}

