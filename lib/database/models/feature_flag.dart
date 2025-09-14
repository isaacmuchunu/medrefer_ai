import 'base_model.dart';

class FeatureFlag extends BaseModel {
  final String key;
  final bool isEnabled;
  final String? description;
  final String? rolloutStrategy; // e.g., percentage, user-role, tenant
  final double? rolloutPercentage;

  FeatureFlag({
    super.id,
    required this.key,
    required this.isEnabled,
    this.description,
    this.rolloutStrategy,
    this.rolloutPercentage,
    super.createdAt,
    super.updatedAt,
  });

  factory FeatureFlag.fromMap(Map<String, dynamic> map) {
    return FeatureFlag(
      id: map['id'],
      key: map['key'],
      isEnabled: (map['is_enabled'] ?? 0) == 1,
      description: map['description'],
      rolloutStrategy: map['rollout_strategy'],
      rolloutPercentage: (map['rollout_percentage'] as num?)?.toDouble(),
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'key': key,
      'is_enabled': isEnabled ? 1 : 0,
      'description': description,
      'rollout_strategy': rolloutStrategy,
      'rollout_percentage': rolloutPercentage,
    });
    return map;
  }
}

