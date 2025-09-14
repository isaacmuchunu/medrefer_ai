import 'base_model.dart';

class VitalStatistics extends BaseModel {
  String patientId;
  String? bloodPressure;
  String? heartRate;
  String? temperature;
  String? oxygenSaturation;
  double? weight;
  double? height;
  double? bmi;
  DateTime recordedDate;
  String? recordedBy;
  
  // Getter aliases for compatibility
  DateTime get recordedAt => recordedDate;
  String? get bloodPressureSystolic {
    if (bloodPressure == null) return null;
    final parts = bloodPressure!.split('/');
    return parts.isNotEmpty ? parts[0] : null;
  }
  
  String? get bloodPressureDiastolic {
    if (bloodPressure == null) return null;
    final parts = bloodPressure!.split('/');
    return parts.length > 1 ? parts[1] : null;
  }

  VitalStatistics({
    super.id,
    required this.patientId,
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bmi,
    DateTime? recordedDate,
    this.recordedBy,
    super.createdAt,
    super.updatedAt,
  }) : recordedDate = recordedDate ?? DateTime.now();

  factory VitalStatistics.fromMap(Map<String, dynamic> map) {
    return VitalStatistics(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      bloodPressure: map['blood_pressure'],
      heartRate: map['heart_rate'],
      temperature: map['temperature'],
      oxygenSaturation: map['oxygen_saturation'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      bmi: map['bmi']?.toDouble(),
      recordedDate: BaseModel.parseDateTime(map['recorded_date']),
      recordedBy: map['recorded_by'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'patient_id': patientId,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'temperature': temperature,
      'oxygen_saturation': oxygenSaturation,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'recorded_date': recordedDate.toIso8601String(),
      'recorded_by': recordedBy,
    });
    return map;
  }

  VitalStatistics copyWith({
    String? patientId,
    String? bloodPressure,
    String? heartRate,
    String? temperature,
    String? oxygenSaturation,
    double? weight,
    double? height,
    double? bmi,
    DateTime? recordedDate,
    String? recordedBy,
  }) {
    return VitalStatistics(
      id: id,
      patientId: patientId ?? this.patientId,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      recordedDate: recordedDate ?? this.recordedDate,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to calculate BMI if height and weight are available
  void calculateBmi() {
    if (weight != null && height != null && height! > 0) {
      // Convert height from cm to meters for BMI calculation
      final heightInMeters = height! / 100;
      bmi = weight! / (heightInMeters * heightInMeters);
    }
  }

  @override
  String toString() {
    return 'VitalStatistics{id: $id, patientId: $patientId, recordedDate: $recordedDate}';
  }
}
