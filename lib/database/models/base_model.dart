import 'package:uuid/uuid.dart';

abstract class BaseModel {
  String id;
  DateTime createdAt;
  DateTime updatedAt;

  BaseModel({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap();
  
  void updateTimestamp() {
    updatedAt = DateTime.now();
  }

  // Common fields for all models
  Map<String, dynamic> baseToMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to parse DateTime from string
  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  // Helper method to parse list from JSON string
  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        // Simple comma-separated parsing for now
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Helper method to convert list to JSON string
  static String stringListToJson(List<String> list) {
    return list.join(',');
  }
}
