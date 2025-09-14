import '../database_helper.dart';
import '../models/consent.dart';

class ConsentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'consents';

  Future<String> createConsent(Consent consent) async {
    return await _dbHelper.insert(tableName, consent.toMap());
  }

  Future<bool> updateConsent(Consent consent) async {
    consent.updateTimestamp();
    final rows = await _dbHelper.update(tableName, consent.toMap(), consent.id);
    return rows > 0;
  }

  Future<bool> deleteConsent(String id) async {
    final rows = await _dbHelper.delete(tableName, id);
    return rows > 0;
  }

  Future<Consent?> getConsentById(String id) async {
    final map = await _dbHelper.queryById(tableName, id);
    return map != null ? Consent.fromMap(map) : null;
  }

  Future<List<Consent>> getConsentsByPatientId(String patientId) async {
    final maps = await _dbHelper.query(
      tableName,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'updated_at DESC',
    );
    return maps.map((e) => Consent.fromMap(e)).toList();
  }

  Future<int> getActiveConsentCount(String patientId) async {
    return await _dbHelper.getCount(
      tableName,
      where: "patient_id = ? AND status = 'active'",
      whereArgs: [patientId],
    );
  }
}

