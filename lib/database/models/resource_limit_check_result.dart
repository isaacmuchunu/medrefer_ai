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
