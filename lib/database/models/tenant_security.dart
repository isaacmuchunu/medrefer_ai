class TenantSecurity {
  final String tenantId;
  final bool enforceMFA;
  final int passwordMinLength;
  final bool requireSpecialChar;
  final bool requireNumber;
  final bool requireUppercase;
  final int passwordExpiryDays;
  final int sessionTimeoutMinutes;
  final int maxLoginAttempts;
  final int lockoutDurationMinutes;
  final List<String> allowedIpRanges;
  final List<String> blockedIpAddresses;
  final bool auditTrailEnabled;
  final int auditLogRetentionDays;
  final bool dataEncryptionEnabled;
  final String encryptionAlgorithm; // AES-256, RSA-2048, etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  TenantSecurity({
    required this.tenantId,
    required this.enforceMFA,
    required this.passwordMinLength,
    required this.requireSpecialChar,
    required this.requireNumber,
    required this.requireUppercase,
    required this.passwordExpiryDays,
    required this.sessionTimeoutMinutes,
    required this.maxLoginAttempts,
    required this.lockoutDurationMinutes,
    required this.allowedIpRanges,
    required this.blockedIpAddresses,
    required this.auditTrailEnabled,
    required this.auditLogRetentionDays,
    required this.dataEncryptionEnabled,
    required this.encryptionAlgorithm,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'enforceMFA': enforceMFA,
      'passwordMinLength': passwordMinLength,
      'requireSpecialChar': requireSpecialChar,
      'requireNumber': requireNumber,
      'requireUppercase': requireUppercase,
      'passwordExpiryDays': passwordExpiryDays,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDurationMinutes': lockoutDurationMinutes,
      'allowedIpRanges': allowedIpRanges,
      'blockedIpAddresses': blockedIpAddresses,
      'auditTrailEnabled': auditTrailEnabled,
      'auditLogRetentionDays': auditLogRetentionDays,
      'dataEncryptionEnabled': dataEncryptionEnabled,
      'encryptionAlgorithm': encryptionAlgorithm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TenantSecurity.fromMap(Map<String, dynamic> map) {
    return TenantSecurity(
      tenantId: map['tenantId'],
      enforceMFA: map['enforceMFA'],
      passwordMinLength: map['passwordMinLength'],
      requireSpecialChar: map['requireSpecialChar'],
      requireNumber: map['requireNumber'],
      requireUppercase: map['requireUppercase'],
      passwordExpiryDays: map['passwordExpiryDays'],
      sessionTimeoutMinutes: map['sessionTimeoutMinutes'],
      maxLoginAttempts: map['maxLoginAttempts'],
      lockoutDurationMinutes: map['lockoutDurationMinutes'],
      allowedIpRanges: List<String>.from(map['allowedIpRanges']),
      blockedIpAddresses: List<String>.from(map['blockedIpAddresses']),
      auditTrailEnabled: map['auditTrailEnabled'],
      auditLogRetentionDays: map['auditLogRetentionDays'],
      dataEncryptionEnabled: map['dataEncryptionEnabled'],
      encryptionAlgorithm: map['encryptionAlgorithm'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
