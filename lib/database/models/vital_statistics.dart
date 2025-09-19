class VitalStatistics {
  final String id;
  final String patientId;
  final double? heartRate;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? oxygenSaturation;
  final double? temperature;
  final double? respiratoryRate;
  final double? glucoseLevel;
  final double? weight;
  final double? height;
  final double? bmi;
  final DateTime timestamp;
  final String? deviceId;
  final String? recordedBy;
  final String? notes;
  final Map<String, dynamic>? metadata;

  VitalStatistics({
    required this.id,
    required this.patientId,
    this.heartRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.oxygenSaturation,
    this.temperature,
    this.respiratoryRate,
    this.glucoseLevel,
    this.weight,
    this.height,
    this.bmi,
    required this.timestamp,
    this.deviceId,
    this.recordedBy,
    this.notes,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'heartRate': heartRate,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
      'respiratoryRate': respiratoryRate,
      'glucoseLevel': glucoseLevel,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'recordedBy': recordedBy,
      'notes': notes,
      'metadata': metadata != null ? metadata.toString() : null,
    };
  }

  factory VitalStatistics.fromMap(Map<String, dynamic> map) {
    return VitalStatistics(
      id: map['id'],
      patientId: map['patientId'],
      heartRate: map['heartRate']?.toDouble(),
      bloodPressureSystolic: map['bloodPressureSystolic']?.toDouble(),
      bloodPressureDiastolic: map['bloodPressureDiastolic']?.toDouble(),
      oxygenSaturation: map['oxygenSaturation']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      respiratoryRate: map['respiratoryRate']?.toDouble(),
      glucoseLevel: map['glucoseLevel']?.toDouble(),
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      bmi: map['bmi']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      deviceId: map['deviceId'],
      recordedBy: map['recordedBy'],
      notes: map['notes'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  VitalStatistics copyWith({
    String? id,
    String? patientId,
    double? heartRate,
    double? bloodPressureSystolic,
    double? bloodPressureDiastolic,
    double? oxygenSaturation,
    double? temperature,
    double? respiratoryRate,
    double? glucoseLevel,
    double? weight,
    double? height,
    double? bmi,
    DateTime? timestamp,
    String? deviceId,
    String? recordedBy,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return VitalStatistics(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      heartRate: heartRate ?? this.heartRate,
      bloodPressureSystolic: bloodPressureSystolic ?? this.bloodPressureSystolic,
      bloodPressureDiastolic: bloodPressureDiastolic ?? this.bloodPressureDiastolic,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      temperature: temperature ?? this.temperature,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      glucoseLevel: glucoseLevel ?? this.glucoseLevel,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VitalStatistics &&
        other.id == id &&
        other.patientId == patientId &&
        other.heartRate == heartRate &&
        other.bloodPressureSystolic == bloodPressureSystolic &&
        other.bloodPressureDiastolic == bloodPressureDiastolic &&
        other.oxygenSaturation == oxygenSaturation &&
        other.temperature == temperature &&
        other.respiratoryRate == respiratoryRate &&
        other.glucoseLevel == glucoseLevel &&
        other.weight == weight &&
        other.height == height &&
        other.bmi == bmi &&
        other.timestamp == timestamp &&
        other.deviceId == deviceId &&
        other.recordedBy == recordedBy &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        patientId.hashCode ^
        heartRate.hashCode ^
        bloodPressureSystolic.hashCode ^
        bloodPressureDiastolic.hashCode ^
        oxygenSaturation.hashCode ^
        temperature.hashCode ^
        respiratoryRate.hashCode ^
        glucoseLevel.hashCode ^
        weight.hashCode ^
        height.hashCode ^
        bmi.hashCode ^
        timestamp.hashCode ^
        deviceId.hashCode ^
        recordedBy.hashCode ^
        notes.hashCode;
  }

  double? get systolicBP => bloodPressureSystolic;
  double? get diastolicBP => bloodPressureDiastolic;

  @override
  String toString() {
    return 'VitalStatistics(id: $id, patientId: $patientId, heartRate: $heartRate, bloodPressure: $bloodPressureSystolic/$bloodPressureDiastolic, oxygenSaturation: $oxygenSaturation, temperature: $temperature, timestamp: $timestamp)';
  }
}
