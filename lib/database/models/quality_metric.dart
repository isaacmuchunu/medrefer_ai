import 'base_model.dart';

class QualityMetric extends BaseModel {
  @override
  final String id;
  final String metricType; // 'patient_satisfaction', 'response_time', 'outcome', 'compliance'
  final String title;
  final String description;
  final String category; // 'clinical', 'operational', 'financial', 'safety'
  final String measurement; // 'percentage', 'count', 'time', 'score'
  final double targetValue;
  final double currentValue;
  final String unit; // '%', 'hours', 'days', 'score'
  final String period; // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final DateTime measurementDate;
  final String? departmentId;
  final String? specialistId;
  final String? facilityId;
  final Map<String, dynamic> breakdown; // Detailed breakdown of the metric
  final List<String> tags;
  final String status; // 'good', 'warning', 'critical', 'improving', 'declining'
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final bool isActive;

  QualityMetric({
    required this.id,
    required this.metricType,
    required this.title,
    required this.description,
    required this.category,
    required this.measurement,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.period,
    required this.measurementDate,
    this.departmentId,
    this.specialistId,
    this.facilityId,
    required this.breakdown,
    required this.tags,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metric_type': metricType,
      'title': title,
      'description': description,
      'category': category,
      'measurement': measurement,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'period': period,
      'measurement_date': measurementDate.toIso8601String(),
      'department_id': departmentId,
      'specialist_id': specialistId,
      'facility_id': facilityId,
      'breakdown': breakdown.toString(),
      'tags': tags.join(','),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory QualityMetric.fromMap(Map<String, dynamic> map) {
    return QualityMetric(
      id: map['id'] ?? '',
      metricType: map['metric_type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      measurement: map['measurement'] ?? '',
      targetValue: (map['target_value'] ?? 0.0).toDouble(),
      currentValue: (map['current_value'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      period: map['period'] ?? '',
      measurementDate: DateTime.parse(map['measurement_date'] ?? DateTime.now().toIso8601String()),
      departmentId: map['department_id'],
      specialistId: map['specialist_id'],
      facilityId: map['facility_id'],
      breakdown: map['breakdown'] != null ? Map<String, dynamic>.from(map['breakdown']) : {},
      tags: map['tags']?.split(',') ?? [],
      status: map['status'] ?? '',
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
    );
  }

  QualityMetric copyWith({
    String? id,
    String? metricType,
    String? title,
    String? description,
    String? category,
    String? measurement,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? period,
    DateTime? measurementDate,
    String? departmentId,
    String? specialistId,
    String? facilityId,
    Map<String, dynamic>? breakdown,
    List<String>? tags,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return QualityMetric(
      id: id ?? this.id,
      metricType: metricType ?? this.metricType,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      measurement: measurement ?? this.measurement,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      period: period ?? this.period,
      measurementDate: measurementDate ?? this.measurementDate,
      departmentId: departmentId ?? this.departmentId,
      specialistId: specialistId ?? this.specialistId,
      facilityId: facilityId ?? this.facilityId,
      breakdown: breakdown ?? this.breakdown,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  double get performancePercentage => targetValue > 0 ? (currentValue / targetValue) * 100 : 0;
  
  bool get isTargetMet => currentValue >= targetValue;
  
  String get performanceStatus {
    if (performancePercentage >= 100) return 'excellent';
    if (performancePercentage >= 80) return 'good';
    if (performancePercentage >= 60) return 'fair';
    return 'poor';
  }
}