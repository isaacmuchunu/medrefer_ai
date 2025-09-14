import '../../database/database_helper.dart';
import '../models/models.dart';

class PrescriptionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'prescriptions';

  Future<String> createPrescription(Prescription prescription) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, prescription.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create prescription: $e');
    }
  }

  Future<List<Prescription>> getAllPrescriptions() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) => Prescription.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all prescriptions: $e');
    }
  }

  Future<Prescription?> getPrescriptionById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Prescription.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get prescription by id: $e');
    }
  }

  Future<List<Prescription>> getPrescriptionsByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'patient_id = ?', whereArgs: [patientId]);
      return List.generate(maps.length, (i) => Prescription.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get prescriptions by patient id: $e');
    }
  }

  Future<List<Prescription>> getPrescriptionsBySpecialistId(String specialistId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'specialist_id = ?', whereArgs: [specialistId]);
      return List.generate(maps.length, (i) => Prescription.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get prescriptions by specialist id: $e');
    }
  }

  Future<bool> updatePrescription(Prescription prescription) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, prescription.toMap(), where: 'id = ?', whereArgs: [prescription.id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update prescription: $e');
    }
  }

  Future<bool> deletePrescription(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete prescription: $e');
    }
  }

  Future<int> getTotalPrescriptionsCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return result.first.values.first as int;
    } catch (e) {
      throw Exception('Failed to get total prescriptions count: $e');
    }
  }
}
