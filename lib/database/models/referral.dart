import 'base_model.dart';

class Referral extends BaseModel {
  String trackingNumber;
  String patientId;
  String? specialistId;
  String status;
  String urgency;
  String? symptomsDescription;
  double aiConfidence;
  String? estimatedTime;
  String? department;
  String? referringPhysician;

  Referral({
    super.id,
    required this.trackingNumber,
    required this.patientId,
    this.specialistId,
    this.status = 'Pending',
    required this.urgency,
    this.symptomsDescription,
    this.aiConfidence = 0.0,
    this.estimatedTime,
    this.department,
    this.referringPhysician,
    super.createdAt,
    super.updatedAt,
  });

  factory Referral.fromMap(Map<String, dynamic> map) {
    return Referral(
      id: map['id'],
      trackingNumber: map['tracking_number'] ?? '',
      patientId: map['patient_id'] ?? '',
      specialistId: map['specialist_id'],
      status: map['status'] ?? 'Pending',
      urgency: map['urgency'] ?? '',
      symptomsDescription: map['symptoms_description'],
      aiConfidence: (map['ai_confidence'] ?? 0.0).toDouble(),
      estimatedTime: map['estimated_time'],
      department: map['department'],
      referringPhysician: map['referring_physician'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'tracking_number': trackingNumber,
      'patient_id': patientId,
      'specialist_id': specialistId,
      'status': status,
      'urgency': urgency,
      'symptoms_description': symptomsDescription,
      'ai_confidence': aiConfidence,
      'estimated_time': estimatedTime,
      'department': department,
      'referring_physician': referringPhysician,
    });
    return map;
  }

  Referral copyWith({
    String? trackingNumber,
    String? patientId,
    String? specialistId,
    String? status,
    String? urgency,
    String? symptomsDescription,
    double? aiConfidence,
    String? estimatedTime,
    String? department,
    String? referringPhysician,
  }) {
    return Referral(
      id: id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      patientId: patientId ?? this.patientId,
      specialistId: specialistId ?? this.specialistId,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      symptomsDescription: symptomsDescription ?? this.symptomsDescription,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      department: department ?? this.department,
      referringPhysician: referringPhysician ?? this.referringPhysician,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for status management
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  // Helper methods for urgency
  bool get isEmergency => urgency.toLowerCase() == 'emergency';
  bool get isUrgent => urgency.toLowerCase() == 'urgent' || urgency.toLowerCase() == 'high';
  bool get isCritical => urgency.toLowerCase() == 'critical';

  @override
  String toString() {
    return 'Referral{id: $id, trackingNumber: $trackingNumber, patientId: $patientId, status: $status}';
  }
}
