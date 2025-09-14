import 'package:sqflite/sqflite.dart';
import '../models/app_notification.dart';

class NotificationDAO {
  static const String _table = 'notifications';

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        user_id TEXT,
        action_route TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_notifications_user ON $_table (user_id)');
    await db.execute('CREATE INDEX idx_notifications_read ON $_table (is_read)');
    await db.execute('CREATE INDEX idx_notifications_created ON $_table (created_at)');
  }

  final Database _db;
  NotificationDAO(this._db);

  Future<void> insert(AppNotificationModel notification) async {
    await _db.insert(_table, notification.toMap());
  }

  Future<List<AppNotificationModel>> getAll({String? userId}) async {
    final rows = await _db.query(
      _table,
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'created_at DESC',
    );
    return rows.map(AppNotificationModel.fromMap).toList();
  }

  Future<List<AppNotificationModel>> getUnread({String? userId}) async {
    final where = <String>['is_read = 0'];
    final args = <dynamic>[];
    if (userId != null) {
      where.add('user_id = ?');
      args.add(userId);
    }

    final rows = await _db.query(
      _table,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(AppNotificationModel.fromMap).toList();
  }

  Future<void> markAsRead(String id) async {
    await _db.update(_table, {
      'is_read': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllAsRead({String? userId}) async {
    await _db.update(
      _table,
      {
        'is_read': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
  }
}

