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
class TenantOperationResult {
  TenantOperationResult({
    required this.success,
    required this.tenantId,
    this.operation,
    this.error,
  });
  final bool success;
  final String tenantId;
  final String? operation;
  final String? error;

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'operation': operation,
      'error': error,
    };
  }

  factory TenantOperationResult.success(String tenantId, String operation) {
    return TenantOperationResult(
      success: true,
      tenantId: tenantId,
      operation: operation,
    );
  }

  factory TenantOperationResult.failure(String tenantId, String error) {
    return TenantOperationResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory TenantOperationResult.fromMap(Map<String, dynamic> map) {
    return TenantOperationResult(
      success: map['success'],
      tenantId: map['tenantId'],
      operation: map['operation'],
      error: map['error'],
    );
  }
}
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
