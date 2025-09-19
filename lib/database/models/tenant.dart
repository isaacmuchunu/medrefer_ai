import 'subscription.dart';

enum TenantStatus { active, suspended, inactive, deleted }

class Tenant {
  Tenant({
    required this.tenantId,
    required this.name,
    required this.adminEmail,
    required this.plan,
    required this.status,
    required this.createdAt,
    this.lastActiveAt,
    this.suspensionReason,
    required this.settings,
  });
  final String tenantId;
  final String name;
  final String adminEmail;
  TenantPlan plan;
  TenantStatus status;
  final DateTime createdAt;
  DateTime? lastActiveAt;
  String? suspensionReason;
  final Map<String, dynamic> settings;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'name': name,
      'adminEmail': adminEmail,
      'plan': plan.toString(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'suspensionReason': suspensionReason,
      'settings': settings,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      tenantId: map['tenantId'],
      name: map['name'],
      adminEmail: map['adminEmail'],
      plan: TenantPlan.values.firstWhere(
          (e) => e.toString() == map['plan']),
      status: TenantStatus.values.firstWhere(
          (e) => e.toString() == map['status']),
      createdAt: DateTime.parse(map['createdAt']),
      lastActiveAt: map['lastActiveAt'] != null ? DateTime.parse(map['lastActiveAt']) : null,
      suspensionReason: map['suspensionReason'],
      settings: Map<String, dynamic>.from(map['settings']),
    );
  }

  Tenant copyWith({
    String? name,
    String? adminEmail,
    TenantPlan? plan,
    TenantStatus? status,
    DateTime? lastActiveAt,
    String? suspensionReason,
    Map<String, dynamic>? settings,
  }) {
    return Tenant(
      tenantId: this.tenantId,
      name: name ?? this.name,
      adminEmail: adminEmail ?? this.adminEmail,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      createdAt: this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      settings: settings ?? this.settings,
    );
  }
}
