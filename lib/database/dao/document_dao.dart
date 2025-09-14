import '../database_helper.dart';
import '../models/models.dart';

class DocumentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'documents';

  // Create
  Future<String> createDocument(Document document) async {
    try {
      return await _dbHelper.insert(tableName, document.toMap());
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  // Read
  Future<List<Document>> getAllDocuments() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'upload_date DESC');
      return maps.map((map) => Document.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  Future<Document?> getDocumentById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? Document.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  Future<List<Document>> getDocumentsByPatientId(String patientId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'upload_date DESC',
      );
      return maps.map((map) => Document.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get documents by patient: $e');
    }
  }

  Future<List<Document>> getDocumentsByReferralId(String referralId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'referral_id = ?',
        whereArgs: [referralId],
        orderBy: 'upload_date DESC',
      );
      return maps.map((map) => Document.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get documents by referral: $e');
    }
  }

  Future<List<Document>> getDocumentsByType(String type) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'upload_date DESC',
      );
      return maps.map((map) => Document.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get documents by type: $e');
    }
  }

  // Update
  Future<bool> updateDocument(Document document) async {
    try {
      document.updatedAt = DateTime.now();
      final rowsAffected = await _dbHelper.update(tableName, document.toMap(), document.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // Delete
  Future<bool> deleteDocument(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Batch Create
  Future<void> createMultipleDocuments(List<Document> documents) async {
    for (var document in documents) {
      await createDocument(document);
    }
  }

  // Statistics
  Future<int> getTotalDocumentsCount(String? patientId) async {
    try {
      if (patientId == null) {
        return await _dbHelper.getCount(tableName);
      }
      return await _dbHelper.getCount(tableName, where: 'patient_id = ?', whereArgs: [patientId]);
    } catch (e) {
      throw Exception('Failed to get documents count: $e');
    }
  }
}