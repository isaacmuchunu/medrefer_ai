import 'base_model.dart';

enum CarePlanStatus { active, onHold, completed, cancelled }

class CarePlan extends BaseModel {
  final String patientId;
  String title;
  String description;
  CarePlanStatus status;
  DateTime startDate;
  DateTime? endDate;
  List<String> goals;
  List<String> interventions;
  List<String> assignedTo; // userIds or role names

  CarePlan({
    super.id,
    required this.patientId,
    required this.title,
    required this.description,
    this.status = CarePlanStatus.active,
    DateTime? startDate,
    this.endDate,
    this.goals = const [],
    this.interventions = const [],
    this.assignedTo = const [],
    super.createdAt,
    super.updatedAt,
  }) : startDate = startDate ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'patient_id': patientId,
      'title': title,
      'description': description,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'goals': BaseModel.stringListToJson(goals),
      'interventions': BaseModel.stringListToJson(interventions),
      'assigned_to': BaseModel.stringListToJson(assignedTo),
    });
    return map;
  }

  factory CarePlan.fromMap(Map<String, dynamic> map) {
    return CarePlan(
      id: map['id'],
      patientId: map['patient_id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: CarePlanStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => CarePlanStatus.active,
      ),
      startDate: BaseModel.parseDateTime(map['start_date']),
      endDate: BaseModel.parseDateTime(map['end_date']),
      goals: BaseModel.parseStringList(map['goals']),
      interventions: BaseModel.parseStringList(map['interventions']),
      assignedTo: BaseModel.parseStringList(map['assigned_to']),
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }
}

