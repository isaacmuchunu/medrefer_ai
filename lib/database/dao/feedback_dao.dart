import '../../database/database_helper.dart';
import '../models/models.dart';

class FeedbackDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'feedback';

  Future<String> createFeedback(Feedback feedback) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, feedback.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create feedback: $e');
    }
  }

  Future<List<Feedback>> getAllFeedback() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) => Feedback.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all feedback: $e');
    }
  }

  Future<Feedback?> getFeedbackById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Feedback.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get feedback by id: $e');
    }
  }

  Future<List<Feedback>> getFeedbackByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'patient_id = ?', whereArgs: [patientId]);
      return List.generate(maps.length, (i) => Feedback.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get feedback by patient id: $e');
    }
  }

  Future<List<Feedback>> getFeedbackBySpecialistId(String specialistId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'specialist_id = ?', whereArgs: [specialistId]);
      return List.generate(maps.length, (i) => Feedback.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get feedback by specialist id: $e');
    }
  }

  Future<bool> updateFeedback(Feedback feedback) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, feedback.toMap(), where: 'id = ?', whereArgs: [feedback.id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  Future<bool> deleteFeedback(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  Future<int> getTotalFeedbackCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return result.first.values.first as int;
    } catch (e) {
      throw Exception('Failed to get total feedback count: $e');
    }
  }

  Future<double> getAverageRatingBySpecialist(String specialistId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT AVG(rating) FROM $_tableName WHERE specialist_id = ?', [specialistId]);
      return (result.first.values.first as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get average rating by specialist: $e');
    }
  }
}
