import 'package:sqflite/sqflite.dart';
import '../models/emergency_protocol.dart';
import 'dao.dart';

class EmergencyProtocolDao extends BaseDao<EmergencyProtocol> {
  static const String _tableName = 'emergency_protocols';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'title': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'emergency_type': 'TEXT NOT NULL',
    'severity': 'TEXT NOT NULL',
    'category': 'TEXT NOT NULL',
    'status': 'TEXT NOT NULL',
    'protocol': 'TEXT NOT NULL',
    'steps': 'TEXT NOT NULL',
    'required_equipment': 'TEXT',
    'required_personnel': 'TEXT',
    'contacts': 'TEXT',
    'department_id': 'TEXT',
    'facility_id': 'TEXT',
    'created_by': 'TEXT NOT NULL',
    'approved_by': 'TEXT',
    'approved_at': 'TEXT',
    'last_reviewed': 'TEXT NOT NULL',
    'next_review': 'TEXT',
    'version': 'INTEGER NOT NULL',
    'tags': 'TEXT',
    'metadata': 'TEXT',
    'notes': 'TEXT',
    'created_at': 'TEXT NOT NULL',
    'updated_at': 'TEXT NOT NULL',
    'is_active': 'INTEGER NOT NULL',
    'is_public': 'INTEGER NOT NULL',
  };

  @override
  EmergencyProtocol fromMap(Map<String, dynamic> map) => EmergencyProtocol.fromMap(map);

  @override
  Map<String, dynamic> toMap(EmergencyProtocol item) => item.toMap();

  // Get protocols by emergency type
  Future<List<EmergencyProtocol>> getByEmergencyType(String emergencyType) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'emergency_type = ? AND is_active = 1',
      whereArgs: [emergencyType],
      orderBy: 'severity DESC, title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get protocols by severity
  Future<List<EmergencyProtocol>> getBySeverity(String severity) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'severity = ? AND is_active = 1',
      whereArgs: [severity],
      orderBy: 'title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get protocols by category
  Future<List<EmergencyProtocol>> getByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'severity DESC, title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get protocols by status
  Future<List<EmergencyProtocol>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get active protocols
  Future<List<EmergencyProtocol>> getActiveProtocols() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['active'],
      orderBy: 'severity DESC, title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get critical protocols
  Future<List<EmergencyProtocol>> getCriticalProtocols() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'severity = ? AND status = ? AND is_active = 1',
      whereArgs: ['critical', 'active'],
      orderBy: 'title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get protocols by department
  Future<List<EmergencyProtocol>> getByDepartment(String departmentId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'department_id = ? AND is_active = 1',
      whereArgs: [departmentId],
      orderBy: 'severity DESC, title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get protocols needing review
  Future<List<EmergencyProtocol>> getProtocolsNeedingReview() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'next_review < ? AND is_active = 1',
      whereArgs: [now],
      orderBy: 'next_review ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get approved protocols
  Future<List<EmergencyProtocol>> getApprovedProtocols() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'approved_by IS NOT NULL AND is_active = 1',
      orderBy: 'approved_at DESC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get public protocols
  Future<List<EmergencyProtocol>> getPublicProtocols() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'is_public = 1 AND status = ? AND is_active = 1',
      whereArgs: ['active'],
      orderBy: 'severity DESC, title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Update protocol status
  Future<int> updateProtocolStatus(String id, String status) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'status': status,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Approve protocol
  Future<int> approveProtocol(String id, String approvedBy) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'approved_by': approvedBy,
        'approved_at': now,
        'status': 'active',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update review date
  Future<int> updateReviewDate(String id, DateTime nextReview) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'last_reviewed': now,
        'next_review': nextReview.toIso8601String(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search protocols
  Future<List<EmergencyProtocol>> searchProtocols(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '(title LIKE ? OR description LIKE ? OR tags LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'severity DESC, title ASC',
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  // Get protocols summary
  Future<Map<String, dynamic>> getProtocolsSummary() async {
    final db = await database;
    
    final totalProtocols = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
    final activeProtocols = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['active']);
    final criticalProtocols = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE severity = ? AND is_active = 1', ['critical']);
    final needsReview = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE next_review < ? AND is_active = 1', [DateTime.now().toIso8601String()]);
    
    return {
      'total_protocols': totalProtocols.first['count'],
      'active_protocols': activeProtocols.first['count'],
      'critical_protocols': criticalProtocols.first['count'],
      'needs_review': needsReview.first['count'],
    };
  }
}