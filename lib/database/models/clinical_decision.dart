import 'base_model.dart';

class ClinicalDecision extends BaseModel {
  @override
  final String id;
  final String patientId;
  final String specialistId;
  final String conditionId;
  final String decisionType; // 'diagnosis', 'treatment', 'referral', 'medication'
  final String title;
  final String description;
  final String rationale;
  final String confidence; // 'low', 'medium', 'high'
  final List<String> evidence;
  final List<String> recommendations;
  final List<String> contraindications;
  final String status; // 'pending', 'approved', 'rejected', 'implemented'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  @override
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime? expiresAt;

  ClinicalDecision({
    required this.id,
    required this.patientId,
    required this.specialistId,
    required this.conditionId,
    required this.decisionType,
    required this.title,
    required this.description,
    required this.rationale,
    required this.confidence,
    required this.evidence,
    required this.recommendations,
    required this.contraindications,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    required this.metadata,
    required this.isActive,
    this.expiresAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'specialist_id': specialistId,
      'condition_id': conditionId,
      'decision_type': decisionType,
      'title': title,
      'description': description,
      'rationale': rationale,
      'confidence': confidence,
      'evidence': evidence.join(','),
      'recommendations': recommendations.join(','),
      'contraindications': contraindications.join(','),
      'status': status,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'metadata': metadata.toString(),
      'is_active': isActive ? 1 : 0,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory ClinicalDecision.fromMap(Map<String, dynamic> map) {
    return ClinicalDecision(
      id: map['id'] ?? '',
      patientId: map['patient_id'] ?? '',
      specialistId: map['specialist_id'] ?? '',
      conditionId: map['condition_id'] ?? '',
      decisionType: map['decision_type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rationale: map['rationale'] ?? '',
      confidence: map['confidence'] ?? '',
      evidence: map['evidence']?.split(',') ?? [],
      recommendations: map['recommendations']?.split(',') ?? [],
      contraindications: map['contraindications']?.split(',') ?? [],
      status: map['status'] ?? '',
      priority: map['priority'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      reviewedBy: map['reviewed_by'],
      reviewNotes: map['review_notes'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : {},
      isActive: (map['is_active'] ?? 0) == 1,
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
    );
  }

  ClinicalDecision copyWith({
    String? id,
    String? patientId,
    String? specialistId,
    String? conditionId,
    String? decisionType,
    String? title,
    String? description,
    String? rationale,
    String? confidence,
    List<String>? evidence,
    List<String>? recommendations,
    List<String>? contraindications,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
    Map<String, dynamic>? metadata,
    bool? isActive,
    DateTime? expiresAt,
  }) {
    return ClinicalDecision(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      specialistId: specialistId ?? this.specialistId,
      conditionId: conditionId ?? this.conditionId,
      decisionType: decisionType ?? this.decisionType,
      title: title ?? this.title,
      description: description ?? this.description,
      rationale: rationale ?? this.rationale,
      confidence: confidence ?? this.confidence,
      evidence: evidence ?? this.evidence,
      recommendations: recommendations ?? this.recommendations,
      contraindications: contraindications ?? this.contraindications,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}