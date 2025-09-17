class TenantOperationResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final String operation; // suspend, reactivate, delete, etc.
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  TenantOperationResult({
    required this.success,
    this.tenantId,
    this.error,
    required this.operation,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'operation': operation,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }

  factory TenantOperationResult.success({
    required String tenantId,
    required String operation,
    Map<String, dynamic>? details,
  }) {
    return TenantOperationResult(
      success: true,
      tenantId: tenantId,
      operation: operation,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  factory TenantOperationResult.failure({
    required String error,
    required String operation,
    String? tenantId,
  }) {
    return TenantOperationResult(
      success: false,
      tenantId: tenantId,
      error: error,
      operation: operation,
      timestamp: DateTime.now(),
    );
  }

  factory TenantOperationResult.fromMap(Map<String, dynamic> map) {
    return TenantOperationResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      operation: map['operation'],
      timestamp: DateTime.parse(map['timestamp']),
      details: map['details'],
    );
  }
}
