import 'base_model.dart';

class ResearchStudy extends BaseModel {
  @override
  final String id;
  final String title;
  final String description;
  final String studyType; // 'observational', 'interventional', 'retrospective', 'prospective'
  final String status; // 'planning', 'recruiting', 'active', 'completed', 'suspended', 'terminated'
  final String principalInvestigator;
  final List<String> coInvestigators;
  final String institution;
  final String department;
  final String protocol;
  final String objectives;
  final String methodology;
  final String inclusionCriteria;
  final String exclusionCriteria;
  final int targetParticipants;
  final int currentParticipants;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? estimatedCompletion;
  final String fundingSource;
  final String ethicalApproval;
  final String irbNumber;
  final List<String> keywords;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? results;
  final String? conclusions;
  final List<String> publications;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final bool isActive;
  final bool isPublic;

  ResearchStudy({
    required this.id,
    required this.title,
    required this.description,
    required this.studyType,
    required this.status,
    required this.principalInvestigator,
    required this.coInvestigators,
    required this.institution,
    required this.department,
    required this.protocol,
    required this.objectives,
    required this.methodology,
    required this.inclusionCriteria,
    required this.exclusionCriteria,
    required this.targetParticipants,
    required this.currentParticipants,
    required this.startDate,
    this.endDate,
    this.estimatedCompletion,
    required this.fundingSource,
    required this.ethicalApproval,
    required this.irbNumber,
    required this.keywords,
    required this.tags,
    required this.metadata,
    this.results,
    this.conclusions,
    required this.publications,
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
      'study_type': studyType,
      'status': status,
      'principal_investigator': principalInvestigator,
      'co_investigators': coInvestigators.join(','),
      'institution': institution,
      'department': department,
      'protocol': protocol,
      'objectives': objectives,
      'methodology': methodology,
      'inclusion_criteria': inclusionCriteria,
      'exclusion_criteria': exclusionCriteria,
      'target_participants': targetParticipants,
      'current_participants': currentParticipants,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'estimated_completion': estimatedCompletion?.toIso8601String(),
      'funding_source': fundingSource,
      'ethical_approval': ethicalApproval,
      'irb_number': irbNumber,
      'keywords': keywords.join(','),
      'tags': tags.join(','),
      'metadata': metadata.toString(),
      'results': results,
      'conclusions': conclusions,
      'publications': publications.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_public': isPublic ? 1 : 0,
    };
  }

  factory ResearchStudy.fromMap(Map<String, dynamic> map) {
    return ResearchStudy(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      studyType: map['study_type'] ?? '',
      status: map['status'] ?? '',
      principalInvestigator: map['principal_investigator'] ?? '',
      coInvestigators: map['co_investigators']?.split(',') ?? [],
      institution: map['institution'] ?? '',
      department: map['department'] ?? '',
      protocol: map['protocol'] ?? '',
      objectives: map['objectives'] ?? '',
      methodology: map['methodology'] ?? '',
      inclusionCriteria: map['inclusion_criteria'] ?? '',
      exclusionCriteria: map['exclusion_criteria'] ?? '',
      targetParticipants: map['target_participants'] ?? 0,
      currentParticipants: map['current_participants'] ?? 0,
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      estimatedCompletion: map['estimated_completion'] != null ? DateTime.parse(map['estimated_completion']) : null,
      fundingSource: map['funding_source'] ?? '',
      ethicalApproval: map['ethical_approval'] ?? '',
      irbNumber: map['irb_number'] ?? '',
      keywords: map['keywords']?.split(',') ?? [],
      tags: map['tags']?.split(',') ?? [],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : {},
      results: map['results'],
      conclusions: map['conclusions'],
      publications: map['publications']?.split(',') ?? [],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
      isPublic: (map['is_public'] ?? 0) == 1,
    );
  }

  ResearchStudy copyWith({
    String? id,
    String? title,
    String? description,
    String? studyType,
    String? status,
    String? principalInvestigator,
    List<String>? coInvestigators,
    String? institution,
    String? department,
    String? protocol,
    String? objectives,
    String? methodology,
    String? inclusionCriteria,
    String? exclusionCriteria,
    int? targetParticipants,
    int? currentParticipants,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? estimatedCompletion,
    String? fundingSource,
    String? ethicalApproval,
    String? irbNumber,
    List<String>? keywords,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? results,
    String? conclusions,
    List<String>? publications,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPublic,
  }) {
    return ResearchStudy(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      studyType: studyType ?? this.studyType,
      status: status ?? this.status,
      principalInvestigator: principalInvestigator ?? this.principalInvestigator,
      coInvestigators: coInvestigators ?? this.coInvestigators,
      institution: institution ?? this.institution,
      department: department ?? this.department,
      protocol: protocol ?? this.protocol,
      objectives: objectives ?? this.objectives,
      methodology: methodology ?? this.methodology,
      inclusionCriteria: inclusionCriteria ?? this.inclusionCriteria,
      exclusionCriteria: exclusionCriteria ?? this.exclusionCriteria,
      targetParticipants: targetParticipants ?? this.targetParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      fundingSource: fundingSource ?? this.fundingSource,
      ethicalApproval: ethicalApproval ?? this.ethicalApproval,
      irbNumber: irbNumber ?? this.irbNumber,
      keywords: keywords ?? this.keywords,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      results: results ?? this.results,
      conclusions: conclusions ?? this.conclusions,
      publications: publications ?? this.publications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  double get recruitmentProgress => targetParticipants > 0 ? (currentParticipants / targetParticipants) * 100 : 0;
  
  bool get isRecruiting => status == 'recruiting' && currentParticipants < targetParticipants;
  
  bool get isCompleted => status == 'completed' || (endDate != null && DateTime.now().isAfter(endDate!));
}