class EmergencyServiceException implements Exception {
  final String message;

  EmergencyServiceException(this.message);

  @override
  String toString() => 'EmergencyServiceException: $message';
}
