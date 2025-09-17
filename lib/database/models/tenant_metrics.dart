class TenantMetrics {
  final String tenantId;
  final int activeUsers;
  final int totalUsers;
  final double storageUsed; // in GB
  final int apiCallsThisMonth;
  final double averageResponseTime; // in ms
  final double uptime; // percentage
  final int errorCount;
  final int totalPatients;
  final int totalAppointments;
  final Map<String, dynamic> customMetrics;
  final DateTime lastUpdated;

  TenantMetrics({
    required this.tenantId,
    required this.activeUsers,
    required this.totalUsers,
    required this.storageUsed,
    required this.apiCallsThisMonth,
    required this.averageResponseTime,
    required this.uptime,
    required this.errorCount,
    required this.totalPatients,
    required this.totalAppointments,
    required this.customMetrics,
    required this.lastUpdated,
  });
class TenantMetrics {
  TenantMetrics({
    required this.tenantId,
    required this.activeUsers,
    required this.totalRequests,
    required this.storageUsed,
    required this.bandwidthUsed,
    required this.lastUpdated,
  });
  final String tenantId;
  int activeUsers;
  int totalRequests;
  int storageUsed;
  int bandwidthUsed;
  DateTime lastUpdated;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'activeUsers': activeUsers,
      'totalRequests': totalRequests,
      'storageUsed': storageUsed,
      'bandwidthUsed': bandwidthUsed,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TenantMetrics.fromMap(Map<String, dynamic> map) {
    return TenantMetrics(
      tenantId: map['tenantId'],
      activeUsers: map['activeUsers'],
      totalRequests: map['totalRequests'],
      storageUsed: map['storageUsed'],
      bandwidthUsed: map['bandwidthUsed'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'activeUsers': activeUsers,
      'totalUsers': totalUsers,
      'storageUsed': storageUsed,
      'apiCallsThisMonth': apiCallsThisMonth,
      'averageResponseTime': averageResponseTime,
      'uptime': uptime,
      'errorCount': errorCount,
      'totalPatients': totalPatients,
      'totalAppointments': totalAppointments,
      'customMetrics': customMetrics,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TenantMetrics.fromMap(Map<String, dynamic> map) {
    return TenantMetrics(
      tenantId: map['tenantId'],
      activeUsers: map['activeUsers'],
      totalUsers: map['totalUsers'],
      storageUsed: map['storageUsed'],
      apiCallsThisMonth: map['apiCallsThisMonth'],
      averageResponseTime: map['averageResponseTime'],
      uptime: map['uptime'],
      errorCount: map['errorCount'],
      totalPatients: map['totalPatients'],
      totalAppointments: map['totalAppointments'],
      customMetrics: map['customMetrics'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
