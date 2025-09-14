import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database.dart';
import 'ai_service.dart';

/// Advanced Analytics Service
/// Provides comprehensive analytics with predictive models, trend analysis, and KPI tracking
class AnalyticsService extends ChangeNotifier {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Configuration
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const int _maxDataPoints = 1000;
  static const int _trendWindow = 30; // days
  
  // Analytics data
  final Map<String, List<DataPoint>> _timeSeriesData = {};
  final Map<String, KPI> _kpis = {};
  final Map<String, TrendAnalysis> _trends = {};
  final Map<String, PredictiveModel> _predictiveModels = {};
  final List<AnalyticsEvent> _eventLog = [];
  
  // Real-time metrics
  final Map<String, RealTimeMetric> _realTimeMetrics = {};
  final StreamController<MetricUpdate> _metricUpdateController = StreamController<MetricUpdate>.broadcast();
  
  // Dashboards
  final Map<String, Dashboard> _dashboards = {};
  final Map<String, Widget> _customWidgets = {};
  
  // Performance tracking
  int _queriesExecuted = 0;
  int _predictionsGenerated = 0;
  Duration _totalProcessingTime = Duration.zero;
  
  // Database
  Database? _database;
  Timer? _refreshTimer;
  
  // AI Service integration
  AIService? _aiService;

  /// Initialize analytics service
  Future<void> initialize() async {
    try {
      _database = await DatabaseHelper().database;
      _aiService = AIService();
      
      await _createAnalyticsTables();
      await _loadHistoricalData();
      await _initializeKPIs();
      await _initializePredictiveModels();
      
      _startRealTimeMonitoring();
      _startRefreshTimer();
      
      debugPrint('Analytics Service initialized');
    } catch (e) {
      debugPrint('Error initializing Analytics Service: $e');
      throw AnalyticsException('Failed to initialize analytics service');
    }
  }

  /// Create analytics database tables
  Future<void> _createAnalyticsTables() async {
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS analytics_events (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        event_name TEXT NOT NULL,
        user_id TEXT,
        properties TEXT,
        timestamp INTEGER NOT NULL,
        session_id TEXT
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS kpi_snapshots (
        id TEXT PRIMARY KEY,
        kpi_name TEXT NOT NULL,
        value REAL NOT NULL,
        target REAL,
        timestamp INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS predictions (
        id TEXT PRIMARY KEY,
        model_name TEXT NOT NULL,
        prediction_type TEXT NOT NULL,
        predicted_value REAL,
        confidence REAL,
        actual_value REAL,
        timestamp INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_events_timestamp 
      ON analytics_events(timestamp DESC)
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_kpi_timestamp 
      ON kpi_snapshots(timestamp DESC)
    ''');
  }

  /// Track analytics event
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    String? userId,
    Map<String, dynamic>? properties,
    String? sessionId,
  }) async {
    try {
      final event = AnalyticsEvent(
        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
        eventType: eventType,
        eventName: eventName,
        userId: userId,
        properties: properties,
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      
      _eventLog.add(event);
      
      // Store in database
      await _database!.insert('analytics_events', event.toMap());
      
      // Update real-time metrics
      _updateRealTimeMetrics(event);
      
      // Trigger relevant analytics
      await _processEvent(event);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking event: $e');
    }
  }

  /// Get comprehensive dashboard data
  Future<DashboardData> getDashboardData(String dashboardType) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      switch (dashboardType) {
        case 'executive':
          return await _getExecutiveDashboard();
        case 'clinical':
          return await _getClinicalDashboard();
        case 'operational':
          return await _getOperationalDashboard();
        case 'financial':
          return await _getFinancialDashboard();
        case 'quality':
          return await _getQualityDashboard();
        default:
          return await _getDefaultDashboard();
      }
    } finally {
      _queriesExecuted++;
      _totalProcessingTime += Stopwatch().elapsed;
    }
  }

  /// Get executive dashboard
  Future<DashboardData> _getExecutiveDashboard() async {
    final kpis = await _calculateExecutiveKPIs();
    final trends = await _analyzeTrends(['revenue', 'patients', 'referrals']);
    final predictions = await _generatePredictions(['growth', 'churn']);
    final insights = await _generateInsights(kpis, trends);
    
    return DashboardData(
      id: 'exec_${DateTime.now().millisecondsSinceEpoch}',
      type: 'executive',
      kpis: kpis,
      charts: await _generateExecutiveCharts(),
      trends: trends,
      predictions: predictions,
      insights: insights,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get clinical dashboard
  Future<DashboardData> _getClinicalDashboard() async {
    final kpis = await _calculateClinicalKPIs();
    final outcomes = await _analyzePatientOutcomes();
    final quality = await _assessQualityMetrics();
    
    return DashboardData(
      id: 'clinical_${DateTime.now().millisecondsSinceEpoch}',
      type: 'clinical',
      kpis: kpis,
      charts: await _generateClinicalCharts(),
      trends: await _analyzeTrends(['outcomes', 'readmissions', 'satisfaction']),
      predictions: await _generatePredictions(['patient_risk', 'readmission']),
      insights: await _generateClinicalInsights(outcomes, quality),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get operational dashboard
  Future<DashboardData> _getOperationalDashboard() async {
    final efficiency = await _calculateEfficiencyMetrics();
    final utilization = await _calculateResourceUtilization();
    final bottlenecks = await _identifyBottlenecks();
    
    return DashboardData(
      id: 'ops_${DateTime.now().millisecondsSinceEpoch}',
      type: 'operational',
      kpis: await _calculateOperationalKPIs(),
      charts: await _generateOperationalCharts(),
      trends: await _analyzeTrends(['wait_times', 'throughput', 'utilization']),
      predictions: await _generatePredictions(['capacity', 'demand']),
      insights: await _generateOperationalInsights(efficiency, bottlenecks),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get financial dashboard
  Future<DashboardData> _getFinancialDashboard() async {
    final revenue = await _calculateRevenueMetrics();
    final costs = await _analyzeCosts();
    final profitability = await _assessProfitability();
    
    return DashboardData(
      id: 'fin_${DateTime.now().millisecondsSinceEpoch}',
      type: 'financial',
      kpis: await _calculateFinancialKPIs(),
      charts: await _generateFinancialCharts(),
      trends: await _analyzeTrends(['revenue', 'costs', 'margin']),
      predictions: await _generatePredictions(['revenue_forecast', 'cost_projection']),
      insights: await _generateFinancialInsights(revenue, profitability),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get quality dashboard
  Future<DashboardData> _getQualityDashboard() async {
    final satisfaction = await _measurePatientSatisfaction();
    final compliance = await _assessCompliance();
    final safety = await _evaluateSafety();
    
    return DashboardData(
      id: 'quality_${DateTime.now().millisecondsSinceEpoch}',
      type: 'quality',
      kpis: await _calculateQualityKPIs(),
      charts: await _generateQualityCharts(),
      trends: await _analyzeTrends(['satisfaction', 'incidents', 'compliance']),
      predictions: await _generatePredictions(['quality_score', 'risk_areas']),
      insights: await _generateQualityInsights(satisfaction, safety),
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculate KPIs
  Future<List<KPI>> _calculateExecutiveKPIs() async {
    final kpis = <KPI>[];
    
    // Patient volume
    final patientCount = await _getPatientCount();
    kpis.add(KPI(
      id: 'patient_volume',
      name: 'Total Patients',
      value: patientCount.toDouble(),
      target: 10000,
      unit: 'patients',
      trend: await _calculateTrend('patients', 30),
      status: _getKPIStatus(patientCount.toDouble(), 10000),
    ));
    
    // Referral completion rate
    final completionRate = await _getReferralCompletionRate();
    kpis.add(KPI(
      id: 'referral_completion',
      name: 'Referral Completion Rate',
      value: completionRate,
      target: 85,
      unit: '%',
      trend: await _calculateTrend('referral_completion', 30),
      status: _getKPIStatus(completionRate, 85),
    ));
    
    // Average wait time
    final avgWaitTime = await _getAverageWaitTime();
    kpis.add(KPI(
      id: 'avg_wait_time',
      name: 'Average Wait Time',
      value: avgWaitTime,
      target: 15,
      unit: 'minutes',
      trend: await _calculateTrend('wait_time', 30),
      status: _getKPIStatus(avgWaitTime, 15, inverse: true),
    ));
    
    // System uptime
    final uptime = await _getSystemUptime();
    kpis.add(KPI(
      id: 'system_uptime',
      name: 'System Uptime',
      value: uptime,
      target: 99.9,
      unit: '%',
      trend: TrendDirection.stable,
      status: _getKPIStatus(uptime, 99.9),
    ));
    
    return kpis;
  }

  /// Analyze trends
  Future<List<TrendAnalysis>> _analyzeTrends(List<String> metrics) async {
    final trends = <TrendAnalysis>[];
    
    for (final metric in metrics) {
      final data = await _getTimeSeriesData(metric, _trendWindow);
      
      if (data.isNotEmpty) {
        final trend = _performTrendAnalysis(data);
        trends.add(trend);
        _trends[metric] = trend;
      }
    }
    
    return trends;
  }

  /// Perform trend analysis on time series data
  TrendAnalysis _performTrendAnalysis(List<DataPoint> data) {
    if (data.length < 2) {
      return TrendAnalysis(
        metric: 'unknown',
        direction: TrendDirection.stable,
        strength: 0,
        forecast: [],
      );
    }
    
    // Calculate linear regression
    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i].value;
      sumXY += i * data[i].value;
      sumX2 += i * i;
    }
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    // Determine trend direction
    TrendDirection direction;
    if (slope.abs() < 0.01) {
      direction = TrendDirection.stable;
    } else if (slope > 0) {
      direction = TrendDirection.up;
    } else {
      direction = TrendDirection.down;
    }
    
    // Calculate R-squared for trend strength
    double ssTotal = 0, ssResidual = 0;
    final meanY = sumY / n;
    
    for (int i = 0; i < n; i++) {
      final predicted = slope * i + intercept;
      ssTotal += pow(data[i].value - meanY, 2);
      ssResidual += pow(data[i].value - predicted, 2);
    }
    
    final rSquared = 1 - (ssResidual / ssTotal);
    
    // Generate forecast
    final forecast = <DataPoint>[];
    for (int i = 0; i < 7; i++) {
      final futureValue = slope * (n + i) + intercept;
      forecast.add(DataPoint(
        value: futureValue,
        timestamp: DateTime.now().add(Duration(days: i + 1)),
      ));
    }
    
    // Identify anomalies
    final anomalies = _detectAnomalies(data, slope, intercept);
    
    // Detect seasonality
    final seasonality = _detectSeasonality(data);
    
    return TrendAnalysis(
      metric: data.first.label ?? 'metric',
      direction: direction,
      strength: rSquared,
      slope: slope,
      forecast: forecast,
      anomalies: anomalies,
      seasonality: seasonality,
      confidence: _calculateConfidence(rSquared, data.length),
    );
  }

  /// Detect anomalies in time series data
  List<Anomaly> _detectAnomalies(List<DataPoint> data, double slope, double intercept) {
    final anomalies = <Anomaly>[];
    
    // Calculate standard deviation of residuals
    double sumSquaredResiduals = 0;
    for (int i = 0; i < data.length; i++) {
      final predicted = slope * i + intercept;
      sumSquaredResiduals += pow(data[i].value - predicted, 2);
    }
    final stdDev = sqrt(sumSquaredResiduals / data.length);
    
    // Identify points beyond 2 standard deviations
    for (int i = 0; i < data.length; i++) {
      final predicted = slope * i + intercept;
      final residual = data[i].value - predicted;
      
      if (residual.abs() > 2 * stdDev) {
        anomalies.add(Anomaly(
          timestamp: data[i].timestamp,
          value: data[i].value,
          expectedValue: predicted,
          deviation: residual,
          severity: residual.abs() > 3 * stdDev 
            ? AnomalySeverity.high 
            : AnomalySeverity.medium,
        ));
      }
    }
    
    return anomalies;
  }

  /// Detect seasonality in data
  Seasonality? _detectSeasonality(List<DataPoint> data) {
    if (data.length < 14) return null; // Need at least 2 weeks of data
    
    // Try different period lengths
    final periods = [7, 30, 90]; // Daily, monthly, quarterly
    Seasonality? bestSeasonality;
    double bestScore = 0;
    
    for (final period in periods) {
      if (data.length < period * 2) continue;
      
      // Calculate autocorrelation for this period
      double correlation = _calculateAutocorrelation(data, period);
      
      if (correlation > bestScore && correlation > 0.5) {
        bestScore = correlation;
        bestSeasonality = Seasonality(
          period: period,
          strength: correlation,
          type: _getSeasonalityType(period),
        );
      }
    }
    
    return bestSeasonality;
  }

  /// Calculate autocorrelation
  double _calculateAutocorrelation(List<DataPoint> data, int lag) {
    if (lag >= data.length) return 0;
    
    final n = data.length - lag;
    double sumXY = 0, sumX = 0, sumY = 0, sumX2 = 0, sumY2 = 0;
    
    for (int i = 0; i < n; i++) {
      final x = data[i].value;
      final y = data[i + lag].value;
      sumXY += x * y;
      sumX += x;
      sumY += y;
      sumX2 += x * x;
      sumY2 += y * y;
    }
    
    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    return denominator == 0 ? 0 : numerator / denominator;
  }

  /// Generate predictions
  Future<List<Prediction>> _generatePredictions(List<String> models) async {
    final predictions = <Prediction>[];
    
    for (final modelName in models) {
      final model = _predictiveModels[modelName] ?? await _loadPredictiveModel(modelName);
      
      if (model != null) {
        final prediction = await _runPrediction(model);
        predictions.add(prediction);
        _predictionsGenerated++;
      }
    }
    
    return predictions;
  }

  /// Run prediction model
  Future<Prediction> _runPrediction(PredictiveModel model) async {
    // Get input features
    final features = await _extractFeatures(model.featureNames);
    
    // Apply model (simplified - in production would use actual ML model)
    double predictedValue = model.intercept;
    for (int i = 0; i < features.length && i < model.coefficients.length; i++) {
      predictedValue += features[i] * model.coefficients[i];
    }
    
    // Calculate confidence based on historical accuracy
    final confidence = await _calculatePredictionConfidence(model);
    
    // Generate prediction intervals
    final intervals = _generatePredictionIntervals(predictedValue, confidence);
    
    return Prediction(
      id: 'pred_${DateTime.now().millisecondsSinceEpoch}',
      modelName: model.name,
      type: model.type,
      predictedValue: predictedValue,
      confidence: confidence,
      intervals: intervals,
      features: features,
      timestamp: DateTime.now(),
    );
  }

  /// Generate insights
  Future<List<Insight>> _generateInsights(
    List<KPI> kpis,
    List<TrendAnalysis> trends,
  ) async {
    final insights = <Insight>[];
    
    // KPI-based insights
    for (final kpi in kpis) {
      if (kpi.status == KPIStatus.critical) {
        insights.add(Insight(
          id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.alert,
          title: '${kpi.name} Below Target',
          description: '${kpi.name} is at ${kpi.value}${kpi.unit}, '
              'which is below the target of ${kpi.target}${kpi.unit}',
          severity: InsightSeverity.high,
          actionable: true,
          recommendations: await _generateRecommendations(kpi),
        ));
      } else if (kpi.status == KPIStatus.excellent && kpi.trend == TrendDirection.up) {
        insights.add(Insight(
          id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.positive,
          title: '${kpi.name} Performing Well',
          description: '${kpi.name} shows positive growth and exceeds target',
          severity: InsightSeverity.low,
          actionable: false,
        ));
      }
    }
    
    // Trend-based insights
    for (final trend in trends) {
      if (trend.anomalies?.isNotEmpty == true) {
        insights.add(Insight(
          id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.anomaly,
          title: 'Anomalies Detected in ${trend.metric}',
          description: '${trend.anomalies?.length ?? 0} unusual patterns detected',
          severity: InsightSeverity.medium,
          actionable: true,
          recommendations: ['Investigate anomalies', 'Review data quality'],
        ));
      }
      
      if (trend.seasonality != null && trend.seasonality!.strength > 0.7) {
        insights.add(Insight(
          id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.discovery,
          title: 'Seasonal Pattern in ${trend.metric}',
          description: 'Strong ${trend.seasonality!.type} pattern detected',
          severity: InsightSeverity.low,
          actionable: true,
          recommendations: ['Adjust staffing for seasonal variations'],
        ));
      }
    }
    
    // AI-powered insights
    if (_aiService != null) {
      final aiInsights = await _generateAIInsights(kpis, trends);
      insights.addAll(aiInsights);
    }
    
    // Sort by severity
    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    
    return insights;
  }

  /// Generate charts for executive dashboard
  Future<List<ChartData>> _generateExecutiveCharts() async {
    final charts = <ChartData>[];
    
    // Revenue trend chart
    charts.add(await _createLineChart(
      'revenue_trend',
      'Revenue Trend',
      await _getTimeSeriesData('revenue', 30),
      showForecast: true,
    ));
    
    // Patient volume chart
    charts.add(await _createBarChart(
      'patient_volume',
      'Patient Volume by Department',
      await _getDepartmentPatientVolume(),
    ));
    
    // Referral status pie chart
    charts.add(await _createPieChart(
      'referral_status',
      'Referral Status Distribution',
      await _getReferralStatusDistribution(),
    ));
    
    // Performance heatmap
    charts.add(await _createHeatmap(
      'performance_matrix',
      'Performance Matrix',
      await _getPerformanceMatrix(),
    ));
    
    return charts;
  }

  /// Create line chart
  Future<ChartData> _createLineChart(
    String id,
    String title,
    List<DataPoint> data, {
    bool showForecast = false,
  }) async {
    final chartData = ChartData(
      id: id,
      type: ChartType.line,
      title: title,
      data: data,
      config: {
        'showGrid': true,
        'showLegend': true,
        'animated': true,
      },
    );
    
    if (showForecast) {
      final trend = _performTrendAnalysis(data);
      chartData.forecast = trend.forecast;
    }
    
    return chartData;
  }

  /// Create bar chart
  Future<ChartData> _createBarChart(
    String id,
    String title,
    Map<String, double> data,
  ) async {
    return ChartData(
      id: id,
      type: ChartType.bar,
      title: title,
      data: data.entries.map((e) => DataPoint(
        value: e.value,
        label: e.key,
        timestamp: DateTime.now(),
      )).toList(),
      config: {
        'orientation': 'vertical',
        'showValues': true,
      },
    );
  }

  /// Create pie chart
  Future<ChartData> _createPieChart(
    String id,
    String title,
    Map<String, double> data,
  ) async {
    return ChartData(
      id: id,
      type: ChartType.pie,
      title: title,
      data: data.entries.map((e) => DataPoint(
        value: e.value,
        label: e.key,
        timestamp: DateTime.now(),
      )).toList(),
      config: {
        'showPercentages': true,
        'donut': true,
      },
    );
  }

  /// Create heatmap
  Future<ChartData> _createHeatmap(
    String id,
    String title,
    List<List<double>> matrix,
  ) async {
    return ChartData(
      id: id,
      type: ChartType.heatmap,
      title: title,
      matrixData: matrix,
      config: {
        'colorScheme': 'green-red',
        'showValues': true,
      },
    );
  }

  /// Real-time metric monitoring
  void _startRealTimeMonitoring() {
    // Monitor active users
    _realTimeMetrics['active_users'] = RealTimeMetric(
      name: 'Active Users',
      value: 0,
      unit: 'users',
      updateInterval: Duration(seconds: 10),
    );
    
    // Monitor system performance
    _realTimeMetrics['response_time'] = RealTimeMetric(
      name: 'Response Time',
      value: 0,
      unit: 'ms',
      updateInterval: Duration(seconds: 5),
    );
    
    // Monitor referral processing
    _realTimeMetrics['referrals_per_minute'] = RealTimeMetric(
      name: 'Referrals/Min',
      value: 0,
      unit: 'rpm',
      updateInterval: Duration(minutes: 1),
    );
  }

  /// Update real-time metrics
  void _updateRealTimeMetrics(AnalyticsEvent event) {
    // Update relevant metrics based on event
    if (event.eventType == 'user_action') {
      _incrementMetric('active_users');
    }
    
    if (event.eventType == 'referral_created') {
      _incrementMetric('referrals_per_minute');
    }
    
    // Broadcast update
    _metricUpdateController.add(MetricUpdate(
      metricName: event.eventType,
      value: 1,
      timestamp: DateTime.now(),
    ));
  }

  /// Cohort analysis
  Future<CohortAnalysis> performCohortAnalysis({
    required String cohortType,
    required DateTime startDate,
    required DateTime endDate,
    String? segmentBy,
  }) async {
    try {
      // Define cohorts
      final cohorts = await _defineCohorts(cohortType, startDate, endDate);
      
      // Calculate retention
      final retention = await _calculateCohortRetention(cohorts);
      
      // Calculate metrics
      final metrics = await _calculateCohortMetrics(cohorts);
      
      // Segment if requested
      Map<String, CohortData>? segments;
      if (segmentBy != null) {
        segments = await _segmentCohorts(cohorts, segmentBy);
      }
      
      return CohortAnalysis(
        id: 'cohort_${DateTime.now().millisecondsSinceEpoch}',
        type: cohortType,
        startDate: startDate,
        endDate: endDate,
        cohorts: cohorts,
        retention: retention,
        metrics: metrics,
        segments: segments,
      );
    } catch (e) {
      debugPrint('Error in cohort analysis: $e');
      throw AnalyticsException('Failed to perform cohort analysis');
    }
  }

  /// Funnel analysis
  Future<FunnelAnalysis> performFunnelAnalysis({
    required List<String> steps,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final funnelData = <FunnelStep>[];
      int previousCount = 0;
      
      for (int i = 0; i < steps.length; i++) {
        final stepName = steps[i];
        final count = await _getEventCount(stepName, startDate, endDate, filters);
        
        final conversionRate = i == 0 ? 100.0 : (count / previousCount * 100);
        final dropOffRate = i == 0 ? 0.0 : 100 - conversionRate;
        
        funnelData.add(FunnelStep(
          name: stepName,
          count: count,
          conversionRate: conversionRate,
          dropOffRate: dropOffRate,
          averageTime: await _getAverageTimeBetweenSteps(
            i > 0 ? steps[i - 1] : null,
            stepName,
          ),
        ));
        
        previousCount = count;
      }
      
      return FunnelAnalysis(
        id: 'funnel_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Conversion Funnel',
        steps: funnelData,
        overallConversion: funnelData.isNotEmpty 
          ? (funnelData.last.count / funnelData.first.count * 100)
          : 0,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error in funnel analysis: $e');
      throw AnalyticsException('Failed to perform funnel analysis');
    }
  }

  /// A/B test analysis
  Future<ABTestResult> analyzeABTest({
    required String testName,
    required String variantA,
    required String variantB,
    required String metricName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get variant data
      final dataA = await _getVariantData(variantA, metricName, startDate, endDate);
      final dataB = await _getVariantData(variantB, metricName, startDate, endDate);
      
      // Calculate statistics
      final statsA = _calculateStatistics(dataA);
      final statsB = _calculateStatistics(dataB);
      
      // Perform statistical test
      final pValue = _performTTest(dataA, dataB);
      final significant = pValue < 0.05;
      
      // Calculate lift
      final lift = ((statsB.mean - statsA.mean) / statsA.mean) * 100;
      
      // Determine winner
      String? winner;
      if (significant) {
        winner = lift > 0 ? variantB : variantA;
      }
      
      return ABTestResult(
        id: 'abtest_${DateTime.now().millisecondsSinceEpoch}',
        testName: testName,
        variantA: VariantData(
          name: variantA,
          sampleSize: dataA.length,
          mean: statsA.mean,
          stdDev: statsA.stdDev,
          conversionRate: statsA.conversionRate,
        ),
        variantB: VariantData(
          name: variantB,
          sampleSize: dataB.length,
          mean: statsB.mean,
          stdDev: statsB.stdDev,
          conversionRate: statsB.conversionRate,
        ),
        pValue: pValue,
        significant: significant,
        lift: lift,
        winner: winner,
        confidence: (1 - pValue) * 100,
      );
    } catch (e) {
      debugPrint('Error in A/B test analysis: $e');
      throw AnalyticsException('Failed to analyze A/B test');
    }
  }

  /// Custom metric builder
  Future<CustomMetric> buildCustomMetric({
    required String name,
    required String formula,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      // Parse formula
      final parsedFormula = _parseFormula(formula);
      
      // Get required data
      final data = await _getDataForFormula(parsedFormula, parameters);
      
      // Calculate metric
      final value = _evaluateFormula(parsedFormula, data);
      
      // Store custom metric
      final metric = CustomMetric(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        formula: formula,
        value: value,
        parameters: parameters,
        lastCalculated: DateTime.now(),
      );
      
      return metric;
    } catch (e) {
      debugPrint('Error building custom metric: $e');
      throw AnalyticsException('Failed to build custom metric');
    }
  }

  // Helper methods

  Future<int> _getPatientCount() async {
    final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM patients');
    return result.first['count'] as int;
  }

  Future<double> _getReferralCompletionRate() async {
    final total = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM referrals'
    );
    final completed = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM referrals WHERE status = ?',
      ['Completed']
    );
    
    final totalCount = total.first['count'] as int;
    final completedCount = completed.first['count'] as int;
    
    return totalCount > 0 ? (completedCount / totalCount * 100) : 0;
  }

  Future<double> _getAverageWaitTime() async {
    // Simulated calculation
    return 12.5;
  }

  Future<double> _getSystemUptime() async {
    // Simulated calculation
    return 99.95;
  }

  Future<List<DataPoint>> _getTimeSeriesData(String metric, int days) async {
    final data = <DataPoint>[];
    final now = DateTime.now();
    
    // Simulated data generation
    for (int i = days; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final value = _generateSimulatedValue(metric, i);
      
      data.add(DataPoint(
        value: value,
        timestamp: date,
        label: metric,
      ));
    }
    
    return data;
  }

  double _generateSimulatedValue(String metric, int daysAgo) {
    final random = Random();
    
    switch (metric) {
      case 'revenue':
        return 50000 + random.nextDouble() * 20000 - daysAgo * 100;
      case 'patients':
        return 100 + random.nextDouble() * 50 - daysAgo * 0.5;
      case 'referrals':
        return 20 + random.nextDouble() * 10;
      default:
        return random.nextDouble() * 100;
    }
  }

  TrendDirection _calculateTrend(String metric, int days) {
    // Simplified trend calculation
    final random = Random();
    final value = random.nextDouble();
    
    if (value < 0.33) return TrendDirection.down;
    if (value < 0.67) return TrendDirection.stable;
    return TrendDirection.up;
  }

  KPIStatus _getKPIStatus(double value, double target, {bool inverse = false}) {
    final ratio = value / target;
    
    if (inverse) {
      if (ratio <= 0.8) return KPIStatus.excellent;
      if (ratio <= 1.0) return KPIStatus.good;
      if (ratio <= 1.2) return KPIStatus.warning;
      return KPIStatus.critical;
    } else {
      if (ratio >= 1.2) return KPIStatus.excellent;
      if (ratio >= 1.0) return KPIStatus.good;
      if (ratio >= 0.8) return KPIStatus.warning;
      return KPIStatus.critical;
    }
  }

  SeasonalityType _getSeasonalityType(int period) {
    if (period == 7) return SeasonalityType.weekly;
    if (period == 30) return SeasonalityType.monthly;
    if (period == 90) return SeasonalityType.quarterly;
    return SeasonalityType.yearly;
  }

  double _calculateConfidence(double rSquared, int dataPoints) {
    // Confidence based on R-squared and sample size
    final sizeBonus = min(dataPoints / 100, 1.0) * 0.2;
    return min(rSquared + sizeBonus, 1.0);
  }

  void _incrementMetric(String metricName) {
    if (_realTimeMetrics.containsKey(metricName)) {
      _realTimeMetrics[metricName]!.value++;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _refreshDashboards();
    });
  }

  Future<void> _refreshDashboards() async {
    // Refresh all active dashboards
    for (final dashboard in _dashboards.values) {
      if (dashboard.autoRefresh) {
        // Refresh dashboard data
        notifyListeners();
      }
    }
  }

  Future<void> _loadHistoricalData() async {
    // Load historical analytics data from database
    final events = await _database!.query(
      'analytics_events',
      orderBy: 'timestamp DESC',
      limit: 10000,
    );
    
    for (final event in events) {
      _eventLog.add(AnalyticsEvent.fromMap(event));
    }
  }

  Future<void> _initializeKPIs() async {
    // Initialize standard KPIs
    _kpis['patient_satisfaction'] = KPI(
      id: 'patient_satisfaction',
      name: 'Patient Satisfaction',
      value: 4.5,
      target: 4.0,
      unit: '/5',
      trend: TrendDirection.up,
      status: KPIStatus.excellent,
    );
    
    // Load more KPIs...
  }

  Future<void> _initializePredictiveModels() async {
    // Initialize predictive models
    _predictiveModels['growth'] = PredictiveModel(
      name: 'growth',
      type: 'regression',
      featureNames: ['current_patients', 'referral_rate', 'satisfaction'],
      coefficients: [0.3, 0.5, 0.2],
      intercept: 10.0,
      accuracy: 0.85,
    );
    
    // Load more models...
  }

  Future<void> _processEvent(AnalyticsEvent event) async {
    // Process event for real-time analytics
    // Update relevant metrics and dashboards
  }

  // Missing method implementations
  Future<DashboardData> _getDefaultDashboard() async {
    final kpis = await _calculateExecutiveKPIs();
    final trends = await _analyzeTrends(['general']);
    
    return DashboardData(
      id: 'default_${DateTime.now().millisecondsSinceEpoch}',
      type: 'default',
      kpis: kpis,
      charts: [],
      trends: trends,
      predictions: [],
      insights: [],
      lastUpdated: DateTime.now(),
    );
  }

  Future<List<KPI>> _calculateClinicalKPIs() async {
    return [
      KPI(
        id: 'readmission_rate',
        name: 'Readmission Rate',
        value: 12.5,
        target: 10.0,
        unit: '%',
        trend: TrendDirection.down,
        status: KPIStatus.warning,
      ),
    ];
  }

  Future<Map<String, dynamic>> _analyzePatientOutcomes() async {
    return {'success_rate': 0.85, 'satisfaction': 4.2};
  }

  Future<Map<String, dynamic>> _assessQualityMetrics() async {
    return {'safety_score': 0.92, 'compliance': 0.88};
  }

  Future<List<ChartData>> _generateClinicalCharts() async {
    return [
      ChartData(
        id: 'outcomes',
        type: ChartType.line,
        title: 'Patient Outcomes',
        data: [],
      ),
    ];
  }

  Future<List<Insight>> _generateClinicalInsights(
    Map<String, dynamic> outcomes, 
    Map<String, dynamic> quality
  ) async {
    return [];
  }

  Future<Map<String, dynamic>> _calculateEfficiencyMetrics() async {
    return {'throughput': 45.2, 'utilization': 0.78};
  }

  Future<Map<String, dynamic>> _calculateResourceUtilization() async {
    return {'bed_utilization': 0.82, 'staff_utilization': 0.75};
  }

  Future<List<String>> _identifyBottlenecks() async {
    return ['Registration process', 'Lab results'];
  }

  Future<List<KPI>> _calculateOperationalKPIs() async {
    return [
      KPI(
        id: 'wait_time',
        name: 'Average Wait Time',
        value: 25.0,
        target: 20.0,
        unit: ' min',
        trend: TrendDirection.up,
        status: KPIStatus.warning,
      ),
    ];
  }

  Future<List<ChartData>> _generateOperationalCharts() async {
    return [
      ChartData(
        id: 'efficiency',
        type: ChartType.bar,
        title: 'Operational Efficiency',
        data: [],
      ),
    ];
  }

  Future<List<Insight>> _generateOperationalInsights(
    Map<String, dynamic> efficiency, 
    List<String> bottlenecks
  ) async {
    return [];
  }

  Future<Map<String, dynamic>> _calculateRevenueMetrics() async {
    return {'monthly_revenue': 125000.0, 'growth_rate': 0.08};
  }

  Future<Map<String, dynamic>> _analyzeCosts() async {
    return {'operational_costs': 95000.0, 'cost_per_patient': 420.0};
  }

  Future<Map<String, dynamic>> _assessProfitability() async {
    return {'profit_margin': 0.24, 'roi': 0.18};
  }

  Future<List<KPI>> _calculateFinancialKPIs() async {
    return [
      KPI(
        id: 'revenue',
        name: 'Monthly Revenue',
        value: 125000.0,
        target: 120000.0,
        unit: ' USD',
        trend: TrendDirection.up,
        status: KPIStatus.excellent,
      ),
    ];
  }

  Future<List<ChartData>> _generateFinancialCharts() async {
    return [
      ChartData(
        id: 'revenue_trend',
        type: ChartType.line,
        title: 'Revenue Trend',
        data: [],
      ),
    ];
  }

  Future<List<Insight>> _generateFinancialInsights(
    Map<String, dynamic> revenue,
    Map<String, dynamic> profitability
  ) async {
    return [];
  }

  Future<Map<String, dynamic>> _measurePatientSatisfaction() async {
    return {'avg_rating': 4.2, 'response_rate': 0.68};
  }

  Future<Map<String, dynamic>> _assessCompliance() async {
    return {'compliance_score': 0.92, 'violations': 3};
  }

  Future<Map<String, dynamic>> _evaluateSafety() async {
    return {'safety_incidents': 2, 'safety_score': 0.88};
  }

  Future<List<KPI>> _calculateQualityKPIs() async {
    return [
      KPI(
        id: 'satisfaction',
        name: 'Patient Satisfaction',
        value: 4.2,
        target: 4.0,
        unit: '/5',
        trend: TrendDirection.up,
        status: KPIStatus.excellent,
      ),
    ];
  }

  Future<List<ChartData>> _generateQualityCharts() async {
    return [
      ChartData(
        id: 'satisfaction_trend',
        type: ChartType.gauge,
        title: 'Patient Satisfaction',
        data: [],
      ),
    ];
  }

  Future<List<Insight>> _generateQualityInsights(
    Map<String, dynamic> satisfaction,
    Map<String, dynamic> safety
  ) async {
    return [];
  }

  Future<PredictiveModel?> _loadPredictiveModel(String modelName) async {
    // Simulate loading a model
    return PredictiveModel(
      name: modelName,
      type: 'regression',
      featureNames: ['feature1', 'feature2'],
      coefficients: [0.5, 0.3],
      intercept: 10.0,
      accuracy: 0.8,
    );
  }

  Future<List<double>> _extractFeatures(List<String> featureNames) async {
    // Simulate feature extraction
    return List.generate(featureNames.length, (i) => Random().nextDouble() * 100);
  }

  Future<double> _calculatePredictionConfidence(PredictiveModel model) async {
    return model.accuracy;
  }

  Map<String, double> _generatePredictionIntervals(double value, double confidence) {
    final margin = value * (1 - confidence) * 0.1;
    return {
      'lower': value - margin,
      'upper': value + margin,
    };
  }

  Future<List<String>> _generateRecommendations(KPI kpi) async {
    return ['Review ${kpi.name} process', 'Implement improvement plan'];
  }

  Future<List<Insight>> _generateAIInsights(
    List<KPI> kpis,
    List<TrendAnalysis> trends
  ) async {
    return [];
  }

  Future<Map<String, int>> _getDepartmentPatientVolume() async {
    return {
      'Cardiology': 145,
      'Emergency': 89,
      'Surgery': 67,
    };
  }

  Future<Map<String, int>> _getReferralStatusDistribution() async {
    return {
      'Pending': 45,
      'Approved': 123,
      'Completed': 89,
    };
  }

  Future<List<List<double>>> _getPerformanceMatrix() async {
    return [
      [0.8, 0.7, 0.9],
      [0.6, 0.8, 0.7],
      [0.9, 0.6, 0.8],
    ];
  }

  Future<Map<String, CohortData>> _defineCohorts(DateTime startDate, DateTime endDate) async {
    return {
      'new_patients': CohortData(
        name: 'New Patients',
        size: 100,
        metrics: {'retention': 0.75},
      ),
    };
  }

  Map<String, double> _calculateCohortRetention(Map<String, CohortData> cohorts) {
    return cohorts.map((key, value) => MapEntry(key, value.metrics['retention'] ?? 0.0));
  }

  Map<String, double> _calculateCohortMetrics(Map<String, CohortData> cohorts) {
    return cohorts.map((key, value) => MapEntry(key, value.size.toDouble()));
  }

  Map<String, CohortData> _segmentCohorts(Map<String, CohortData> cohorts) {
    return cohorts;
  }

  Future<int> _getEventCount(String eventType) async {
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM analytics_events WHERE event_type = ?',
      [eventType],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<Duration> _getAverageTimeBetweenSteps(String step1, String step2) async {
    // Simulate time calculation
    return Duration(minutes: 15);
  }

  Future<VariantData> _getVariantData(String variant) async {
    return VariantData(
      name: variant,
      sampleSize: 100,
      mean: 25.5,
      stdDev: 5.2,
      conversionRate: 0.15,
    );
  }

  Map<String, double> _calculateStatistics(VariantData data) {
    return {
      'mean': data.mean,
      'stdDev': data.stdDev,
      'conversionRate': data.conversionRate,
    };
  }

  double _performTTest(VariantData variantA, VariantData variantB) {
    // Simplified t-test calculation
    final pooledStdDev = sqrt(
      (variantA.stdDev * variantA.stdDev + variantB.stdDev * variantB.stdDev) / 2,
    );
    final tStat = (variantA.mean - variantB.mean) / 
        (pooledStdDev * sqrt(2 / min(variantA.sampleSize, variantB.sampleSize)));
    
    // Return p-value approximation
    return max(0.001, 1 / (1 + tStat.abs()));
  }

  List<String> _parseFormula(String formula) {
    return formula.split('+').map((e) => e.trim()).toList();
  }

  Future<Map<String, double>> _getDataForFormula(List<String> components) async {
    final data = <String, double>{};
    for (final component in components) {
      data[component] = Random().nextDouble() * 100;
    }
    return data;
  }

  double _evaluateFormula(String formula, Map<String, double> data) {
    // Simplified formula evaluation
    double result = 0;
    final components = _parseFormula(formula);
    for (final component in components) {
      result += data[component] ?? 0;
    }
    return result;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _metricUpdateController.close();
    super.dispose();
  }
}

// Data Models

class DashboardData {
  final String id;
  final String type;
  final List<KPI> kpis;
  final List<ChartData> charts;
  final List<TrendAnalysis> trends;
  final List<Prediction> predictions;
  final List<Insight> insights;
  final DateTime lastUpdated;

  DashboardData({
    required this.id,
    required this.type,
    required this.kpis,
    required this.charts,
    required this.trends,
    required this.predictions,
    required this.insights,
    required this.lastUpdated,
  });
}

class KPI {
  final String id;
  final String name;
  final double value;
  final double target;
  final String unit;
  final TrendDirection trend;
  final KPIStatus status;

  KPI({
    required this.id,
    required this.name,
    required this.value,
    required this.target,
    required this.unit,
    required this.trend,
    required this.status,
  });
}

enum KPIStatus {
  excellent,
  good,
  warning,
  critical,
}

enum TrendDirection {
  up,
  down,
  stable,
}

class TrendAnalysis {
  final String metric;
  final TrendDirection direction;
  final double strength;
  final double? slope;
  final List<DataPoint> forecast;
  final List<Anomaly>? anomalies;
  final Seasonality? seasonality;
  final double? confidence;

  TrendAnalysis({
    required this.metric,
    required this.direction,
    required this.strength,
    this.slope,
    required this.forecast,
    this.anomalies,
    this.seasonality,
    this.confidence,
  });
}

class DataPoint {
  final double value;
  final DateTime timestamp;
  final String? label;

  DataPoint({
    required this.value,
    required this.timestamp,
    this.label,
  });
}

class Anomaly {
  final DateTime timestamp;
  final double value;
  final double expectedValue;
  final double deviation;
  final AnomalySeverity severity;

  Anomaly({
    required this.timestamp,
    required this.value,
    required this.expectedValue,
    required this.deviation,
    required this.severity,
  });
}

class Seasonality {
  final int period;
  final double strength;
  final SeasonalityType type;

  Seasonality({
    required this.period,
    required this.strength,
    required this.type,
  });
}

enum SeasonalityType {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

class Prediction {
  final String id;
  final String modelName;
  final String type;
  final double predictedValue;
  final double confidence;
  final Map<String, double>? intervals;
  final List<double>? features;
  final DateTime timestamp;

  Prediction({
    required this.id,
    required this.modelName,
    required this.type,
    required this.predictedValue,
    required this.confidence,
    this.intervals,
    this.features,
    required this.timestamp,
  });
}

class PredictiveModel {
  final String name;
  final String type;
  final List<String> featureNames;
  final List<double> coefficients;
  final double intercept;
  final double accuracy;

  PredictiveModel({
    required this.name,
    required this.type,
    required this.featureNames,
    required this.coefficients,
    required this.intercept,
    required this.accuracy,
  });
}

class Insight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final InsightSeverity severity;
  final bool actionable;
  final List<String>? recommendations;

  Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.actionable,
    this.recommendations,
  });
}

enum InsightType {
  alert,
  anomaly,
  trend,
  discovery,
  positive,
}

enum InsightSeverity {
  low,
  medium,
  high,
  critical,
}

class ChartData {
  final String id;
  final ChartType type;
  final String title;
  final List<DataPoint>? data;
  final List<List<double>>? matrixData;
  final Map<String, dynamic>? config;
  List<DataPoint>? forecast;

  ChartData({
    required this.id,
    required this.type,
    required this.title,
    this.data,
    this.matrixData,
    this.config,
    this.forecast,
  });
}

enum ChartType {
  line,
  bar,
  pie,
  scatter,
  heatmap,
  gauge,
  funnel,
}

class AnalyticsEvent {
  final String id;
  final String eventType;
  final String eventName;
  final String? userId;
  final Map<String, dynamic>? properties;
  final DateTime timestamp;
  final String? sessionId;

  AnalyticsEvent({
    required this.id,
    required this.eventType,
    required this.eventName,
    this.userId,
    this.properties,
    required this.timestamp,
    this.sessionId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'event_type': eventType,
    'event_name': eventName,
    'user_id': userId,
    'properties': properties != null ? jsonEncode(properties) : null,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'session_id': sessionId,
  };

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) => AnalyticsEvent(
    id: map['id'],
    eventType: map['event_type'],
    eventName: map['event_name'],
    userId: map['user_id'],
    properties: map['properties'] != null ? jsonDecode(map['properties']) : null,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    sessionId: map['session_id'],
  );
}

class RealTimeMetric {
  final String name;
  double value;
  final String unit;
  final Duration updateInterval;

  RealTimeMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.updateInterval,
  });
}

class MetricUpdate {
  final String metricName;
  final double value;
  final DateTime timestamp;

  MetricUpdate({
    required this.metricName,
    required this.value,
    required this.timestamp,
  });
}

class Dashboard {
  final String id;
  final String name;
  final String type;
  final bool autoRefresh;
  final List<String> widgetIds;

  Dashboard({
    required this.id,
    required this.name,
    required this.type,
    required this.autoRefresh,
    required this.widgetIds,
  });
}

class Widget {
  final String id;
  final String type;
  final Map<String, dynamic> config;

  Widget({
    required this.id,
    required this.type,
    required this.config,
  });
}

class CohortAnalysis {
  final String id;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final List<CohortData> cohorts;
  final Map<String, double> retention;
  final Map<String, double> metrics;
  final Map<String, CohortData>? segments;

  CohortAnalysis({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.cohorts,
    required this.retention,
    required this.metrics,
    this.segments,
  });
}

class CohortData {
  final String name;
  final int size;
  final Map<String, double> metrics;

  CohortData({
    required this.name,
    required this.size,
    required this.metrics,
  });
}

class FunnelAnalysis {
  final String id;
  final String name;
  final List<FunnelStep> steps;
  final double overallConversion;
  final DateTime startDate;
  final DateTime endDate;

  FunnelAnalysis({
    required this.id,
    required this.name,
    required this.steps,
    required this.overallConversion,
    required this.startDate,
    required this.endDate,
  });
}

class FunnelStep {
  final String name;
  final int count;
  final double conversionRate;
  final double dropOffRate;
  final Duration? averageTime;

  FunnelStep({
    required this.name,
    required this.count,
    required this.conversionRate,
    required this.dropOffRate,
    this.averageTime,
  });
}

class ABTestResult {
  final String id;
  final String testName;
  final VariantData variantA;
  final VariantData variantB;
  final double pValue;
  final bool significant;
  final double lift;
  final String? winner;
  final double confidence;

  ABTestResult({
    required this.id,
    required this.testName,
    required this.variantA,
    required this.variantB,
    required this.pValue,
    required this.significant,
    required this.lift,
    this.winner,
    required this.confidence,
  });
}

class VariantData {
  final String name;
  final int sampleSize;
  final double mean;
  final double stdDev;
  final double conversionRate;

  VariantData({
    required this.name,
    required this.sampleSize,
    required this.mean,
    required this.stdDev,
    required this.conversionRate,
  });
}

class CustomMetric {
  final String id;
  final String name;
  final String formula;
  final double value;
  final Map<String, dynamic> parameters;
  final DateTime lastCalculated;

  CustomMetric({
    required this.id,
    required this.name,
    required this.formula,
    required this.value,
    required this.parameters,
    required this.lastCalculated,
  });
}

class AnalyticsException implements Exception {
  final String message;
  AnalyticsException(this.message);
  
  @override
  String toString() => 'AnalyticsException: $message';
}

// Additional helper classes would go here...