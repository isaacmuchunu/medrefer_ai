import '../database_helper.dart';
import '../models/models.dart';

class ReferralDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'referrals';

  // Create
  Future<String> createReferral(Referral referral) async {
    try {
      return await _dbHelper.insert(tableName, referral.toMap());
    } catch (e) {
      throw Exception('Failed to create referral: $e');
    }
  }

  // Read
  Future<List<Referral>> getAllReferrals() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'created_at DESC');
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get referrals: $e');
    }
  }

  Future<Referral?> getReferralById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? Referral.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get referral: $e');
    }
  }

  Future<Referral?> getReferralByTrackingNumber(String trackingNumber) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'tracking_number = ?',
        whereArgs: [trackingNumber],
        limit: 1,
      );
      return maps.isNotEmpty ? Referral.fromMap(maps.first) : null;
    } catch (e) {
      throw Exception('Failed to get referral by tracking number: $e');
    }
  }

  Future<List<Referral>> getReferralsByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'created_at DESC',
      );
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get referrals by patient: $e');
    }
  }

  Future<List<Referral>> getReferralsBySpecialistId(String specialistId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'specialist_id = ?',
        whereArgs: [specialistId],
        orderBy: 'created_at DESC',
      );
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get referrals by specialist: $e');
    }
  }

  Future<List<Referral>> getReferralsByStatus(String status) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'created_at DESC',
      );
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get referrals by status: $e');
    }
  }

  Future<List<Referral>> getReferralsByUrgency(String urgency) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'urgency = ?',
        whereArgs: [urgency],
        orderBy: 'created_at DESC',
      );
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get referrals by urgency: $e');
    }
  }

  Future<List<Referral>> searchReferrals(String searchTerm) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'tracking_number LIKE ? OR symptoms_description LIKE ? OR department LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: 'created_at DESC',
      );
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to search referrals: $e');
    }
  }

  Future<List<Referral>> filterReferrals({
    String? status,
    String? urgency,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    double? minAiConfidence,
  }) async {
    try {
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      if (status != null) {
        whereConditions.add('status = ?');
        whereArgs.add(status);
      }

      if (urgency != null) {
        whereConditions.add('urgency = ?');
        whereArgs.add(urgency);
      }

      if (department != null) {
        whereConditions.add('department = ?');
        whereArgs.add(department);
      }

      if (startDate != null) {
        whereConditions.add('created_at >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereConditions.add('created_at <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (minAiConfidence != null) {
        whereConditions.add('ai_confidence >= ?');
        whereArgs.add(minAiConfidence);
      }

      final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

      final maps = await _dbHelper.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to filter referrals: $e');
    }
  }

  // Update
  Future<bool> updateReferral(Referral referral) async {
    try {
      referral.updateTimestamp();
      final rowsAffected = await _dbHelper.update(tableName, referral.toMap(), referral.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update referral: $e');
    }
  }

  Future<bool> updateReferralStatus(String id, String status) async {
    try {
      final rowsAffected = await _dbHelper.update(
        tableName,
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        id,
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update referral status: $e');
    }
  }

  Future<bool> assignSpecialist(String referralId, String specialistId) async {
    try {
      final rowsAffected = await _dbHelper.update(
        tableName,
        {
          'specialist_id': specialistId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        referralId,
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to assign specialist: $e');
    }
  }

  // Delete
  Future<bool> deleteReferral(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete referral: $e');
    }
  }

  // Statistics
  Future<int> getTotalReferralsCount() async {
    try {
      return await _dbHelper.getTableCount(tableName);
    } catch (e) {
      throw Exception('Failed to get referrals count: $e');
    }
  }

  Future<Map<String, int>> getReferralsByStatusCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM $tableName 
        GROUP BY status
      ''');
      
      final statusCounts = <String, int>{};
      for (var row in result) {
        statusCounts[row['status'] as String] = row['count'] as int;
      }
      return statusCounts;
    } catch (e) {
      throw Exception('Failed to get status statistics: $e');
    }
  }

  Future<Map<String, int>> getReferralsByUrgencyCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT urgency, COUNT(*) as count 
        FROM $tableName 
        GROUP BY urgency
      ''');
      
      final urgencyCounts = <String, int>{};
      for (var row in result) {
        urgencyCounts[row['urgency'] as String] = row['count'] as int;
      }
      return urgencyCounts;
    } catch (e) {
      throw Exception('Failed to get urgency statistics: $e');
    }
  }
}
