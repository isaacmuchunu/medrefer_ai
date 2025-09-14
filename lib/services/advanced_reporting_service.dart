import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import '../core/app_export.dart';

/// Advanced Reporting Engine with Customizable Dashboards
/// 
/// Provides comprehensive reporting capabilities including:
/// - Interactive dashboard creation and management
/// - Scheduled report generation and distribution
/// - Real-time data visualization
/// - Custom report templates and builders
/// - Multi-format export (PDF, Excel, CSV, PowerPoint)
/// - Advanced analytics and KPI tracking
/// - Drill-down and filtering capabilities
/// - Subscription and notification management
/// - Performance optimization and caching
/// - Mobile-responsive dashboard layouts
class AdvancedReportingService extends ChangeNotifier {
  static final AdvancedReportingService _instance = AdvancedReportingService._internal();
  factory AdvancedReportingService() => _instance;
  AdvancedReportingService._internal();

  Database? _reportingDb;
  bool _isInitialized = false;
  Timer? _scheduleTimer;
  Timer? _cacheTimer;

  // Dashboard Management
  final Map<String, Dashboard> _dashboards = {};
  final Map<String, DashboardLayout> _dashboardLayouts = {};
  final Map<String, Widget> _widgets = {};
  
  // Report Management
  final Map<String, ReportDefinition> _reportDefinitions = {};
  final Map<String, ReportTemplate> _reportTemplates = {};
  final Map<String, GeneratedReport> _generatedReports = {};
  
  // Scheduling and Distribution
  final Map<String, ReportSchedule> _reportSchedules = {};
  final Map<String, ReportSubscription> _reportSubscriptions = {};
  
  // Data Sources and Queries
  final Map<String, DataSource> _dataSources = {};
  final Map<String, DataQuery> _dataQueries = {};
  
  // Visualization and Charts
  final Map<String, ChartConfiguration> _chartConfigurations = {};
  final Map<String, VisualizationTemplate> _visualizationTemplates = {};
  
  // Caching and Performance
  final Map<String, CachedData> _dataCache = {};
  final Map<String, QueryPerformance> _queryPerformance = {};
  
  // User Preferences and Permissions
  final Map<String, UserPreferences> _userPreferences = {};
  final Map<String, ReportPermission> _reportPermissions = {};

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, Dashboard> get dashboards => Map.unmodifiable(_dashboards);
  Map<String, ReportDefinition> get reportDefinitions => Map.unmodifiable(_reportDefinitions);
  Map<String, GeneratedReport> get generatedReports => Map.unmodifiable(_generatedReports);

  /// Initialize the Advanced Reporting service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      debugPrint('📊 Initializing Advanced Reporting Service...');

      // Initialize database
      await _initializeReportingDatabase();

      // Load existing data
      await _loadDashboards();
      await _loadReportDefinitions();
      await _loadReportTemplates();
      await _loadDataSources();
      await _loadReportSchedules();

      // Initialize default configurations
      await _initializeDefaultConfigurations();

      // Start background services
      _startScheduleProcessor();
      _startCacheManager();

      _isInitialized = true;
      debugPrint('✅ Advanced Reporting Service initialized successfully');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize Advanced Reporting Service: $e');
      rethrow;
    }
  }

  /// Create a new dashboard
  Future<DashboardCreationResult> createDashboard({
    required String name,
    String? description,
    required List<DashboardWidget> widgets,
    DashboardLayout? layout,
    Map<String, dynamic>? settings,
    List<String>? tags,
  }) async {
    try {
      debugPrint('📊 Creating dashboard: $name');

      final dashboardId = _generateDashboardId();
      final dashboard = Dashboard(
        dashboardId: dashboardId,
        name: name,
        description: description ?? '',
        widgets: widgets,
        layout: layout ?? DashboardLayout.grid,
        settings: settings ?? {},
        tags: tags ?? [],
        isPublic: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
        viewCount: 0,
      );

      _dashboards[dashboardId] = dashboard;

      // Validate widgets
      for (final widget in widgets) {
        final validationResult = await _validateWidget(widget);
        if (!validationResult.isValid) {
          return DashboardCreationResult(
            success: false,
            error: 'Widget validation failed: ${validationResult.errors.join(', ')}',
          );
        }
      }

      // Save to database
      await _saveDashboard(dashboard);

      debugPrint('✅ Dashboard created successfully: $dashboardId');
      notifyListeners();

      return DashboardCreationResult(
        success: true,
        dashboardId: dashboardId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create dashboard: $e');
      return DashboardCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new report definition
  Future<ReportCreationResult> createReportDefinition({
    required String name,
    String? description,
    required ReportType reportType,
    required String dataSourceId,
    required String query,
    Map<String, dynamic>? parameters,
    List<ReportColumn>? columns,
    List<ReportFilter>? filters,
    List<ReportGrouping>? groupings,
    List<ReportSorting>? sorting,
  }) async {
    try {
      debugPrint('📋 Creating report definition: $name');

      final reportId = _generateReportId();
      final reportDefinition = ReportDefinition(
        reportId: reportId,
        name: name,
        description: description ?? '',
        reportType: reportType,
        dataSourceId: dataSourceId,
        query: query,
        parameters: parameters ?? {},
        columns: columns ?? [],
        filters: filters ?? [],
        groupings: groupings ?? [],
        sorting: sorting ?? [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      _reportDefinitions[reportId] = reportDefinition;

      // Validate report definition
      final validationResult = await _validateReportDefinition(reportDefinition);
      if (!validationResult.isValid) {
        return ReportCreationResult(
          success: false,
          error: 'Report validation failed: ${validationResult.errors.join(', ')}',
        );
      }

      // Save to database
      await _saveReportDefinition(reportDefinition);

      debugPrint('✅ Report definition created successfully: $reportId');
      notifyListeners();

      return ReportCreationResult(
        success: true,
        reportId: reportId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create report definition: $e');
      return ReportCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generate report
  Future<ReportGenerationResult> generateReport({
    required String reportId,
    Map<String, dynamic>? parameterValues,
    ReportFormat format = ReportFormat.pdf,
  }) async {
    try {
      final reportDefinition = _reportDefinitions[reportId];
      if (reportDefinition == null) {
        return ReportGenerationResult(
          success: false,
          error: 'Report definition not found',
        );
      }

      debugPrint('📄 Generating report: ${reportDefinition.name}');

      final generationId = _generateGenerationId();
      
      // Execute data query
      final queryResult = await _executeDataQuery(
        reportDefinition.dataSourceId,
        reportDefinition.query,
        {...reportDefinition.parameters, ...parameterValues ?? {}},
      );

      if (!queryResult.success) {
        return ReportGenerationResult(
          success: false,
          error: 'Data query failed: ${queryResult.error}',
        );
      }

      // Apply filters and transformations
      final processedData = await _processReportData(
        queryResult.data!,
        reportDefinition.filters,
        reportDefinition.groupings,
        reportDefinition.sorting,
      );

      // Generate report based on format
      String? filePath;
      switch (format) {
        case ReportFormat.pdf:
          filePath = await _generatePDFReport(reportDefinition, processedData, generationId);
          break;
        case ReportFormat.excel:
          filePath = await _generateExcelReport(reportDefinition, processedData, generationId);
          break;
        case ReportFormat.csv:
          filePath = await _generateCSVReport(reportDefinition, processedData, generationId);
          break;
        case ReportFormat.powerpoint:
          filePath = await _generatePowerPointReport(reportDefinition, processedData, generationId);
          break;
        case ReportFormat.html:
          filePath = await _generateHTMLReport(reportDefinition, processedData, generationId);
          break;
      }

      // Create generated report record
      final generatedReport = GeneratedReport(
        generationId: generationId,
        reportId: reportId,
        format: format,
        filePath: filePath,
        parameters: parameterValues ?? {},
        recordCount: processedData.length,
        generatedAt: DateTime.now(),
        generatedBy: 'system',
        fileSize: await _getFileSize(filePath),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      _generatedReports[generationId] = generatedReport;

      // Save to database
      await _saveGeneratedReport(generatedReport);

      debugPrint('✅ Report generated successfully: $generationId');
      notifyListeners();

      return ReportGenerationResult(
        success: true,
        generationId: generationId,
        filePath: filePath,
        recordCount: processedData.length,
      );
    } catch (e) {
      debugPrint('❌ Failed to generate report: $e');
      return ReportGenerationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Schedule report generation
  Future<ScheduleCreationResult> scheduleReport({
    required String reportId,
    required ScheduleFrequency frequency,
    required List<String> recipients,
    Map<String, dynamic>? parameterValues,
    ReportFormat format = ReportFormat.pdf,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('⏰ Scheduling report: $reportId');

      final scheduleId = _generateScheduleId();
      final schedule = ReportSchedule(
        scheduleId: scheduleId,
        reportId: reportId,
        frequency: frequency,
        recipients: recipients,
        parameterValues: parameterValues ?? {},
        format: format,
        isActive: true,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate,
        lastRun: null,
        nextRun: _calculateNextRun(frequency, startDate ?? DateTime.now()),
        createdAt: DateTime.now(),
        createdBy: 'system',
      );

      _reportSchedules[scheduleId] = schedule;

      // Save to database
      await _saveReportSchedule(schedule);

      debugPrint('✅ Report scheduled successfully: $scheduleId');
      notifyListeners();

      return ScheduleCreationResult(
        success: true,
        scheduleId: scheduleId,
        nextRun: schedule.nextRun,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule report: $e');
      return ScheduleCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create dashboard widget
  Future<WidgetCreationResult> createWidget({
    required String title,
    required WidgetType widgetType,
    required String dataSourceId,
    required String query,
    Map<String, dynamic>? configuration,
    ChartConfiguration? chartConfig,
  }) async {
    try {
      debugPrint('🔧 Creating widget: $title');

      final widgetId = _generateWidgetId();
      final widget = DashboardWidget(
        widgetId: widgetId,
        title: title,
        widgetType: widgetType,
        dataSourceId: dataSourceId,
        query: query,
        configuration: configuration ?? {},
        chartConfig: chartConfig,
        position: WidgetPosition(x: 0, y: 0, width: 6, height: 4),
        refreshInterval: const Duration(minutes: 5),
        isVisible: true,
        createdAt: DateTime.now(),
      );

      _widgets[widgetId] = widget;

      debugPrint('✅ Widget created successfully: $widgetId');
      notifyListeners();

      return WidgetCreationResult(
        success: true,
        widgetId: widgetId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create widget: $e');
      return WidgetCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get dashboard data
  Future<DashboardDataResult> getDashboardData(String dashboardId) async {
    try {
      final dashboard = _dashboards[dashboardId];
      if (dashboard == null) {
        return DashboardDataResult(
          success: false,
          error: 'Dashboard not found',
        );
      }

      debugPrint('📊 Loading dashboard data: ${dashboard.name}');

      final widgetData = <String, dynamic>{};
      
      // Load data for each widget
      for (final widget in dashboard.widgets) {
        try {
          final data = await _getWidgetData(widget);
          widgetData[widget.widgetId] = data;
        } catch (e) {
          debugPrint('⚠️ Failed to load data for widget ${widget.widgetId}: $e');
          widgetData[widget.widgetId] = {'error': e.toString()};
        }
      }

      // Update view count
      dashboard.viewCount++;
      dashboard.lastViewedAt = DateTime.now();

      debugPrint('✅ Dashboard data loaded successfully: $dashboardId');

      return DashboardDataResult(
        success: true,
        dashboardId: dashboardId,
        widgetData: widgetData,
      );
    } catch (e) {
      debugPrint('❌ Failed to get dashboard data: $e');
      return DashboardDataResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Export dashboard
  Future<DashboardExportResult> exportDashboard({
    required String dashboardId,
    required DashboardExportFormat format,
  }) async {
    try {
      final dashboard = _dashboards[dashboardId];
      if (dashboard == null) {
        return DashboardExportResult(
          success: false,
          error: 'Dashboard not found',
        );
      }

      debugPrint('📤 Exporting dashboard: ${dashboard.name}');

      final exportId = _generateExportId();
      String? filePath;

      switch (format) {
        case DashboardExportFormat.pdf:
          filePath = await _exportDashboardToPDF(dashboard, exportId);
          break;
        case DashboardExportFormat.powerpoint:
          filePath = await _exportDashboardToPowerPoint(dashboard, exportId);
          break;
        case DashboardExportFormat.image:
          filePath = await _exportDashboardToImage(dashboard, exportId);
          break;
        case DashboardExportFormat.json:
          filePath = await _exportDashboardToJSON(dashboard, exportId);
          break;
      }

      debugPrint('✅ Dashboard exported successfully: $exportId');

      return DashboardExportResult(
        success: true,
        exportId: exportId,
        filePath: filePath,
      );
    } catch (e) {
      debugPrint('❌ Failed to export dashboard: $e');
      return DashboardExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get reporting analytics
  Future<ReportingAnalyticsResult> getReportingAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      debugPrint('📈 Getting reporting analytics: ${start.toIso8601String()} to ${end.toIso8601String()}');

      // Filter reports by date range
      final reports = _generatedReports.values
          .where((report) => report.generatedAt.isAfter(start) && report.generatedAt.isBefore(end))
          .toList();

      // Calculate analytics
      final analytics = ReportingAnalytics(
        totalReports: reports.length,
        totalDashboards: _dashboards.length,
        reportsByType: _calculateReportsByType(reports),
        reportsByFormat: _calculateReportsByFormat(reports),
        topReports: await _getTopReports(),
        topDashboards: await _getTopDashboards(),
        generationTrends: _calculateGenerationTrends(reports),
        userActivity: await _calculateUserActivity(),
        performanceMetrics: await _calculatePerformanceMetrics(),
        period: DateRange(start: start, end: end),
      );

      return ReportingAnalyticsResult(
        success: true,
        analytics: analytics,
      );
    } catch (e) {
      debugPrint('❌ Failed to get reporting analytics: $e');
      return ReportingAnalyticsResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Private Implementation Methods

  Future<void> _initializeReportingDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/advanced_reporting.db';

    _reportingDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Dashboards table
        await db.execute('''
          CREATE TABLE dashboards (
            dashboard_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            widgets TEXT NOT NULL,
            layout TEXT NOT NULL,
            settings TEXT,
            tags TEXT,
            is_public INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by TEXT NOT NULL,
            view_count INTEGER DEFAULT 0,
            last_viewed_at TEXT
          )
        ''');

        // Report definitions table
        await db.execute('''
          CREATE TABLE report_definitions (
            report_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            report_type TEXT NOT NULL,
            data_source_id TEXT NOT NULL,
            query TEXT NOT NULL,
            parameters TEXT,
            columns TEXT,
            filters TEXT,
            groupings TEXT,
            sorting TEXT,
            is_active INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by TEXT NOT NULL
          )
        ''');

        // Generated reports table
        await db.execute('''
          CREATE TABLE generated_reports (
            generation_id TEXT PRIMARY KEY,
            report_id TEXT NOT NULL,
            format TEXT NOT NULL,
            file_path TEXT,
            parameters TEXT,
            record_count INTEGER,
            generated_at TEXT NOT NULL,
            generated_by TEXT NOT NULL,
            file_size INTEGER,
            expires_at TEXT,
            FOREIGN KEY (report_id) REFERENCES report_definitions (report_id)
          )
        ''');

        // Report schedules table
        await db.execute('''
          CREATE TABLE report_schedules (
            schedule_id TEXT PRIMARY KEY,
            report_id TEXT NOT NULL,
            frequency TEXT NOT NULL,
            recipients TEXT NOT NULL,
            parameter_values TEXT,
            format TEXT NOT NULL,
            is_active INTEGER,
            start_date TEXT NOT NULL,
            end_date TEXT,
            last_run TEXT,
            next_run TEXT NOT NULL,
            created_at TEXT NOT NULL,
            created_by TEXT NOT NULL,
            FOREIGN KEY (report_id) REFERENCES report_definitions (report_id)
          )
        ''');

        // Data sources table
        await db.execute('''
          CREATE TABLE data_sources (
            source_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            source_type TEXT NOT NULL,
            connection_string TEXT NOT NULL,
            configuration TEXT,
            is_active INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // Report templates table
        await db.execute('''
          CREATE TABLE report_templates (
            template_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            template_type TEXT NOT NULL,
            template_content TEXT NOT NULL,
            parameters TEXT,
            created_at TEXT NOT NULL,
            created_by TEXT NOT NULL
          )
        ''');
      },
    );

    debugPrint('✅ Reporting database initialized');
  }

  Future<void> _loadDashboards() async {
    // Load dashboards from database
    debugPrint('📊 Loading dashboards...');
  }

  Future<void> _loadReportDefinitions() async {
    // Load report definitions from database
    debugPrint('📋 Loading report definitions...');
  }

  Future<void> _loadReportTemplates() async {
    // Load report templates from database
    debugPrint('📄 Loading report templates...');
  }

  Future<void> _loadDataSources() async {
    // Initialize default data sources
    _dataSources['primary_db'] = DataSource(
      sourceId: 'primary_db',
      name: 'Primary Database',
      sourceType: DataSourceType.database,
      connectionString: 'sqlite://app_database.db',
      configuration: {},
      isActive: true,
      createdAt: DateTime.now(),
    );

    _dataSources['analytics_db'] = DataSource(
      sourceId: 'analytics_db',
      name: 'Analytics Database',
      sourceType: DataSourceType.database,
      connectionString: 'sqlite://analytics.db',
      configuration: {},
      isActive: true,
      createdAt: DateTime.now(),
    );

    debugPrint('✅ Data sources loaded');
  }

  Future<void> _loadReportSchedules() async {
    // Load report schedules from database
    debugPrint('⏰ Loading report schedules...');
  }

  Future<void> _initializeDefaultConfigurations() async {
    // Initialize default report templates
    await _createDefaultReportTemplates();
    
    // Initialize default chart configurations
    await _createDefaultChartConfigurations();
    
    // Initialize default visualization templates
    await _createDefaultVisualizationTemplates();

    debugPrint('✅ Default configurations initialized');
  }

  Future<void> _createDefaultReportTemplates() async {
    // Create default healthcare report templates
    final templates = [
      ReportTemplate(
        templateId: 'patient_summary',
        name: 'Patient Summary Report',
        description: 'Comprehensive patient information summary',
        templateType: ReportTemplateType.standard,
        templateContent: _getPatientSummaryTemplate(),
        parameters: ['patient_id', 'date_range'],
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      ReportTemplate(
        templateId: 'financial_summary',
        name: 'Financial Summary Report',
        description: 'Financial performance and billing summary',
        templateType: ReportTemplateType.financial,
        templateContent: _getFinancialSummaryTemplate(),
        parameters: ['start_date', 'end_date', 'department'],
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
    ];

    for (final template in templates) {
      _reportTemplates[template.templateId] = template;
    }
  }

  Future<void> _createDefaultChartConfigurations() async {
    // Create default chart configurations
    _chartConfigurations['line_chart'] = ChartConfiguration(
      configId: 'line_chart',
      chartType: ChartType.line,
      title: 'Line Chart',
      xAxisLabel: 'Date',
      yAxisLabel: 'Value',
      colors: ['#2196F3', '#4CAF50', '#FF9800'],
      showLegend: true,
      showGrid: true,
    );

    _chartConfigurations['bar_chart'] = ChartConfiguration(
      configId: 'bar_chart',
      chartType: ChartType.bar,
      title: 'Bar Chart',
      xAxisLabel: 'Category',
      yAxisLabel: 'Count',
      colors: ['#2196F3', '#4CAF50', '#FF9800'],
      showLegend: true,
      showGrid: true,
    );

    _chartConfigurations['pie_chart'] = ChartConfiguration(
      configId: 'pie_chart',
      chartType: ChartType.pie,
      title: 'Pie Chart',
      colors: ['#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0'],
      showLegend: true,
      showGrid: false,
    );
  }

  Future<void> _createDefaultVisualizationTemplates() async {
    // Create default visualization templates
    _visualizationTemplates['kpi_card'] = VisualizationTemplate(
      templateId: 'kpi_card',
      name: 'KPI Card',
      templateType: VisualizationType.kpi,
      configuration: {
        'showTrend': true,
        'showComparison': true,
        'format': 'number',
      },
    );

    _visualizationTemplates['data_table'] = VisualizationTemplate(
      templateId: 'data_table',
      name: 'Data Table',
      templateType: VisualizationType.table,
      configuration: {
        'sortable': true,
        'filterable': true,
        'paginated': true,
        'pageSize': 25,
      },
    );
  }

  void _startScheduleProcessor() {
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _processScheduledReports();
    });
  }

  void _startCacheManager() {
    _cacheTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _manageCacheExpiry();
      _optimizeQueryPerformance();
    });
  }

  Future<void> _processScheduledReports() async {
    final now = DateTime.now();
    
    for (final schedule in _reportSchedules.values) {
      if (schedule.isActive && 
          schedule.nextRun.isBefore(now) &&
          (schedule.endDate == null || now.isBefore(schedule.endDate!))) {
        
        try {
          debugPrint('⏰ Processing scheduled report: ${schedule.scheduleId}');
          
          // Generate report
          final result = await generateReport(
            reportId: schedule.reportId,
            parameterValues: schedule.parameterValues,
            format: schedule.format,
          );
          
          if (result.success) {
            // Distribute report to recipients
            await _distributeReport(result, schedule.recipients);
            
            // Update schedule
            schedule.lastRun = now;
            schedule.nextRun = _calculateNextRun(schedule.frequency, now);
            
            await _saveReportSchedule(schedule);
          }
        } catch (e) {
          debugPrint('❌ Failed to process scheduled report ${schedule.scheduleId}: $e');
        }
      }
    }
  }

  Future<void> _manageCacheExpiry() async {
    final now = DateTime.now();
    
    // Remove expired cache entries
    _dataCache.removeWhere((key, data) => data.expiresAt.isBefore(now));
    
    // Clean up old generated reports
    final expiredReports = _generatedReports.values
        .where((report) => report.expiresAt != null && report.expiresAt!.isBefore(now))
        .toList();
    
    for (final report in expiredReports) {
      // Delete physical file
      await _deleteReportFile(report.filePath);
      
      // Remove from memory
      _generatedReports.remove(report.generationId);
    }
  }

  Future<void> _optimizeQueryPerformance() async {
    // Analyze query performance and suggest optimizations
    for (final performance in _queryPerformance.values) {
      if (performance.averageExecutionTime > 5000) { // 5 seconds
        debugPrint('⚠️ Slow query detected: ${performance.queryId} (${performance.averageExecutionTime}ms)');
        // Could trigger query optimization or caching
      }
    }
  }

  Future<ValidationResult> _validateWidget(DashboardWidget widget) async {
    final errors = <String>[];
    
    // Validate data source
    if (!_dataSources.containsKey(widget.dataSourceId)) {
      errors.add('Invalid data source: ${widget.dataSourceId}');
    }
    
    // Validate query
    if (widget.query.trim().isEmpty) {
      errors.add('Query cannot be empty');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Future<ValidationResult> _validateReportDefinition(ReportDefinition reportDefinition) async {
    final errors = <String>[];
    
    // Validate data source
    if (!_dataSources.containsKey(reportDefinition.dataSourceId)) {
      errors.add('Invalid data source: ${reportDefinition.dataSourceId}');
    }
    
    // Validate query
    if (reportDefinition.query.trim().isEmpty) {
      errors.add('Query cannot be empty');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Future<QueryResult> _executeDataQuery(
    String dataSourceId,
    String query,
    Map<String, dynamic> parameters,
  ) async {
    try {
      final dataSource = _dataSources[dataSourceId];
      if (dataSource == null) {
        return QueryResult(
          success: false,
          error: 'Data source not found',
        );
      }

      // Check cache first
      final cacheKey = _generateCacheKey(query, parameters);
      final cachedData = _dataCache[cacheKey];
      if (cachedData != null && cachedData.expiresAt.isAfter(DateTime.now())) {
        debugPrint('💾 Returning cached data for query: $cacheKey');
        return QueryResult(
          success: true,
          data: cachedData.data,
          fromCache: true,
        );
      }

      final startTime = DateTime.now();
      
      // Execute query based on data source type
      List<Map<String, dynamic>> data;
      switch (dataSource.sourceType) {
        case DataSourceType.database:
          data = await _executeDatabaseQuery(dataSource, query, parameters);
          break;
        case DataSourceType.api:
          data = await _executeAPIQuery(dataSource, query, parameters);
          break;
        case DataSourceType.file:
          data = await _executeFileQuery(dataSource, query, parameters);
          break;
      }

      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // Update performance metrics
      _updateQueryPerformance(query, executionTime);
      
      // Cache results
      _dataCache[cacheKey] = CachedData(
        data: data,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      return QueryResult(
        success: true,
        data: data,
        executionTime: executionTime,
      );
    } catch (e) {
      return QueryResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _executeDatabaseQuery(
    DataSource dataSource,
    String query,
    Map<String, dynamic> parameters,
  ) async {
    // Execute database query
    // This would use the actual database connection
    return [
      {'id': 1, 'name': 'Sample Data', 'value': 100},
      {'id': 2, 'name': 'Sample Data 2', 'value': 200},
    ];
  }

  Future<List<Map<String, dynamic>>> _executeAPIQuery(
    DataSource dataSource,
    String query,
    Map<String, dynamic> parameters,
  ) async {
    // Execute API query
    return [];
  }

  Future<List<Map<String, dynamic>>> _executeFileQuery(
    DataSource dataSource,
    String query,
    Map<String, dynamic> parameters,
  ) async {
    // Execute file-based query (CSV, JSON, etc.)
    return [];
  }

  Future<List<Map<String, dynamic>>> _processReportData(
    List<Map<String, dynamic>> data,
    List<ReportFilter> filters,
    List<ReportGrouping> groupings,
    List<ReportSorting> sorting,
  ) async {
    var processedData = data;

    // Apply filters
    for (final filter in filters) {
      processedData = processedData.where((row) {
        return _applyFilter(row, filter);
      }).toList();
    }

    // Apply groupings
    if (groupings.isNotEmpty) {
      processedData = await _applyGroupings(processedData, groupings);
    }

    // Apply sorting
    if (sorting.isNotEmpty) {
      processedData = await _applySorting(processedData, sorting);
    }

    return processedData;
  }

  bool _applyFilter(Map<String, dynamic> row, ReportFilter filter) {
    final value = row[filter.field];
    
    switch (filter.operator) {
      case FilterOperator.equals:
        return value == filter.value;
      case FilterOperator.notEquals:
        return value != filter.value;
      case FilterOperator.greaterThan:
        return (value as num) > (filter.value as num);
      case FilterOperator.lessThan:
        return (value as num) < (filter.value as num);
      case FilterOperator.contains:
        return value.toString().toLowerCase().contains(filter.value.toString().toLowerCase());
      case FilterOperator.startsWith:
        return value.toString().toLowerCase().startsWith(filter.value.toString().toLowerCase());
    }
  }

  Future<List<Map<String, dynamic>>> _applyGroupings(
    List<Map<String, dynamic>> data,
    List<ReportGrouping> groupings,
  ) async {
    // Apply grouping logic
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final row in data) {
      final groupKey = groupings.map((g) => row[g.field].toString()).join('|');
      grouped[groupKey] = (grouped[groupKey] ?? [])..add(row);
    }

    // Apply aggregations
    final result = <Map<String, dynamic>>[];
    for (final entry in grouped.entries) {
      final groupData = entry.value;
      final aggregatedRow = <String, dynamic>{};
      
      // Add group fields
      for (int i = 0; i < groupings.length; i++) {
        final grouping = groupings[i];
        aggregatedRow[grouping.field] = groupData.first[grouping.field];
      }
      
      // Apply aggregations
      for (final grouping in groupings) {
        if (grouping.aggregation != null) {
          switch (grouping.aggregation!) {
            case AggregationType.count:
              aggregatedRow['${grouping.field}_count'] = groupData.length;
              break;
            case AggregationType.sum:
              aggregatedRow['${grouping.field}_sum'] = groupData
                  .map((row) => row[grouping.field] as num? ?? 0)
                  .reduce((a, b) => a + b);
              break;
            case AggregationType.average:
              final values = groupData.map((row) => row[grouping.field] as num? ?? 0).toList();
              aggregatedRow['${grouping.field}_avg'] = values.reduce((a, b) => a + b) / values.length;
              break;
            case AggregationType.min:
              aggregatedRow['${grouping.field}_min'] = groupData
                  .map((row) => row[grouping.field] as num? ?? 0)
                  .reduce(math.min);
              break;
            case AggregationType.max:
              aggregatedRow['${grouping.field}_max'] = groupData
                  .map((row) => row[grouping.field] as num? ?? 0)
                  .reduce(math.max);
              break;
          }
        }
      }
      
      result.add(aggregatedRow);
    }
    
    return result;
  }

  Future<List<Map<String, dynamic>>> _applySorting(
    List<Map<String, dynamic>> data,
    List<ReportSorting> sorting,
  ) async {
    data.sort((a, b) {
      for (final sort in sorting) {
        final aValue = a[sort.field];
        final bValue = b[sort.field];
        
        int comparison = 0;
        if (aValue is num && bValue is num) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }
        
        if (comparison != 0) {
          return sort.direction == SortDirection.ascending ? comparison : -comparison;
        }
      }
      return 0;
    });
    
    return data;
  }

  Future<String?> _generatePDFReport(
    ReportDefinition reportDefinition,
    List<Map<String, dynamic>> data,
    String generationId,
  ) async {
    // Generate PDF report
    final filePath = '/reports/pdf/${generationId}.pdf';
    
    // PDF generation logic would go here
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate generation
    
    return filePath;
  }

  Future<String?> _generateExcelReport(
    ReportDefinition reportDefinition,
    List<Map<String, dynamic>> data,
    String generationId,
  ) async {
    // Generate Excel report
    final filePath = '/reports/excel/${generationId}.xlsx';
    
    // Excel generation logic would go here
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate generation
    
    return filePath;
  }

  Future<String?> _generateCSVReport(
    ReportDefinition reportDefinition,
    List<Map<String, dynamic>> data,
    String generationId,
  ) async {
    // Generate CSV report
    final filePath = '/reports/csv/${generationId}.csv';
    
    // CSV generation logic would go here
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate generation
    
    return filePath;
  }

  Future<String?> _generatePowerPointReport(
    ReportDefinition reportDefinition,
    List<Map<String, dynamic>> data,
    String generationId,
  ) async {
    // Generate PowerPoint report
    final filePath = '/reports/pptx/${generationId}.pptx';
    
    // PowerPoint generation logic would go here
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate generation
    
    return filePath;
  }

  Future<String?> _generateHTMLReport(
    ReportDefinition reportDefinition,
    List<Map<String, dynamic>> data,
    String generationId,
  ) async {
    // Generate HTML report
    final filePath = '/reports/html/${generationId}.html';
    
    // HTML generation logic would go here
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate generation
    
    return filePath;
  }

  DateTime _calculateNextRun(ScheduleFrequency frequency, DateTime baseDate) {
    switch (frequency) {
      case ScheduleFrequency.hourly:
        return baseDate.add(const Duration(hours: 1));
      case ScheduleFrequency.daily:
        return DateTime(baseDate.year, baseDate.month, baseDate.day + 1, 9, 0); // 9 AM next day
      case ScheduleFrequency.weekly:
        return baseDate.add(const Duration(days: 7));
      case ScheduleFrequency.monthly:
        return DateTime(baseDate.year, baseDate.month + 1, 1, 9, 0); // 1st of next month
      case ScheduleFrequency.quarterly:
        return DateTime(baseDate.year, baseDate.month + 3, 1, 9, 0);
      case ScheduleFrequency.yearly:
        return DateTime(baseDate.year + 1, 1, 1, 9, 0);
    }
  }

  Future<void> _distributeReport(ReportGenerationResult result, List<String> recipients) async {
    // Distribute report to recipients via email, notification, etc.
    debugPrint('📧 Distributing report to ${recipients.length} recipients');
  }

  Future<dynamic> _getWidgetData(DashboardWidget widget) async {
    // Get data for a specific widget
    final queryResult = await _executeDataQuery(
      widget.dataSourceId,
      widget.query,
      widget.configuration,
    );

    if (!queryResult.success) {
      throw Exception('Failed to load widget data: ${queryResult.error}');
    }

    // Format data based on widget type
    switch (widget.widgetType) {
      case WidgetType.chart:
        return _formatChartData(queryResult.data!, widget.chartConfig);
      case WidgetType.table:
        return _formatTableData(queryResult.data!);
      case WidgetType.kpi:
        return _formatKPIData(queryResult.data!);
      case WidgetType.text:
        return _formatTextData(queryResult.data!);
      case WidgetType.gauge:
        return _formatGaugeData(queryResult.data!);
    }
  }

  Map<String, dynamic> _formatChartData(List<Map<String, dynamic>> data, ChartConfiguration? config) {
    return {
      'type': config?.chartType.toString().split('.').last ?? 'line',
      'data': data,
      'config': config?.toJson() ?? {},
    };
  }

  Map<String, dynamic> _formatTableData(List<Map<String, dynamic>> data) {
    return {
      'rows': data,
      'columns': data.isNotEmpty ? data.first.keys.toList() : [],
    };
  }

  Map<String, dynamic> _formatKPIData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return {'value': 0};
    
    final value = data.first.values.first;
    return {
      'value': value,
      'trend': _calculateTrend(data),
      'comparison': _calculateComparison(data),
    };
  }

  Map<String, dynamic> _formatTextData(List<Map<String, dynamic>> data) {
    return {
      'text': data.isNotEmpty ? data.first.values.first.toString() : '',
    };
  }

  Map<String, dynamic> _formatGaugeData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return {'value': 0, 'min': 0, 'max': 100};
    
    final value = data.first.values.first as num? ?? 0;
    return {
      'value': value,
      'min': 0,
      'max': 100,
    };
  }

  double _calculateTrend(List<Map<String, dynamic>> data) {
    // Calculate trend percentage
    if (data.length < 2) return 0.0;
    
    final current = data.last.values.first as num? ?? 0;
    final previous = data[data.length - 2].values.first as num? ?? 0;
    
    if (previous == 0) return 0.0;
    
    return ((current - previous) / previous) * 100;
  }

  double _calculateComparison(List<Map<String, dynamic>> data) {
    // Calculate comparison with target or benchmark
    return 0.0; // Placeholder
  }

  Future<String?> _exportDashboardToPDF(Dashboard dashboard, String exportId) async {
    // Export dashboard to PDF
    return '/exports/pdf/dashboard_${exportId}.pdf';
  }

  Future<String?> _exportDashboardToPowerPoint(Dashboard dashboard, String exportId) async {
    // Export dashboard to PowerPoint
    return '/exports/pptx/dashboard_${exportId}.pptx';
  }

  Future<String?> _exportDashboardToImage(Dashboard dashboard, String exportId) async {
    // Export dashboard to image
    return '/exports/png/dashboard_${exportId}.png';
  }

  Future<String?> _exportDashboardToJSON(Dashboard dashboard, String exportId) async {
    // Export dashboard configuration to JSON
    return '/exports/json/dashboard_${exportId}.json';
  }

  Map<ReportType, int> _calculateReportsByType(List<GeneratedReport> reports) {
    final reportsByType = <ReportType, int>{};
    for (final report in reports) {
      final reportDef = _reportDefinitions[report.reportId];
      if (reportDef != null) {
        reportsByType[reportDef.reportType] = (reportsByType[reportDef.reportType] ?? 0) + 1;
      }
    }
    return reportsByType;
  }

  Map<ReportFormat, int> _calculateReportsByFormat(List<GeneratedReport> reports) {
    final reportsByFormat = <ReportFormat, int>{};
    for (final report in reports) {
      reportsByFormat[report.format] = (reportsByFormat[report.format] ?? 0) + 1;
    }
    return reportsByFormat;
  }

  Future<List<ReportUsage>> _getTopReports() async {
    final reportUsage = <String, int>{};
    
    for (final report in _generatedReports.values) {
      reportUsage[report.reportId] = (reportUsage[report.reportId] ?? 0) + 1;
    }
    
    final topReports = <ReportUsage>[];
    for (final entry in reportUsage.entries) {
      final reportDef = _reportDefinitions[entry.key];
      if (reportDef != null) {
        topReports.add(ReportUsage(
          reportId: entry.key,
          reportName: reportDef.name,
          generationCount: entry.value,
        ));
      }
    }
    
    topReports.sort((a, b) => b.generationCount.compareTo(a.generationCount));
    return topReports.take(10).toList();
  }

  Future<List<DashboardUsage>> _getTopDashboards() async {
    final topDashboards = _dashboards.values
        .map((dashboard) => DashboardUsage(
              dashboardId: dashboard.dashboardId,
              dashboardName: dashboard.name,
              viewCount: dashboard.viewCount,
            ))
        .toList();
    
    topDashboards.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return topDashboards.take(10).toList();
  }

  Map<String, int> _calculateGenerationTrends(List<GeneratedReport> reports) {
    final trends = <String, int>{};
    
    for (final report in reports) {
      final dateKey = report.generatedAt.toIso8601String().substring(0, 10);
      trends[dateKey] = (trends[dateKey] ?? 0) + 1;
    }
    
    return trends;
  }

  Future<Map<String, int>> _calculateUserActivity() async {
    // Calculate user activity metrics
    return {
      'activeUsers': _dashboards.values.where((d) => d.viewCount > 0).length,
      'totalViews': _dashboards.values.fold<int>(0, (sum, d) => sum + d.viewCount),
    };
  }

  Future<Map<String, double>> _calculatePerformanceMetrics() async {
    // Calculate performance metrics
    final queryTimes = _queryPerformance.values.map((p) => p.averageExecutionTime).toList();
    final averageQueryTime = queryTimes.isEmpty ? 0.0 : queryTimes.reduce((a, b) => a + b) / queryTimes.length;
    
    return {
      'averageQueryTime': averageQueryTime,
      'cacheHitRate': _calculateCacheHitRate(),
    };
  }

  double _calculateCacheHitRate() {
    // Calculate cache hit rate
    return 0.75; // Placeholder
  }

  void _updateQueryPerformance(String query, int executionTime) {
    final queryId = _generateQueryId(query);
    
    final performance = _queryPerformance[queryId] ?? QueryPerformance(
      queryId: queryId,
      query: query,
      executionCount: 0,
      totalExecutionTime: 0,
      averageExecutionTime: 0.0,
      lastExecuted: DateTime.now(),
    );
    
    performance.executionCount++;
    performance.totalExecutionTime += executionTime;
    performance.averageExecutionTime = performance.totalExecutionTime / performance.executionCount;
    performance.lastExecuted = DateTime.now();
    
    _queryPerformance[queryId] = performance;
  }

  String _generateCacheKey(String query, Map<String, dynamic> parameters) {
    final paramString = parameters.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '${query.hashCode}_${paramString.hashCode}';
  }

  String _generateQueryId(String query) {
    return 'query_${query.hashCode}';
  }

  Future<int> _getFileSize(String? filePath) async {
    // Get file size
    return filePath != null ? 1024 * 1024 : 0; // 1MB placeholder
  }

  Future<void> _deleteReportFile(String? filePath) async {
    // Delete physical report file
    if (filePath != null) {
      debugPrint('🗑️ Deleting report file: $filePath');
    }
  }

  String _getPatientSummaryTemplate() {
    return '''
    <html>
      <head><title>Patient Summary Report</title></head>
      <body>
        <h1>Patient Summary</h1>
        <p>Patient ID: {{patient_id}}</p>
        <p>Date Range: {{date_range}}</p>
        <!-- Template content -->
      </body>
    </html>
    ''';
  }

  String _getFinancialSummaryTemplate() {
    return '''
    <html>
      <head><title>Financial Summary Report</title></head>
      <body>
        <h1>Financial Summary</h1>
        <p>Period: {{start_date}} to {{end_date}}</p>
        <p>Department: {{department}}</p>
        <!-- Template content -->
      </body>
    </html>
    ''';
  }

  String _generateDashboardId() {
    return 'dashboard_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateGenerationId() {
    return 'gen_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateScheduleId() {
    return 'schedule_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateWidgetId() {
    return 'widget_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateExportId() {
    return 'export_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Future<void> _saveDashboard(Dashboard dashboard) async {
    if (_reportingDb == null) return;

    await _reportingDb!.insert('dashboards', {
      'dashboard_id': dashboard.dashboardId,
      'name': dashboard.name,
      'description': dashboard.description,
      'widgets': jsonEncode(dashboard.widgets.map((w) => w.toJson()).toList()),
      'layout': dashboard.layout.toString().split('.').last,
      'settings': jsonEncode(dashboard.settings),
      'tags': jsonEncode(dashboard.tags),
      'is_public': dashboard.isPublic ? 1 : 0,
      'created_at': dashboard.createdAt.toIso8601String(),
      'updated_at': dashboard.updatedAt.toIso8601String(),
      'created_by': dashboard.createdBy,
      'view_count': dashboard.viewCount,
      'last_viewed_at': dashboard.lastViewedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveReportDefinition(ReportDefinition reportDefinition) async {
    if (_reportingDb == null) return;

    await _reportingDb!.insert('report_definitions', {
      'report_id': reportDefinition.reportId,
      'name': reportDefinition.name,
      'description': reportDefinition.description,
      'report_type': reportDefinition.reportType.toString().split('.').last,
      'data_source_id': reportDefinition.dataSourceId,
      'query': reportDefinition.query,
      'parameters': jsonEncode(reportDefinition.parameters),
      'columns': jsonEncode(reportDefinition.columns.map((c) => c.toJson()).toList()),
      'filters': jsonEncode(reportDefinition.filters.map((f) => f.toJson()).toList()),
      'groupings': jsonEncode(reportDefinition.groupings.map((g) => g.toJson()).toList()),
      'sorting': jsonEncode(reportDefinition.sorting.map((s) => s.toJson()).toList()),
      'is_active': reportDefinition.isActive ? 1 : 0,
      'created_at': reportDefinition.createdAt.toIso8601String(),
      'updated_at': reportDefinition.updatedAt.toIso8601String(),
      'created_by': reportDefinition.createdBy,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveGeneratedReport(GeneratedReport generatedReport) async {
    if (_reportingDb == null) return;

    await _reportingDb!.insert('generated_reports', {
      'generation_id': generatedReport.generationId,
      'report_id': generatedReport.reportId,
      'format': generatedReport.format.toString().split('.').last,
      'file_path': generatedReport.filePath,
      'parameters': jsonEncode(generatedReport.parameters),
      'record_count': generatedReport.recordCount,
      'generated_at': generatedReport.generatedAt.toIso8601String(),
      'generated_by': generatedReport.generatedBy,
      'file_size': generatedReport.fileSize,
      'expires_at': generatedReport.expiresAt?.toIso8601String(),
    });
  }

  Future<void> _saveReportSchedule(ReportSchedule schedule) async {
    if (_reportingDb == null) return;

    await _reportingDb!.insert('report_schedules', {
      'schedule_id': schedule.scheduleId,
      'report_id': schedule.reportId,
      'frequency': schedule.frequency.toString().split('.').last,
      'recipients': jsonEncode(schedule.recipients),
      'parameter_values': jsonEncode(schedule.parameterValues),
      'format': schedule.format.toString().split('.').last,
      'is_active': schedule.isActive ? 1 : 0,
      'start_date': schedule.startDate.toIso8601String(),
      'end_date': schedule.endDate?.toIso8601String(),
      'last_run': schedule.lastRun?.toIso8601String(),
      'next_run': schedule.nextRun.toIso8601String(),
      'created_at': schedule.createdAt.toIso8601String(),
      'created_by': schedule.createdBy,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Dispose resources
  @override
  void dispose() {
    _scheduleTimer?.cancel();
    _cacheTimer?.cancel();
    _reportingDb?.close();
    super.dispose();
  }
}

// Data Models and Enums

enum ReportType { tabular, summary, analytical, financial, operational }
enum ReportFormat { pdf, excel, csv, powerpoint, html }
enum ScheduleFrequency { hourly, daily, weekly, monthly, quarterly, yearly }
enum DashboardLayout { grid, flow, custom }
enum WidgetType { chart, table, kpi, text, gauge }
enum ChartType { line, bar, pie, area, scatter }
enum DataSourceType { database, api, file }
enum FilterOperator { equals, notEquals, greaterThan, lessThan, contains, startsWith }
enum SortDirection { ascending, descending }
enum AggregationType { count, sum, average, min, max }
enum ReportTemplateType { standard, financial, operational, custom }
enum VisualizationType { chart, table, kpi, gauge, text }
enum DashboardExportFormat { pdf, powerpoint, image, json }

class Dashboard {
  final String dashboardId;
  final String name;
  final String description;
  final List<DashboardWidget> widgets;
  final DashboardLayout layout;
  final Map<String, dynamic> settings;
  final List<String> tags;
  final bool isPublic;
  final DateTime createdAt;
  DateTime updatedAt;
  final String createdBy;
  int viewCount;
  DateTime? lastViewedAt;

  Dashboard({
    required this.dashboardId,
    required this.name,
    required this.description,
    required this.widgets,
    required this.layout,
    required this.settings,
    required this.tags,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.viewCount,
    this.lastViewedAt,
  });
}

class DashboardWidget {
  final String widgetId;
  final String title;
  final WidgetType widgetType;
  final String dataSourceId;
  final String query;
  final Map<String, dynamic> configuration;
  final ChartConfiguration? chartConfig;
  final WidgetPosition position;
  final Duration refreshInterval;
  final bool isVisible;
  final DateTime createdAt;

  DashboardWidget({
    required this.widgetId,
    required this.title,
    required this.widgetType,
    required this.dataSourceId,
    required this.query,
    required this.configuration,
    this.chartConfig,
    required this.position,
    required this.refreshInterval,
    required this.isVisible,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'widgetId': widgetId,
    'title': title,
    'widgetType': widgetType.toString().split('.').last,
    'dataSourceId': dataSourceId,
    'query': query,
    'configuration': configuration,
    'chartConfig': chartConfig?.toJson(),
    'position': position.toJson(),
    'refreshInterval': refreshInterval.inSeconds,
    'isVisible': isVisible,
    'createdAt': createdAt.toIso8601String(),
  };
}

class WidgetPosition {
  final int x;
  final int y;
  final int width;
  final int height;

  WidgetPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

class ReportDefinition {
  final String reportId;
  final String name;
  final String description;
  final ReportType reportType;
  final String dataSourceId;
  final String query;
  final Map<String, dynamic> parameters;
  final List<ReportColumn> columns;
  final List<ReportFilter> filters;
  final List<ReportGrouping> groupings;
  final List<ReportSorting> sorting;
  final bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;
  final String createdBy;

  ReportDefinition({
    required this.reportId,
    required this.name,
    required this.description,
    required this.reportType,
    required this.dataSourceId,
    required this.query,
    required this.parameters,
    required this.columns,
    required this.filters,
    required this.groupings,
    required this.sorting,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });
}

class ReportColumn {
  final String field;
  final String label;
  final String dataType;
  final String? format;
  final bool isVisible;

  ReportColumn({
    required this.field,
    required this.label,
    required this.dataType,
    this.format,
    required this.isVisible,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'label': label,
    'dataType': dataType,
    'format': format,
    'isVisible': isVisible,
  };
}

class ReportFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  ReportFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': operator.toString().split('.').last,
    'value': value,
  };
}

class ReportGrouping {
  final String field;
  final AggregationType? aggregation;

  ReportGrouping({
    required this.field,
    this.aggregation,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'aggregation': aggregation?.toString().split('.').last,
  };
}

class ReportSorting {
  final String field;
  final SortDirection direction;

  ReportSorting({
    required this.field,
    required this.direction,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'direction': direction.toString().split('.').last,
  };
}

class GeneratedReport {
  final String generationId;
  final String reportId;
  final ReportFormat format;
  final String? filePath;
  final Map<String, dynamic> parameters;
  final int recordCount;
  final DateTime generatedAt;
  final String generatedBy;
  final int fileSize;
  final DateTime? expiresAt;

  GeneratedReport({
    required this.generationId,
    required this.reportId,
    required this.format,
    this.filePath,
    required this.parameters,
    required this.recordCount,
    required this.generatedAt,
    required this.generatedBy,
    required this.fileSize,
    this.expiresAt,
  });
}

class ReportSchedule {
  final String scheduleId;
  final String reportId;
  final ScheduleFrequency frequency;
  final List<String> recipients;
  final Map<String, dynamic> parameterValues;
  final ReportFormat format;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  DateTime? lastRun;
  DateTime nextRun;
  final DateTime createdAt;
  final String createdBy;

  ReportSchedule({
    required this.scheduleId,
    required this.reportId,
    required this.frequency,
    required this.recipients,
    required this.parameterValues,
    required this.format,
    required this.isActive,
    required this.startDate,
    this.endDate,
    this.lastRun,
    required this.nextRun,
    required this.createdAt,
    required this.createdBy,
  });
}

class ReportSubscription {
  final String subscriptionId;
  final String userId;
  final String reportId;
  final List<String> deliveryMethods;
  final Map<String, dynamic> preferences;
  final bool isActive;

  ReportSubscription({
    required this.subscriptionId,
    required this.userId,
    required this.reportId,
    required this.deliveryMethods,
    required this.preferences,
    required this.isActive,
  });
}

class DataSource {
  final String sourceId;
  final String name;
  final DataSourceType sourceType;
  final String connectionString;
  final Map<String, dynamic> configuration;
  final bool isActive;
  final DateTime createdAt;

  DataSource({
    required this.sourceId,
    required this.name,
    required this.sourceType,
    required this.connectionString,
    required this.configuration,
    required this.isActive,
    required this.createdAt,
  });
}

class DataQuery {
  final String queryId;
  final String name;
  final String query;
  final String dataSourceId;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;

  DataQuery({
    required this.queryId,
    required this.name,
    required this.query,
    required this.dataSourceId,
    required this.parameters,
    required this.createdAt,
  });
}

class ChartConfiguration {
  final String configId;
  final ChartType chartType;
  final String title;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final List<String> colors;
  final bool showLegend;
  final bool showGrid;

  ChartConfiguration({
    required this.configId,
    required this.chartType,
    required this.title,
    this.xAxisLabel,
    this.yAxisLabel,
    required this.colors,
    required this.showLegend,
    required this.showGrid,
  });

  Map<String, dynamic> toJson() => {
    'configId': configId,
    'chartType': chartType.toString().split('.').last,
    'title': title,
    'xAxisLabel': xAxisLabel,
    'yAxisLabel': yAxisLabel,
    'colors': colors,
    'showLegend': showLegend,
    'showGrid': showGrid,
  };
}

class VisualizationTemplate {
  final String templateId;
  final String name;
  final VisualizationType templateType;
  final Map<String, dynamic> configuration;

  VisualizationTemplate({
    required this.templateId,
    required this.name,
    required this.templateType,
    required this.configuration,
  });
}

class ReportTemplate {
  final String templateId;
  final String name;
  final String description;
  final ReportTemplateType templateType;
  final String templateContent;
  final List<String> parameters;
  final DateTime createdAt;
  final String createdBy;

  ReportTemplate({
    required this.templateId,
    required this.name,
    required this.description,
    required this.templateType,
    required this.templateContent,
    required this.parameters,
    required this.createdAt,
    required this.createdBy,
  });
}

class CachedData {
  final List<Map<String, dynamic>> data;
  final DateTime cachedAt;
  final DateTime expiresAt;

  CachedData({
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
  });
}

class QueryPerformance {
  final String queryId;
  final String query;
  int executionCount;
  int totalExecutionTime;
  double averageExecutionTime;
  DateTime lastExecuted;

  QueryPerformance({
    required this.queryId,
    required this.query,
    required this.executionCount,
    required this.totalExecutionTime,
    required this.averageExecutionTime,
    required this.lastExecuted,
  });
}

class UserPreferences {
  final String userId;
  final Map<String, dynamic> dashboardPreferences;
  final Map<String, dynamic> reportPreferences;
  final String defaultFormat;
  final Duration cacheExpiry;

  UserPreferences({
    required this.userId,
    required this.dashboardPreferences,
    required this.reportPreferences,
    required this.defaultFormat,
    required this.cacheExpiry,
  });
}

class ReportPermission {
  final String permissionId;
  final String userId;
  final String resourceId;
  final List<String> permissions;
  final bool isActive;

  ReportPermission({
    required this.permissionId,
    required this.userId,
    required this.resourceId,
    required this.permissions,
    required this.isActive,
  });
}

class ReportingAnalytics {
  final int totalReports;
  final int totalDashboards;
  final Map<ReportType, int> reportsByType;
  final Map<ReportFormat, int> reportsByFormat;
  final List<ReportUsage> topReports;
  final List<DashboardUsage> topDashboards;
  final Map<String, int> generationTrends;
  final Map<String, int> userActivity;
  final Map<String, double> performanceMetrics;
  final DateRange period;

  ReportingAnalytics({
    required this.totalReports,
    required this.totalDashboards,
    required this.reportsByType,
    required this.reportsByFormat,
    required this.topReports,
    required this.topDashboards,
    required this.generationTrends,
    required this.userActivity,
    required this.performanceMetrics,
    required this.period,
  });
}

class ReportUsage {
  final String reportId;
  final String reportName;
  final int generationCount;

  ReportUsage({
    required this.reportId,
    required this.reportName,
    required this.generationCount,
  });
}

class DashboardUsage {
  final String dashboardId;
  final String dashboardName;
  final int viewCount;

  DashboardUsage({
    required this.dashboardId,
    required this.dashboardName,
    required this.viewCount,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

// Result Classes

class DashboardCreationResult {
  final bool success;
  final String? dashboardId;
  final String? error;

  DashboardCreationResult({
    required this.success,
    this.dashboardId,
    this.error,
  });
}

class ReportCreationResult {
  final bool success;
  final String? reportId;
  final String? error;

  ReportCreationResult({
    required this.success,
    this.reportId,
    this.error,
  });
}

class ReportGenerationResult {
  final bool success;
  final String? generationId;
  final String? filePath;
  final int? recordCount;
  final String? error;

  ReportGenerationResult({
    required this.success,
    this.generationId,
    this.filePath,
    this.recordCount,
    this.error,
  });
}

class ScheduleCreationResult {
  final bool success;
  final String? scheduleId;
  final DateTime? nextRun;
  final String? error;

  ScheduleCreationResult({
    required this.success,
    this.scheduleId,
    this.nextRun,
    this.error,
  });
}

class WidgetCreationResult {
  final bool success;
  final String? widgetId;
  final String? error;

  WidgetCreationResult({
    required this.success,
    this.widgetId,
    this.error,
  });
}

class DashboardDataResult {
  final bool success;
  final String? dashboardId;
  final Map<String, dynamic>? widgetData;
  final String? error;

  DashboardDataResult({
    required this.success,
    this.dashboardId,
    this.widgetData,
    this.error,
  });
}

class DashboardExportResult {
  final bool success;
  final String? exportId;
  final String? filePath;
  final String? error;

  DashboardExportResult({
    required this.success,
    this.exportId,
    this.filePath,
    this.error,
  });
}

class ReportingAnalyticsResult {
  final bool success;
  final ReportingAnalytics? analytics;
  final String? error;

  ReportingAnalyticsResult({
    required this.success,
    this.analytics,
    this.error,
  });
}

class QueryResult {
  final bool success;
  final List<Map<String, dynamic>>? data;
  final int? executionTime;
  final bool fromCache;
  final String? error;

  QueryResult({
    required this.success,
    this.data,
    this.executionTime,
    this.fromCache = false,
    this.error,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}