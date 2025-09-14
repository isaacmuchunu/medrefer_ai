import 'base_model.dart';

class Patient extends BaseModel {
  String name;
  int age;
  String medicalRecordNumber;
  DateTime dateOfBirth;
  String gender;
  String? bloodType;
  String? phone;
  String? email;
  String? address;
  String? insurance;
  String? profileImageUrl;

  Patient({
    super.id,
    required this.name,
    required this.age,
    required this.medicalRecordNumber,
    required this.dateOfBirth,
    required this.gender,
    this.bloodType,
    this.phone,
    this.email,
    this.address,
    this.insurance,
    this.profileImageUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      medicalRecordNumber: map['medical_record_number'] ?? '',
      dateOfBirth: BaseModel.parseDateTime(map['date_of_birth']),
      gender: map['gender'] ?? '',
      bloodType: map['blood_type'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      insurance: map['insurance'],
      profileImageUrl: map['profile_image_url'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'name': name,
      'age': age,
      'medical_record_number': medicalRecordNumber,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'blood_type': bloodType,
      'phone': phone,
      'email': email,
      'address': address,
      'insurance': insurance,
      'profile_image_url': profileImageUrl,
    });
    return map;
  }

  Patient copyWith({
    String? name,
    int? age,
    String? medicalRecordNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? phone,
    String? email,
    String? address,
    String? insurance,
    String? profileImageUrl,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      medicalRecordNumber: medicalRecordNumber ?? this.medicalRecordNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      insurance: insurance ?? this.insurance,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Patient{id: $id, name: $name, mrn: $medicalRecordNumber, age: $age}';
  }
}
