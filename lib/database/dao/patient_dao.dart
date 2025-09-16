import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/models.dart';

/// Data Access Object for Patient operations with caching and advanced features
class PatientDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'patients';
  
  // Cache management
  static final Map<String, Patient> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Stream controllers for real-time updates
  final StreamController<List<Patient>> _patientsStreamController = 
      StreamController<List<Patient>>.broadcast();
  
  Stream<List<Patient>> get patientsStream => _patientsStreamController.stream;
  
  /// Clear cache for a specific patient or all patients
  void clearCache([String? patientId]) {
    if (patientId != null) {
      _cache.remove(patientId);
      _cacheTimestamps.remove(patientId);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
  
  /// Check if cache is valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  // Create
  Future<String> createPatient(Patient patient) async {
    try {
      // Validate patient data
      _validatePatient(patient);
      
      // Check for duplicate MRN
      final existing = await getPatientByMrn(patient.medicalRecordNumber);
      if (existing != null) {
        throw DuplicateRecordException('Patient with MRN ${patient.medicalRecordNumber} already exists');
      }
      
      final id = await _dbHelper.insert(tableName, patient.toMap());
      
      // Add to cache
      _cache[id] = patient;
      _cacheTimestamps[id] = DateTime.now();
      
      // Notify listeners
      _notifyPatientsChanged();
      
      debugPrint('Patient created successfully: $id');
      return id;
    } catch (e) {
      debugPrint('Error creating patient: $e');
      throw PatientDaoException('Failed to create patient: $e');
    }
  }

  // Read
  Future<List<Patient>> getAllPatients({int? limit, int? offset}) async {
    try {
      final maps = await _dbHelper.query(
        tableName, 
        orderBy: 'name ASC',
        limit: limit ?? defaultPageSize,
        offset: offset ?? 0,
      );
      final patients = maps.map(Patient.fromMap).toList();
      
      // Update stream
      _patientsStreamController.add(patients);
      
      return patients;
    } catch (e) {
      debugPrint('Error getting all patients: $e');
      throw PatientDaoException('Failed to get patients: $e');
    }
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      // Check cache first
      if (_cache.containsKey(id) && _isCacheValid(id)) {
        debugPrint('Returning patient from cache: $id');
        return _cache[id];
      }
      
      final map = await _dbHelper.queryById(tableName, id);
      if (map != null) {
        final patient = Patient.fromMap(map);
        
        // Update cache
        _cache[id] = patient;
        _cacheTimestamps[id] = DateTime.now();
        
        return patient;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting patient by ID: $e');
      throw PatientDaoException('Failed to get patient: $e');
    }
  }

  Future<Patient?> getPatientByMrn(String mrn) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'medical_record_number = ?',
        whereArgs: [mrn],
        limit: 1,
      );
      return maps.isNotEmpty ? Patient.fromMap(maps.first) : null;
    } catch (e) {
      throw Exception('Failed to get patient by MRN: $e');
    }
  }

  Future<List<Patient>> searchPatients(String searchTerm) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'name LIKE ? OR medical_record_number LIKE ? OR email LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: 'name ASC',
      );
      return maps.map(Patient.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to search patients: $e');
    }
  }

  Future<List<Patient>> getPatientsByAge(int minAge, int maxAge) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'age BETWEEN ? AND ?',
        whereArgs: [minAge, maxAge],
        orderBy: 'age ASC',
      );
      return maps.map(Patient.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get patients by age: $e');
    }
  }

  Future<List<Patient>> getPatientsByGender(String gender) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'gender = ?',
        whereArgs: [gender],
        orderBy: 'name ASC',
      );
      return maps.map(Patient.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get patients by gender: $e');
    }
  }

  // Update
  Future<bool> updatePatient(Patient patient) async {
    try {
      patient.updateTimestamp();
      final rowsAffected = await _dbHelper.update(tableName, patient.toMap(), patient.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  // Delete
  Future<bool> deletePatient(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete patient: $e');
    }
  }

  // Batch operations
  Future<void> createMultiplePatients(List<Patient> patients) async {
    try {
      final maps = patients.map((patient) => patient.toMap()).toList();
      await _dbHelper.batchInsert(tableName, maps);
    } catch (e) {
      throw Exception('Failed to create multiple patients: $e');
    }
  }

  // Statistics
  Future<int> getTotalPatientsCount() async {
    try {
      return await _dbHelper.getTableCount(tableName);
    } catch (e) {
      throw Exception('Failed to get patients count: $e');
    }
  }

  Future<Map<String, int>> getPatientsByGenderCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT gender, COUNT(*) as count 
        FROM $tableName 
        GROUP BY gender
      ''');
      
      final genderCounts = <String, int>{};
      for (var row in result) {
        genderCounts[row['gender'] as String] = row['count'] as int;
      }
      return genderCounts;
    } catch (e) {
      throw Exception('Failed to get gender statistics: $e');
    }
  }

  Future<Map<String, int>> getPatientsByAgeGroup() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          CASE 
            WHEN age < 18 THEN 'Under 18'
            WHEN age BETWEEN 18 AND 30 THEN '18-30'
            WHEN age BETWEEN 31 AND 50 THEN '31-50'
            WHEN age BETWEEN 51 AND 70 THEN '51-70'
            ELSE 'Over 70'
          END as age_group,
          COUNT(*) as count
        FROM $tableName 
        GROUP BY age_group
      ''');
      
      final ageCounts = <String, int>{};
      for (var row in result) {
        ageCounts[row['age_group'] as String] = row['count'] as int;
      }
      return ageCounts;
    } catch (e) {
      throw Exception('Failed to get age group statistics: $e');
    }
  }
  
  // Helper Methods
  
  /// Validate patient data before database operations
  void _validatePatient(Patient patient) {
    if (patient.name.isEmpty) {
      throw ValidationException('Patient name is required');
    }
    if (patient.medicalRecordNumber.isEmpty) {
      throw ValidationException('Medical record number is required');
    }
    if (patient.age < 0 || patient.age > 150) {
      throw ValidationException('Invalid age: ${patient.age}');
    }
    if (patient.email != null && patient.email!.isNotEmpty && !_isValidEmail(patient.email!)) {
      throw ValidationException('Invalid email format: ${patient.email}');
    }
    if (patient.phone != null && patient.phone!.isNotEmpty && !_isValidPhone(patient.phone!)) {
      throw ValidationException('Invalid phone format: ${patient.phone}');
    }
  }
  
  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate phone format
  bool _isValidPhone(String phone) {
    return RegExp(r'^[+]?[\d\s-()]+$').hasMatch(phone);
  }
  
  /// Notify listeners of patient data changes
  Future<void> _notifyPatientsChanged() async {
    final patients = await getAllPatients();
    _patientsStreamController.add(patients);
  }
  
  /// Get recent patients based on creation date
  Future<List<Patient>> getRecentPatients({int limit = 10}) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return maps.map(Patient.fromMap).toList();
    } catch (e) {
      debugPrint('Error getting recent patients: $e');
      throw PatientDaoException('Failed to get recent patients: $e');
    }
  }
  
  /// Get patients with upcoming appointments
  Future<List<Patient>> getPatientsWithUpcomingAppointments() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT p.* 
        FROM $tableName p
        INNER JOIN appointments a ON p.id = a.patient_id
        WHERE a.date >= ?
        ORDER BY a.date ASC
      ''', [DateTime.now().millisecondsSinceEpoch]);
      
      return result.map(Patient.fromMap).toList();
    } catch (e) {
      debugPrint('Error getting patients with appointments: $e');
      throw PatientDaoException('Failed to get patients with appointments: $e');
    }
  }
  
  /// Export patients data to JSON
  Future<String> exportToJson() async {
    try {
      final patients = await getAllPatients();
      final jsonData = patients.map((p) => p.toMap()).toList();
      return jsonEncode(jsonData);
    } catch (e) {
      debugPrint('Error exporting patients: $e');
      throw PatientDaoException('Failed to export patients: $e');
    }
  }
  
  /// Import patients from JSON
  Future<int> importFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      final patients = jsonData.map((map) => Patient.fromMap(map)).toList();
      
      var imported = 0;
      for (final patient in patients) {
        try {
          await createPatient(patient);
          imported++;
        } catch (e) {
          debugPrint('Skipping patient ${patient.medicalRecordNumber}: $e');
        }
      }
      
      return imported;
    } catch (e) {
      debugPrint('Error importing patients: $e');
      throw PatientDaoException('Failed to import patients: $e');
    }
  }
  
  /// Clean up resources
  void dispose() {
    _patientsStreamController.close();
    clearCache();
  }
}

// Custom Exceptions

/// Base exception for PatientDao operations
class PatientDaoException implements Exception {
  final String message;
  PatientDaoException(this.message);
  
  @override
  String toString() => 'PatientDaoException: $message';
}

/// Exception for validation errors
class ValidationException extends PatientDaoException {
  ValidationException(super.message);
}

/// Exception for duplicate records
class DuplicateRecordException extends PatientDaoException {
  DuplicateRecordException(super.message);
}
