import 'base_model.dart';

class LabResult extends BaseModel {
  final String? patientId;
  final String? testName;
  final String? testType;
  final String? result;
  final String? unit;
  final String? referenceRange;
  final String? status;
  final DateTime? testDate;
  final String? orderedBy;
  final String? performedBy;
  final String? notes;

  LabResult({
    super.id,
    this.patientId,
    this.testName,
    this.testType,
    this.result,
    this.unit,
    this.referenceRange,
    this.status,
    this.testDate,
    this.orderedBy,
    this.performedBy,
    this.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory LabResult.fromMap(Map<String, dynamic> map) {
    return LabResult(
      id: map['id'] as String?,
      patientId: map['patientId'] as String?,
      testName: map['testName'] as String?,
      testType: map['testType'] as String?,
      result: map['result'] as String?,
      unit: map['unit'] as String?,
      referenceRange: map['referenceRange'] as String?,
      status: map['status'] as String?,
      testDate: map['testDate'] != null 
          ? DateTime.parse(map['testDate'] as String) 
          : null,
      orderedBy: map['orderedBy'] as String?,
      performedBy: map['performedBy'] as String?,
      notes: map['notes'] as String?,
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
      'testName': testName,
      'testType': testType,
      'result': result,
      'unit': unit,
      'referenceRange': referenceRange,
      'status': status,
      'testDate': testDate?.toIso8601String(),
      'orderedBy': orderedBy,
      'performedBy': performedBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LabResult copyWith({
    String? id,
    String? patientId,
    String? testName,
    String? testType,
    String? result,
    String? unit,
    String? referenceRange,
    String? status,
    DateTime? testDate,
    String? orderedBy,
    String? performedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabResult(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      testName: testName ?? this.testName,
      testType: testType ?? this.testType,
      result: result ?? this.result,
      unit: unit ?? this.unit,
      referenceRange: referenceRange ?? this.referenceRange,
      status: status ?? this.status,
      testDate: testDate ?? this.testDate,
      orderedBy: orderedBy ?? this.orderedBy,
      performedBy: performedBy ?? this.performedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}