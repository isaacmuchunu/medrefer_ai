import 'base_model.dart';

enum AuditEventType { authentication, dataAccess, system, security, compliance }
enum AuditRiskLevel { low, medium, high, critical }

class AuditLog extends BaseModel {
  final AuditEventType eventType;
  final String userId;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? ipAddress;
  final AuditRiskLevel riskLevel;
  final Map<String, dynamic> metadata;
  final String? sessionId;

  AuditLog({
    super.id,
    required this.eventType,
    required this.userId,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.ipAddress,
    this.riskLevel = AuditRiskLevel.low,
    this.metadata = const {},
    this.sessionId,
    super.createdAt,
    super.updatedAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      eventType: AuditEventType.values.firstWhere((e) => e.name == map['event_type'], orElse: () => AuditEventType.system),
      userId: map['user_id'] ?? 'system',
      action: map['action'] ?? '',
      resourceType: map['resource_type'],
      resourceId: map['resource_id'],
      ipAddress: map['ip_address'],
      riskLevel: AuditRiskLevel.values.firstWhere((e) => e.name == map['risk_level'], orElse: () => AuditRiskLevel.low),
      metadata: const {},
      sessionId: map['session_id'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'event_type': eventType.name,
      'user_id': userId,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'ip_address': ipAddress,
      'risk_level': riskLevel.name,
      'session_id': sessionId,
    });
    return map;
  }
}

