import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../core/app_export.dart';

/// Robotic Process Automation (RPA) Service for Administrative Tasks
/// 
/// Provides comprehensive RPA capabilities including:
/// - Automated workflow execution and orchestration
/// - Screen scraping and UI automation
/// - Data entry and form filling automation
/// - Document processing and validation
/// - Email and communication automation
/// - Database operations and data migration
/// - Report generation and distribution
/// - System integration and API automation
/// - Exception handling and error recovery
/// - Performance monitoring and optimization
class RoboticProcessAutomationService extends ChangeNotifier {
  static final RoboticProcessAutomationService _instance = RoboticProcessAutomationService._internal();
  factory RoboticProcessAutomationService() => _instance;
  RoboticProcessAutomationService._internal();

  Database? _rpaDb;
  bool _isInitialized = false;
  Timer? _executionTimer;
  Timer? _monitoringTimer;

  // Bot Management
  final Map<String, RPABot> _bots = {};
  final Map<String, BotExecution> _botExecutions = {};
  final Map<String, ProcessDefinition> _processDefinitions = {};
  
  // Task and Activity Management
  final Map<String, RPATask> _tasks = {};
  final Map<String, ActivityDefinition> _activityDefinitions = {};
  final List<TaskExecution> _executionQueue = [];
  
  // Automation Components
  final Map<String, AutomationAction> _automationActions = {};
  final Map<String, DataExtractor> _dataExtractors = {};
  final Map<String, FormFiller> _formFillers = {};
  
  // Monitoring and Analytics
  final Map<String, BotPerformance> _botPerformance = {};
  final Map<String, ExecutionMetrics> _executionMetrics = {};
  final List<RPALog> _executionLogs = [];
  
  // Error Handling and Recovery
  final Map<String, ErrorHandler> _errorHandlers = {};
  final Map<String, RecoveryStrategy> _recoveryStrategies = {};
  
  // Scheduling and Triggers
  final Map<String, RPASchedule> _schedules = {};
  final Map<String, EventTrigger> _eventTriggers = {};

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, RPABot> get bots => Map.unmodifiable(_bots);
  Map<String, ProcessDefinition> get processDefinitions => Map.unmodifiable(_processDefinitions);
  List<TaskExecution> get executionQueue => List.unmodifiable(_executionQueue);
  Map<String, BotPerformance> get botPerformance => Map.unmodifiable(_botPerformance);

  /// Initialize the RPA service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      debugPrint('🤖 Initializing Robotic Process Automation Service...');

      // Initialize database
      await _initializeRPADatabase();

      // Load existing configurations
      await _loadBots();
      await _loadProcessDefinitions();
      await _loadTasks();
      await _loadSchedules();

      // Initialize default automation components
      await _initializeDefaultComponents();

      // Start background services
      _startExecutionEngine();
      _startMonitoringService();

      _isInitialized = true;
      debugPrint('✅ Robotic Process Automation Service initialized successfully');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize RPA Service: $e');
      rethrow;
    }
  }

  /// Create a new RPA bot
  Future<BotCreationResult> createBot({
    required String name,
    String? description,
    required List<String> capabilities,
    Map<String, dynamic>? configuration,
    List<String>? tags,
  }) async {
    try {
      debugPrint('🤖 Creating RPA bot: $name');

      final botId = _generateBotId();
      final bot = RPABot(
        botId: botId,
        name: name,
        description: description ?? '',
        capabilities: capabilities,
        configuration: configuration ?? {},
        tags: tags ?? [],
        status: BotStatus.idle,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
        version: '1.0',
        isActive: true,
      );

      _bots[botId] = bot;

      // Initialize bot performance tracking
      _botPerformance[botId] = BotPerformance(
        botId: botId,
        totalExecutions: 0,
        successfulExecutions: 0,
        failedExecutions: 0,
        averageExecutionTime: 0.0,
        uptime: 0.0,
        lastExecution: null,
      );

      // Save to database
      await _saveBot(bot);

      debugPrint('✅ RPA bot created successfully: $botId');
      notifyListeners();

      return BotCreationResult(
        success: true,
        botId: botId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create RPA bot: $e');
      return BotCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create a process definition
  Future<ProcessCreationResult> createProcessDefinition({
    required String name,
    String? description,
    required List<ProcessStep> steps,
    Map<String, dynamic>? variables,
    List<String>? tags,
  }) async {
    try {
      debugPrint('📋 Creating process definition: $name');

      final processId = _generateProcessId();
      final processDefinition = ProcessDefinition(
        processId: processId,
        name: name,
        description: description ?? '',
        steps: steps,
        variables: variables ?? {},
        tags: tags ?? [],
        version: '1.0',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      _processDefinitions[processId] = processDefinition;

      // Validate process definition
      final validationResult = await _validateProcessDefinition(processDefinition);
      if (!validationResult.isValid) {
        return ProcessCreationResult(
          success: false,
          error: 'Process validation failed: ${validationResult.errors.join(', ')}',
        );
      }

      // Save to database
      await _saveProcessDefinition(processDefinition);

      debugPrint('✅ Process definition created successfully: $processId');
      notifyListeners();

      return ProcessCreationResult(
        success: true,
        processId: processId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create process definition: $e');
      return ProcessCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Execute a process
  Future<ProcessExecutionResult> executeProcess({
    required String processId,
    String? botId,
    Map<String, dynamic>? inputVariables,
    ExecutionPriority priority = ExecutionPriority.normal,
  }) async {
    try {
      final processDefinition = _processDefinitions[processId];
      if (processDefinition == null) {
        return ProcessExecutionResult(
          success: false,
          error: 'Process definition not found',
        );
      }

      debugPrint('▶️ Executing process: ${processDefinition.name}');

      final executionId = _generateExecutionId();
      
      // Select bot if not specified
      final selectedBot = botId != null ? _bots[botId] : await _selectBestBot(processDefinition);
      if (selectedBot == null) {
        return ProcessExecutionResult(
          success: false,
          error: 'No suitable bot available',
        );
      }

      // Create bot execution
      final botExecution = BotExecution(
        executionId: executionId,
        botId: selectedBot.botId,
        processId: processId,
        status: ExecutionStatus.running,
        startTime: DateTime.now(),
        variables: {...processDefinition.variables, ...inputVariables ?? {}},
        currentStepIndex: 0,
        priority: priority,
      );

      _botExecutions[executionId] = botExecution;

      // Update bot status
      selectedBot.status = BotStatus.running;
      selectedBot.currentExecutionId = executionId;

      // Execute process steps
      final result = await _executeProcessSteps(botExecution, processDefinition);

      // Update execution status
      botExecution.status = result.success ? ExecutionStatus.completed : ExecutionStatus.failed;
      botExecution.endTime = DateTime.now();
      botExecution.error = result.error;

      // Update bot status
      selectedBot.status = BotStatus.idle;
      selectedBot.currentExecutionId = null;

      // Update performance metrics
      await _updateBotPerformance(selectedBot.botId, result.success, botExecution.endTime!.difference(botExecution.startTime));

      debugPrint('✅ Process execution completed: $executionId');
      notifyListeners();

      return ProcessExecutionResult(
        success: result.success,
        executionId: executionId,
        result: result.result,
        error: result.error,
      );
    } catch (e) {
      debugPrint('❌ Failed to execute process: $e');
      return ProcessExecutionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Schedule process execution
  Future<ScheduleCreationResult> scheduleProcess({
    required String processId,
    required ScheduleFrequency frequency,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? inputVariables,
  }) async {
    try {
      debugPrint('⏰ Scheduling process: $processId');

      final scheduleId = _generateScheduleId();
      final schedule = RPASchedule(
        scheduleId: scheduleId,
        processId: processId,
        frequency: frequency,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate,
        inputVariables: inputVariables ?? {},
        isActive: true,
        lastRun: null,
        nextRun: _calculateNextRun(frequency, startDate ?? DateTime.now()),
        createdAt: DateTime.now(),
      );

      _schedules[scheduleId] = schedule;

      // Save to database
      await _saveSchedule(schedule);

      debugPrint('✅ Process scheduled successfully: $scheduleId');
      notifyListeners();

      return ScheduleCreationResult(
        success: true,
        scheduleId: scheduleId,
        nextRun: schedule.nextRun,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule process: $e');
      return ScheduleCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create automation task
  Future<TaskCreationResult> createTask({
    required String name,
    required TaskType taskType,
    required Map<String, dynamic> configuration,
    String? description,
    List<String>? dependencies,
  }) async {
    try {
      debugPrint('📝 Creating automation task: $name');

      final taskId = _generateTaskId();
      final task = RPATask(
        taskId: taskId,
        name: name,
        description: description ?? '',
        taskType: taskType,
        configuration: configuration,
        dependencies: dependencies ?? [],
        status: TaskStatus.ready,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      _tasks[taskId] = task;

      // Save to database
      await _saveTask(task);

      debugPrint('✅ Automation task created successfully: $taskId');
      notifyListeners();

      return TaskCreationResult(
        success: true,
        taskId: taskId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create automation task: $e');
      return TaskCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Execute data extraction
  Future<DataExtractionResult> extractData({
    required String sourceType,
    required String source,
    required Map<String, dynamic> extractionRules,
  }) async {
    try {
      debugPrint('📊 Extracting data from: $sourceType');

      final extractorId = _generateExtractorId();
      final extractor = DataExtractor(
        extractorId: extractorId,
        sourceType: sourceType,
        source: source,
        extractionRules: extractionRules,
        createdAt: DateTime.now(),
      );

      _dataExtractors[extractorId] = extractor;

      // Execute extraction based on source type
      List<Map<String, dynamic>> extractedData;
      switch (sourceType.toLowerCase()) {
        case 'web':
          extractedData = await _extractFromWeb(source, extractionRules);
          break;
        case 'database':
          extractedData = await _extractFromDatabase(source, extractionRules);
          break;
        case 'file':
          extractedData = await _extractFromFile(source, extractionRules);
          break;
        case 'api':
          extractedData = await _extractFromAPI(source, extractionRules);
          break;
        case 'email':
          extractedData = await _extractFromEmail(source, extractionRules);
          break;
        default:
          throw Exception('Unsupported source type: $sourceType');
      }

      debugPrint('✅ Data extraction completed: ${extractedData.length} records');

      return DataExtractionResult(
        success: true,
        extractorId: extractorId,
        data: extractedData,
        recordCount: extractedData.length,
      );
    } catch (e) {
      debugPrint('❌ Data extraction failed: $e');
      return DataExtractionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Execute form filling
  Future<FormFillingResult> fillForm({
    required String formUrl,
    required Map<String, dynamic> formData,
    Map<String, dynamic>? options,
  }) async {
    try {
      debugPrint('📝 Filling form: $formUrl');

      final fillerId = _generateFillerId();
      final formFiller = FormFiller(
        fillerId: fillerId,
        formUrl: formUrl,
        formData: formData,
        options: options ?? {},
        createdAt: DateTime.now(),
      );

      _formFillers[fillerId] = formFiller;

      // Execute form filling
      final result = await _executeFormFilling(formFiller);

      debugPrint('✅ Form filling completed: $fillerId');

      return FormFillingResult(
        success: result.success,
        fillerId: fillerId,
        submissionId: result.submissionId,
        error: result.error,
      );
    } catch (e) {
      debugPrint('❌ Form filling failed: $e');
      return FormFillingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get bot analytics
  Future<BotAnalyticsResult> getBotAnalytics(String botId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final bot = _bots[botId];
      if (bot == null) {
        return BotAnalyticsResult(
          success: false,
          error: 'Bot not found',
        );
      }

      final performance = _botPerformance[botId];
      if (performance == null) {
        return BotAnalyticsResult(
          success: false,
          error: 'Performance data not found',
        );
      }

      debugPrint('📈 Getting bot analytics: ${bot.name}');

      // Filter executions by date range
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final executions = _botExecutions.values
          .where((exec) => exec.botId == botId && 
                         exec.startTime.isAfter(start) && 
                         exec.startTime.isBefore(end))
          .toList();

      // Calculate analytics
      final analytics = BotAnalytics(
        botId: botId,
        botName: bot.name,
        period: DateRange(start: start, end: end),
        totalExecutions: executions.length,
        successfulExecutions: executions.where((e) => e.status == ExecutionStatus.completed).length,
        failedExecutions: executions.where((e) => e.status == ExecutionStatus.failed).length,
        averageExecutionTime: performance.averageExecutionTime,
        uptime: performance.uptime,
        executionTrends: _calculateExecutionTrends(executions),
        errorAnalysis: await _analyzeErrors(executions),
        performanceMetrics: await _calculatePerformanceMetrics(executions),
      );

      return BotAnalyticsResult(
        success: true,
        analytics: analytics,
      );
    } catch (e) {
      debugPrint('❌ Failed to get bot analytics: $e');
      return BotAnalyticsResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Private Implementation Methods

  Future<void> _initializeRPADatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/rpa_service.db';

    _rpaDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Bots table
        await db.execute('''
          CREATE TABLE rpa_bots (
            bot_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            capabilities TEXT NOT NULL,
            configuration TEXT,
            tags TEXT,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by TEXT NOT NULL,
            version TEXT NOT NULL,
            is_active INTEGER,
            current_execution_id TEXT
          )
        ''');

        // Process definitions table
        await db.execute('''
          CREATE TABLE process_definitions (
            process_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            steps TEXT NOT NULL,
            variables TEXT,
            tags TEXT,
            version TEXT NOT NULL,
            is_active INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by TEXT NOT NULL
          )
        ''');

        // Bot executions table
        await db.execute('''
          CREATE TABLE bot_executions (
            execution_id TEXT PRIMARY KEY,
            bot_id TEXT NOT NULL,
            process_id TEXT NOT NULL,
            status TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            variables TEXT,
            current_step_index INTEGER,
            priority TEXT NOT NULL,
            error TEXT,
            FOREIGN KEY (bot_id) REFERENCES rpa_bots (bot_id),
            FOREIGN KEY (process_id) REFERENCES process_definitions (process_id)
          )
        ''');

        // Tasks table
        await db.execute('''
          CREATE TABLE rpa_tasks (
            task_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            task_type TEXT NOT NULL,
            configuration TEXT NOT NULL,
            dependencies TEXT,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by TEXT NOT NULL
          )
        ''');

        // Schedules table
        await db.execute('''
          CREATE TABLE rpa_schedules (
            schedule_id TEXT PRIMARY KEY,
            process_id TEXT NOT NULL,
            frequency TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            input_variables TEXT,
            is_active INTEGER,
            last_run TEXT,
            next_run TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (process_id) REFERENCES process_definitions (process_id)
          )
        ''');

        // Execution logs table
        await db.execute('''
          CREATE TABLE execution_logs (
            log_id TEXT PRIMARY KEY,
            execution_id TEXT NOT NULL,
            log_level TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            step_index INTEGER,
            details TEXT
          )
        ''');
      },
    );

    debugPrint('✅ RPA database initialized');
  }

  Future<void> _loadBots() async {
    // Load bots from database
    debugPrint('🤖 Loading RPA bots...');
  }

  Future<void> _loadProcessDefinitions() async {
    // Load process definitions from database
    debugPrint('📋 Loading process definitions...');
  }

  Future<void> _loadTasks() async {
    // Load tasks from database
    debugPrint('📝 Loading tasks...');
  }

  Future<void> _loadSchedules() async {
    // Load schedules from database
    debugPrint('⏰ Loading schedules...');
  }

  Future<void> _initializeDefaultComponents() async {
    // Create default healthcare automation bots
    await _createHealthcareBots();
    
    // Create default process definitions
    await _createDefaultProcesses();
    
    // Create default automation actions
    await _createDefaultActions();

    debugPrint('✅ Default RPA components initialized');
  }

  Future<void> _createHealthcareBots() async {
    // Create patient registration bot
    await createBot(
      name: 'Patient Registration Bot',
      description: 'Automates patient registration and data entry processes',
      capabilities: ['form_filling', 'data_validation', 'database_operations'],
      configuration: {
        'maxConcurrentTasks': 5,
        'retryAttempts': 3,
        'timeout': 300,
      },
      tags: ['healthcare', 'registration', 'patient'],
    );

    // Create appointment scheduling bot
    await createBot(
      name: 'Appointment Scheduling Bot',
      description: 'Automates appointment scheduling and calendar management',
      capabilities: ['calendar_integration', 'notification_sending', 'conflict_resolution'],
      configuration: {
        'maxConcurrentTasks': 10,
        'retryAttempts': 2,
        'timeout': 180,
      },
      tags: ['healthcare', 'scheduling', 'appointments'],
    );

    // Create billing automation bot
    await createBot(
      name: 'Billing Automation Bot',
      description: 'Automates billing processes and invoice generation',
      capabilities: ['invoice_generation', 'payment_processing', 'report_generation'],
      configuration: {
        'maxConcurrentTasks': 3,
        'retryAttempts': 5,
        'timeout': 600,
      },
      tags: ['healthcare', 'billing', 'finance'],
    );
  }

  Future<void> _createDefaultProcesses() async {
    // Create patient onboarding process
    await createProcessDefinition(
      name: 'Patient Onboarding Process',
      description: 'Complete patient onboarding workflow',
      steps: [
        ProcessStep(
          stepId: 'validate_patient_data',
          name: 'Validate Patient Data',
          actionType: ActionType.dataValidation,
          configuration: {
            'requiredFields': ['name', 'email', 'phone', 'dateOfBirth'],
            'validationRules': {
              'email': r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              'phone': r'^\+?[\d\s-()]+$',
            },
          },
          order: 1,
        ),
        ProcessStep(
          stepId: 'create_patient_record',
          name: 'Create Patient Record',
          actionType: ActionType.databaseOperation,
          configuration: {
            'operation': 'insert',
            'table': 'patients',
            'fields': ['name', 'email', 'phone', 'date_of_birth', 'created_at'],
          },
          order: 2,
        ),
        ProcessStep(
          stepId: 'send_welcome_email',
          name: 'Send Welcome Email',
          actionType: ActionType.emailSending,
          configuration: {
            'template': 'patient_welcome',
            'recipient': '{{patient_email}}',
            'subject': 'Welcome to Our Healthcare System',
          },
          order: 3,
        ),
      ],
      variables: {
        'patient_name': '',
        'patient_email': '',
        'patient_phone': '',
        'patient_dob': '',
      },
      tags: ['healthcare', 'onboarding', 'patient'],
    );

    // Create appointment reminder process
    await createProcessDefinition(
      name: 'Appointment Reminder Process',
      description: 'Automated appointment reminder system',
      steps: [
        ProcessStep(
          stepId: 'fetch_upcoming_appointments',
          name: 'Fetch Upcoming Appointments',
          actionType: ActionType.databaseQuery,
          configuration: {
            'query': 'SELECT * FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND status = "scheduled"',
            'parameters': ['tomorrow', 'next_week'],
          },
          order: 1,
        ),
        ProcessStep(
          stepId: 'send_reminders',
          name: 'Send Appointment Reminders',
          actionType: ActionType.bulkEmailSending,
          configuration: {
            'template': 'appointment_reminder',
            'batchSize': 50,
          },
          order: 2,
        ),
      ],
      variables: {
        'reminder_days': 1,
        'batch_size': 50,
      },
      tags: ['healthcare', 'appointments', 'reminders'],
    );
  }

  Future<void> _createDefaultActions() async {
    // Create default automation actions
    _automationActions['data_validation'] = AutomationAction(
      actionId: 'data_validation',
      name: 'Data Validation',
      actionType: ActionType.dataValidation,
      configuration: {
        'validationEngine': 'regex_based',
        'errorHandling': 'collect_and_report',
      },
    );

    _automationActions['form_filling'] = AutomationAction(
      actionId: 'form_filling',
      name: 'Form Filling',
      actionType: ActionType.formFilling,
      configuration: {
        'browser': 'headless_chrome',
        'waitStrategy': 'element_visible',
        'timeout': 30,
      },
    );

    _automationActions['email_sending'] = AutomationAction(
      actionId: 'email_sending',
      name: 'Email Sending',
      actionType: ActionType.emailSending,
      configuration: {
        'smtpServer': 'localhost',
        'port': 587,
        'encryption': 'tls',
      },
    );
  }

  void _startExecutionEngine() {
    _executionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _processExecutionQueue();
      _processScheduledTasks();
    });
  }

  void _startMonitoringService() {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _monitorBotHealth();
      _updatePerformanceMetrics();
    });
  }

  Future<void> _processExecutionQueue() async {
    if (_executionQueue.isEmpty) return;

    // Process high-priority tasks first
    _executionQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    final tasksToProcess = _executionQueue.take(5).toList();
    _executionQueue.removeRange(0, tasksToProcess.length);

    for (final taskExecution in tasksToProcess) {
      try {
        await _executeTask(taskExecution);
      } catch (e) {
        debugPrint('❌ Failed to execute task ${taskExecution.taskId}: $e');
      }
    }
  }

  Future<void> _processScheduledTasks() async {
    final now = DateTime.now();
    
    for (final schedule in _schedules.values) {
      if (schedule.isActive && schedule.nextRun.isBefore(now)) {
        try {
          debugPrint('⏰ Processing scheduled task: ${schedule.scheduleId}');
          
          // Execute process
          final result = await executeProcess(
            processId: schedule.processId,
            inputVariables: schedule.inputVariables,
            priority: ExecutionPriority.scheduled,
          );
          
          // Update schedule
          schedule.lastRun = now;
          schedule.nextRun = _calculateNextRun(schedule.frequency, now);
          
          await _saveSchedule(schedule);
          
          if (result.success) {
            debugPrint('✅ Scheduled task completed successfully');
          } else {
            debugPrint('❌ Scheduled task failed: ${result.error}');
          }
        } catch (e) {
          debugPrint('❌ Failed to process scheduled task: $e');
        }
      }
    }
  }

  Future<void> _monitorBotHealth() async {
    for (final bot in _bots.values) {
      // Check bot health and status
      if (bot.status == BotStatus.running && bot.currentExecutionId != null) {
        final execution = _botExecutions[bot.currentExecutionId];
        if (execution != null) {
          final runningTime = DateTime.now().difference(execution.startTime);
          
          // Check for stuck executions (running for more than 30 minutes)
          if (runningTime.inMinutes > 30) {
            debugPrint('⚠️ Bot ${bot.name} appears to be stuck, attempting recovery');
            await _recoverStuckBot(bot, execution);
          }
        }
      }
    }
  }

  Future<void> _updatePerformanceMetrics() async {
    for (final botId in _bots.keys) {
      final performance = _botPerformance[botId];
      if (performance != null) {
        // Update uptime calculation
        final totalTime = DateTime.now().difference(_bots[botId]!.createdAt);
        final downtime = 0; // Calculate actual downtime
        performance.uptime = ((totalTime.inMinutes - downtime) / totalTime.inMinutes) * 100;
      }
    }
  }

  Future<ValidationResult> _validateProcessDefinition(ProcessDefinition processDefinition) async {
    final errors = <String>[];
    
    // Validate steps
    if (processDefinition.steps.isEmpty) {
      errors.add('Process must have at least one step');
    }
    
    // Check for duplicate step IDs
    final stepIds = processDefinition.steps.map((s) => s.stepId).toList();
    final uniqueStepIds = stepIds.toSet();
    if (stepIds.length != uniqueStepIds.length) {
      errors.add('Process steps must have unique IDs');
    }
    
    // Validate step order
    final orders = processDefinition.steps.map((s) => s.order).toList();
    orders.sort();
    for (int i = 0; i < orders.length; i++) {
      if (orders[i] != i + 1) {
        errors.add('Process steps must have sequential order starting from 1');
        break;
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Future<RPABot?> _selectBestBot(ProcessDefinition processDefinition) async {
    // Find available bots that can handle the process
    final availableBots = _bots.values
        .where((bot) => bot.isActive && bot.status == BotStatus.idle)
        .toList();
    
    if (availableBots.isEmpty) return null;
    
    // Score bots based on capabilities and performance
    RPABot? bestBot;
    double bestScore = 0.0;
    
    for (final bot in availableBots) {
      double score = 0.0;
      
      // Check capability match
      final requiredCapabilities = _getRequiredCapabilities(processDefinition);
      final matchedCapabilities = bot.capabilities.where((cap) => requiredCapabilities.contains(cap)).length;
      score += (matchedCapabilities / requiredCapabilities.length) * 50;
      
      // Consider performance metrics
      final performance = _botPerformance[bot.botId];
      if (performance != null) {
        score += (performance.successfulExecutions / max(performance.totalExecutions, 1)) * 30;
        score += min(performance.uptime / 100, 1.0) * 20;
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestBot = bot;
      }
    }
    
    return bestBot;
  }

  List<String> _getRequiredCapabilities(ProcessDefinition processDefinition) {
    final capabilities = <String>[];
    
    for (final step in processDefinition.steps) {
      switch (step.actionType) {
        case ActionType.formFilling:
          capabilities.add('form_filling');
          break;
        case ActionType.dataValidation:
          capabilities.add('data_validation');
          break;
        case ActionType.databaseOperation:
          capabilities.add('database_operations');
          break;
        case ActionType.emailSending:
          capabilities.add('email_sending');
          break;
        case ActionType.webScraping:
          capabilities.add('web_scraping');
          break;
        case ActionType.fileProcessing:
          capabilities.add('file_processing');
          break;
        case ActionType.apiCall:
          capabilities.add('api_integration');
          break;
      }
    }
    
    return capabilities.toSet().toList();
  }

  Future<StepExecutionResult> _executeProcessSteps(BotExecution execution, ProcessDefinition processDefinition) async {
    for (int i = execution.currentStepIndex; i < processDefinition.steps.length; i++) {
      final step = processDefinition.steps[i];
      
      try {
        debugPrint('🔄 Executing step: ${step.name}');
        
        // Log step start
        await _logExecution(execution.executionId, 'info', 'Starting step: ${step.name}', i);
        
        // Execute step
        final stepResult = await _executeProcessStep(step, execution.variables);
        
        if (!stepResult.success) {
          await _logExecution(execution.executionId, 'error', 'Step failed: ${stepResult.error}', i);
          return StepExecutionResult(
            success: false,
            error: 'Step ${step.name} failed: ${stepResult.error}',
          );
        }
        
        // Update variables with step output
        if (stepResult.outputVariables != null) {
          execution.variables.addAll(stepResult.outputVariables!);
        }
        
        // Update current step
        execution.currentStepIndex = i + 1;
        
        await _logExecution(execution.executionId, 'info', 'Step completed successfully', i);
        
      } catch (e) {
        await _logExecution(execution.executionId, 'error', 'Step execution error: $e', i);
        return StepExecutionResult(
          success: false,
          error: 'Step ${step.name} error: $e',
        );
      }
    }
    
    return StepExecutionResult(
      success: true,
      result: execution.variables,
    );
  }

  Future<StepExecutionResult> _executeProcessStep(ProcessStep step, Map<String, dynamic> variables) async {
    switch (step.actionType) {
      case ActionType.dataValidation:
        return await _executeDataValidation(step, variables);
      case ActionType.formFilling:
        return await _executeFormFilling(step, variables);
      case ActionType.databaseOperation:
        return await _executeDatabaseOperation(step, variables);
      case ActionType.emailSending:
        return await _executeEmailSending(step, variables);
      case ActionType.webScraping:
        return await _executeWebScraping(step, variables);
      case ActionType.fileProcessing:
        return await _executeFileProcessing(step, variables);
      case ActionType.apiCall:
        return await _executeAPICall(step, variables);
      case ActionType.databaseQuery:
        return await _executeDatabaseQuery(step, variables);
      case ActionType.bulkEmailSending:
        return await _executeBulkEmailSending(step, variables);
    }
  }

  Future<StepExecutionResult> _executeDataValidation(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute data validation
    final config = step.configuration;
    final requiredFields = config['requiredFields'] as List<String>? ?? [];
    final validationRules = config['validationRules'] as Map<String, String>? ?? {};
    
    final errors = <String>[];
    
    // Check required fields
    for (final field in requiredFields) {
      if (!variables.containsKey(field) || variables[field] == null || variables[field].toString().isEmpty) {
        errors.add('Required field missing: $field');
      }
    }
    
    // Apply validation rules
    for (final entry in validationRules.entries) {
      final field = entry.key;
      final pattern = entry.value;
      final value = variables[field]?.toString() ?? '';
      
      if (value.isNotEmpty && !RegExp(pattern).hasMatch(value)) {
        errors.add('Validation failed for field $field');
      }
    }
    
    return StepExecutionResult(
      success: errors.isEmpty,
      error: errors.isNotEmpty ? errors.join(', ') : null,
      outputVariables: {'validation_errors': errors},
    );
  }

  Future<StepExecutionResult> _executeFormFilling(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute form filling
    await Future.delayed(const Duration(seconds: 2)); // Simulate form filling
    
    return StepExecutionResult(
      success: true,
      outputVariables: {'form_submission_id': _generateSubmissionId()},
    );
  }

  Future<StepExecutionResult> _executeDatabaseOperation(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute database operation
    final config = step.configuration;
    final operation = config['operation'] as String;
    final table = config['table'] as String;
    
    switch (operation.toLowerCase()) {
      case 'insert':
        // Simulate database insert
        await Future.delayed(const Duration(milliseconds: 500));
        return StepExecutionResult(
          success: true,
          outputVariables: {'inserted_id': Random().nextInt(10000)},
        );
      case 'update':
        // Simulate database update
        await Future.delayed(const Duration(milliseconds: 300));
        return StepExecutionResult(
          success: true,
          outputVariables: {'updated_rows': Random().nextInt(5) + 1},
        );
      case 'delete':
        // Simulate database delete
        await Future.delayed(const Duration(milliseconds: 200));
        return StepExecutionResult(
          success: true,
          outputVariables: {'deleted_rows': Random().nextInt(3) + 1},
        );
      default:
        return StepExecutionResult(
          success: false,
          error: 'Unsupported database operation: $operation',
        );
    }
  }

  Future<StepExecutionResult> _executeEmailSending(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute email sending
    final config = step.configuration;
    final template = config['template'] as String;
    final recipient = _replaceVariables(config['recipient'] as String, variables);
    final subject = _replaceVariables(config['subject'] as String, variables);
    
    // Simulate email sending
    await Future.delayed(const Duration(milliseconds: 800));
    
    return StepExecutionResult(
      success: true,
      outputVariables: {
        'email_sent_to': recipient,
        'email_subject': subject,
        'email_id': _generateEmailId(),
      },
    );
  }

  Future<StepExecutionResult> _executeWebScraping(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute web scraping
    await Future.delayed(const Duration(seconds: 3)); // Simulate scraping
    
    return StepExecutionResult(
      success: true,
      outputVariables: {
        'scraped_data': [
          {'title': 'Sample Data 1', 'value': 'Value 1'},
          {'title': 'Sample Data 2', 'value': 'Value 2'},
        ],
      },
    );
  }

  Future<StepExecutionResult> _executeFileProcessing(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute file processing
    await Future.delayed(const Duration(seconds: 1)); // Simulate processing
    
    return StepExecutionResult(
      success: true,
      outputVariables: {'processed_files': 1, 'output_path': '/processed/file.xlsx'},
    );
  }

  Future<StepExecutionResult> _executeAPICall(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute API call
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate API call
    
    return StepExecutionResult(
      success: true,
      outputVariables: {
        'api_response': {'status': 'success', 'data': 'Sample API response'},
        'response_code': 200,
      },
    );
  }

  Future<StepExecutionResult> _executeDatabaseQuery(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute database query
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate query
    
    return StepExecutionResult(
      success: true,
      outputVariables: {
        'query_results': [
          {'id': 1, 'name': 'John Doe', 'appointment_date': '2024-03-15'},
          {'id': 2, 'name': 'Jane Smith', 'appointment_date': '2024-03-16'},
        ],
      },
    );
  }

  Future<StepExecutionResult> _executeBulkEmailSending(ProcessStep step, Map<String, dynamic> variables) async {
    // Execute bulk email sending
    final queryResults = variables['query_results'] as List<dynamic>? ?? [];
    
    await Future.delayed(Duration(milliseconds: queryResults.length * 100)); // Simulate bulk sending
    
    return StepExecutionResult(
      success: true,
      outputVariables: {
        'emails_sent': queryResults.length,
        'batch_id': _generateBatchId(),
      },
    );
  }

  Future<void> _executeTask(TaskExecution taskExecution) async {
    // Execute individual task
    debugPrint('⚡ Executing task: ${taskExecution.taskId}');
    
    // Simulate task execution
    await Future.delayed(Duration(seconds: Random().nextInt(5) + 1));
    
    taskExecution.status = TaskStatus.completed;
    taskExecution.endTime = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _extractFromWeb(String url, Map<String, dynamic> rules) async {
    // Simulate web scraping
    await Future.delayed(const Duration(seconds: 2));
    
    return [
      {'title': 'Web Data 1', 'content': 'Content from web page'},
      {'title': 'Web Data 2', 'content': 'More content from web page'},
    ];
  }

  Future<List<Map<String, dynamic>>> _extractFromDatabase(String connectionString, Map<String, dynamic> rules) async {
    // Simulate database extraction
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      {'id': 1, 'name': 'Database Record 1', 'value': 100},
      {'id': 2, 'name': 'Database Record 2', 'value': 200},
    ];
  }

  Future<List<Map<String, dynamic>>> _extractFromFile(String filePath, Map<String, dynamic> rules) async {
    // Simulate file extraction
    await Future.delayed(const Duration(milliseconds: 1200));
    
    return [
      {'row': 1, 'column1': 'File Data 1', 'column2': 'Value 1'},
      {'row': 2, 'column1': 'File Data 2', 'column2': 'Value 2'},
    ];
  }

  Future<List<Map<String, dynamic>>> _extractFromAPI(String apiUrl, Map<String, dynamic> rules) async {
    // Simulate API extraction
    await Future.delayed(const Duration(milliseconds: 1500));
    
    return [
      {'id': 1, 'api_data': 'API Response 1', 'timestamp': DateTime.now().toIso8601String()},
      {'id': 2, 'api_data': 'API Response 2', 'timestamp': DateTime.now().toIso8601String()},
    ];
  }

  Future<List<Map<String, dynamic>>> _extractFromEmail(String emailConfig, Map<String, dynamic> rules) async {
    // Simulate email extraction
    await Future.delayed(const Duration(seconds: 3));
    
    return [
      {'subject': 'Email Subject 1', 'sender': 'sender1@example.com', 'body': 'Email content'},
      {'subject': 'Email Subject 2', 'sender': 'sender2@example.com', 'body': 'More email content'},
    ];
  }

  Future<FormFillingExecutionResult> _executeFormFilling(FormFiller formFiller) async {
    // Simulate form filling execution
    await Future.delayed(const Duration(seconds: 2));
    
    return FormFillingExecutionResult(
      success: true,
      submissionId: _generateSubmissionId(),
    );
  }

  Future<void> _updateBotPerformance(String botId, bool success, Duration executionTime) async {
    final performance = _botPerformance[botId];
    if (performance != null) {
      performance.totalExecutions++;
      if (success) {
        performance.successfulExecutions++;
      } else {
        performance.failedExecutions++;
      }
      
      // Update average execution time
      performance.averageExecutionTime = 
        (performance.averageExecutionTime * (performance.totalExecutions - 1) + executionTime.inMilliseconds) / 
        performance.totalExecutions;
      
      performance.lastExecution = DateTime.now();
    }
  }

  Future<void> _recoverStuckBot(RPABot bot, BotExecution execution) async {
    // Implement bot recovery logic
    debugPrint('🔧 Recovering stuck bot: ${bot.name}');
    
    // Mark execution as failed
    execution.status = ExecutionStatus.failed;
    execution.endTime = DateTime.now();
    execution.error = 'Execution timeout - bot recovered';
    
    // Reset bot status
    bot.status = BotStatus.idle;
    bot.currentExecutionId = null;
    
    // Log recovery action
    await _logExecution(execution.executionId, 'warning', 'Bot recovered from stuck state', null);
  }

  DateTime _calculateNextRun(ScheduleFrequency frequency, DateTime baseDate) {
    switch (frequency) {
      case ScheduleFrequency.hourly:
        return baseDate.add(const Duration(hours: 1));
      case ScheduleFrequency.daily:
        return DateTime(baseDate.year, baseDate.month, baseDate.day + 1, 9, 0);
      case ScheduleFrequency.weekly:
        return baseDate.add(const Duration(days: 7));
      case ScheduleFrequency.monthly:
        return DateTime(baseDate.year, baseDate.month + 1, 1, 9, 0);
    }
  }

  Map<String, int> _calculateExecutionTrends(List<BotExecution> executions) {
    final trends = <String, int>{};
    
    for (final execution in executions) {
      final dateKey = execution.startTime.toIso8601String().substring(0, 10);
      trends[dateKey] = (trends[dateKey] ?? 0) + 1;
    }
    
    return trends;
  }

  Future<Map<String, int>> _analyzeErrors(List<BotExecution> executions) async {
    final errorAnalysis = <String, int>{};
    
    for (final execution in executions) {
      if (execution.status == ExecutionStatus.failed && execution.error != null) {
        final errorType = _categorizeError(execution.error!);
        errorAnalysis[errorType] = (errorAnalysis[errorType] ?? 0) + 1;
      }
    }
    
    return errorAnalysis;
  }

  String _categorizeError(String error) {
    if (error.toLowerCase().contains('timeout')) return 'Timeout';
    if (error.toLowerCase().contains('network')) return 'Network';
    if (error.toLowerCase().contains('validation')) return 'Validation';
    if (error.toLowerCase().contains('database')) return 'Database';
    if (error.toLowerCase().contains('permission')) return 'Permission';
    return 'Other';
  }

  Future<Map<String, double>> _calculatePerformanceMetrics(List<BotExecution> executions) async {
    if (executions.isEmpty) {
      return {
        'averageExecutionTime': 0.0,
        'successRate': 0.0,
        'throughput': 0.0,
      };
    }
    
    final completedExecutions = executions.where((e) => e.endTime != null).toList();
    final executionTimes = completedExecutions
        .map((e) => e.endTime!.difference(e.startTime).inMilliseconds)
        .toList();
    
    final averageExecutionTime = executionTimes.isEmpty ? 0.0 : 
        executionTimes.reduce((a, b) => a + b) / executionTimes.length;
    
    final successfulExecutions = executions.where((e) => e.status == ExecutionStatus.completed).length;
    final successRate = (successfulExecutions / executions.length) * 100;
    
    // Calculate throughput (executions per hour)
    final timeSpan = executions.last.startTime.difference(executions.first.startTime);
    final throughput = timeSpan.inHours > 0 ? executions.length / timeSpan.inHours : 0.0;
    
    return {
      'averageExecutionTime': averageExecutionTime,
      'successRate': successRate,
      'throughput': throughput,
    };
  }

  String _replaceVariables(String template, Map<String, dynamic> variables) {
    String result = template;
    
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value.toString());
    }
    
    return result;
  }

  Future<void> _logExecution(String executionId, String level, String message, int? stepIndex) async {
    final log = RPALog(
      logId: _generateLogId(),
      executionId: executionId,
      logLevel: level,
      message: message,
      timestamp: DateTime.now(),
      stepIndex: stepIndex,
      details: {},
    );

    _executionLogs.add(log);

    // Save to database
    if (_rpaDb != null) {
      await _rpaDb!.insert('execution_logs', {
        'log_id': log.logId,
        'execution_id': log.executionId,
        'log_level': log.logLevel,
        'message': log.message,
        'timestamp': log.timestamp.toIso8601String(),
        'step_index': log.stepIndex,
        'details': jsonEncode(log.details),
      });
    }
  }

  String _generateBotId() {
    return 'bot_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateProcessId() {
    return 'process_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateExecutionId() {
    return 'exec_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateScheduleId() {
    return 'schedule_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateExtractorId() {
    return 'extractor_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateFillerId() {
    return 'filler_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateSubmissionId() {
    return 'submission_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateEmailId() {
    return 'email_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Future<void> _saveBot(RPABot bot) async {
    if (_rpaDb == null) return;

    await _rpaDb!.insert('rpa_bots', {
      'bot_id': bot.botId,
      'name': bot.name,
      'description': bot.description,
      'capabilities': jsonEncode(bot.capabilities),
      'configuration': jsonEncode(bot.configuration),
      'tags': jsonEncode(bot.tags),
      'status': bot.status.toString().split('.').last,
      'created_at': bot.createdAt.toIso8601String(),
      'updated_at': bot.updatedAt.toIso8601String(),
      'created_by': bot.createdBy,
      'version': bot.version,
      'is_active': bot.isActive ? 1 : 0,
      'current_execution_id': bot.currentExecutionId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveProcessDefinition(ProcessDefinition processDefinition) async {
    if (_rpaDb == null) return;

    await _rpaDb!.insert('process_definitions', {
      'process_id': processDefinition.processId,
      'name': processDefinition.name,
      'description': processDefinition.description,
      'steps': jsonEncode(processDefinition.steps.map((s) => s.toJson()).toList()),
      'variables': jsonEncode(processDefinition.variables),
      'tags': jsonEncode(processDefinition.tags),
      'version': processDefinition.version,
      'is_active': processDefinition.isActive ? 1 : 0,
      'created_at': processDefinition.createdAt.toIso8601String(),
      'updated_at': processDefinition.updatedAt.toIso8601String(),
      'created_by': processDefinition.createdBy,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveTask(RPATask task) async {
    if (_rpaDb == null) return;

    await _rpaDb!.insert('rpa_tasks', {
      'task_id': task.taskId,
      'name': task.name,
      'description': task.description,
      'task_type': task.taskType.toString().split('.').last,
      'configuration': jsonEncode(task.configuration),
      'dependencies': jsonEncode(task.dependencies),
      'status': task.status.toString().split('.').last,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
      'created_by': task.createdBy,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveSchedule(RPASchedule schedule) async {
    if (_rpaDb == null) return;

    await _rpaDb!.insert('rpa_schedules', {
      'schedule_id': schedule.scheduleId,
      'process_id': schedule.processId,
      'frequency': schedule.frequency.toString().split('.').last,
      'start_date': schedule.startDate.toIso8601String(),
      'end_date': schedule.endDate?.toIso8601String(),
      'input_variables': jsonEncode(schedule.inputVariables),
      'is_active': schedule.isActive ? 1 : 0,
      'last_run': schedule.lastRun?.toIso8601String(),
      'next_run': schedule.nextRun.toIso8601String(),
      'created_at': schedule.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Dispose resources
  @override
  void dispose() {
    _executionTimer?.cancel();
    _monitoringTimer?.cancel();
    _rpaDb?.close();
    super.dispose();
  }
}

// Data Models and Enums

enum BotStatus { idle, running, paused, error, maintenance }
enum ExecutionStatus { queued, running, completed, failed, cancelled }
enum TaskStatus { ready, running, completed, failed, cancelled }
enum ActionType { 
  dataValidation, 
  formFilling, 
  databaseOperation, 
  emailSending, 
  webScraping, 
  fileProcessing, 
  apiCall,
  databaseQuery,
  bulkEmailSending,
}
enum TaskType { automation, monitoring, maintenance, reporting }
enum ExecutionPriority { low, normal, high, critical, scheduled }
enum ScheduleFrequency { hourly, daily, weekly, monthly }

class RPABot {
  final String botId;
  final String name;
  final String description;
  final List<String> capabilities;
  final Map<String, dynamic> configuration;
  final List<String> tags;
  BotStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  final String createdBy;
  final String version;
  final bool isActive;
  String? currentExecutionId;

  RPABot({
    required this.botId,
    required this.name,
    required this.description,
    required this.capabilities,
    required this.configuration,
    required this.tags,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.version,
    required this.isActive,
    this.currentExecutionId,
  });
}

class ProcessDefinition {
  final String processId;
  final String name;
  final String description;
  final List<ProcessStep> steps;
  final Map<String, dynamic> variables;
  final List<String> tags;
  final String version;
  final bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;
  final String createdBy;

  ProcessDefinition({
    required this.processId,
    required this.name,
    required this.description,
    required this.steps,
    required this.variables,
    required this.tags,
    required this.version,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });
}

class ProcessStep {
  final String stepId;
  final String name;
  final ActionType actionType;
  final Map<String, dynamic> configuration;
  final int order;
  final List<String> dependencies;

  ProcessStep({
    required this.stepId,
    required this.name,
    required this.actionType,
    required this.configuration,
    required this.order,
    this.dependencies = const [],
  });

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'name': name,
    'actionType': actionType.toString().split('.').last,
    'configuration': configuration,
    'order': order,
    'dependencies': dependencies,
  };
}

class BotExecution {
  final String executionId;
  final String botId;
  final String processId;
  ExecutionStatus status;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic> variables;
  int currentStepIndex;
  final ExecutionPriority priority;
  String? error;

  BotExecution({
    required this.executionId,
    required this.botId,
    required this.processId,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.variables,
    required this.currentStepIndex,
    required this.priority,
    this.error,
  });
}

class RPATask {
  final String taskId;
  final String name;
  final String description;
  final TaskType taskType;
  final Map<String, dynamic> configuration;
  final List<String> dependencies;
  TaskStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  final String createdBy;

  RPATask({
    required this.taskId,
    required this.name,
    required this.description,
    required this.taskType,
    required this.configuration,
    required this.dependencies,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });
}

class TaskExecution {
  final String taskId;
  final String executionId;
  final ExecutionPriority priority;
  TaskStatus status;
  final DateTime startTime;
  DateTime? endTime;
  String? error;

  TaskExecution({
    required this.taskId,
    required this.executionId,
    required this.priority,
    required this.status,
    required this.startTime,
    this.endTime,
    this.error,
  });
}

class ActivityDefinition {
  final String activityId;
  final String name;
  final String description;
  final ActionType actionType;
  final Map<String, dynamic> configuration;
  final Duration timeout;

  ActivityDefinition({
    required this.activityId,
    required this.name,
    required this.description,
    required this.actionType,
    required this.configuration,
    required this.timeout,
  });
}

class AutomationAction {
  final String actionId;
  final String name;
  final ActionType actionType;
  final Map<String, dynamic> configuration;

  AutomationAction({
    required this.actionId,
    required this.name,
    required this.actionType,
    required this.configuration,
  });
}

class DataExtractor {
  final String extractorId;
  final String sourceType;
  final String source;
  final Map<String, dynamic> extractionRules;
  final DateTime createdAt;

  DataExtractor({
    required this.extractorId,
    required this.sourceType,
    required this.source,
    required this.extractionRules,
    required this.createdAt,
  });
}

class FormFiller {
  final String fillerId;
  final String formUrl;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> options;
  final DateTime createdAt;

  FormFiller({
    required this.fillerId,
    required this.formUrl,
    required this.formData,
    required this.options,
    required this.createdAt,
  });
}

class BotPerformance {
  final String botId;
  int totalExecutions;
  int successfulExecutions;
  int failedExecutions;
  double averageExecutionTime;
  double uptime;
  DateTime? lastExecution;

  BotPerformance({
    required this.botId,
    required this.totalExecutions,
    required this.successfulExecutions,
    required this.failedExecutions,
    required this.averageExecutionTime,
    required this.uptime,
    this.lastExecution,
  });
}

class ExecutionMetrics {
  final String executionId;
  final Duration executionTime;
  final int stepsCompleted;
  final int stepsTotal;
  final bool success;
  final DateTime timestamp;

  ExecutionMetrics({
    required this.executionId,
    required this.executionTime,
    required this.stepsCompleted,
    required this.stepsTotal,
    required this.success,
    required this.timestamp,
  });
}

class RPALog {
  final String logId;
  final String executionId;
  final String logLevel;
  final String message;
  final DateTime timestamp;
  final int? stepIndex;
  final Map<String, dynamic> details;

  RPALog({
    required this.logId,
    required this.executionId,
    required this.logLevel,
    required this.message,
    required this.timestamp,
    this.stepIndex,
    required this.details,
  });
}

class ErrorHandler {
  final String handlerId;
  final String errorType;
  final String handlingStrategy;
  final Map<String, dynamic> configuration;

  ErrorHandler({
    required this.handlerId,
    required this.errorType,
    required this.handlingStrategy,
    required this.configuration,
  });
}

class RecoveryStrategy {
  final String strategyId;
  final String name;
  final List<String> recoverySteps;
  final int maxRetries;
  final Duration retryDelay;

  RecoveryStrategy({
    required this.strategyId,
    required this.name,
    required this.recoverySteps,
    required this.maxRetries,
    required this.retryDelay,
  });
}

class RPASchedule {
  final String scheduleId;
  final String processId;
  final ScheduleFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic> inputVariables;
  final bool isActive;
  DateTime? lastRun;
  DateTime nextRun;
  final DateTime createdAt;

  RPASchedule({
    required this.scheduleId,
    required this.processId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.inputVariables,
    required this.isActive,
    this.lastRun,
    required this.nextRun,
    required this.createdAt,
  });
}

class EventTrigger {
  final String triggerId;
  final String eventType;
  final String processId;
  final Map<String, dynamic> triggerConditions;
  final bool isActive;

  EventTrigger({
    required this.triggerId,
    required this.eventType,
    required this.processId,
    required this.triggerConditions,
    required this.isActive,
  });
}

class BotAnalytics {
  final String botId;
  final String botName;
  final DateRange period;
  final int totalExecutions;
  final int successfulExecutions;
  final int failedExecutions;
  final double averageExecutionTime;
  final double uptime;
  final Map<String, int> executionTrends;
  final Map<String, int> errorAnalysis;
  final Map<String, double> performanceMetrics;

  BotAnalytics({
    required this.botId,
    required this.botName,
    required this.period,
    required this.totalExecutions,
    required this.successfulExecutions,
    required this.failedExecutions,
    required this.averageExecutionTime,
    required this.uptime,
    required this.executionTrends,
    required this.errorAnalysis,
    required this.performanceMetrics,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

// Result Classes

class BotCreationResult {
  final bool success;
  final String? botId;
  final String? error;

  BotCreationResult({
    required this.success,
    this.botId,
    this.error,
  });
}

class ProcessCreationResult {
  final bool success;
  final String? processId;
  final String? error;

  ProcessCreationResult({
    required this.success,
    this.processId,
    this.error,
  });
}

class ProcessExecutionResult {
  final bool success;
  final String? executionId;
  final Map<String, dynamic>? result;
  final String? error;

  ProcessExecutionResult({
    required this.success,
    this.executionId,
    this.result,
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

class TaskCreationResult {
  final bool success;
  final String? taskId;
  final String? error;

  TaskCreationResult({
    required this.success,
    this.taskId,
    this.error,
  });
}

class DataExtractionResult {
  final bool success;
  final String? extractorId;
  final List<Map<String, dynamic>>? data;
  final int? recordCount;
  final String? error;

  DataExtractionResult({
    required this.success,
    this.extractorId,
    this.data,
    this.recordCount,
    this.error,
  });
}

class FormFillingResult {
  final bool success;
  final String? fillerId;
  final String? submissionId;
  final String? error;

  FormFillingResult({
    required this.success,
    this.fillerId,
    this.submissionId,
    this.error,
  });
}

class BotAnalyticsResult {
  final bool success;
  final BotAnalytics? analytics;
  final String? error;

  BotAnalyticsResult({
    required this.success,
    this.analytics,
    this.error,
  });
}

class StepExecutionResult {
  final bool success;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? outputVariables;
  final String? error;

  StepExecutionResult({
    required this.success,
    this.result,
    this.outputVariables,
    this.error,
  });
}

class FormFillingExecutionResult {
  final bool success;
  final String? submissionId;
  final String? error;

  FormFillingExecutionResult({
    required this.success,
    this.submissionId,
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