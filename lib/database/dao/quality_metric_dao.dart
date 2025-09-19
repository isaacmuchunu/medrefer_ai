import '../models/quality_metric.dart';
import 'dao.dart';

class QualityMetricDao extends BaseDao<QualityMetric> {
  static const String _tableName = 'quality_metrics';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'metric_type': 'TEXT NOT NULL',
    'title': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'category': 'TEXT NOT NULL',
    'measurement': 'TEXT NOT NULL',
    'target_value': 'REAL NOT NULL',
    'current_value': 'REAL NOT NULL',
    'unit': 'TEXT NOT NULL',
    'period': 'TEXT NOT NULL',
    'measurement_date': 'TEXT NOT NULL',
    'department_id': 'TEXT',
    'specialist_id': 'TEXT',
    'facility_id': 'TEXT',
    'breakdown': 'TEXT',
    'tags': 'TEXT',
    'status': 'TEXT NOT NULL',
    'notes': 'TEXT',
    'created_at': 'TEXT NOT NULL',
    'updated_at': 'TEXT NOT NULL',
    'is_active': 'INTEGER NOT NULL',
  };

  @override
  QualityMetric fromMap(Map<String, dynamic> map) => QualityMetric.fromMap(map);

  @override
  Map<String, dynamic> toMap(QualityMetric item) => item.toMap();

  // Get metrics by category
  Future<List<QualityMetric>> getByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get metrics by type
  Future<List<QualityMetric>> getByType(String metricType) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'metric_type = ? AND is_active = 1',
      whereArgs: [metricType],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get metrics by status
  Future<List<QualityMetric>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get metrics by department
  Future<List<QualityMetric>> getByDepartment(String departmentId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'department_id = ? AND is_active = 1',
      whereArgs: [departmentId],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get metrics by specialist
  Future<List<QualityMetric>> getBySpecialist(String specialistId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'specialist_id = ? AND is_active = 1',
      whereArgs: [specialistId],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get metrics by period
  Future<List<QualityMetric>> getByPeriod(String period) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'period = ? AND is_active = 1',
      whereArgs: [period],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get metrics within date range
  Future<List<QualityMetric>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'measurement_date >= ? AND measurement_date <= ? AND is_active = 1',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get underperforming metrics
  Future<List<QualityMetric>> getUnderperformingMetrics() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'current_value < target_value AND is_active = 1',
      orderBy: '(target_value - current_value) DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get critical metrics
  Future<List<QualityMetric>> getCriticalMetrics() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: ['critical'],
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Update metric value
  Future<int> updateMetricValue(String id, double currentValue, {String? notes}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'current_value': currentValue,
        'notes': notes,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get metrics summary
  Future<Map<String, dynamic>> getMetricsSummary() async {
    final db = await database;

    final totalMetrics = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
    final targetMet = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE current_value >= target_value AND is_active = 1');
    final underperforming = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE current_value < target_value AND is_active = 1');
    final critical = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE status = ? AND is_active = 1', ['critical']);

    return {
      'total_metrics': totalMetrics.first['count'],
      'target_met': targetMet.first['count'],
      'underperforming': underperforming.first['count'],
      'critical': critical.first['count'],
    };
  }

  // Get all metrics
  Future<List<QualityMetric>> getAll() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'is_active = 1',
      orderBy: 'measurement_date DESC',
    );
    return maps.map(fromMap).toList();
  }
}
