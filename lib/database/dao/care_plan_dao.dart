import '../database_helper.dart';
import '../models/care_plan.dart';

class CarePlanDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'care_plans';

  Future<String> createCarePlan(CarePlan plan) async {
    return await _dbHelper.insert(tableName, plan.toMap());
  }

  Future<bool> updateCarePlan(CarePlan plan) async {
    plan.updateTimestamp();
    final rows = await _dbHelper.update(tableName, plan.toMap(), plan.id);
    return rows > 0;
  }

  Future<bool> deleteCarePlan(String id) async {
    final rows = await _dbHelper.delete(tableName, id);
    return rows > 0;
  }

  Future<CarePlan?> getCarePlanById(String id) async {
    final map = await _dbHelper.queryById(tableName, id);
    return map != null ? CarePlan.fromMap(map) : null;
  }

  Future<List<CarePlan>> getCarePlansByPatientId(String patientId) async {
    final maps = await _dbHelper.query(
      tableName,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'updated_at DESC',
    );
    return maps.map(CarePlan.fromMap).toList();
  }

  Future<int> getActiveCarePlanCount(String patientId) async {
    return await _dbHelper.getCount(
      tableName,
      where: "patient_id = ? AND status = 'active'",
      whereArgs: [patientId],
    );
  }
}

