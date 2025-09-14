import '../database_helper.dart';
import '../models/models.dart';

class MedicationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'medications';

  // Create
  Future<String> createMedication(Medication medication) async {
    try {
      return await _dbHelper.insert(tableName, medication.toMap());
    } catch (e) {
      throw Exception('Failed to create medication: $e');
    }
  }

  // Read
  Future<List<Medication>> getAllMedications() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'name ASC');
      return maps.map((map) => Medication.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get medications: $e');
    }
  }

  Future<Medication?> getMedicationById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? Medication.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get medication: $e');
    }
  }

  Future<List<Medication>> getMedicationsByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'start_date DESC',
      );
      return maps.map((map) => Medication.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get medications by patient: $e');
    }
  }

  Future<List<Medication>> getActiveMedications(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ? AND status = "Active"',
        whereArgs: [patientId],
        orderBy: 'name ASC',
      );
      return maps.map((map) => Medication.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get active medications: $e');
    }
  }

  // Update
  Future<bool> updateMedication(Medication medication) async {
    try {
      medication.updatedAt = DateTime.now();
      final rowsAffected = await _dbHelper.update(tableName, medication.toMap(), medication.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update medication: $e');
    }
  }

  // Delete
  Future<bool> deleteMedication(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }

  // Batch Create
  Future<void> createMultipleMedications(List<Medication> medications) async {
    for (var medication in medications) {
      await createMedication(medication);
    }
  }

  // Statistics
  Future<int> getTotalMedicationsCount(String patientId) async {
    try {
      return await _dbHelper.getCount(tableName, where: 'patient_id = ?', whereArgs: [patientId]);
    } catch (e) {
      throw Exception('Failed to get medications count: $e');
    }
  }
}