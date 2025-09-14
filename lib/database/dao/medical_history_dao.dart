import '../database_helper.dart';
import '../models/models.dart';

class MedicalHistoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'medical_history';

  // Create
  Future<String> createMedicalHistory(MedicalHistory history) async {
    try {
      return await _dbHelper.insert(tableName, history.toMap());
    } catch (e) {
      throw Exception('Failed to create medical history: $e');
    }
  }

  // Read
  Future<List<MedicalHistory>> getMedicalHistoryByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'date DESC',
      );
      return maps.map((map) => MedicalHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get medical history: $e');
    }
  }

  Future<MedicalHistory?> getMedicalHistoryById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? MedicalHistory.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get medical history: $e');
    }
  }

  Future<List<MedicalHistory>> getMedicalHistoryByType(String patientId, String type) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ? AND type = ?',
        whereArgs: [patientId, type],
        orderBy: 'date DESC',
      );
      return maps.map((map) => MedicalHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get medical history by type: $e');
    }
  }

  // Update
  Future<bool> updateMedicalHistory(MedicalHistory history) async {
    try {
      history.updateTimestamp();
      final rowsAffected = await _dbHelper.update(tableName, history.toMap(), history.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update medical history: $e');
    }
  }

  // Delete
  Future<bool> deleteMedicalHistory(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete medical history: $e');
    }
  }

  Future<bool> deleteMedicalHistoryByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.delete(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete patient medical history: $e');
    }
  }
}
