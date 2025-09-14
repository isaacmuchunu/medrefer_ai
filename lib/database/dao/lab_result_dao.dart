import '../../database/database_helper.dart';
import '../models/models.dart';

class LabResultDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'lab_results';

  Future<String> createLabResult(LabResult labResult) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, labResult.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create lab result: $e');
    }
  }

  Future<List<LabResult>> getAllLabResults() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) => LabResult.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all lab results: $e');
    }
  }

  Future<LabResult?> getLabResultById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return LabResult.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lab result by id: $e');
    }
  }

  Future<List<LabResult>> getLabResultsByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'patient_id = ?', whereArgs: [patientId]);
      return List.generate(maps.length, (i) => LabResult.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get lab results by patient id: $e');
    }
  }

  Future<bool> updateLabResult(LabResult labResult) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, labResult.toMap(), where: 'id = ?', whereArgs: [labResult.id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update lab result: $e');
    }
  }

  Future<bool> deleteLabResult(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete lab result: $e');
    }
  }

  Future<int> getTotalLabResultsCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return result.first.values.first as int;
    } catch (e) {
      throw Exception('Failed to get total lab results count: $e');
    }
  }
}
