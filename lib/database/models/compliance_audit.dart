import 'base_model.dart';

class ComplianceAudit extends BaseModel {
  @override
  final String id;
  final String auditType; // 'hipaa', 'gdpr', 'sox', 'iso27001', 'internal'
  final String title;
  final String description;
  final String status; // 'scheduled', 'in_progress', 'completed', 'failed', 'remediation'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String category; // 'data_protection', 'access_control', 'encryption', 'backup', 'training'
  final String? departmentId;
  final String? facilityId;
  final String auditorId;
  final String? assignedTo;
  final DateTime scheduledDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? dueDate;
  final List<String> checkpoints;
  final List<String> findings;
  final List<String> recommendations;
  final List<String> evidence;
  final String? report;
  final double complianceScore;
  final double targetScore;
  final Map<String, dynamic> details;
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final bool isActive;
  final bool requiresRemediation;

  ComplianceAudit({
    required this.id,
    required this.auditType,
    required this.title,
    required this.description,
    required this.status,
    required this.severity,
    required this.category,
    this.departmentId,
    this.facilityId,
    required this.auditorId,
    this.assignedTo,
    required this.scheduledDate,
    this.startDate,
    this.endDate,
    this.dueDate,
    required this.checkpoints,
    required this.findings,
    required this.recommendations,
    required this.evidence,
    this.report,
    required this.complianceScore,
    required this.targetScore,
    required this.details,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.requiresRemediation,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audit_type': auditType,
      'title': title,
      'description': description,
      'status': status,
      'severity': severity,
      'category': category,
      'department_id': departmentId,
      'facility_id': facilityId,
      'auditor_id': auditorId,
      'assigned_to': assignedTo,
      'scheduled_date': scheduledDate.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'checkpoints': checkpoints.join(','),
      'findings': findings.join(','),
      'recommendations': recommendations.join(','),
      'evidence': evidence.join(','),
      'report': report,
      'compliance_score': complianceScore,
      'target_score': targetScore,
      'details': details.toString(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'requires_remediation': requiresRemediation ? 1 : 0,
    };
  }

  factory ComplianceAudit.fromMap(Map<String, dynamic> map) {
    return ComplianceAudit(
      id: map['id'] ?? '',
      auditType: map['audit_type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      severity: map['severity'] ?? '',
      category: map['category'] ?? '',
      departmentId: map['department_id'],
      facilityId: map['facility_id'],
      auditorId: map['auditor_id'] ?? '',
      assignedTo: map['assigned_to'],
      scheduledDate: DateTime.parse(map['scheduled_date'] ?? DateTime.now().toIso8601String()),
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      checkpoints: map['checkpoints']?.split(',') ?? [],
      findings: map['findings']?.split(',') ?? [],
      recommendations: map['recommendations']?.split(',') ?? [],
      evidence: map['evidence']?.split(',') ?? [],
      report: map['report'],
      complianceScore: (map['compliance_score'] ?? 0.0).toDouble(),
      targetScore: (map['target_score'] ?? 100.0).toDouble(),
      details: map['details'] != null ? Map<String, dynamic>.from(map['details']) : {},
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
      requiresRemediation: (map['requires_remediation'] ?? 0) == 1,
    );
  }

  ComplianceAudit copyWith({
    String? id,
    String? auditType,
    String? title,
    String? description,
    String? status,
    String? severity,
    String? category,
    String? departmentId,
    String? facilityId,
    String? auditorId,
    String? assignedTo,
    DateTime? scheduledDate,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    List<String>? checkpoints,
    List<String>? findings,
    List<String>? recommendations,
    List<String>? evidence,
    String? report,
    double? complianceScore,
    double? targetScore,
    Map<String, dynamic>? details,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? requiresRemediation,
  }) {
    return ComplianceAudit(
      id: id ?? this.id,
      auditType: auditType ?? this.auditType,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      departmentId: departmentId ?? this.departmentId,
      facilityId: facilityId ?? this.facilityId,
      auditorId: auditorId ?? this.auditorId,
      assignedTo: assignedTo ?? this.assignedTo,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dueDate: dueDate ?? this.dueDate,
      checkpoints: checkpoints ?? this.checkpoints,
      findings: findings ?? this.findings,
      recommendations: recommendations ?? this.recommendations,
      evidence: evidence ?? this.evidence,
      report: report ?? this.report,
      complianceScore: complianceScore ?? this.complianceScore,
      targetScore: targetScore ?? this.targetScore,
      details: details ?? this.details,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      requiresRemediation: requiresRemediation ?? this.requiresRemediation,
    );
  }

  double get compliancePercentage => targetScore > 0 ? (complianceScore / targetScore) * 100 : 0;
  
  bool get isCompliant => complianceScore >= targetScore;
  
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && status != 'completed';
  
  String get complianceStatus {
    if (compliancePercentage >= 95) return 'excellent';
    if (compliancePercentage >= 85) return 'good';
    if (compliancePercentage >= 70) return 'fair';
    return 'poor';
  }
}