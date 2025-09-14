import 'package:sqflite/sqflite.dart';
import '../models/user.dart';

class UserDAO {
  static const String _usersTable = 'users';
  static const String _userAuthTable = 'user_auth';

  // Create tables
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_usersTable (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone_number TEXT,
        role TEXT NOT NULL DEFAULT 'patient',
        status TEXT NOT NULL DEFAULT 'active',
        profile_image_url TEXT,
        last_login_at TEXT,
        is_email_verified INTEGER DEFAULT 0,
        is_phone_verified INTEGER DEFAULT 0,
        department TEXT,
        specialization TEXT,
        license_number TEXT,
        preferences TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_userAuthTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT,
        last_password_change TEXT,
        failed_login_attempts INTEGER DEFAULT 0,
        locked_until TEXT,
        requires_password_change INTEGER DEFAULT 0,
        reset_token TEXT,
        reset_token_expiry TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_users_email ON $_usersTable (email)');
    await db.execute('CREATE INDEX idx_users_role ON $_usersTable (role)');
    await db.execute('CREATE INDEX idx_users_status ON $_usersTable (status)');
    await db.execute('CREATE INDEX idx_user_auth_user_id ON $_userAuthTable (user_id)');
  }

  final Database _db;

  UserDAO(this._db);

  // User operations
  Future<List<User>> getAllUsers() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      orderBy: 'first_name ASC, last_name ASC',
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<List<User>> getUsersByRole(UserRole role) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      where: 'role = ? AND status = ?',
      whereArgs: [role.name, UserStatus.active.name],
      orderBy: 'first_name ASC, last_name ASC',
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<List<User>> getActiveUsers() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      where: 'status = ?',
      whereArgs: [UserStatus.active.name],
      orderBy: 'first_name ASC, last_name ASC',
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(String id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> searchUsers(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      where: '''
        (first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR 
         department LIKE ? OR specialization LIKE ?) AND status = ?
      ''',
      whereArgs: [
        '%$query%', '%$query%', '%$query%', 
        '%$query%', '%$query%', UserStatus.active.name
      ],
      orderBy: 'first_name ASC, last_name ASC',
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> insertUser(User user) async {
    await _db.insert(_usersTable, user.toMap());
  }

  Future<void> updateUser(User user) async {
    await _db.update(
      _usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateLastLogin(String userId) async {
    await _db.update(
      _usersTable,
      {
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    await _db.update(
      _usersTable,
      {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(String id) async {
    await _db.delete(
      _usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User authentication operations
  Future<UserAuth?> getUserAuth(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _userAuthTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return UserAuth.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertUserAuth(UserAuth userAuth) async {
    await _db.insert(_userAuthTable, userAuth.toMap());
  }

  Future<void> updateUserAuth(UserAuth userAuth) async {
    await _db.update(
      _userAuthTable,
      userAuth.toMap(),
      where: 'user_id = ?',
      whereArgs: [userAuth.userId],
    );
  }

  Future<void> updatePassword(String userId, String passwordHash, {String? salt}) async {
    await _db.update(
      _userAuthTable,
      {
        'password_hash': passwordHash,
        'salt': salt,
        'last_password_change': DateTime.now().toIso8601String(),
        'requires_password_change': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> incrementFailedLoginAttempts(String userId) async {
    await _db.rawUpdate('''
      UPDATE $_userAuthTable 
      SET failed_login_attempts = failed_login_attempts + 1,
          updated_at = ?
      WHERE user_id = ?
    ''', [DateTime.now().toIso8601String(), userId]);
  }

  Future<void> resetFailedLoginAttempts(String userId) async {
    await _db.update(
      _userAuthTable,
      {
        'failed_login_attempts': 0,
        'locked_until': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> lockUser(String userId, DateTime lockUntil) async {
    await _db.update(
      _userAuthTable,
      {
        'locked_until': lockUntil.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> setPasswordResetToken(String userId, String token, DateTime expiry) async {
    await _db.update(
      _userAuthTable,
      {
        'reset_token': token,
        'reset_token_expiry': expiry.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearPasswordResetToken(String userId) async {
    await _db.update(
      _userAuthTable,
      {
        'reset_token': null,
        'reset_token_expiry': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<User?> getUserByResetToken(String token) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery('''
      SELECT u.* FROM $_usersTable u
      INNER JOIN $_userAuthTable ua ON u.id = ua.user_id
      WHERE ua.reset_token = ? AND ua.reset_token_expiry > ?
    ''', [token, DateTime.now().toIso8601String()]);
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Statistics
  Future<Map<String, int>> getUserStatistics() async {
    final result = await _db.rawQuery('''
      SELECT 
        role,
        COUNT(*) as count
      FROM $_usersTable 
      WHERE status = ?
      GROUP BY role
    ''', [UserStatus.active.name]);

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['role'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<int> getTotalActiveUsers() async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM $_usersTable WHERE status = ?
    ''', [UserStatus.active.name]);
    
    return result.first['count'] as int;
  }

  Future<List<User>> getRecentlyActiveUsers({int limit = 10}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _usersTable,
      where: 'status = ? AND last_login_at IS NOT NULL',
      whereArgs: [UserStatus.active.name],
      orderBy: 'last_login_at DESC',
      limit: limit,
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }
}
