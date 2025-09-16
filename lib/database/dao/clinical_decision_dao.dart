import '../models/clinical_decision.dart';
import 'dao.dart';

class ClinicalDecisionDao extends BaseDao<ClinicalDecision> {
  static const String _tableName = 'clinical_decisions';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'patient_id': 'TEXT NOT NULL',
    'specialist_id': 'TEXT NOT NULL',
    'condition_id': 'TEXT NOT NULL',
    'decision_type': 'TEXT NOT NULL',
    'title': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'rationale': 'TEXT NOT NULL',
    'confidence': 'TEXT NOT NULL',
    'evidence': 'TEXT',
    'recommendations': 'TEXT',
    'contraindications': 'TEXT',
    'status': 'TEXT NOT NULL',
    'priority': 'TEXT NOT NULL',
    'created_at': 'TEXT NOT NULL',
    'reviewed_at': 'TEXT',
    'reviewed_by': 'TEXT',
    'review_notes': 'TEXT',
    'metadata': 'TEXT',
    'is_active': 'INTEGER NOT NULL',
    'expires_at': 'TEXT',
  };

  @override
  ClinicalDecision fromMap(Map<String, dynamic> map) => ClinicalDecision.fromMap(map);

  @override
  Map<String, dynamic> toMap(ClinicalDecision item) => item.toMap();

  // Get decisions by patient
  Future<List<ClinicalDecision>> getByPatient(String patientId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'patient_id = ? AND is_active = 1',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get decisions by specialist
  Future<List<ClinicalDecision>> getBySpecialist(String specialistId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'specialist_id = ? AND is_active = 1',
      whereArgs: [specialistId],
      orderBy: 'created_at DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get decisions by status
  Future<List<ClinicalDecision>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get decisions by priority
  Future<List<ClinicalDecision>> getByPriority(String priority) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'priority = ? AND is_active = 1',
      whereArgs: [priority],
      orderBy: 'created_at DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get pending decisions
  Future<List<ClinicalDecision>> getPendingDecisions() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['pending'],
      orderBy: 'priority DESC, created_at ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get decisions by decision type
  Future<List<ClinicalDecision>> getByDecisionType(String decisionType) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'decision_type = ? AND is_active = 1',
      whereArgs: [decisionType],
      orderBy: 'created_at DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Update decision status
  Future<int> updateStatus(String id, String status, {String? reviewedBy, String? reviewNotes}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'status': status,
        'reviewed_at': now,
        'reviewed_by': reviewedBy,
        'review_notes': reviewNotes,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get expired decisions
  Future<List<ClinicalDecision>> getExpiredDecisions() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'expires_at < ? AND is_active = 1',
      whereArgs: [now],
      orderBy: 'expires_at ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Search decisions
  Future<List<ClinicalDecision>> searchDecisions(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '(title LIKE ? OR description LIKE ? OR rationale LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(fromMap).toList();
  }
}