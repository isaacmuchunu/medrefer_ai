import 'base_model.dart';

class Insurance extends BaseModel {
  final String? patientId;
  final String? provider;
  final String? policyNumber;
  final String? groupNumber;
  final String? coverageType;
  final DateTime? effectiveDate;
  final DateTime? expirationDate;
  final String? status;
  final String? primaryHolder;
  final String? relationship;

  Insurance({
    String? id,
    this.patientId,
    this.provider,
    this.policyNumber,
    this.groupNumber,
    this.coverageType,
    this.effectiveDate,
    this.expirationDate,
    this.status,
    this.primaryHolder,
    this.relationship,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory Insurance.fromMap(Map<String, dynamic> map) {
    return Insurance(
      id: map['id'] as String?,
      patientId: map['patientId'] as String?,
      provider: map['provider'] as String?,
      policyNumber: map['policyNumber'] as String?,
      groupNumber: map['groupNumber'] as String?,
      coverageType: map['coverageType'] as String?,
      effectiveDate: map['effectiveDate'] != null 
          ? DateTime.parse(map['effectiveDate'] as String) 
          : null,
      expirationDate: map['expirationDate'] != null 
          ? DateTime.parse(map['expirationDate'] as String) 
          : null,
      status: map['status'] as String?,
      primaryHolder: map['primaryHolder'] as String?,
      relationship: map['relationship'] as String?,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'provider': provider,
      'policyNumber': policyNumber,
      'groupNumber': groupNumber,
      'coverageType': coverageType,
      'effectiveDate': effectiveDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'status': status,
      'primaryHolder': primaryHolder,
      'relationship': relationship,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Insurance copyWith({
    String? id,
    String? patientId,
    String? provider,
    String? policyNumber,
    String? groupNumber,
    String? coverageType,
    DateTime? effectiveDate,
    DateTime? expirationDate,
    String? status,
    String? primaryHolder,
    String? relationship,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Insurance(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      groupNumber: groupNumber ?? this.groupNumber,
      coverageType: coverageType ?? this.coverageType,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      primaryHolder: primaryHolder ?? this.primaryHolder,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}