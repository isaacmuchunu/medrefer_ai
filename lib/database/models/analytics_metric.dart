import 'package:medrefer_ai/core/app_export.dart';

/// Analytics metric model for tracking various business metrics
class AnalyticsMetric extends BaseModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? userId;
  final String? organizationId;

  AnalyticsMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
    this.userId,
    this.organizationId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': jsonEncode(metadata),
      'user_id': userId,
      'organization_id': organizationId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AnalyticsMetric.fromMap(Map<String, dynamic> map) {
    return AnalyticsMetric(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      value: (map['value'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      userId: map['user_id'],
      organizationId: map['organization_id'],
    );
  }

  AnalyticsMetric copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? value,
    String? unit,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? userId,
    String? organizationId,
  }) {
    return AnalyticsMetric(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}

/// Analytics dashboard configuration
class DashboardConfig extends BaseModel {
  final String id;
  final String name;
  final String description;
  final List<String> metricIds;
  final String layoutType; // grid, list, custom
  final Map<String, dynamic> layoutConfig;
  final bool isDefault;
  final String? userId;
  final String? organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.metricIds,
    required this.layoutType,
    this.layoutConfig = const {},
    this.isDefault = false,
    this.userId,
    this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metric_ids': jsonEncode(metricIds),
      'layout_type': layoutType,
      'layout_config': jsonEncode(layoutConfig),
      'is_default': isDefault ? 1 : 0,
      'user_id': userId,
      'organization_id': organizationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    return DashboardConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      metricIds: map['metric_ids'] != null 
          ? List<String>.from(jsonDecode(map['metric_ids'])) 
          : [],
      layoutType: map['layout_type'] ?? 'grid',
      layoutConfig: map['layout_config'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['layout_config'])) 
          : {},
      isDefault: (map['is_default'] ?? 0) == 1,
      userId: map['user_id'],
      organizationId: map['organization_id'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Analytics report model
class AnalyticsReport extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String reportType; // daily, weekly, monthly, custom
  final List<String> metricIds;
  final Map<String, dynamic> filters;
  final String format; // pdf, excel, csv, json
  final bool isScheduled;
  final String? scheduleExpression; // cron expression
  final String? userId;
  final String? organizationId;
  final DateTime? lastGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnalyticsReport({
    required this.id,
    required this.name,
    required this.description,
    required this.reportType,
    required this.metricIds,
    this.filters = const {},
    required this.format,
    this.isScheduled = false,
    this.scheduleExpression,
    this.userId,
    this.organizationId,
    this.lastGenerated,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'report_type': reportType,
      'metric_ids': jsonEncode(metricIds),
      'filters': jsonEncode(filters),
      'format': format,
      'is_scheduled': isScheduled ? 1 : 0,
      'schedule_expression': scheduleExpression,
      'user_id': userId,
      'organization_id': organizationId,
      'last_generated': lastGenerated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AnalyticsReport.fromMap(Map<String, dynamic> map) {
    return AnalyticsReport(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      reportType: map['report_type'] ?? 'daily',
      metricIds: map['metric_ids'] != null 
          ? List<String>.from(jsonDecode(map['metric_ids'])) 
          : [],
      filters: map['filters'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['filters'])) 
          : {},
      format: map['format'] ?? 'pdf',
      isScheduled: (map['is_scheduled'] ?? 0) == 1,
      scheduleExpression: map['schedule_expression'],
      userId: map['user_id'],
      organizationId: map['organization_id'],
      lastGenerated: map['last_generated'] != null 
          ? DateTime.parse(map['last_generated']) 
          : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Key Performance Indicator model
class KPI extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double currentValue;
  final double targetValue;
  final String unit;
  final String trend; // up, down, stable
  final double percentageChange;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  KPI({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.trend,
    required this.percentageChange,
    required this.lastUpdated,
    this.metadata = const {},
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'current_value': currentValue,
      'target_value': targetValue,
      'unit': unit,
      'trend': trend,
      'percentage_change': percentageChange,
      'last_updated': lastUpdated.toIso8601String(),
      'metadata': jsonEncode(metadata),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory KPI.fromMap(Map<String, dynamic> map) {
    return KPI(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      currentValue: (map['current_value'] ?? 0.0).toDouble(),
      targetValue: (map['target_value'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      trend: map['trend'] ?? 'stable',
      percentageChange: (map['percentage_change'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(map['last_updated'] ?? DateTime.now().toIso8601String()),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
    );
  }
}