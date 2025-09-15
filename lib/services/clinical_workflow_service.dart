import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/models/patient.dart';
import '../database/services/data_service.dart';
import '../core/result.dart';
import 'ai_service.dart';
import 'blockchain_medical_records_service.dart';
import 'notification_service.dart';
import 'logging_service.dart';

enum WorkflowStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  onHold,
  failed,
}

enum WorkflowPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

enum WorkflowType {
  patientAdmission,
  patientDischarge,
  surgicalPrep,
  labOrderProcessing,
  medicationAdministration,
  emergencyProtocol,
  qualityAssurance,
  patientTransfer,
  documentationReview,
  followUpCare,
}

enum TaskType {
  manual,
  automated,
  decision,
  notification,
  documentation,
  approval,
  verification,
}

class WorkflowTask {
  final String id;
  final String workflowId;
  final String name;
  final String description;
  final TaskType type;
  final WorkflowStatus status;
  final WorkflowPriority priority;
  final String? assignedTo;
  final String? assignedRole;
  final DateTime? dueDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final List<String> dependencies;
  final List<String> conditions;
  final Map<String, dynamic> metadata;
  final String? notes;

  WorkflowTask({
    required this.id,
    required this.workflowId,
    required this.name,
    required this.description,
    required this.type,
    this.status = WorkflowStatus.pending,
    this.priority = WorkflowPriority.normal,
    this.assignedTo,
    this.assignedRole,
    this.dueDate,
    this.startedAt,
    this.completedAt,
    this.inputs = const {},
    this.outputs = const {},
    this.dependencies = const [],
    this.conditions = const [],
    this.metadata = const {},
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workflowId': workflowId,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'assignedRole': assignedRole,
      'dueDate': dueDate?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'inputs': jsonEncode(inputs),
      'outputs': jsonEncode(outputs),
      'dependencies': jsonEncode(dependencies),
      'conditions': jsonEncode(conditions),
      'metadata': jsonEncode(metadata),
      'notes': notes,
    };
  }

  factory WorkflowTask.fromMap(Map<String, dynamic> map) {
    return WorkflowTask(
      id: map['id'],
      workflowId: map['workflowId'],
      name: map['name'],
      description: map['description'],
      type: TaskType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TaskType.manual,
      ),
      status: WorkflowStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WorkflowStatus.pending,
      ),
      priority: WorkflowPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => WorkflowPriority.normal,
      ),
      assignedTo: map['assignedTo'],
      assignedRole: map['assignedRole'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      inputs: map['inputs'] != null ? jsonDecode(map['inputs']) : {},
      outputs: map['outputs'] != null ? jsonDecode(map['outputs']) : {},
      dependencies: map['dependencies'] != null 
          ? List<String>.from(jsonDecode(map['dependencies']))
          : [],
      conditions: map['conditions'] != null 
          ? List<String>.from(jsonDecode(map['conditions']))
          : [],
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
      notes: map['notes'],
    );
  }

  WorkflowTask copyWith({
    WorkflowStatus? status,
    String? assignedTo,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? outputs,
    String? notes,
  }) {
    return WorkflowTask(
      id: id,
      workflowId: workflowId,
      name: name,
      description: description,
      type: type,
      status: status ?? this.status,
      priority: priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedRole: assignedRole,
      dueDate: dueDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      inputs: inputs,
      outputs: outputs ?? this.outputs,
      dependencies: dependencies,
      conditions: conditions,
      metadata: metadata,
      notes: notes ?? this.notes,
    );
  }
}

class ClinicalWorkflow {
  final String id;
  final String name;
  final String description;
  final WorkflowType type;
  final WorkflowStatus status;
  final WorkflowPriority priority;
  final String patientId;
  final String? initiatedBy;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final List<WorkflowTask> tasks;
  final Map<String, dynamic> context;
  final Map<String, dynamic> metadata;
  final String? notes;

  ClinicalWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.status = WorkflowStatus.pending,
    this.priority = WorkflowPriority.normal,
    required this.patientId,
    this.initiatedBy,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.dueDate,
    this.tasks = const [],
    this.context = const {},
    this.metadata = const {},
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'patientId': patientId,
      'initiatedBy': initiatedBy,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'context': jsonEncode(context),
      'metadata': jsonEncode(metadata),
      'notes': notes,
    };
  }

  factory ClinicalWorkflow.fromMap(Map<String, dynamic> map) {
    return ClinicalWorkflow(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: WorkflowType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WorkflowType.patientAdmission,
      ),
      status: WorkflowStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WorkflowStatus.pending,
      ),
      priority: WorkflowPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => WorkflowPriority.normal,
      ),
      patientId: map['patientId'],
      initiatedBy: map['initiatedBy'],
      createdAt: DateTime.parse(map['createdAt']),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      context: map['context'] != null ? jsonDecode(map['context']) : {},
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
      notes: map['notes'],
    );
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((t) => t.status == WorkflowStatus.completed).length;
    return completedTasks / tasks.length;
  }

  List<WorkflowTask> get availableTasks {
    return tasks.where((task) {
      if (task.status != WorkflowStatus.pending) return false;
      
      // Check if all dependencies are completed
      for (final depId in task.dependencies) {
        final depTask = tasks.firstWhere(
          (t) => t.id == depId,
          orElse: () => null as WorkflowTask,
        );
        if (depTask == null || depTask.status != WorkflowStatus.completed) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
}

class ClinicalWorkflowService {
  static ClinicalWorkflowService? _instance;
  static ClinicalWorkflowService get instance => _instance ??= ClinicalWorkflowService._();
  ClinicalWorkflowService._();

  final DataService _dataService = DataService();
  final AIService _aiService = AIService();
  final BlockchainMedicalRecordsService _blockchainService = BlockchainMedicalRecordsService();
  final NotificationService _notificationService = NotificationService();
  final LoggingService _loggingService = LoggingService();

  final Map<String, ClinicalWorkflow> _activeWorkflows = {};
  final StreamController<ClinicalWorkflow> _workflowController = StreamController.broadcast();
  final StreamController<WorkflowTask> _taskController = StreamController.broadcast();

  bool _isInitialized = false;
  Timer? _automationTimer;

  Stream<ClinicalWorkflow> get workflowStream => _workflowController.stream;
  Stream<WorkflowTask> get taskStream => _taskController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeServices();
      await _loadActiveWorkflows();
      _startAutomationEngine();
      
      _isInitialized = true;
      _loggingService.info('ClinicalWorkflowService initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize ClinicalWorkflowService', error: e);
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    await _aiService.initialize();
    await _blockchainService.initialize();
    await _notificationService.initialize();
  }

  Future<void> _loadActiveWorkflows() async {
    try {
      final result = await _dataService.query(
        'clinical_workflows',
        where: 'status NOT IN (?, ?)',
        whereArgs: ['completed', 'cancelled'],
      );
      
      if (result.isSuccess) {
        for (final workflowMap in result.data!) {
          final workflow = ClinicalWorkflow.fromMap(workflowMap);
          
          // Load tasks for this workflow
          final tasksResult = await _dataService.query(
            'workflow_tasks',
            where: 'workflowId = ?',
            whereArgs: [workflow.id],
          );
          
          if (tasksResult.isSuccess) {
            final tasks = tasksResult.data!
                .map((taskMap) => WorkflowTask.fromMap(taskMap))
                .toList();
            
            final workflowWithTasks = ClinicalWorkflow(
              id: workflow.id,
              name: workflow.name,
              description: workflow.description,
              type: workflow.type,
              status: workflow.status,
              priority: workflow.priority,
              patientId: workflow.patientId,
              initiatedBy: workflow.initiatedBy,
              createdAt: workflow.createdAt,
              startedAt: workflow.startedAt,
              completedAt: workflow.completedAt,
              dueDate: workflow.dueDate,
              tasks: tasks,
              context: workflow.context,
              metadata: workflow.metadata,
              notes: workflow.notes,
            );
            
            _activeWorkflows[workflow.id] = workflowWithTasks;
          }
        }
      }
    } catch (e) {
      _loggingService.error('Failed to load active workflows', error: e);
    }
  }

  void _startAutomationEngine() {
    _automationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _processAutomatedTasks();
      _checkWorkflowTimeouts();
      _optimizeWorkflows();
    });
  }

  /// Create a new clinical workflow
  Future<Result<ClinicalWorkflow>> createWorkflow({
    required WorkflowType type,
    required String patientId,
    String? initiatedBy,
    WorkflowPriority priority = WorkflowPriority.normal,
    Map<String, dynamic> context = const {},
    DateTime? dueDate,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final workflowId = DateTime.now().millisecondsSinceEpoch.toString();
      final workflowTemplate = await _getWorkflowTemplate(type);
      
      final workflow = ClinicalWorkflow(
        id: workflowId,
        name: workflowTemplate['name'],
        description: workflowTemplate['description'],
        type: type,
        priority: priority,
        patientId: patientId,
        initiatedBy: initiatedBy,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        context: context,
      );

      // Create workflow tasks based on template
      final tasks = await _createWorkflowTasks(workflowId, workflowTemplate, context);
      
      final workflowWithTasks = ClinicalWorkflow(
        id: workflow.id,
        name: workflow.name,
        description: workflow.description,
        type: workflow.type,
        status: workflow.status,
        priority: workflow.priority,
        patientId: workflow.patientId,
        initiatedBy: workflow.initiatedBy,
        createdAt: workflow.createdAt,
        startedAt: workflow.startedAt,
        completedAt: workflow.completedAt,
        dueDate: workflow.dueDate,
        tasks: tasks,
        context: workflow.context,
        metadata: workflow.metadata,
        notes: workflow.notes,
      );

      // Store in database
      await _dataService.insert('clinical_workflows', workflow.toMap());
      
      for (final task in tasks) {
        await _dataService.insert('workflow_tasks', task.toMap());
      }

      // Store in active workflows
      _activeWorkflows[workflowId] = workflowWithTasks;

      // Store in blockchain for audit trail
      await _blockchainService.storeWorkflow(patientId, workflowWithTasks.toMap());

      // Start workflow
      await _startWorkflow(workflowId);

      _loggingService.info(
        'Clinical workflow created',
        context: 'ClinicalWorkflowService',
        metadata: {
          'workflowId': workflowId,
          'type': type.name,
          'patientId': patientId,
        },
      );

      _workflowController.add(workflowWithTasks);
      
      return Result.success(workflowWithTasks);
    } catch (e) {
      _loggingService.error('Error creating workflow', error: e);
      return Result.error('Failed to create workflow: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _getWorkflowTemplate(WorkflowType type) async {
    // Workflow templates define the structure and tasks for each workflow type
    final templates = {
      WorkflowType.patientAdmission: {
        'name': 'Patient Admission Workflow',
        'description': 'Complete patient admission process',
        'tasks': [
          {
            'name': 'Verify Patient Identity',
            'description': 'Confirm patient identity and registration details',
            'type': TaskType.manual,
            'assignedRole': 'Registration Staff',
            'priority': WorkflowPriority.high,
          },
          {
            'name': 'Insurance Verification',
            'description': 'Verify insurance coverage and benefits',
            'type': TaskType.automated,
            'dependencies': ['Verify Patient Identity'],
          },
          {
            'name': 'Room Assignment',
            'description': 'Assign appropriate room based on condition and availability',
            'type': TaskType.decision,
            'assignedRole': 'Bed Management',
            'dependencies': ['Insurance Verification'],
          },
          {
            'name': 'Initial Assessment',
            'description': 'Conduct initial nursing assessment',
            'type': TaskType.manual,
            'assignedRole': 'Nurse',
            'dependencies': ['Room Assignment'],
            'priority': WorkflowPriority.high,
          },
          {
            'name': 'Physician Evaluation',
            'description': 'Initial physician evaluation and care plan',
            'type': TaskType.manual,
            'assignedRole': 'Physician',
            'dependencies': ['Initial Assessment'],
            'priority': WorkflowPriority.high,
          },
          {
            'name': 'Medication Reconciliation',
            'description': 'Review and reconcile patient medications',
            'type': TaskType.manual,
            'assignedRole': 'Pharmacist',
            'dependencies': ['Physician Evaluation'],
          },
          {
            'name': 'Care Plan Documentation',
            'description': 'Document initial care plan and orders',
            'type': TaskType.documentation,
            'assignedRole': 'Physician',
            'dependencies': ['Medication Reconciliation'],
          },
        ],
      },
      WorkflowType.surgicalPrep: {
        'name': 'Surgical Preparation Workflow',
        'description': 'Pre-operative preparation process',
        'tasks': [
          {
            'name': 'Pre-operative Assessment',
            'description': 'Complete pre-operative nursing assessment',
            'type': TaskType.manual,
            'assignedRole': 'OR Nurse',
            'priority': WorkflowPriority.high,
          },
          {
            'name': 'Anesthesia Consultation',
            'description': 'Anesthesiologist evaluation and planning',
            'type': TaskType.manual,
            'assignedRole': 'Anesthesiologist',
            'dependencies': ['Pre-operative Assessment'],
            'priority': WorkflowPriority.high,
          },
          {
            'name': 'Surgical Site Marking',
            'description': 'Mark surgical site and verify procedure',
            'type': TaskType.verification,
            'assignedRole': 'Surgeon',
            'dependencies': ['Anesthesia Consultation'],
          },
          {
            'name': 'Equipment Preparation',
            'description': 'Prepare and verify surgical equipment',
            'type': TaskType.automated,
            'assignedRole': 'OR Tech',
            'dependencies': ['Surgical Site Marking'],
          },
          {
            'name': 'Time Out Verification',
            'description': 'Final verification before procedure',
            'type': TaskType.verification,
            'assignedRole': 'OR Team',
            'dependencies': ['Equipment Preparation'],
            'priority': WorkflowPriority.critical,
          },
        ],
      },
      WorkflowType.emergencyProtocol: {
        'name': 'Emergency Response Protocol',
        'description': 'Emergency patient care workflow',
        'tasks': [
          {
            'name': 'Triage Assessment',
            'description': 'Initial emergency triage assessment',
            'type': TaskType.manual,
            'assignedRole': 'Triage Nurse',
            'priority': WorkflowPriority.critical,
          },
          {
            'name': 'Emergency Physician Evaluation',
            'description': 'Emergency physician assessment',
            'type': TaskType.manual,
            'assignedRole': 'Emergency Physician',
            'dependencies': ['Triage Assessment'],
            'priority': WorkflowPriority.critical,
          },
          {
            'name': 'Diagnostic Orders',
            'description': 'Order emergency diagnostics',
            'type': TaskType.automated,
            'assignedRole': 'Emergency Physician',
            'dependencies': ['Emergency Physician Evaluation'],
            'priority': WorkflowPriority.urgent,
          },
          {
            'name': 'Treatment Implementation',
            'description': 'Implement emergency treatment plan',
            'type': TaskType.manual,
            'assignedRole': 'Emergency Team',
            'dependencies': ['Diagnostic Orders'],
            'priority': WorkflowPriority.critical,
          },
        ],
      },
    };

    return templates[type] ?? {
      'name': 'Generic Workflow',
      'description': 'Generic clinical workflow',
      'tasks': [],
    };
  }

  Future<List<WorkflowTask>> _createWorkflowTasks(
    String workflowId,
    Map<String, dynamic> template,
    Map<String, dynamic> context,
  ) async {
    final tasks = <WorkflowTask>[];
    final taskTemplates = List<Map<String, dynamic>>.from(template['tasks'] ?? []);
    
    for (int i = 0; i < taskTemplates.length; i++) {
      final taskTemplate = taskTemplates[i];
      final taskId = '${workflowId}_task_$i';
      
      // Resolve dependencies
      final dependencies = <String>[];
      if (taskTemplate['dependencies'] != null) {
        for (final depName in taskTemplate['dependencies']) {
          final depIndex = taskTemplates.indexWhere((t) => t['name'] == depName);
          if (depIndex >= 0) {
            dependencies.add('${workflowId}_task_$depIndex');
          }
        }
      }

      // Calculate due date based on priority and dependencies
      DateTime? dueDate;
      if (taskTemplate['priority'] == WorkflowPriority.critical) {
        dueDate = DateTime.now().add(const Duration(minutes: 15));
      } else if (taskTemplate['priority'] == WorkflowPriority.urgent) {
        dueDate = DateTime.now().add(const Duration(hours: 1));
      } else if (taskTemplate['priority'] == WorkflowPriority.high) {
        dueDate = DateTime.now().add(const Duration(hours: 4));
      }

      final task = WorkflowTask(
        id: taskId,
        workflowId: workflowId,
        name: taskTemplate['name'],
        description: taskTemplate['description'],
        type: taskTemplate['type'] ?? TaskType.manual,
        priority: taskTemplate['priority'] ?? WorkflowPriority.normal,
        assignedRole: taskTemplate['assignedRole'],
        dependencies: dependencies,
        dueDate: dueDate,
        inputs: Map<String, dynamic>.from(context),
      );
      
      tasks.add(task);
    }
    
    return tasks;
  }

  Future<Result<void>> _startWorkflow(String workflowId) async {
    try {
      final workflow = _activeWorkflows[workflowId];
      if (workflow == null) {
        return Result.error('Workflow not found');
      }

      // Update workflow status
      final updatedWorkflow = ClinicalWorkflow(
        id: workflow.id,
        name: workflow.name,
        description: workflow.description,
        type: workflow.type,
        status: WorkflowStatus.inProgress,
        priority: workflow.priority,
        patientId: workflow.patientId,
        initiatedBy: workflow.initiatedBy,
        createdAt: workflow.createdAt,
        startedAt: DateTime.now(),
        completedAt: workflow.completedAt,
        dueDate: workflow.dueDate,
        tasks: workflow.tasks,
        context: workflow.context,
        metadata: workflow.metadata,
        notes: workflow.notes,
      );

      _activeWorkflows[workflowId] = updatedWorkflow;
      
      // Update in database
      await _dataService.update('clinical_workflows', {
        'status': WorkflowStatus.inProgress.name,
        'startedAt': DateTime.now().toIso8601String(),
      }, workflowId);

      // Assign available tasks
      await _assignAvailableTasks(workflowId);

      // Send notifications for assigned tasks
      await _notifyAssignedTasks(workflowId);

      _workflowController.add(updatedWorkflow);
      
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to start workflow: ${e.toString()}');
    }
  }

  Future<void> _assignAvailableTasks(String workflowId) async {
    final workflow = _activeWorkflows[workflowId];
    if (workflow == null) return;

    for (final task in workflow.availableTasks) {
      if (task.type == TaskType.automated) {
        // Auto-assign automated tasks
        await completeTask(
          taskId: task.id,
          completedBy: 'System',
          outputs: await _executeAutomatedTask(task),
        );
      } else if (task.assignedRole != null) {
        // Find available staff member for the role
        final assignee = await _findAvailableStaff(task.assignedRole!);
        if (assignee != null) {
          await _assignTask(task.id, assignee);
        }
      }
    }
  }

  Future<String?> _findAvailableStaff(String role) async {
    // This would integrate with staff scheduling system
    // For now, return a placeholder
    final staffMap = {
      'Registration Staff': 'staff_registration_001',
      'Nurse': 'staff_nurse_001',
      'Physician': 'staff_physician_001',
      'Pharmacist': 'staff_pharmacist_001',
      'OR Nurse': 'staff_or_nurse_001',
      'Anesthesiologist': 'staff_anesthesiologist_001',
      'Surgeon': 'staff_surgeon_001',
      'OR Tech': 'staff_or_tech_001',
      'Triage Nurse': 'staff_triage_nurse_001',
      'Emergency Physician': 'staff_emergency_physician_001',
      'Emergency Team': 'staff_emergency_team_001',
    };
    
    return staffMap[role];
  }

  Future<void> _assignTask(String taskId, String assignee) async {
    // Find the task and workflow
    ClinicalWorkflow? targetWorkflow;
    WorkflowTask? targetTask;
    
    for (final workflow in _activeWorkflows.values) {
      final task = workflow.tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => null as WorkflowTask,
      );
      if (task != null) {
        targetWorkflow = workflow;
        targetTask = task;
        break;
      }
    }

    if (targetWorkflow == null || targetTask == null) return;

    // Update task
    final updatedTask = targetTask.copyWith(
      assignedTo: assignee,
      status: WorkflowStatus.inProgress,
      startedAt: DateTime.now(),
    );

    // Update in memory
    final taskIndex = targetWorkflow.tasks.indexWhere((t) => t.id == taskId);
    final updatedTasks = List<WorkflowTask>.from(targetWorkflow.tasks);
    updatedTasks[taskIndex] = updatedTask;
    
    final updatedWorkflow = ClinicalWorkflow(
      id: targetWorkflow.id,
      name: targetWorkflow.name,
      description: targetWorkflow.description,
      type: targetWorkflow.type,
      status: targetWorkflow.status,
      priority: targetWorkflow.priority,
      patientId: targetWorkflow.patientId,
      initiatedBy: targetWorkflow.initiatedBy,
      createdAt: targetWorkflow.createdAt,
      startedAt: targetWorkflow.startedAt,
      completedAt: targetWorkflow.completedAt,
      dueDate: targetWorkflow.dueDate,
      tasks: updatedTasks,
      context: targetWorkflow.context,
      metadata: targetWorkflow.metadata,
      notes: targetWorkflow.notes,
    );
    
    _activeWorkflows[targetWorkflow.id] = updatedWorkflow;

    // Update in database
    await _dataService.update('workflow_tasks', {
      'assignedTo': assignee,
      'status': WorkflowStatus.inProgress.name,
      'startedAt': DateTime.now().toIso8601String(),
    }, taskId);

    _taskController.add(updatedTask);
  }

  Future<void> _notifyAssignedTasks(String workflowId) async {
    final workflow = _activeWorkflows[workflowId];
    if (workflow == null) return;

    for (final task in workflow.tasks) {
      if (task.assignedTo != null && task.status == WorkflowStatus.inProgress) {
        await _notificationService.sendTaskAssignment(
          assigneeId: task.assignedTo!,
          taskName: task.name,
          workflowName: workflow.name,
          patientId: workflow.patientId,
          priority: task.priority.name,
          dueDate: task.dueDate,
        );
      }
    }
  }

  /// Complete a workflow task
  Future<Result<void>> completeTask({
    required String taskId,
    required String completedBy,
    Map<String, dynamic> outputs = const {},
    String? notes,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Find the task and workflow
      ClinicalWorkflow? targetWorkflow;
      WorkflowTask? targetTask;
      
      for (final workflow in _activeWorkflows.values) {
        final task = workflow.tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => null as WorkflowTask,
        );
        if (task != null) {
          targetWorkflow = workflow;
          targetTask = task;
          break;
        }
      }

      if (targetWorkflow == null || targetTask == null) {
        return Result.error('Task not found');
      }

      // Update task
      final updatedTask = targetTask.copyWith(
        status: WorkflowStatus.completed,
        completedAt: DateTime.now(),
        outputs: outputs,
        notes: notes,
      );

      // Update in memory
      final taskIndex = targetWorkflow.tasks.indexWhere((t) => t.id == taskId);
      final updatedTasks = List<WorkflowTask>.from(targetWorkflow.tasks);
      updatedTasks[taskIndex] = updatedTask;
      
      final updatedWorkflow = ClinicalWorkflow(
        id: targetWorkflow.id,
        name: targetWorkflow.name,
        description: targetWorkflow.description,
        type: targetWorkflow.type,
        status: targetWorkflow.status,
        priority: targetWorkflow.priority,
        patientId: targetWorkflow.patientId,
        initiatedBy: targetWorkflow.initiatedBy,
        createdAt: targetWorkflow.createdAt,
        startedAt: targetWorkflow.startedAt,
        completedAt: targetWorkflow.completedAt,
        dueDate: targetWorkflow.dueDate,
        tasks: updatedTasks,
        context: targetWorkflow.context,
        metadata: targetWorkflow.metadata,
        notes: targetWorkflow.notes,
      );
      
      _activeWorkflows[targetWorkflow.id] = updatedWorkflow;

      // Update in database
      await _dataService.update('workflow_tasks', {
        'status': WorkflowStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
        'outputs': jsonEncode(outputs),
        'notes': notes,
      }, taskId);

      // Store in blockchain
      await _blockchainService.storeTaskCompletion(
        targetWorkflow.patientId,
        taskId,
        {
          'completedBy': completedBy,
          'completedAt': DateTime.now().toIso8601String(),
          'outputs': outputs,
        },
      );

      // Check if workflow is complete
      if (updatedWorkflow.tasks.every((t) => t.status == WorkflowStatus.completed)) {
        await _completeWorkflow(targetWorkflow.id);
      } else {
        // Assign newly available tasks
        await _assignAvailableTasks(targetWorkflow.id);
        await _notifyAssignedTasks(targetWorkflow.id);
      }

      _taskController.add(updatedTask);
      _workflowController.add(updatedWorkflow);

      _loggingService.info(
        'Task completed',
        context: 'ClinicalWorkflowService',
        metadata: {
          'taskId': taskId,
          'workflowId': targetWorkflow.id,
          'completedBy': completedBy,
        },
      );

      return Result.success(null);
    } catch (e) {
      _loggingService.error('Error completing task', error: e);
      return Result.error('Failed to complete task: ${e.toString()}');
    }
  }

  Future<void> _completeWorkflow(String workflowId) async {
    final workflow = _activeWorkflows[workflowId];
    if (workflow == null) return;

    final completedWorkflow = ClinicalWorkflow(
      id: workflow.id,
      name: workflow.name,
      description: workflow.description,
      type: workflow.type,
      status: WorkflowStatus.completed,
      priority: workflow.priority,
      patientId: workflow.patientId,
      initiatedBy: workflow.initiatedBy,
      createdAt: workflow.createdAt,
      startedAt: workflow.startedAt,
      completedAt: DateTime.now(),
      dueDate: workflow.dueDate,
      tasks: workflow.tasks,
      context: workflow.context,
      metadata: workflow.metadata,
      notes: workflow.notes,
    );

    _activeWorkflows[workflowId] = completedWorkflow;

    // Update in database
    await _dataService.update('clinical_workflows', {
      'status': WorkflowStatus.completed.name,
      'completedAt': DateTime.now().toIso8601String(),
    }, workflowId);

    // Store completion in blockchain
    await _blockchainService.storeWorkflowCompletion(
      workflow.patientId,
      workflowId,
      DateTime.now(),
    );

    // Send completion notification
    await _notificationService.sendWorkflowCompletion(
      workflowName: workflow.name,
      patientId: workflow.patientId,
      completedAt: DateTime.now(),
    );

    _workflowController.add(completedWorkflow);

    _loggingService.info(
      'Workflow completed',
      context: 'ClinicalWorkflowService',
      metadata: {
        'workflowId': workflowId,
        'type': workflow.type.name,
        'patientId': workflow.patientId,
        'duration': DateTime.now().difference(workflow.startedAt!).inMinutes,
      },
    );
  }

  Future<Map<String, dynamic>> _executeAutomatedTask(WorkflowTask task) async {
    // Execute automated tasks based on task type and context
    switch (task.name) {
      case 'Insurance Verification':
        return await _verifyInsurance(task.inputs);
      case 'Equipment Preparation':
        return await _prepareEquipment(task.inputs);
      case 'Diagnostic Orders':
        return await _orderDiagnostics(task.inputs);
      default:
        return {'status': 'completed', 'automated': true};
    }
  }

  Future<Map<String, dynamic>> _verifyInsurance(Map<String, dynamic> inputs) async {
    // Simulate insurance verification
    await Future.delayed(const Duration(seconds: 2));
    return {
      'verified': true,
      'coverage': 'Active',
      'copay': 50.0,
      'deductible': 1000.0,
      'verifiedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _prepareEquipment(Map<String, dynamic> inputs) async {
    // Simulate equipment preparation
    await Future.delayed(const Duration(seconds: 1));
    return {
      'equipment': ['Surgical instruments', 'Monitoring devices', 'Anesthesia equipment'],
      'sterilized': true,
      'checked': true,
      'preparedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _orderDiagnostics(Map<String, dynamic> inputs) async {
    // Simulate diagnostic ordering
    await Future.delayed(const Duration(seconds: 1));
    return {
      'orders': ['CBC', 'Basic Metabolic Panel', 'Chest X-ray'],
      'priority': 'STAT',
      'orderedAt': DateTime.now().toIso8601String(),
    };
  }

  void _processAutomatedTasks() {
    for (final workflow in _activeWorkflows.values) {
      if (workflow.status != WorkflowStatus.inProgress) continue;
      
      for (final task in workflow.availableTasks) {
        if (task.type == TaskType.automated && task.status == WorkflowStatus.pending) {
          completeTask(
            taskId: task.id,
            completedBy: 'System',
            outputs: {'automated': true},
          );
        }
      }
    }
  }

  void _checkWorkflowTimeouts() {
    final now = DateTime.now();
    
    for (final workflow in _activeWorkflows.values) {
      // Check workflow timeout
      if (workflow.dueDate != null && now.isAfter(workflow.dueDate!)) {
        _handleWorkflowTimeout(workflow);
      }
      
      // Check task timeouts
      for (final task in workflow.tasks) {
        if (task.dueDate != null && 
            now.isAfter(task.dueDate!) && 
            task.status == WorkflowStatus.inProgress) {
          _handleTaskTimeout(task);
        }
      }
    }
  }

  void _handleWorkflowTimeout(ClinicalWorkflow workflow) {
    _notificationService.sendWorkflowTimeout(
      workflowName: workflow.name,
      patientId: workflow.patientId,
      dueDate: workflow.dueDate!,
    );
  }

  void _handleTaskTimeout(WorkflowTask task) {
    _notificationService.sendTaskTimeout(
      taskName: task.name,
      assignedTo: task.assignedTo,
      dueDate: task.dueDate!,
    );
  }

  void _optimizeWorkflows() {
    // Use AI to optimize workflow performance
    _aiService.optimizeWorkflows(_activeWorkflows.values.toList());
  }

  /// Get workflows for a patient
  Future<Result<List<ClinicalWorkflow>>> getPatientWorkflows(String patientId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final workflows = _activeWorkflows.values
          .where((w) => w.patientId == patientId)
          .toList();
      
      return Result.success(workflows);
    } catch (e) {
      return Result.error('Failed to get patient workflows: ${e.toString()}');
    }
  }

  /// Get tasks assigned to a user
  Future<Result<List<WorkflowTask>>> getUserTasks(String userId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final tasks = <WorkflowTask>[];
      
      for (final workflow in _activeWorkflows.values) {
        final userTasks = workflow.tasks
            .where((t) => t.assignedTo == userId && t.status != WorkflowStatus.completed)
            .toList();
        tasks.addAll(userTasks);
      }
      
      // Sort by priority and due date
      tasks.sort((a, b) {
        final priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        
        return a.dueDate!.compareTo(b.dueDate!);
      });
      
      return Result.success(tasks);
    } catch (e) {
      return Result.error('Failed to get user tasks: ${e.toString()}');
    }
  }

  /// Get workflow statistics
  Future<Result<Map<String, dynamic>>> getWorkflowStatistics() async {
    try {
      if (!_isInitialized) await initialize();
      
      final stats = <String, dynamic>{};
      
      // Active workflows
      stats['activeWorkflows'] = _activeWorkflows.length;
      
      // Workflows by status
      final statusCounts = <String, int>{};
      for (final status in WorkflowStatus.values) {
        statusCounts[status.name] = _activeWorkflows.values
            .where((w) => w.status == status)
            .length;
      }
      stats['workflowsByStatus'] = statusCounts;
      
      // Tasks by status
      final taskStatusCounts = <String, int>{};
      for (final status in WorkflowStatus.values) {
        taskStatusCounts[status.name] = _activeWorkflows.values
            .expand((w) => w.tasks)
            .where((t) => t.status == status)
            .length;
      }
      stats['tasksByStatus'] = taskStatusCounts;
      
      // Overdue tasks
      final now = DateTime.now();
      stats['overdueTasks'] = _activeWorkflows.values
          .expand((w) => w.tasks)
          .where((t) => t.dueDate != null && 
                       now.isAfter(t.dueDate!) && 
                       t.status != WorkflowStatus.completed)
          .length;
      
      // Average completion time
      final completedWorkflows = _activeWorkflows.values
          .where((w) => w.status == WorkflowStatus.completed)
          .toList();
      
      if (completedWorkflows.isNotEmpty) {
        final totalDuration = completedWorkflows
            .map((w) => w.completedAt!.difference(w.startedAt!).inMinutes)
            .reduce((a, b) => a + b);
        stats['averageCompletionTimeMinutes'] = totalDuration / completedWorkflows.length;
      } else {
        stats['averageCompletionTimeMinutes'] = 0;
      }
      
      return Result.success(stats);
    } catch (e) {
      return Result.error('Failed to get workflow statistics: ${e.toString()}');
    }
  }

  void dispose() {
    _automationTimer?.cancel();
    _workflowController.close();
    _taskController.close();
  }
}