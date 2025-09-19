class TenantSecurity {
  TenantSecurity({
    required this.tenantId,
    required this.encryptionKey,
    required this.accessPolicies,
    required this.auditSettings,
    this.ssoSettings,
  });
  final String tenantId;
  String encryptionKey;
  Map<String, dynamic> accessPolicies;
  Map<String, dynamic> auditSettings;
  Map<String, dynamic>? ssoSettings;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'encryptionKey': encryptionKey,
      'accessPolicies': accessPolicies,
      'auditSettings': auditSettings,
      'ssoSettings': ssoSettings,
    };
  }

  factory TenantSecurity.fromMap(Map<String, dynamic> map) {
    return TenantSecurity(
      tenantId: map['tenantId'],
      encryptionKey: map['encryptionKey'],
      accessPolicies: map['accessPolicies'],
      auditSettings: map['auditSettings'],
      ssoSettings: map['ssoSettings'],
    );
  }
}
