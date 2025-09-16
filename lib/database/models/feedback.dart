import 'base_model.dart';

class Feedback extends BaseModel {
  final String? userId;
  final String? referralId;
  final String? patientId;
  final String? specialistId;
  final int? rating;
  final String? comments;
  final String? type;
  final String? category;

  Feedback({
    super.id,
    this.userId,
    this.referralId,
    this.patientId,
    this.specialistId,
    this.rating,
    this.comments,
    this.type,
    this.category,
    super.createdAt,
    super.updatedAt,
  });

  factory Feedback.fromMap(Map<String, dynamic> map) {
    return Feedback(
      id: map['id'] as String?,
      userId: map['userId'] as String?,
      referralId: map['referralId'] as String?,
      patientId: map['patientId'] as String?,
      specialistId: map['specialistId'] as String?,
      rating: map['rating'] as int?,
      comments: map['comments'] as String?,
      type: map['type'] as String?,
      category: map['category'] as String?,
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
      'userId': userId,
      'referralId': referralId,
      'patientId': patientId,
      'specialistId': specialistId,
      'rating': rating,
      'comments': comments,
      'type': type,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Feedback copyWith({
    String? id,
    String? userId,
    String? referralId,
    String? patientId,
    String? specialistId,
    int? rating,
    String? comments,
    String? type,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referralId: referralId ?? this.referralId,
      patientId: patientId ?? this.patientId,
      specialistId: specialistId ?? this.specialistId,
      rating: rating ?? this.rating,
      comments: comments ?? this.comments,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}