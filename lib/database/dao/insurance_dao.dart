import '../../database/database_helper.dart';
import '../models/models.dart';

class InsuranceDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'insurance';

  Future<String> createInsurance(Insurance insurance) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, insurance.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create insurance: $e');
    }
  }

  Future<List<Insurance>> getAllInsurance() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) => Insurance.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all insurance: $e');
    }
  }

  Future<Insurance?> getInsuranceById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Insurance.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get insurance by id: $e');
    }
  }

  Future<List<Insurance>> getInsuranceByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'patient_id = ?', whereArgs: [patientId]);
      return List.generate(maps.length, (i) => Insurance.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get insurance by patient id: $e');
    }
  }

  Future<bool> updateInsurance(Insurance insurance) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, insurance.toMap(), where: 'id = ?', whereArgs: [insurance.id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update insurance: $e');
    }
  }

  Future<bool> deleteInsurance(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete insurance: $e');
    }
  }

  Future<int> getTotalInsuranceCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return result.first.values.first as int;
    } catch (e) {
      throw Exception('Failed to get total insurance count: $e');
    }
  }
}
