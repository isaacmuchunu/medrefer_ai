class TenantAnalyticsResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? analytics;
  final DateTime startDate;
  final DateTime endDate;

  TenantAnalyticsResult({
    required this.success,
    this.tenantId,
    this.error,
    this.analytics,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'analytics': analytics,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory TenantAnalyticsResult.success({
    required String tenantId,
    required Map<String, dynamic> analytics,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return TenantAnalyticsResult(
      success: true,
      tenantId: tenantId,
      analytics: analytics,
      startDate: startDate,
      endDate: endDate,
    );
  }

  factory TenantAnalyticsResult.failure(String error) {
    return TenantAnalyticsResult(
      success: false,
      error: error,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );
  }

  factory TenantAnalyticsResult.fromMap(Map<String, dynamic> map) {
    return TenantAnalyticsResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      analytics: map['analytics'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
