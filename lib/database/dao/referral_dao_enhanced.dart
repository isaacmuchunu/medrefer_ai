import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/models.dart';

/// Enhanced Data Access Object for Referral operations
class ReferralDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'referrals';
  
  // Cache management
  static final Map<String, Referral> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Stream controllers for real-time updates
  final StreamController<List<Referral>> _referralsStreamController = 
      StreamController<List<Referral>>.broadcast();
  final StreamController<ReferralUpdate> _referralUpdateController = 
      StreamController<ReferralUpdate>.broadcast();
  
  // Analytics tracking
  int _totalReferralsCreated = 0;
  int _totalStatusUpdates = 0;
  final Map<String, int> _departmentCounts = {};
  
  // Getters
  Stream<List<Referral>> get referralsStream => _referralsStreamController.stream;
  Stream<ReferralUpdate> get referralUpdateStream => _referralUpdateController.stream;
  int get totalReferralsCreated => _totalReferralsCreated;
  
  /// Clear cache
  void clearCache([String? referralId]) {
    if (referralId != null) {
      _cache.remove(referralId);
      _cacheTimestamps.remove(referralId);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
  
  /// Check cache validity
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  // Enhanced Create operations
  
  Future<String> createReferral(Referral referral) async {
    try {
      // Validate referral data
      _validateReferral(referral);
      
      // Generate tracking number if not provided
      if (referral.trackingNumber.isEmpty) {
        referral = referral.copyWith(
          trackingNumber: _generateTrackingNumber(),
        );
      }
      
      // Check for duplicate tracking number
      final existing = await getReferralByTrackingNumber(referral.trackingNumber);
      if (existing != null) {
        throw DuplicateReferralException('Referral with tracking number ${referral.trackingNumber} already exists');
      }
      
      // AI processing if confidence not set
      if (referral.aiConfidence == 0) {
        referral = await _processWithAI(referral);
      }
      
      final id = await _dbHelper.insert(tableName, referral.toMap());
      
      // Update cache
      _cache[id] = referral;
      _cacheTimestamps[id] = DateTime.now();
      
      // Update analytics
      _totalReferralsCreated++;
      _departmentCounts[referral.department ?? 'Unknown'] = 
          (_departmentCounts[referral.department ?? 'Unknown'] ?? 0) + 1;
      
      // Notify listeners
      _notifyReferralsChanged();
      _referralUpdateController.add(ReferralUpdate(
        type: UpdateType.created,
        referralId: id,
        referral: referral,
      ));
      
      debugPrint('Referral created successfully: $id');
      return id;
    } catch (e) {
      debugPrint('Error creating referral: $e');
      throw ReferralDaoException('Failed to create referral: $e');
    }
  }

  // Enhanced Read operations
  
  Future<List<Referral>> getAllReferrals({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        orderBy: orderBy ?? 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      final referrals = maps.map(Referral.fromMap).toList();
      
      // Update stream
      _referralsStreamController.add(referrals);
      
      return referrals;
    } catch (e) {
      debugPrint('Error getting all referrals: $e');
      throw ReferralDaoException('Failed to get referrals: $e');
    }
  }

  Future<Referral?> getReferralById(String id) async {
    try {
      // Check cache first
      if (_cache.containsKey(id) && _isCacheValid(id)) {
        debugPrint('Returning referral from cache: $id');
        return _cache[id];
      }
      
      final map = await _dbHelper.queryById(tableName, id);
      if (map != null) {
        final referral = Referral.fromMap(map);
        
        // Update cache
        _cache[id] = referral;
        _cacheTimestamps[id] = DateTime.now();
        
        return referral;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting referral by ID: $e');
      throw ReferralDaoException('Failed to get referral: $e');
    }
  }

  Future<Referral?> getReferralByTrackingNumber(String trackingNumber) async {
    try {
      // Check cache for tracking number
      Referral? cachedReferral;
      try {
        cachedReferral = _cache.values.firstWhere(
          (r) => r.trackingNumber == trackingNumber,
        );
      } catch (e) {
        cachedReferral = null;
      }
      
      if (cachedReferral != null && _isCacheValid(cachedReferral.id)) {
        return cachedReferral;
      }
      
      final maps = await _dbHelper.query(
        tableName,
        where: 'tracking_number = ?',
        whereArgs: [trackingNumber],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        final referral = Referral.fromMap(maps.first);
        
        // Update cache
        _cache[referral.id] = referral;
        _cacheTimestamps[referral.id] = DateTime.now();
        
        return referral;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting referral by tracking number: $e');
      throw ReferralDaoException('Failed to get referral by tracking number: $e');
    }
  }

  Future<List<Referral>> getReferralsByPatientId(String patientId, {
    int? limit,
    String? status,
  }) async {
    try {
      var where = 'patient_id = ?';
      final whereArgs = <dynamic>[patientId];
      
      if (status != null) {
        where += ' AND status = ?';
        whereArgs.add(status);
      }
      
      final maps = await _dbHelper.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      debugPrint('Error getting referrals by patient: $e');
      throw ReferralDaoException('Failed to get referrals by patient: $e');
    }
  }

  Future<List<Referral>> getReferralsBySpecialistId(String specialistId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var where = 'specialist_id = ?';
      final whereArgs = <dynamic>[specialistId];
      
      if (startDate != null) {
        where += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final maps = await _dbHelper.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      debugPrint('Error getting referrals by specialist: $e');
      throw ReferralDaoException('Failed to get referrals by specialist: $e');
    }
  }

  // Advanced filtering
  
  Future<List<Referral>> filterReferrals({
    String? status,
    String? urgency,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    double? minAiConfidence,
    String? patientId,
    String? specialistId,
    int? limit,
    int? offset,
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

      if (patientId != null) {
        whereConditions.add('patient_id = ?');
        whereArgs.add(patientId);
      }

      if (specialistId != null) {
        whereConditions.add('specialist_id = ?');
        whereArgs.add(specialistId);
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
        limit: limit,
        offset: offset,
      );
      
      return maps.map(Referral.fromMap).toList();
    } catch (e) {
      debugPrint('Error filtering referrals: $e');
      throw ReferralDaoException('Failed to filter referrals: $e');
    }
  }

  // Enhanced Update operations
  
  Future<bool> updateReferral(Referral referral) async {
    try {
      // Validate referral data
      _validateReferral(referral);
      
      referral.updateTimestamp();
      final rowsAffected = await _dbHelper.update(tableName, referral.toMap(), referral.id);
      
      if (rowsAffected > 0) {
        // Update cache
        _cache[referral.id] = referral;
        _cacheTimestamps[referral.id] = DateTime.now();
        
        // Notify listeners
        _notifyReferralsChanged();
        _referralUpdateController.add(ReferralUpdate(
          type: UpdateType.updated,
          referralId: referral.id,
          referral: referral,
        ));
        
        debugPrint('Referral updated successfully: ${referral.id}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating referral: $e');
      throw ReferralDaoException('Failed to update referral: $e');
    }
  }

  Future<bool> updateReferralStatus(String id, String status, {String? notes}) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (notes != null) {
        // Append notes to existing notes
        final existing = await getReferralById(id);
        if (existing != null) {
          final existingNotes = existing.symptomsDescription ?? '';
          updates['symptoms_description'] = '$existingNotes\n[${DateTime.now().toIso8601String()}] Status changed to $status: $notes';
        }
      }
      
      final rowsAffected = await _dbHelper.update(tableName, updates, id);
      
      if (rowsAffected > 0) {
        // Clear cache for this referral
        clearCache(id);
        
        // Update analytics
        _totalStatusUpdates++;
        
        // Notify listeners
        _notifyReferralsChanged();
        _referralUpdateController.add(ReferralUpdate(
          type: UpdateType.statusChanged,
          referralId: id,
          newStatus: status,
        ));
        
        debugPrint('Referral status updated: $id -> $status');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating referral status: $e');
      throw ReferralDaoException('Failed to update referral status: $e');
    }
  }

  // Delete operations
  
  Future<bool> deleteReferral(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      
      if (rowsAffected > 0) {
        // Clear cache
        clearCache(id);
        
        // Notify listeners
        _notifyReferralsChanged();
        _referralUpdateController.add(ReferralUpdate(
          type: UpdateType.deleted,
          referralId: id,
        ));
        
        debugPrint('Referral deleted: $id');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting referral: $e');
      throw ReferralDaoException('Failed to delete referral: $e');
    }
  }

  // Batch operations
  
  Future<void> createMultipleReferrals(List<Referral> referrals) async {
    try {
      final batch = <Map<String, dynamic>>[];
      
      for (var referral in referrals) {
        _validateReferral(referral);
        
        if (referral.trackingNumber.isEmpty) {
          referral = referral.copyWith(
            trackingNumber: _generateTrackingNumber(),
          );
        }
        
        batch.add(referral.toMap());
      }
      
      await _dbHelper.batchInsert(tableName, batch);
      
      // Clear cache and notify
      clearCache();
      _notifyReferralsChanged();
      
      debugPrint('Created ${referrals.length} referrals in batch');
    } catch (e) {
      debugPrint('Error creating multiple referrals: $e');
      throw ReferralDaoException('Failed to create multiple referrals: $e');
    }
  }

  // Statistics and Analytics
  
  Future<int> getTotalReferralsCount() async {
    try {
      return await _dbHelper.getTableCount(tableName);
    } catch (e) {
      debugPrint('Error getting referrals count: $e');
      throw ReferralDaoException('Failed to get referrals count: $e');
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
      debugPrint('Error getting status statistics: $e');
      throw ReferralDaoException('Failed to get status statistics: $e');
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
      debugPrint('Error getting urgency statistics: $e');
      throw ReferralDaoException('Failed to get urgency statistics: $e');
    }
  }

  Future<Map<String, int>> getReferralsByDepartmentCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT department, COUNT(*) as count 
        FROM $tableName 
        GROUP BY department
        ORDER BY count DESC
      ''');
      
      final departmentCounts = <String, int>{};
      for (var row in result) {
        departmentCounts[row['department'] as String] = row['count'] as int;
      }
      return departmentCounts;
    } catch (e) {
      debugPrint('Error getting department statistics: $e');
      throw ReferralDaoException('Failed to get department statistics: $e');
    }
  }

  Future<double> getAverageAIConfidence() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT AVG(ai_confidence) as avg_confidence 
        FROM $tableName 
        WHERE ai_confidence > 0
      ''');
      
      if (result.isNotEmpty && result.first['avg_confidence'] != null) {
        return result.first['avg_confidence'] as double;
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error getting average AI confidence: $e');
      throw ReferralDaoException('Failed to get average AI confidence: $e');
    }
  }

  // Helper methods
  
  void _validateReferral(Referral referral) {
    if (referral.patientId.isEmpty) {
      throw ValidationException('Patient ID is required');
    }
    if (referral.department == null || referral.department!.isEmpty) {
      throw ValidationException('Department is required');
    }
    if (referral.symptomsDescription == null || referral.symptomsDescription!.isEmpty) {
      throw ValidationException('Symptoms description is required');
    }
    if (referral.urgency.isEmpty) {
      throw ValidationException('Urgency level is required');
    }
    
    // Validate urgency values
    const validUrgencies = ['low', 'medium', 'high', 'urgent'];
    if (!validUrgencies.contains(referral.urgency.toLowerCase())) {
      throw ValidationException('Invalid urgency level: ${referral.urgency}');
    }
    
    // Validate status values
    const validStatuses = ['pending', 'approved', 'rejected', 'completed', 'cancelled'];
    if (!validStatuses.contains(referral.status.toLowerCase())) {
      throw ValidationException('Invalid status: ${referral.status}');
    }
  }

  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'REF-${timestamp.toString().substring(6)}-$random';
  }

  Future<Referral> _processWithAI(Referral referral) async {
    // Simulate AI processing
    // In production, this would call your AI service
    
    var confidence = 0.85; // Simulated confidence
    
    // Adjust urgency based on symptoms (simplified logic)
    if (referral.symptomsDescription != null && (referral.symptomsDescription!.toLowerCase().contains('emergency') ||
        referral.symptomsDescription!.toLowerCase().contains('severe'))) {
      confidence = 0.95;
      referral = referral.copyWith(urgency: 'urgent');
    }
    
    return referral.copyWith(aiConfidence: confidence);
  }

  Future<void> _notifyReferralsChanged() async {
    final referrals = await getAllReferrals();
    _referralsStreamController.add(referrals);
  }

  // Export/Import operations
  
  Future<String> exportToJson({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final referrals = await filterReferrals(
        startDate: startDate,
        endDate: endDate,
      );
      
      final jsonData = referrals.map((r) => r.toMap()).toList();
      return jsonEncode(jsonData);
    } catch (e) {
      debugPrint('Error exporting referrals: $e');
      throw ReferralDaoException('Failed to export referrals: $e');
    }
  }

  Future<int> importFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      final referrals = jsonData.map((map) => Referral.fromMap(map)).toList();
      
      var imported = 0;
      for (final referral in referrals) {
        try {
          await createReferral(referral);
          imported++;
        } catch (e) {
          debugPrint('Skipping referral ${referral.trackingNumber}: $e');
        }
      }
      
      return imported;
    } catch (e) {
      debugPrint('Error importing referrals: $e');
      throw ReferralDaoException('Failed to import referrals: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _referralsStreamController.close();
    _referralUpdateController.close();
    clearCache();
  }
}

// Supporting classes and enums

enum UpdateType {
  created,
  updated,
  deleted,
  statusChanged,
}

class ReferralUpdate {
  final UpdateType type;
  final String referralId;
  final Referral? referral;
  final String? newStatus;
  final DateTime timestamp;

  ReferralUpdate({
    required this.type,
    required this.referralId,
    this.referral,
    this.newStatus,
  }) : timestamp = DateTime.now();
}

// Custom Exceptions

class ReferralDaoException implements Exception {
  final String message;
  ReferralDaoException(this.message);
  
  @override
  String toString() => 'ReferralDaoException: $message';
}

class ValidationException extends ReferralDaoException {
  ValidationException(super.message);
}

class DuplicateReferralException extends ReferralDaoException {
  DuplicateReferralException(super.message);
}