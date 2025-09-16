import '../database_helper.dart';
import '../models/models.dart';

class ConditionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'conditions';

  // Create
  Future<String> createCondition(Condition condition) async {
    try {
      return await _dbHelper.insert(tableName, condition.toMap());
    } catch (e) {
      throw Exception('Failed to create condition: $e');
    }
  }

  // Read
  Future<List<Condition>> getAllConditions() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'name ASC');
      return maps.map(Condition.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get conditions: $e');
    }
  }

  Future<Condition?> getConditionById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? Condition.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get condition: $e');
    }
  }

  Future<List<Condition>> getConditionsByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'diagnosed_date DESC',
      );
      return maps.map(Condition.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get conditions by patient: $e');
    }
  }

  Future<List<Condition>> getActiveConditions(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ? AND is_active = 1',
        whereArgs: [patientId],
        orderBy: 'severity DESC',
      );
      return maps.map(Condition.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get active conditions: $e');
    }
  }

  // Update
  Future<bool> updateCondition(Condition condition) async {
    try {
      condition.updatedAt = DateTime.now();
      final rowsAffected = await _dbHelper.update(tableName, condition.toMap(), condition.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update condition: $e');
    }
  }

  // Delete
  Future<bool> deleteCondition(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete condition: $e');
    }
  }

  // Batch Create
  Future<void> createMultipleConditions(List<Condition> conditions) async {
    for (var condition in conditions) {
      await createCondition(condition);
    }
  }

  // Statistics
  Future<int> getTotalConditionsCount(String patientId) async {
    try {
      return await _dbHelper.getCount(tableName, where: 'patient_id = ?', whereArgs: [patientId]);
    } catch (e) {
      throw Exception('Failed to get conditions count: $e');
    }
  }
}