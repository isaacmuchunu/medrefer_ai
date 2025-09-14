import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/database/models/analytics_metric.dart';
import 'package:medrefer_ai/database/dao/dao.dart';

/// Data Access Object for Analytics operations
class AnalyticsDAO extends BaseDAO {
  static const String _tableName = 'analytics_metrics';
  static const String _dashboardConfigTable = 'dashboard_configs';
  static const String _reportsTable = 'analytics_reports';
  static const String _kpiTable = 'kpis';

  AnalyticsDAO(DatabaseHelper dbHelper) : super(dbHelper);

  /// Create analytics metric
  Future<String> createMetric(AnalyticsMetric metric) async {
    try {
      final id = await insert(_tableName, metric.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create analytics metric: $e');
    }
  }

  /// Get analytics metrics by category
  Future<List<AnalyticsMetric>> getMetricsByCategory(String category) async {
    try {
      final results = await query(
        _tableName,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'timestamp DESC',
      );
      
      return results.map((map) => AnalyticsMetric.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get metrics by category: $e');
    }
  }

  /// Get metrics for a specific time range
  Future<List<AnalyticsMetric>> getMetricsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? category,
    String? userId,
    String? organizationId,
  }) async {
    try {
      String where = 'timestamp >= ? AND timestamp <= ?';
      List<dynamic> whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];

      if (category != null) {
        where += ' AND category = ?';
        whereArgs.add(category);
      }

      if (userId != null) {
        where += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      if (organizationId != null) {
        where += ' AND organization_id = ?';
        whereArgs.add(organizationId);
      }

      final results = await query(
        _tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
      );

      return results.map((map) => AnalyticsMetric.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get metrics by date range: $e');
    }
  }

  /// Get aggregated metrics
  Future<Map<String, double>> getAggregatedMetrics(
    String category,
    String aggregation, // sum, avg, min, max, count
    DateTime startDate,
    DateTime endDate, {
    String? userId,
    String? organizationId,
  }) async {
    try {
      String where = 'category = ? AND timestamp >= ? AND timestamp <= ?';
      List<dynamic> whereArgs = [category, startDate.toIso8601String(), endDate.toIso8601String()];

      if (userId != null) {
        where += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      if (organizationId != null) {
        where += ' AND organization_id = ?';
        whereArgs.add(organizationId);
      }

      final results = await rawQuery(
        'SELECT name, $aggregation(value) as aggregated_value FROM $_tableName WHERE $where GROUP BY name',
        whereArgs,
      );

      return Map.fromEntries(
        results.map((row) => MapEntry(
          row['name'] as String,
          (row['aggregated_value'] as num).toDouble(),
        )),
      );
    } catch (e) {
      throw Exception('Failed to get aggregated metrics: $e');
    }
  }

  /// Create dashboard configuration
  Future<String> createDashboardConfig(DashboardConfig config) async {
    try {
      final id = await insert(_dashboardConfigTable, config.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create dashboard config: $e');
    }
  }

  /// Get dashboard configurations for user
  Future<List<DashboardConfig>> getDashboardConfigs({
    String? userId,
    String? organizationId,
  }) async {
    try {
      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      if (organizationId != null) {
        where += ' AND (organization_id = ? OR organization_id IS NULL)';
        whereArgs.add(organizationId);
      }

      final results = await query(
        _dashboardConfigTable,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'is_default DESC, name ASC',
      );

      return results.map((map) => DashboardConfig.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get dashboard configs: $e');
    }
  }

  /// Update dashboard configuration
  Future<void> updateDashboardConfig(DashboardConfig config) async {
    try {
      await update(
        _dashboardConfigTable,
        config.toMap(),
        where: 'id = ?',
        whereArgs: [config.id],
      );
    } catch (e) {
      throw Exception('Failed to update dashboard config: $e');
    }
  }

  /// Create analytics report
  Future<String> createReport(AnalyticsReport report) async {
    try {
      final id = await insert(_reportsTable, report.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create analytics report: $e');
    }
  }

  /// Get analytics reports
  Future<List<AnalyticsReport>> getReports({
    String? userId,
    String? organizationId,
    String? reportType,
  }) async {
    try {
      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      if (organizationId != null) {
        where += ' AND (organization_id = ? OR organization_id IS NULL)';
        whereArgs.add(organizationId);
      }

      if (reportType != null) {
        where += ' AND report_type = ?';
        whereArgs.add(reportType);
      }

      final results = await query(
        _reportsTable,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      return results.map((map) => AnalyticsReport.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get analytics reports: $e');
    }
  }

  /// Update report last generated time
  Future<void> updateReportLastGenerated(String reportId) async {
    try {
      await update(
        _reportsTable,
        {'last_generated': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [reportId],
      );
    } catch (e) {
      throw Exception('Failed to update report last generated: $e');
    }
  }

  /// Create KPI
  Future<String> createKPI(KPI kpi) async {
    try {
      final id = await insert(_kpiTable, kpi.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create KPI: $e');
    }
  }

  /// Get KPIs by category
  Future<List<KPI>> getKPIsByCategory(String category) async {
    try {
      final results = await query(
        _kpiTable,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'last_updated DESC',
      );

      return results.map((map) => KPI.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get KPIs by category: $e');
    }
  }

  /// Get all KPIs
  Future<List<KPI>> getAllKPIs() async {
    try {
      final results = await query(
        _kpiTable,
        orderBy: 'category ASC, name ASC',
      );

      return results.map((map) => KPI.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all KPIs: $e');
    }
  }

  /// Update KPI
  Future<void> updateKPI(KPI kpi) async {
    try {
      await update(
        _kpiTable,
        kpi.toMap(),
        where: 'id = ?',
        whereArgs: [kpi.id],
      );
    } catch (e) {
      throw Exception('Failed to update KPI: $e');
    }
  }

  /// Get trending metrics (metrics with significant changes)
  Future<List<AnalyticsMetric>> getTrendingMetrics({
    int limit = 10,
    double minChangePercent = 10.0,
  }) async {
    try {
      final results = await rawQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE timestamp >= datetime('now', '-7 days')
        ORDER BY ABS(value) DESC
        LIMIT ?
        ''',
        [limit],
      );

      return results.map((map) => AnalyticsMetric.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get trending metrics: $e');
    }
  }

  /// Get metrics summary for dashboard
  Future<Map<String, dynamic>> getDashboardSummary({
    String? userId,
    String? organizationId,
  }) async {
    try {
      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      if (organizationId != null) {
        where += ' AND (organization_id = ? OR organization_id IS NULL)';
        whereArgs.add(organizationId);
      }

      final totalMetrics = await rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE $where',
        whereArgs,
      );

      final categoryCounts = await rawQuery(
        'SELECT category, COUNT(*) as count FROM $_tableName WHERE $where GROUP BY category',
        whereArgs,
      );

      final recentMetrics = await rawQuery(
        'SELECT * FROM $_tableName WHERE $where ORDER BY timestamp DESC LIMIT 5',
        whereArgs,
      );

      return {
        'total_metrics': totalMetrics.first['count'],
        'category_counts': Map.fromEntries(
          categoryCounts.map((row) => MapEntry(
            row['category'] as String,
            row['count'] as int,
          )),
        ),
        'recent_metrics': recentMetrics.map((map) => AnalyticsMetric.fromMap(map)).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard summary: $e');
    }
  }

  /// Delete old metrics (for data retention)
  Future<int> deleteOldMetrics(int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      return await delete(
        _tableName,
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
    } catch (e) {
      throw Exception('Failed to delete old metrics: $e');
    }
  }

  /// Get metrics for specific entities (patients, referrals, etc.)
  Future<List<AnalyticsMetric>> getEntityMetrics(
    String entityType,
    String entityId, {
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String where = 'metadata LIKE ?';
      List<dynamic> whereArgs = ['%"entity_type":"$entityType"%'];

      if (category != null) {
        where += ' AND category = ?';
        whereArgs.add(category);
      }

      if (startDate != null) {
        where += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final results = await query(
        _tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
      );

      // Filter by entity ID in metadata
      return results
          .map((map) => AnalyticsMetric.fromMap(map))
          .where((metric) => metric.metadata['entity_id'] == entityId)
          .toList();
    } catch (e) {
      throw Exception('Failed to get entity metrics: $e');
    }
  }
}