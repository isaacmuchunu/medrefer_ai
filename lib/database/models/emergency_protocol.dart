import 'base_model.dart';

class EmergencyProtocol extends BaseModel {
  final String id;
  final String title;
  final String description;
  final String emergencyType; // 'medical', 'fire', 'security', 'natural_disaster', 'cyber'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String category; // 'cardiac', 'trauma', 'stroke', 'respiratory', 'general'
  final String status; // 'active', 'inactive', 'draft', 'archived'
  final String protocol;
  final List<String> steps;
  final List<String> requiredEquipment;
  final List<String> requiredPersonnel;
  final List<String> contacts;
  final String? departmentId;
  final String? facilityId;
  final String createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime lastReviewed;
  final DateTime? nextReview;
  final int version;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isPublic;

  EmergencyProtocol({
    required this.id,
    required this.title,
    required this.description,
    required this.emergencyType,
    required this.severity,
    required this.category,
    required this.status,
    required this.protocol,
    required this.steps,
    required this.requiredEquipment,
    required this.requiredPersonnel,
    required this.contacts,
    this.departmentId,
    this.facilityId,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    required this.lastReviewed,
    this.nextReview,
    required this.version,
    required this.tags,
    required this.metadata,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isPublic,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emergency_type': emergencyType,
      'severity': severity,
      'category': category,
      'status': status,
      'protocol': protocol,
      'steps': steps.join('|'),
      'required_equipment': requiredEquipment.join(','),
      'required_personnel': requiredPersonnel.join(','),
      'contacts': contacts.join(','),
      'department_id': departmentId,
      'facility_id': facilityId,
      'created_by': createdBy,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'last_reviewed': lastReviewed.toIso8601String(),
      'next_review': nextReview?.toIso8601String(),
      'version': version,
      'tags': tags.join(','),
      'metadata': metadata.toString(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_public': isPublic ? 1 : 0,
    };
  }

  factory EmergencyProtocol.fromMap(Map<String, dynamic> map) {
    return EmergencyProtocol(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      emergencyType: map['emergency_type'] ?? '',
      severity: map['severity'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      protocol: map['protocol'] ?? '',
      steps: map['steps']?.split('|') ?? [],
      requiredEquipment: map['required_equipment']?.split(',') ?? [],
      requiredPersonnel: map['required_personnel']?.split(',') ?? [],
      contacts: map['contacts']?.split(',') ?? [],
      departmentId: map['department_id'],
      facilityId: map['facility_id'],
      createdBy: map['created_by'] ?? '',
      approvedBy: map['approved_by'],
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      lastReviewed: DateTime.parse(map['last_reviewed'] ?? DateTime.now().toIso8601String()),
      nextReview: map['next_review'] != null ? DateTime.parse(map['next_review']) : null,
      version: map['version'] ?? 1,
      tags: map['tags']?.split(',') ?? [],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : {},
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
      isPublic: (map['is_public'] ?? 0) == 1,
    );
  }

  EmergencyProtocol copyWith({
    String? id,
    String? title,
    String? description,
    String? emergencyType,
    String? severity,
    String? category,
    String? status,
    String? protocol,
    List<String>? steps,
    List<String>? requiredEquipment,
    List<String>? requiredPersonnel,
    List<String>? contacts,
    String? departmentId,
    String? facilityId,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? lastReviewed,
    DateTime? nextReview,
    int? version,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPublic,
  }) {
    return EmergencyProtocol(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emergencyType: emergencyType ?? this.emergencyType,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      status: status ?? this.status,
      protocol: protocol ?? this.protocol,
      steps: steps ?? this.steps,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      requiredPersonnel: requiredPersonnel ?? this.requiredPersonnel,
      contacts: contacts ?? this.contacts,
      departmentId: departmentId ?? this.departmentId,
      facilityId: facilityId ?? this.facilityId,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      version: version ?? this.version,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  bool get isApproved => approvedBy != null && approvedAt != null;
  
  bool get needsReview => nextReview != null && DateTime.now().isAfter(nextReview!);
  
  bool get isCritical => severity == 'critical';
}