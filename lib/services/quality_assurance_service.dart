import 'dart:async';
import '../database/dao/quality_metric_dao.dart';
import '../database/models/quality_metric.dart';

class QualityAssuranceService {
  static final QualityAssuranceService _instance = QualityAssuranceService._internal();
  factory QualityAssuranceService() => _instance;
  QualityAssuranceService._internal();

  final QualityMetricDao _dao = QualityMetricDao();
  final StreamController<List<QualityMetric>> _metricsController = 
      StreamController<List<QualityMetric>>.broadcast();

  Stream<List<QualityMetric>> get metricsStream => _metricsController.stream;

  // Create a new quality metric
  Future<QualityMetric> createMetric(QualityMetric metric) async {
    try {
      final createdMetric = await _dao.insert(metric);
      await _refreshMetrics();
      return createdMetric;
    } catch (e) {
      throw Exception('Failed to create quality metric: $e');
    }
  }

  // Get all metrics
  Future<List<QualityMetric>> getAllMetrics() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw Exception('Failed to get quality metrics: $e');
    }
  }

  // Get metrics by category
  Future<List<QualityMetric>> getMetricsByCategory(String category) async {
    try {
      return await _dao.getByCategory(category);
    } catch (e) {
      throw Exception('Failed to get metrics by category: $e');
    }
  }

  // Get metrics by type
  Future<List<QualityMetric>> getMetricsByType(String metricType) async {
    try {
      return await _dao.getByType(metricType);
    } catch (e) {
      throw Exception('Failed to get metrics by type: $e');
    }
  }

  // Get metrics by status
  Future<List<QualityMetric>> getMetricsByStatus(String status) async {
    try {
      return await _dao.getByStatus(status);
    } catch (e) {
      throw Exception('Failed to get metrics by status: $e');
    }
  }

  // Get underperforming metrics
  Future<List<QualityMetric>> getUnderperformingMetrics() async {
    try {
      return await _dao.getUnderperformingMetrics();
    } catch (e) {
      throw Exception('Failed to get underperforming metrics: $e');
    }
  }

  // Get critical metrics
  Future<List<QualityMetric>> getCriticalMetrics() async {
    try {
      return await _dao.getCriticalMetrics();
    } catch (e) {
      throw Exception('Failed to get critical metrics: $e');
    }
  }

  // Get metrics by department
  Future<List<QualityMetric>> getMetricsByDepartment(String departmentId) async {
    try {
      return await _dao.getByDepartment(departmentId);
    } catch (e) {
      throw Exception('Failed to get metrics by department: $e');
    }
  }

  // Get metrics by specialist
  Future<List<QualityMetric>> getMetricsBySpecialist(String specialistId) async {
    try {
      return await _dao.getBySpecialist(specialistId);
    } catch (e) {
      throw Exception('Failed to get metrics by specialist: $e');
    }
  }

  // Get metrics by period
  Future<List<QualityMetric>> getMetricsByPeriod(String period) async {
    try {
      return await _dao.getByPeriod(period);
    } catch (e) {
      throw Exception('Failed to get metrics by period: $e');
    }
  }

  // Get metrics within date range
  Future<List<QualityMetric>> getMetricsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _dao.getByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get metrics by date range: $e');
    }
  }

  // Update metric value
  Future<bool> updateMetricValue(String id, double currentValue, {String? notes}) async {
    try {
      final result = await _dao.updateMetricValue(id, currentValue, notes: notes);
      await _refreshMetrics();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update metric value: $e');
    }
  }

  // Get quality dashboard data
  Future<Map<String, dynamic>> getQualityDashboard() async {
    try {
      final summary = await _dao.getMetricsSummary();
      final underperforming = await getUnderperformingMetrics();
      final critical = await getCriticalMetrics();
      
      return {
        'summary': summary,
        'underperforming_metrics': underperforming,
        'critical_metrics': critical,
        'total_metrics': summary['total_metrics'],
        'target_met': summary['target_met'],
        'underperforming_count': summary['underperforming'],
        'critical_count': summary['critical'],
        'performance_rate': summary['total_metrics'] > 0 ? 
          (summary['target_met'] / summary['total_metrics']) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get quality dashboard: $e');
    }
  }

  // Get performance trends
  Future<Map<String, dynamic>> getPerformanceTrends({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final metrics = await getMetricsByDateRange(startDate, endDate);
      
      final categoryPerformance = <String, List<double>>{};
      final dailyPerformance = <String, double>{};
      final typePerformance = <String, List<double>>{};
      
      for (final metric in metrics) {
        // Category performance
        if (!categoryPerformance.containsKey(metric.category)) {
          categoryPerformance[metric.category] = [];
        }
        categoryPerformance[metric.category]!.add(metric.performancePercentage);
        
        // Daily performance
        final dateKey = '${metric.measurementDate.year}-${metric.measurementDate.month.toString().padLeft(2, '0')}-${metric.measurementDate.day.toString().padLeft(2, '0')}';
        dailyPerformance[dateKey] = (dailyPerformance[dateKey] ?? 0) + metric.performancePercentage;
        
        // Type performance
        if (!typePerformance.containsKey(metric.metricType)) {
          typePerformance[metric.metricType] = [];
        }
        typePerformance[metric.metricType]!.add(metric.performancePercentage);
      }
      
      // Calculate averages
      final avgCategoryPerformance = <String, double>{};
      categoryPerformance.forEach((category, values) {
        avgCategoryPerformance[category] = values.reduce((a, b) => a + b) / values.length;
      });
      
      final avgTypePerformance = <String, double>{};
      typePerformance.forEach((type, values) {
        avgTypePerformance[type] = values.reduce((a, b) => a + b) / values.length;
      });
      
      return {
        'category_performance': avgCategoryPerformance,
        'type_performance': avgTypePerformance,
        'daily_performance': dailyPerformance,
        'total_metrics_analyzed': metrics.length,
        'average_performance': metrics.isNotEmpty ? 
          metrics.map((m) => m.performancePercentage).reduce((a, b) => a + b) / metrics.length : 0,
      };
    } catch (e) {
      throw Exception('Failed to get performance trends: $e');
    }
  }

  // Get quality alerts
  Future<List<Map<String, dynamic>>> getQualityAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];
      
      final underperforming = await getUnderperformingMetrics();
      final critical = await getCriticalMetrics();
      
      // Add underperforming alerts
      for (final metric in underperforming) {
        alerts.add({
          'type': 'underperforming',
          'severity': 'medium',
          'title': 'Underperforming Metric',
          'message': '${metric.title} is below target (${metric.performancePercentage.toStringAsFixed(1)}%)',
          'metric': metric,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add critical alerts
      for (final metric in critical) {
        alerts.add({
          'type': 'critical',
          'severity': 'high',
          'title': 'Critical Quality Issue',
          'message': '${metric.title} requires immediate attention',
          'metric': metric,
          'timestamp': DateTime.now(),
        });
      }
      
      return alerts;
    } catch (e) {
      throw Exception('Failed to get quality alerts: $e');
    }
  }

  // Get benchmark comparison
  Future<Map<String, dynamic>> getBenchmarkComparison() async {
    try {
      final allMetrics = await _dao.getAll();
      
      final categoryBenchmarks = <String, List<double>>{};
      final typeBenchmarks = <String, List<double>>{};
      
      for (final metric in allMetrics) {
        // Category benchmarks
        if (!categoryBenchmarks.containsKey(metric.category)) {
          categoryBenchmarks[metric.category] = [];
        }
        categoryBenchmarks[metric.category]!.add(metric.performancePercentage);
        
        // Type benchmarks
        if (!typeBenchmarks.containsKey(metric.metricType)) {
          typeBenchmarks[metric.metricType] = [];
        }
        typeBenchmarks[metric.metricType]!.add(metric.performancePercentage);
      }
      
      // Calculate benchmarks
      final categoryAverages = <String, double>{};
      categoryBenchmarks.forEach((category, values) {
        categoryAverages[category] = values.reduce((a, b) => a + b) / values.length;
      });
      
      final typeAverages = <String, double>{};
      typeBenchmarks.forEach((type, values) {
        typeAverages[type] = values.reduce((a, b) => a + b) / values.length;
      });
      
      return {
        'category_benchmarks': categoryAverages,
        'type_benchmarks': typeAverages,
        'overall_benchmark': allMetrics.isNotEmpty ? 
          allMetrics.map((m) => m.performancePercentage).reduce((a, b) => a + b) / allMetrics.length : 0,
        'total_metrics': allMetrics.length,
      };
    } catch (e) {
      throw Exception('Failed to get benchmark comparison: $e');
    }
  }

  // Refresh metrics stream
  Future<void> _refreshMetrics() async {
    try {
      final metrics = await _dao.getAll();
      _metricsController.add(metrics);
    } catch (e) {
      _metricsController.addError(e);
    }
  }

  // Dispose resources
  void dispose() {
    _metricsController.close();
  }
}