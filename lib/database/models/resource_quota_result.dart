class ResourceQuotaResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? quotas;

  ResourceQuotaResult({
    required this.success,
    this.tenantId,
    this.error,
    this.quotas,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'quotas': quotas,
    };
  }

  factory ResourceQuotaResult.success(String tenantId, Map<String, dynamic> quotas) {
    return ResourceQuotaResult(
      success: true,
      tenantId: tenantId,
      quotas: quotas,
    );
  }

  factory ResourceQuotaResult.failure(String error) {
    return ResourceQuotaResult(
      success: false,
      error: error,
    );
  }
class ResourceQuotaResult {
  ResourceQuotaResult({
    required this.success,
    required this.tenantId,
    this.quota,
    this.error,
  });
  final bool success;
  final String tenantId;
  final ResourceQuota? quota;
  final String? error;

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'quota': quota?.toMap(),
      'error': error,
    };
  }

  factory ResourceQuotaResult.success(String tenantId, ResourceQuota quota) {
    return ResourceQuotaResult(
      success: true,
      tenantId: tenantId,
      quota: quota,
    );
  }

  factory ResourceQuotaResult.failure(String tenantId, String error) {
    return ResourceQuotaResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory ResourceQuotaResult.fromMap(Map<String, dynamic> map) {
    return ResourceQuotaResult(
      success: map['success'],
      tenantId: map['tenantId'],
      quota: map['quota'] != null ? ResourceQuota.fromMap(map['quota']) : null,
      error: map['error'],
    );
  }
}

class ResourceQuota {
  ResourceQuota({
    required this.tenantId,
    required this.maxUsers,
    required this.maxStorage,
    required this.maxBandwidth,
    required this.maxConnections,
    required this.maxRequests,
    required this.createdAt,
    required this.updatedAt,
  });
  final String tenantId;
  int maxUsers;
  int maxStorage;
  int maxBandwidth;
  int maxConnections;
  int maxRequests;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'maxUsers': maxUsers,
      'maxStorage': maxStorage,
      'maxBandwidth': maxBandwidth,
      'maxConnections': maxConnections,
      'maxRequests': maxRequests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ResourceQuota.fromMap(Map<String, dynamic> map) {
    return ResourceQuota(
      tenantId: map['tenantId'],
      maxUsers: map['maxUsers'],
      maxStorage: map['maxStorage'],
      maxBandwidth: map['maxBandwidth'],
      maxConnections: map['maxConnections'],
      maxRequests: map['maxRequests'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class ResourceUsage {
  ResourceUsage({
    required this.tenantId,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.storageUsage,
    required this.bandwidthUsage,
    required this.activeConnections,
    this.activeUsers = 0,
    required this.lastUpdated,
  });
  final String tenantId;
  double cpuUsage;
  int memoryUsage;
  int storageUsage;
  int bandwidthUsage;
  int activeConnections;
  int activeUsers;
  DateTime lastUpdated;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'storageUsage': storageUsage,
      'bandwidthUsage': bandwidthUsage,
      'activeConnections': activeConnections,
      'activeUsers': activeUsers,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ResourceUsage.fromMap(Map<String, dynamic> map) {
    return ResourceUsage(
      tenantId: map['tenantId'],
      cpuUsage: map['cpuUsage'],
      memoryUsage: map['memoryUsage'],
      storageUsage: map['storageUsage'],
      bandwidthUsage: map['bandwidthUsage'],
      activeConnections: map['activeConnections'],
      activeUsers: map['activeUsers'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
  factory ResourceQuotaResult.fromMap(Map<String, dynamic> map) {
    return ResourceQuotaResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      quotas: map['quotas'],
    );
  }
}
