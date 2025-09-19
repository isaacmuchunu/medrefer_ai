import '../models/tenant.dart';

class TenantCreationResult {
  final bool success;
  final String? tenantId;
  final Tenant? tenant;
  final String? error;
  final Map<String, dynamic>? data;

  TenantCreationResult({
    required this.success,
    this.tenantId,
    this.tenant,
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

  factory TenantCreationResult.success(String tenantId, {Tenant? tenant, Map<String, dynamic>? data}) {
    return TenantCreationResult(
      success: true,
      tenantId: tenantId,
      tenant: tenant,
      data: data,
    );
  }

  factory TenantCreationResult.failure(String error) {
    return TenantCreationResult(
      success: false,
      error: error,
    );
  }
}