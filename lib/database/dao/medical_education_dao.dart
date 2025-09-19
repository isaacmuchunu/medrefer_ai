import '../models/medical_education.dart';
import 'dao.dart';

class MedicalEducationDao extends BaseDao<MedicalEducation> {
  static const String _tableName = 'medical_education';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'title': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'type': 'TEXT NOT NULL',
    'category': 'TEXT NOT NULL',
    'status': 'TEXT NOT NULL',
    'provider': 'TEXT NOT NULL',
    'instructor': 'TEXT NOT NULL',
    'institution': 'TEXT',
    'department': 'TEXT',
    'start_date': 'TEXT NOT NULL',
    'end_date': 'TEXT',
    'duration': 'INTEGER NOT NULL',
    'max_participants': 'INTEGER NOT NULL',
    'current_participants': 'INTEGER NOT NULL',
    'cost': 'REAL NOT NULL',
    'currency': 'TEXT NOT NULL',
    'learning_objectives': 'TEXT',
    'prerequisites': 'TEXT',
    'topics': 'TEXT',
    'materials': 'TEXT',
    'certificate': 'TEXT',
    'cme_credits': 'REAL NOT NULL',
    'location': 'TEXT',
    'meeting_link': 'TEXT',
    'tags': 'TEXT',
    'metadata': 'TEXT',
    'created_at': 'TEXT NOT NULL',
    'updated_at': 'TEXT NOT NULL',
    'is_active': 'INTEGER NOT NULL',
    'is_public': 'INTEGER NOT NULL',
  };

  @override
  MedicalEducation fromMap(Map<String, dynamic> map) => MedicalEducation.fromMap(map);

  @override
  Map<String, dynamic> toMap(MedicalEducation item) => item.toMap();

  // Get education by type
  Future<List<MedicalEducation>> getByType(String type) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'type = ? AND is_active = 1',
      whereArgs: [type],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education by category
  Future<List<MedicalEducation>> getByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education by status
  Future<List<MedicalEducation>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get upcoming education
  Future<List<MedicalEducation>> getUpcomingEducation() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'start_date > ? AND status = ? AND is_active = 1',
      whereArgs: [now, 'upcoming'],
      orderBy: 'start_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get ongoing education
  Future<List<MedicalEducation>> getOngoingEducation() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'start_date <= ? AND (end_date IS NULL OR end_date >= ?) AND status = ? AND is_active = 1',
      whereArgs: [now, now, 'ongoing'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get completed education
  Future<List<MedicalEducation>> getCompletedEducation() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['completed'],
      orderBy: 'end_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education by provider
  Future<List<MedicalEducation>> getByProvider(String provider) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'provider = ? AND is_active = 1',
      whereArgs: [provider],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education by instructor
  Future<List<MedicalEducation>> getByInstructor(String instructor) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'instructor = ? AND is_active = 1',
      whereArgs: [instructor],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get available education (not full)
  Future<List<MedicalEducation>> getAvailableEducation() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'current_participants < max_participants AND status = ? AND is_active = 1',
      whereArgs: ['upcoming'],
      orderBy: 'start_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education with CME credits
  Future<List<MedicalEducation>> getEducationWithCMECredits() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'cme_credits > 0 AND is_active = 1',
      orderBy: 'cme_credits DESC, start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Update participant count
  Future<int> updateParticipantCount(String id, int currentParticipants) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'current_participants': currentParticipants,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update education status
  Future<int> updateEducationStatus(String id, String status, {DateTime? endDate}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'status': status,
        'end_date': endDate?.toIso8601String(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search education
  Future<List<MedicalEducation>> searchEducation(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '(title LIKE ? OR description LIKE ? OR topics LIKE ? OR tags LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education by keyword
  Future<List<MedicalEducation>> getByKeyword(String keyword) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '(topics LIKE ? OR tags LIKE ?) AND is_active = 1',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get all education
  Future<List<MedicalEducation>> getAllEducation() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'is_active = 1',
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get education summary
  Future<Map<String, dynamic>> getEducationSummary() async {
    final db = await database;

    final totalEducation = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
    final upcomingEducation = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['upcoming']);
    final ongoingEducation = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['ongoing']);
    final completedEducation = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['completed']);

    return {
      'total_education': totalEducation.first['count'],
      'upcoming_education': upcomingEducation.first['count'],
      'ongoing_education': ongoingEducation.first['count'],
      'completed_education': completedEducation.first['count'],
    };
  }
}
