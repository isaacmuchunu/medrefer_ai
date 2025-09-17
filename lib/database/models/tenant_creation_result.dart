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
import '../models/tenant.dart';

class TenantCreationResult {
  TenantCreationResult({
    required this.success,
    required this.tenantId,
    this.tenant,
    this.error,
  });
  final bool success;
  final String tenantId;
  final Tenant? tenant;
  final String? error;

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'tenant': tenant?.toMap(),
      'error': error,
    };
  }

  factory TenantCreationResult.success(String tenantId, Tenant tenant) {
    return TenantCreationResult(
      success: true,
      tenantId: tenantId,
      tenant: tenant,
    );
  }

  factory TenantCreationResult.failure(String tenantId, String error) {
    return TenantCreationResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory TenantCreationResult.fromMap(Map<String, dynamic> map) {
    return TenantCreationResult(
      success: map['success'],
      tenantId: map['tenantId'],
      tenant: map['tenant'] != null ? Tenant.fromMap(map['tenant']) : null,
      error: map['error'],
    );
  }
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
