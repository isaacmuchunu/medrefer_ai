import 'base_model.dart';

class MedicalEducation extends BaseModel {
  @override
  final String id;
  final String title;
  final String description;
  final String type; // 'course', 'webinar', 'conference', 'workshop', 'certification'
  final String category; // 'clinical', 'research', 'management', 'technology', 'ethics'
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final String provider;
  final String instructor;
  final String? institution;
  final String? department;
  final DateTime startDate;
  final DateTime? endDate;
  final int duration; // in hours
  final int maxParticipants;
  final int currentParticipants;
  final double cost;
  final String currency;
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final List<String> topics;
  final String? materials;
  final String? certificate;
  final double cmeCredits;
  final String? location;
  final String? meetingLink;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final bool isActive;
  final bool isPublic;

  MedicalEducation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.status,
    required this.provider,
    required this.instructor,
    this.institution,
    this.department,
    required this.startDate,
    this.endDate,
    required this.duration,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.cost,
    required this.currency,
    required this.learningObjectives,
    required this.prerequisites,
    required this.topics,
    this.materials,
    this.certificate,
    required this.cmeCredits,
    this.location,
    this.meetingLink,
    required this.tags,
    required this.metadata,
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
      'type': type,
      'category': category,
      'status': status,
      'provider': provider,
      'instructor': instructor,
      'institution': institution,
      'department': department,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration': duration,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'cost': cost,
      'currency': currency,
      'learning_objectives': learningObjectives.join('|'),
      'prerequisites': prerequisites.join(','),
      'topics': topics.join(','),
      'materials': materials,
      'certificate': certificate,
      'cme_credits': cmeCredits,
      'location': location,
      'meeting_link': meetingLink,
      'tags': tags.join(','),
      'metadata': metadata.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_public': isPublic ? 1 : 0,
    };
  }

  factory MedicalEducation.fromMap(Map<String, dynamic> map) {
    return MedicalEducation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      provider: map['provider'] ?? '',
      instructor: map['instructor'] ?? '',
      institution: map['institution'],
      department: map['department'],
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      duration: map['duration'] ?? 0,
      maxParticipants: map['max_participants'] ?? 0,
      currentParticipants: map['current_participants'] ?? 0,
      cost: (map['cost'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      learningObjectives: map['learning_objectives']?.split('|') ?? [],
      prerequisites: map['prerequisites']?.split(',') ?? [],
      topics: map['topics']?.split(',') ?? [],
      materials: map['materials'],
      certificate: map['certificate'],
      cmeCredits: (map['cme_credits'] ?? 0.0).toDouble(),
      location: map['location'],
      meetingLink: map['meeting_link'],
      tags: map['tags']?.split(',') ?? [],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
      isPublic: (map['is_public'] ?? 0) == 1,
    );
  }

  MedicalEducation copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? category,
    String? status,
    String? provider,
    String? instructor,
    String? institution,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    int? duration,
    int? maxParticipants,
    int? currentParticipants,
    double? cost,
    String? currency,
    List<String>? learningObjectives,
    List<String>? prerequisites,
    List<String>? topics,
    String? materials,
    String? certificate,
    double? cmeCredits,
    String? location,
    String? meetingLink,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPublic,
  }) {
    return MedicalEducation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      provider: provider ?? this.provider,
      instructor: instructor ?? this.instructor,
      institution: institution ?? this.institution,
      department: department ?? this.department,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      duration: duration ?? this.duration,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      prerequisites: prerequisites ?? this.prerequisites,
      topics: topics ?? this.topics,
      materials: materials ?? this.materials,
      certificate: certificate ?? this.certificate,
      cmeCredits: cmeCredits ?? this.cmeCredits,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  double get enrollmentProgress => maxParticipants > 0 ? (currentParticipants / maxParticipants) * 100 : 0;
  
  bool get isFull => currentParticipants >= maxParticipants;
  
  bool get isUpcoming => status == 'upcoming' && DateTime.now().isBefore(startDate);
  
  bool get isOngoing => status == 'ongoing' && (endDate == null || DateTime.now().isBefore(endDate!));
}