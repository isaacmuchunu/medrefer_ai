class TenantSwitchResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? tenantConfig;

  TenantSwitchResult({
    required this.success,
    this.tenantId,
    this.error,
    this.tenantConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'tenantConfig': tenantConfig,
    };
  }

  factory TenantSwitchResult.success(String tenantId, Map<String, dynamic> tenantConfig) {
    return TenantSwitchResult(
      success: true,
      tenantId: tenantId,
      tenantConfig: tenantConfig,
    );
  }

  factory TenantSwitchResult.failure(String error) {
    return TenantSwitchResult(
      success: false,
      error: error,
    );
  }

  factory TenantSwitchResult.fromMap(Map<String, dynamic> map) {
    return TenantSwitchResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      tenantConfig: map['tenantConfig'],
    );
  }
}
