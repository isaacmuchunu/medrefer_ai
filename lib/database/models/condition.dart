import 'base_model.dart';

class Condition extends BaseModel {
  String patientId;
  String name;
  String? severity;
  String? description;
  DateTime? diagnosedDate;
  String? diagnosedBy;
  String? icd10Code;
  bool isActive;

  Condition({
    super.id,
    required this.patientId,
    required this.name,
    this.severity,
    this.description,
    this.diagnosedDate,
    this.diagnosedBy,
    this.icd10Code,
    this.isActive = true,
    super.createdAt,
    super.updatedAt,
  });

  factory Condition.fromMap(Map<String, dynamic> map) {
    return Condition(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      name: map['name'] ?? '',
      severity: map['severity'],
      description: map['description'],
      diagnosedDate: map['diagnosed_date'] != null ? BaseModel.parseDateTime(map['diagnosed_date']) : null,
      diagnosedBy: map['diagnosed_by'],
      icd10Code: map['icd10_code'],
      isActive: (map['is_active'] ?? 1) == 1,
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
      'severity': severity,
      'description': description,
      'diagnosed_date': diagnosedDate?.toIso8601String(),
      'diagnosed_by': diagnosedBy,
      'icd10_code': icd10Code,
      'is_active': isActive ? 1 : 0,
    });
    return map;
  }

  Condition copyWith({
    String? patientId,
    String? name,
    String? severity,
    String? description,
    DateTime? diagnosedDate,
    String? diagnosedBy,
    String? icd10Code,
    bool? isActive,
  }) {
    return Condition(
      id: id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      diagnosedDate: diagnosedDate ?? this.diagnosedDate,
      diagnosedBy: diagnosedBy ?? this.diagnosedBy,
      icd10Code: icd10Code ?? this.icd10Code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for severity
  bool get isMild => severity?.toLowerCase() == 'mild';
  bool get isModerate => severity?.toLowerCase() == 'moderate';
  bool get isSevere => severity?.toLowerCase() == 'severe';
  bool get isCritical => severity?.toLowerCase() == 'critical';

  @override
  String toString() {
    return 'Condition{id: $id, patientId: $patientId, name: $name, severity: $severity}';
  }
}
