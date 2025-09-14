import 'package:sqflite/sqflite.dart';
import '../models/audit_log.dart';

class AuditLogDAO {
  static const String _table = 'audit_logs';

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        action TEXT NOT NULL,
        resource_type TEXT,
        resource_id TEXT,
        ip_address TEXT,
        risk_level TEXT NOT NULL,
        session_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_audit_user ON $_table (user_id)');
    await db.execute('CREATE INDEX idx_audit_event ON $_table (event_type)');
    await db.execute('CREATE INDEX idx_audit_risk ON $_table (risk_level)');
    await db.execute('CREATE INDEX idx_audit_created ON $_table (created_at)');
  }

  final Database _db;
  AuditLogDAO(this._db);

  Future<void> insert(AuditLog log) async {
    await _db.insert(_table, log.toMap());
  }

  Future<List<AuditLog>> query({
    String? userId,
    AuditEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final where = <String>[];
    final args = <dynamic>[];
    if (userId != null) {
      where.add('user_id = ?');
      args.add(userId);
    }
    if (eventType != null) {
      where.add('event_type = ?');
      args.add(eventType.name);
    }
    if (startDate != null) {
      where.add('created_at >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('created_at <= ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await _db.query(
      _table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AuditLog.fromMap).toList();
  }
}

