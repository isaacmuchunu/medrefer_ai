import 'base_model.dart';

class Prescription extends BaseModel {
  final String? patientId;
  final String? prescribedBy;
  final String? medicationName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? refills;
  final String? status;

  Prescription({
    super.id,
    this.patientId,
    this.prescribedBy,
    this.medicationName,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
    this.startDate,
    this.endDate,
    this.refills,
    this.status,
    super.createdAt,
    super.updatedAt,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as String?,
      patientId: map['patientId'] as String?,
      prescribedBy: map['prescribedBy'] as String?,
      medicationName: map['medicationName'] as String?,
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String?,
      duration: map['duration'] as String?,
      instructions: map['instructions'] as String?,
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate'] as String) 
          : null,
      endDate: map['endDate'] != null 
          ? DateTime.parse(map['endDate'] as String) 
          : null,
      refills: map['refills'] as int?,
      status: map['status'] as String?,
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
      'prescribedBy': prescribedBy,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'refills': refills,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Prescription copyWith({
    String? id,
    String? patientId,
    String? prescribedBy,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    DateTime? startDate,
    DateTime? endDate,
    int? refills,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      refills: refills ?? this.refills,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}