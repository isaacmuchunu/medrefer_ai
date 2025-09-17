class Subscription {
  final String id;
  final String tenantId;
  final String planId;
  final String status; // active, canceled, pending, etc.
  final DateTime startDate;
  final DateTime? endDate;
  final double amount;
  final String billingCycle; // monthly, annual, etc.
  final bool autoRenew;
  final Map<String, dynamic> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.tenantId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.amount,
    required this.billingCycle,
    required this.autoRenew,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
  });
enum SubscriptionStatus { active, expired, cancelled, suspended }

class Subscription {
  Subscription({
    required this.tenantId,
    required this.subscriptionId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.features,
  });
  final String tenantId;
  final String subscriptionId;
  TenantPlan plan;
  SubscriptionStatus status;
  final DateTime startDate;
  DateTime endDate;
  bool autoRenew;
  List<String> features;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'subscriptionId': subscriptionId,
      'plan': plan.toString(),
      'status': status.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'autoRenew': autoRenew,
      'features': features,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      tenantId: map['tenantId'],
      subscriptionId: map['subscriptionId'],
      plan: TenantPlan.values.firstWhere(
          (e) => e.toString() == map['plan']),
      status: SubscriptionStatus.values.firstWhere(
          (e) => e.toString() == map['status']),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      autoRenew: map['autoRenew'],
      features: List<String>.from(map['features']),
    );
  }
}

enum TenantPlan { basic, professional, enterprise }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'amount': amount,
      'billingCycle': billingCycle,
      'autoRenew': autoRenew,
      'features': features,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      tenantId: map['tenantId'],
      planId: map['planId'],
      status: map['status'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      amount: map['amount'],
      billingCycle: map['billingCycle'],
      autoRenew: map['autoRenew'],
      features: map['features'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
