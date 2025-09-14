import 'base_model.dart';

class Specialist extends BaseModel {
  String name;
  String? credentials;
  String specialty;
  String hospital;
  String? profileImageUrl;
  bool isAvailable;
  double rating;
  String? distance;
  List<String> languages;
  List<String> insurance;
  String? hospitalNetwork;
  double successRate;
  String? matchReason;
  double? latitude;
  double? longitude;

  Specialist({
    super.id,
    required this.name,
    this.credentials,
    required this.specialty,
    required this.hospital,
    this.profileImageUrl,
    this.isAvailable = true,
    this.rating = 0.0,
    this.distance,
    this.languages = const [],
    this.insurance = const [],
    this.hospitalNetwork,
    this.successRate = 0.0,
    this.matchReason,
    this.latitude,
    this.longitude,
    super.createdAt,
    super.updatedAt,
  });

  factory Specialist.fromMap(Map<String, dynamic> map) {
    return Specialist(
      id: map['id'],
      name: map['name'] ?? '',
      credentials: map['credentials'],
      specialty: map['specialty'] ?? '',
      hospital: map['hospital'] ?? '',
      profileImageUrl: map['profile_image_url'],
      isAvailable: (map['is_available'] ?? 1) == 1,
      rating: (map['rating'] ?? 0.0).toDouble(),
      distance: map['distance'],
      languages: BaseModel.parseStringList(map['languages']),
      insurance: BaseModel.parseStringList(map['insurance']),
      hospitalNetwork: map['hospital_network'],
      successRate: (map['success_rate'] ?? 0.0).toDouble(),
      matchReason: map['match_reason'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'name': name,
      'credentials': credentials,
      'specialty': specialty,
      'hospital': hospital,
      'profile_image_url': profileImageUrl,
      'is_available': isAvailable ? 1 : 0,
      'rating': rating,
      'distance': distance,
      'languages': BaseModel.stringListToJson(languages),
      'insurance': BaseModel.stringListToJson(insurance),
      'hospital_network': hospitalNetwork,
      'success_rate': successRate,
      'match_reason': matchReason,
      'latitude': latitude,
      'longitude': longitude,
    });
    return map;
  }

  Specialist copyWith({
    String? name,
    String? credentials,
    String? specialty,
    String? hospital,
    String? profileImageUrl,
    bool? isAvailable,
    double? rating,
    String? distance,
    List<String>? languages,
    List<String>? insurance,
    String? hospitalNetwork,
    double? successRate,
    String? matchReason,
    double? latitude,
    double? longitude,
  }) {
    return Specialist(
      id: id,
      name: name ?? this.name,
      credentials: credentials ?? this.credentials,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      languages: languages ?? this.languages,
      insurance: insurance ?? this.insurance,
      hospitalNetwork: hospitalNetwork ?? this.hospitalNetwork,
      successRate: successRate ?? this.successRate,
      matchReason: matchReason ?? this.matchReason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Specialist{id: $id, name: $name, specialty: $specialty, hospital: $hospital}';
  }
}
