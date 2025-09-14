import 'base_model.dart';

class Medication extends BaseModel {
  String patientId;
  String name;
  String dosage;
  String frequency;
  String? type;
  String status;
  DateTime? startDate;
  DateTime? endDate;
  String? prescribedBy;
  String? notes;

  Medication({
    super.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.type,
    this.status = 'Active',
    this.startDate,
    this.endDate,
    this.prescribedBy,
    this.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      type: map['type'],
      status: map['status'] ?? 'Active',
      startDate: map['start_date'] != null ? BaseModel.parseDateTime(map['start_date']) : null,
      endDate: map['end_date'] != null ? BaseModel.parseDateTime(map['end_date']) : null,
      prescribedBy: map['prescribed_by'],
      notes: map['notes'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'patient_id': patientId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'type': type,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'prescribed_by': prescribedBy,
      'notes': notes,
    });
    return map;
  }

  Medication copyWith({
    String? patientId,
    String? name,
    String? dosage,
    String? frequency,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribedBy,
    String? notes,
  }) {
    return Medication(
      id: id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for status
  bool get isActive => status.toLowerCase() == 'active';
  bool get isDiscontinued => status.toLowerCase() == 'discontinued';
  bool get isPaused => status.toLowerCase() == 'paused';

  @override
  String toString() {
    return 'Medication{id: $id, patientId: $patientId, name: $name, dosage: $dosage}';
  }
}
