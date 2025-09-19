import '../models/compliance_audit.dart';
import 'dao.dart';

class ComplianceAuditDao extends BaseDao<ComplianceAudit> {
  static const String _tableName = 'compliance_audits';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'audit_type': 'TEXT NOT NULL',
    'title': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'status': 'TEXT NOT NULL',
    'severity': 'TEXT NOT NULL',
    'category': 'TEXT NOT NULL',
    'department_id': 'TEXT',
    'facility_id': 'TEXT',
    'auditor_id': 'TEXT NOT NULL',
    'assigned_to': 'TEXT',
    'scheduled_date': 'TEXT NOT NULL',
    'start_date': 'TEXT',
    'end_date': 'TEXT',
    'due_date': 'TEXT',
    'checkpoints': 'TEXT',
    'findings': 'TEXT',
    'recommendations': 'TEXT',
    'evidence': 'TEXT',
    'report': 'TEXT',
    'compliance_score': 'REAL NOT NULL',
    'target_score': 'REAL NOT NULL',
    'details': 'TEXT',
    'notes': 'TEXT',
    'created_at': 'TEXT NOT NULL',
    'updated_at': 'TEXT NOT NULL',
    'is_active': 'INTEGER NOT NULL',
    'requires_remediation': 'INTEGER NOT NULL',
  };

  @override
  ComplianceAudit fromMap(Map<String, dynamic> map) => ComplianceAudit.fromMap(map);

  @override
  Map<String, dynamic> toMap(ComplianceAudit item) => item.toMap();

  // Get audits by type
  Future<List<ComplianceAudit>> getByType(String auditType) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'audit_type = ? AND is_active = 1',
      whereArgs: [auditType],
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get audits by status
  Future<List<ComplianceAudit>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get audits by severity
  Future<List<ComplianceAudit>> getBySeverity(String severity) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'severity = ? AND is_active = 1',
      whereArgs: [severity],
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get audits by category
  Future<List<ComplianceAudit>> getByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get audits by auditor
  Future<List<ComplianceAudit>> getByAuditor(String auditorId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'auditor_id = ? AND is_active = 1',
      whereArgs: [auditorId],
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get audits by department
  Future<List<ComplianceAudit>> getByDepartment(String departmentId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'department_id = ? AND is_active = 1',
      whereArgs: [departmentId],
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get overdue audits
  Future<List<ComplianceAudit>> getOverdueAudits() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'due_date < ? AND status != ? AND is_active = 1',
      whereArgs: [now, 'completed'],
      orderBy: 'due_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get scheduled audits
  Future<List<ComplianceAudit>> getScheduledAudits() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['scheduled'],
      orderBy: 'scheduled_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get audits requiring remediation
  Future<List<ComplianceAudit>> getAuditsRequiringRemediation() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'requires_remediation = 1 AND is_active = 1',
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get non-compliant audits
  Future<List<ComplianceAudit>> getNonCompliantAudits() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'compliance_score < target_score AND is_active = 1',
      orderBy: '(target_score - compliance_score) DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Update audit status
  Future<int> updateAuditStatus(String id, String status, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'status': status,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update compliance score
  Future<int> updateComplianceScore(String id, double complianceScore, {String? report}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'compliance_score': complianceScore,
        'report': report,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get compliance summary
  Future<Map<String, dynamic>> getComplianceSummary() async {
    final db = await database;

    final totalAudits = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
    final completedAudits = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['completed']);
    final nonCompliantAudits = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE compliance_score < target_score AND is_active = 1');
    final overdueAudits = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE due_date < ? AND status != ? AND is_active = 1', [DateTime.now().toIso8601String(), 'completed']);

    return {
      'total_audits': totalAudits.first['count'],
      'completed_audits': completedAudits.first['count'],
      'non_compliant_audits': nonCompliantAudits.first['count'],
      'overdue_audits': overdueAudits.first['count'],
    };
  }

  // Get all audits
  Future<List<ComplianceAudit>> getAll() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'is_active = 1',
      orderBy: 'scheduled_date DESC',
    );
    return maps.map(fromMap).toList();
  }
}
