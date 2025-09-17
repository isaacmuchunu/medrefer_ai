class ResourceLimitCheckResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? limits;
  final Map<String, dynamic>? usage;
  final bool withinLimits;
  final List<String>? exceededResources;

  ResourceLimitCheckResult({
    required this.success,
    this.tenantId,
    this.error,
    this.limits,
    this.usage,
    required this.withinLimits,
    this.exceededResources,
  });
class ResourceLimitCheckResult {
  ResourceLimitCheckResult({
    required this.success,
    required this.tenantId,
    this.hasViolations = false,
    this.violations = const [],
    this.error,
  });
  final bool success;
  final String tenantId;
  final bool hasViolations;
  final List<ResourceViolation> violations;
  final String? error;

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'hasViolations': hasViolations,
      'violations': violations.map((v) => v.toMap()).toList(),
      'error': error,
    };
  }

  factory ResourceLimitCheckResult.success(String tenantId, List<ResourceViolation> violations) {
    return ResourceLimitCheckResult(
      success: true,
      tenantId: tenantId,
      hasViolations: violations.isNotEmpty,
      violations: violations,
    );
  }

  factory ResourceLimitCheckResult.failure(String tenantId, String error) {
    return ResourceLimitCheckResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory ResourceLimitCheckResult.fromMap(Map<String, dynamic> map) {
    return ResourceLimitCheckResult(
      success: map['success'],
      tenantId: map['tenantId'],
      hasViolations: map['hasViolations'],
      violations: map['violations'] != null
          ? List<ResourceViolation>.from(
              map['violations'].map((x) => ResourceViolation.fromMap(x)))
          : [],
      error: map['error'],
    );
  }
}

class ResourceViolation {
  ResourceViolation({
    required this.type,
    required this.limit,
    required this.current,
    required this.severity,
  });
  final ResourceType type;
  final int limit;
  final int current;
  final ViolationSeverity severity;

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'limit': limit,
      'current': current,
      'severity': severity.toString(),
    };
  }

  factory ResourceViolation.fromMap(Map<String, dynamic> map) {
    return ResourceViolation(
      type: ResourceType.values.firstWhere(
          (e) => e.toString() == map['type']),
      limit: map['limit'],
      current: map['current'],
      severity: ViolationSeverity.values.firstWhere(
          (e) => e.toString() == map['severity']),
    );
  }
}

enum ResourceType { users, storage, bandwidth, connections, requests }
enum ViolationSeverity { low, medium, high, critical }
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'limits': limits,
      'usage': usage,
      'withinLimits': withinLimits,
      'exceededResources': exceededResources,
    };
  }

  factory ResourceLimitCheckResult.success({
    required String tenantId,
    required Map<String, dynamic> limits,
    required Map<String, dynamic> usage,
    required bool withinLimits,
    List<String>? exceededResources,
  }) {
    return ResourceLimitCheckResult(
      success: true,
      tenantId: tenantId,
      limits: limits,
      usage: usage,
      withinLimits: withinLimits,
      exceededResources: exceededResources,
    );
  }

  factory ResourceLimitCheckResult.failure(String error) {
    return ResourceLimitCheckResult(
      success: false,
      error: error,
      withinLimits: false,
    );
  }

  factory ResourceLimitCheckResult.fromMap(Map<String, dynamic> map) {
    return ResourceLimitCheckResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      limits: map['limits'],
      usage: map['usage'],
      withinLimits: map['withinLimits'],
      exceededResources: map['exceededResources'] != null
          ? List<String>.from(map['exceededResources'])
          : null,
    );
  }
}
