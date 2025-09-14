import 'base_model.dart';

class MedicalHistory extends BaseModel {
  String patientId;
  String type; // Surgery, Diagnosis, Treatment, Procedure
  String title;
  String? description;
  DateTime date;
  String? provider;
  String? location;
  String? icd10Code;

  MedicalHistory({
    super.id,
    required this.patientId,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.provider,
    this.location,
    this.icd10Code,
    super.createdAt,
    super.updatedAt,
  });

  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    return MedicalHistory(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      date: BaseModel.parseDateTime(map['date']),
      provider: map['provider'],
      location: map['location'],
      icd10Code: map['icd10_code'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'patient_id': patientId,
      'type': type,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'provider': provider,
      'location': location,
      'icd10_code': icd10Code,
    });
    return map;
  }

  MedicalHistory copyWith({
    String? patientId,
    String? type,
    String? title,
    String? description,
    DateTime? date,
    String? provider,
    String? location,
    String? icd10Code,
  }) {
    return MedicalHistory(
      id: id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      provider: provider ?? this.provider,
      location: location ?? this.location,
      icd10Code: icd10Code ?? this.icd10Code,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for type checking
  bool get isSurgery => type.toLowerCase() == 'surgery';
  bool get isDiagnosis => type.toLowerCase() == 'diagnosis';
  bool get isTreatment => type.toLowerCase() == 'treatment';
  bool get isProcedure => type.toLowerCase() == 'procedure';

  @override
  String toString() {
    return 'MedicalHistory{id: $id, patientId: $patientId, type: $type, title: $title}';
  }
}
