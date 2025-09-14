import 'package:sqflite/sqflite.dart';
import '../models/rbac.dart';

class RBACDAO {
  static const String _rolesTable = 'roles';
  static const String _permissionsTable = 'permissions';
  static const String _rolePermissionsTable = 'role_permissions';

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_rolesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_permissionsTable (
        id TEXT PRIMARY KEY,
        key TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_rolePermissionsTable (
        id TEXT PRIMARY KEY,
        role_id TEXT NOT NULL,
        permission_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(role_id, permission_id),
        FOREIGN KEY (role_id) REFERENCES $_rolesTable (id) ON DELETE CASCADE,
        FOREIGN KEY (permission_id) REFERENCES $_permissionsTable (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_role_permissions_role ON $_rolePermissionsTable (role_id)');
    await db.execute('CREATE INDEX idx_role_permissions_perm ON $_rolePermissionsTable (permission_id)');
  }

  final Database _db;
  RBACDAO(this._db);

  Future<void> upsertRole(Role role) async {
    await _db.insert(_rolesTable, role.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertPermission(PermissionModel permission) async {
    await _db.insert(_permissionsTable, permission.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> assignPermissionToRole(String roleId, String permissionId) async {
    final rp = RolePermission(roleId: roleId, permissionId: permissionId);
    await _db.insert(_rolePermissionsTable, rp.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<PermissionModel>> getPermissionsForRole(String roleId) async {
    final rows = await _db.rawQuery('''
      SELECT p.* FROM $_permissionsTable p
      INNER JOIN $_rolePermissionsTable rp ON p.id = rp.permission_id
      WHERE rp.role_id = ?
      ORDER BY p.key ASC
    ''', [roleId]);
    return rows.map(PermissionModel.fromMap).toList();
  }

  Future<Role?> getRoleByName(String name) async {
    final rows = await _db.query(_rolesTable, where: 'name = ?', whereArgs: [name], limit: 1);
    if (rows.isEmpty) return null;
    return Role.fromMap(rows.first);
  }
}

