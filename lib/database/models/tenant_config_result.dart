class TenantConfigResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? updatedConfig;

  TenantConfigResult({
    required this.success,
    this.tenantId,
    this.error,
    this.updatedConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'updatedConfig': updatedConfig,
    };
  }

  factory TenantConfigResult.success(String tenantId, Map<String, dynamic> updatedConfig) {
    return TenantConfigResult(
      success: true,
      tenantId: tenantId,
      updatedConfig: updatedConfig,
    );
  }

  factory TenantConfigResult.failure(String error) {
    return TenantConfigResult(
      success: false,
      error: error,
    );
  }

  factory TenantConfigResult.fromMap(Map<String, dynamic> map) {
    return TenantConfigResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      updatedConfig: map['updatedConfig'],
    );
  }
}
