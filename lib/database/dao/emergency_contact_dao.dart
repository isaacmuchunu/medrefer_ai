import '../database_helper.dart';
import '../models/models.dart';

class EmergencyContactDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'emergency_contacts';

  // Create
  Future<String> createEmergencyContact(EmergencyContact contact) async {
    try {
      return await _dbHelper.insert(tableName, contact.toMap());
    } catch (e) {
      throw Exception('Failed to create emergency contact: $e');
    }
  }

  // Read
  Future<List<EmergencyContact>> getAllEmergencyContacts() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'name ASC');
      return maps.map((map) => EmergencyContact.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get emergency contacts: $e');
    }
  }

  Future<EmergencyContact?> getEmergencyContactById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? EmergencyContact.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get emergency contact: $e');
    }
  }

  Future<List<EmergencyContact>> getEmergencyContactsByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'is_primary DESC, name ASC',
      );
      return maps.map((map) => EmergencyContact.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get emergency contacts by patient: $e');
    }
  }

  Future<EmergencyContact?> getPrimaryContact(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ? AND is_primary = 1',
        whereArgs: [patientId],
        limit: 1,
      );
      return maps.isNotEmpty ? EmergencyContact.fromMap(maps.first) : null;
    } catch (e) {
      throw Exception('Failed to get primary contact: $e');
    }
  }

  // Update
  Future<bool> updateEmergencyContact(EmergencyContact contact) async {
    try {
      contact.updatedAt = DateTime.now();
      final rowsAffected = await _dbHelper.update(tableName, contact.toMap(), contact.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  // Delete
  Future<bool> deleteEmergencyContact(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  // Batch Create
  Future<void> createMultipleEmergencyContacts(List<EmergencyContact> contacts) async {
    for (var contact in contacts) {
      await createEmergencyContact(contact);
    }
  }

  // Statistics
  Future<int> getTotalContactsCount(String patientId) async {
    try {
      return await _dbHelper.getCount(tableName, where: 'patient_id = ?', whereArgs: [patientId]);
    } catch (e) {
      throw Exception('Failed to get contacts count: $e');
    }
  }
}