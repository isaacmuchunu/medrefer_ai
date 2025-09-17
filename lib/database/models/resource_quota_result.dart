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

  factory ResourceQuotaResult.fromMap(Map<String, dynamic> map) {
    return ResourceQuotaResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      quotas: map['quotas'],
    );
  }
}
