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
class TenantConfigResult {
  TenantConfigResult({
    required this.success,
    required this.tenantId,
    this.configuration,
    this.error,
  });
  final bool success;
  final String tenantId;
  final TenantConfiguration? configuration;
  final String? error;

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'configuration': configuration?.toMap(),
      'error': error,
    };
  }

  factory TenantConfigResult.success(String tenantId, TenantConfiguration configuration) {
    return TenantConfigResult(
      success: true,
      tenantId: tenantId,
      configuration: configuration,
    );
  }

  factory TenantConfigResult.failure(String tenantId, String error) {
    return TenantConfigResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory TenantConfigResult.fromMap(Map<String, dynamic> map) {
    return TenantConfigResult(
      success: map['success'],
      tenantId: map['tenantId'],
      configuration: map['configuration'] != null ? TenantConfiguration.fromMap(map['configuration']) : null,
      error: map['error'],
    );
  }
}

class TenantConfiguration {
  TenantConfiguration({
    required this.tenantId,
    required this.databaseSettings,
    required this.securitySettings,
    required this.featureFlags,
    required this.integrationSettings,
    required this.customSettings,
  });
  final String tenantId;
  final Map<String, dynamic> databaseSettings;
  final Map<String, dynamic> securitySettings;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> integrationSettings;
  final Map<String, dynamic> customSettings;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'databaseSettings': databaseSettings,
      'securitySettings': securitySettings,
      'featureFlags': featureFlags,
      'integrationSettings': integrationSettings,
      'customSettings': customSettings,
    };
  }

  factory TenantConfiguration.fromMap(Map<String, dynamic> map) {
    return TenantConfiguration(
      tenantId: map['tenantId'],
      databaseSettings: Map<String, dynamic>.from(map['databaseSettings']),
      securitySettings: Map<String, dynamic>.from(map['securitySettings']),
      featureFlags: Map<String, bool>.from(map['featureFlags']),
      integrationSettings: Map<String, dynamic>.from(map['integrationSettings']),
      customSettings: Map<String, dynamic>.from(map['customSettings']),
    );
  }
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
