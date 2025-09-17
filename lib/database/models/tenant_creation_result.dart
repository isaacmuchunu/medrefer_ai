class TenantCreationResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? data;

  TenantCreationResult({
    required this.success,
    this.tenantId,
    this.error,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'data': data,
    };
  }

  factory TenantCreationResult.success(String tenantId, {Map<String, dynamic>? data}) {
    return TenantCreationResult(
      success: true,
      tenantId: tenantId,
      data: data,
    );
  }

  factory TenantCreationResult.failure(String error) {
    return TenantCreationResult(
      success: false,
      error: error,
    );
  }

  factory TenantCreationResult.fromMap(Map<String, dynamic> map) {
    return TenantCreationResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      data: map['data'],
    );
  }
}
