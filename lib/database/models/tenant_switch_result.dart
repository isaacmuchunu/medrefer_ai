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
import '../models/tenant.dart';

class TenantSwitchResult {
  TenantSwitchResult({
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

  factory TenantSwitchResult.success(String tenantId, Tenant tenant) {
    return TenantSwitchResult(
      success: true,
      tenantId: tenantId,
      tenant: tenant,
    );
  }

  factory TenantSwitchResult.failure(String tenantId, String error) {
    return TenantSwitchResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory TenantSwitchResult.fromMap(Map<String, dynamic> map) {
    return TenantSwitchResult(
      success: map['success'],
      tenantId: map['tenantId'],
      tenant: map['tenant'] != null ? Tenant.fromMap(map['tenant']) : null,
      error: map['error'],
    );
  }
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
