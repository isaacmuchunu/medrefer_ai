class ResourceLimitCheckResult {
  final bool success;
  final String tenantId;
  final bool hasViolations;
  final List<ResourceViolation> violations;
  final String? error;

  ResourceLimitCheckResult({
    required this.success,
    required this.tenantId,
    this.hasViolations = false,
    this.violations = const [],
    this.error,
  });

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
  final ResourceType type;
  final int limit;
  final int current;
  final ViolationSeverity severity;

  ResourceViolation({
    required this.type,
    required this.limit,
    required this.current,
    required this.severity,
  });

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