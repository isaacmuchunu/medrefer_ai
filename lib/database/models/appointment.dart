import 'base_model.dart';

class Appointment extends BaseModel {
  final String? patientId;
  final String? specialistId;
  final String? referralId;
  final DateTime? appointmentDate;
  final String? appointmentTime;
  final String? status;
  final String? notes;
  final String? reasonForAppointment;
  final String? type;
  final int? duration;
  final String? location;

  Appointment({
    super.id,
    this.patientId,
    this.specialistId,
    this.referralId,
    this.appointmentDate,
    this.appointmentTime,
    this.status,
    this.notes,
    this.reasonForAppointment,
    this.type,
    this.duration,
    this.location,
    super.createdAt,
    super.updatedAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String?,
      patientId: map['patientId'] as String?,
      specialistId: map['specialistId'] as String?,
      referralId: map['referralId'] as String?,
      appointmentDate: map['appointmentDate'] != null 
          ? DateTime.parse(map['appointmentDate'] as String) 
          : null,
      appointmentTime: map['appointmentTime'] as String?,
      status: map['status'] as String?,
      notes: map['notes'] as String?,
      reasonForAppointment: map['reasonForAppointment'] as String?,
      type: map['type'] as String?,
      duration: map['duration'] as int?,
      location: map['location'] as String?,
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
      'specialistId': specialistId,
      'referralId': referralId,
      'appointmentDate': appointmentDate?.toIso8601String(),
      'appointmentTime': appointmentTime,
      'status': status,
      'notes': notes,
      'reasonForAppointment': reasonForAppointment,
      'type': type,
      'duration': duration,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? specialistId,
    String? referralId,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? status,
    String? notes,
    String? reasonForAppointment,
    String? type,
    int? duration,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      specialistId: specialistId ?? this.specialistId,
      referralId: referralId ?? this.referralId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reasonForAppointment: reasonForAppointment ?? this.reasonForAppointment,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}