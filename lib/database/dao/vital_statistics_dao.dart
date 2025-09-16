import '../database_helper.dart';
import '../models/models.dart';

class VitalStatisticsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'vital_statistics';

  // Create
  Future<String> createVitalStatistics(VitalStatistics vitals) async {
    try {
      return await _dbHelper.insert(tableName, vitals.toMap());
    } catch (e) {
      throw Exception('Failed to create vital statistics: $e');
    }
  }

  // Read
  Future<List<VitalStatistics>> getAllVitalStatistics() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'recorded_date DESC');
      return maps.map(VitalStatistics.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get vital statistics: $e');
    }
  }

  Future<VitalStatistics?> getVitalStatisticsById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? VitalStatistics.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get vital statistics: $e');
    }
  }

  Future<List<VitalStatistics>> getVitalStatisticsByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'recorded_date DESC',
      );
      return maps.map(VitalStatistics.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get vital statistics by patient: $e');
    }
  }

  Future<VitalStatistics?> getLatestVitalStatistics(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'recorded_date DESC',
        limit: 1,
      );
      return maps.isNotEmpty ? VitalStatistics.fromMap(maps.first) : null;
    } catch (e) {
      throw Exception('Failed to get latest vital statistics: $e');
    }
  }

  // Update
  Future<bool> updateVitalStatistics(VitalStatistics vitals) async {
    try {
      final rowsAffected = await _dbHelper.update(tableName, vitals.toMap(), vitals.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update vital statistics: $e');
    }
  }

  // Delete
  Future<bool> deleteVitalStatistics(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete vital statistics: $e');
    }
  }

  // Batch Create
  Future<void> createMultipleVitalStatistics(List<VitalStatistics> vitalsList) async {
    for (var vitals in vitalsList) {
      await createVitalStatistics(vitals);
    }
  }

  // Statistics
  Future<int> getTotalVitalRecordsCount(String patientId) async {
    try {
      return await _dbHelper.getCount(tableName, where: 'patient_id = ?', whereArgs: [patientId]);
    } catch (e) {
      throw Exception('Failed to get vital records count: $e');
    }
  }
}