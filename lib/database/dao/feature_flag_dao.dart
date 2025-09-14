import 'package:sqflite/sqflite.dart';
import '../models/feature_flag.dart';

class FeatureFlagDAO {
  static const String _table = 'feature_flags';

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        key TEXT NOT NULL UNIQUE,
        is_enabled INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        rollout_strategy TEXT,
        rollout_percentage REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_feature_flags_enabled ON $_table (is_enabled)');
  }

  final Database _db;
  FeatureFlagDAO(this._db);

  Future<void> upsert(FeatureFlag flag) async {
    await _db.insert(_table, flag.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<FeatureFlag?> getByKey(String key) async {
    final rows = await _db.query(_table, where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return FeatureFlag.fromMap(rows.first);
  }

  Future<bool> isEnabled(String key) async {
    final flag = await getByKey(key);
    return flag?.isEnabled ?? false;
  }

  Future<List<FeatureFlag>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'key ASC');
    return rows.map(FeatureFlag.fromMap).toList();
  }
}

