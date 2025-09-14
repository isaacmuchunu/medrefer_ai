import 'base_model.dart';

class EmergencyContact extends BaseModel {
  String patientId;
  String name;
  String relationship;
  String phone;
  String? email;
  bool isPrimary;

  EmergencyContact({
    super.id,
    required this.patientId,
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
    this.isPrimary = false,
    super.createdAt,
    super.updatedAt,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      isPrimary: (map['is_primary'] ?? 0) == 1,
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
      'relationship': relationship,
      'phone': phone,
      'email': email,
      'is_primary': isPrimary ? 1 : 0,
    });
    return map;
  }

  EmergencyContact copyWith({
    String? patientId,
    String? name,
    String? relationship,
    String? phone,
    String? email,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'EmergencyContact{id: $id, name: $name, relationship: $relationship, phone: $phone}';
  }
}
