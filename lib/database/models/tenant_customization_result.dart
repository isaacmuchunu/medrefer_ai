class TenantCustomizationResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? customization;

  TenantCustomizationResult({
    required this.success,
    this.tenantId,
    this.error,
    this.customization,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'customization': customization,
    };
  }

  factory TenantCustomizationResult.success(String tenantId, Map<String, dynamic> customization) {
    return TenantCustomizationResult(
      success: true,
      tenantId: tenantId,
      customization: customization,
    );
  }

  factory TenantCustomizationResult.failure(String error) {
    return TenantCustomizationResult(
      success: false,
      error: error,
    );
  }

  factory TenantCustomizationResult.fromMap(Map<String, dynamic> map) {
    return TenantCustomizationResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      customization: map['customization'],
    );
  }
}
