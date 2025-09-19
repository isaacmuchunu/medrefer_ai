import '../models/research_study.dart';
import 'dao.dart';

class ResearchStudyDao extends BaseDao<ResearchStudy> {
  static const String _tableName = 'research_studies';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'title': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'study_type': 'TEXT NOT NULL',
    'status': 'TEXT NOT NULL',
    'principal_investigator': 'TEXT NOT NULL',
    'co_investigators': 'TEXT',
    'institution': 'TEXT NOT NULL',
    'department': 'TEXT NOT NULL',
    'protocol': 'TEXT NOT NULL',
    'objectives': 'TEXT NOT NULL',
    'methodology': 'TEXT NOT NULL',
    'inclusion_criteria': 'TEXT NOT NULL',
    'exclusion_criteria': 'TEXT NOT NULL',
    'target_participants': 'INTEGER NOT NULL',
    'current_participants': 'INTEGER NOT NULL',
    'start_date': 'TEXT NOT NULL',
    'end_date': 'TEXT',
    'estimated_completion': 'TEXT',
    'funding_source': 'TEXT NOT NULL',
    'ethical_approval': 'TEXT NOT NULL',
    'irb_number': 'TEXT NOT NULL',
    'keywords': 'TEXT',
    'tags': 'TEXT',
    'metadata': 'TEXT',
    'results': 'TEXT',
    'conclusions': 'TEXT',
    'publications': 'TEXT',
    'created_at': 'TEXT NOT NULL',
    'updated_at': 'TEXT NOT NULL',
    'is_active': 'INTEGER NOT NULL',
    'is_public': 'INTEGER NOT NULL',
  };

  @override
  ResearchStudy fromMap(Map<String, dynamic> map) => ResearchStudy.fromMap(map);

  @override
  Map<String, dynamic> toMap(ResearchStudy item) => item.toMap();

  // Get studies by status
  Future<List<ResearchStudy>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get studies by type
  Future<List<ResearchStudy>> getByType(String studyType) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'study_type = ? AND is_active = 1',
      whereArgs: [studyType],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get studies by principal investigator
  Future<List<ResearchStudy>> getByPrincipalInvestigator(String investigatorId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'principal_investigator = ? AND is_active = 1',
      whereArgs: [investigatorId],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get studies by department
  Future<List<ResearchStudy>> getByDepartment(String department) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'department = ? AND is_active = 1',
      whereArgs: [department],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get recruiting studies
  Future<List<ResearchStudy>> getRecruitingStudies() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND current_participants < target_participants AND is_active = 1',
      whereArgs: ['recruiting'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get active studies
  Future<List<ResearchStudy>> getActiveStudies() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['active'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get completed studies
  Future<List<ResearchStudy>> getCompletedStudies() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['completed'],
      orderBy: 'end_date DESC',
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

  // Update study status
  Future<int> updateStudyStatus(String id, String status, {DateTime? endDate}) async {
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

  // Search studies
  Future<List<ResearchStudy>> searchStudies(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '(title LIKE ? OR description LIKE ? OR keywords LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get studies by keyword
  Future<List<ResearchStudy>> getByKeyword(String keyword) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'keywords LIKE ? AND is_active = 1',
      whereArgs: ['%$keyword%'],
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get studies summary
  Future<Map<String, dynamic>> getStudiesSummary() async {
    final db = await database;

    final totalStudies = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
    final activeStudies = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['active']);
    final recruitingStudies = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['recruiting']);
    final completedStudies = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['completed']);

    return {
      'total_studies': totalStudies.first['count'],
      'active_studies': activeStudies.first['count'],
      'recruiting_studies': recruitingStudies.first['count'],
      'completed_studies': completedStudies.first['count'],
    };
  }

  // Get all studies
  Future<List<ResearchStudy>> getAll() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'is_active = 1',
      orderBy: 'start_date DESC',
    );
    return maps.map(fromMap).toList();
  }
}
