class SubscriptionResult {
  final bool success;
  final String? tenantId;
  final String? error;
  final Map<String, dynamic>? subscription;

  SubscriptionResult({
    required this.success,
    this.tenantId,
    this.error,
    this.subscription,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'error': error,
      'subscription': subscription,
    };
  }

  factory SubscriptionResult.success(String tenantId, Map<String, dynamic> subscription) {
    return SubscriptionResult(
      success: true,
      tenantId: tenantId,
      subscription: subscription,
    );
  }

  factory SubscriptionResult.failure(String error) {
    return SubscriptionResult(
      success: false,
      error: error,
    );
  }

  factory SubscriptionResult.fromMap(Map<String, dynamic> map) {
    return SubscriptionResult(
      success: map['success'],
      tenantId: map['tenantId'],
      error: map['error'],
      subscription: map['subscription'],
    );
  }
}
