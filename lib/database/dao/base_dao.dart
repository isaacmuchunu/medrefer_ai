import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

/// Base Data Access Object class providing common database operations
abstract class BaseDao<T> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  /// Get the table name for this DAO
  String get tableName;
  
  /// Get the database instance
  Future<Database> get database async => await _databaseHelper.database;
  
  /// Convert a map from the database to a model object
  T fromMap(Map<String, dynamic> map);
  
  /// Convert a model object to a map for database storage
  Map<String, dynamic> toMap(T object);
  
  /// Insert a new record
  Future<int> insert(T object) async {
    final db = await database;
    return await db.insert(tableName, toMap(object));
  }
  
  /// Update an existing record
  Future<int> update(T object, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(tableName, toMap(object), where: where, whereArgs: whereArgs);
  }
  
  /// Delete a record
  Future<int> delete(String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(tableName, where: where, whereArgs: whereArgs);
  }
  
  /// Find all records
  Future<List<T>> findAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Find records with a where clause
  Future<List<T>> findWhere(String where, List<dynamic> whereArgs) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName, 
      where: where, 
      whereArgs: whereArgs
    );
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Find a single record by ID
  Future<T?> findById(dynamic id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return fromMap(maps.first);
  }
  
  /// Count total records
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Execute a raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// Execute a raw update/insert/delete query
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
}
