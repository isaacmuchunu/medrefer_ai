import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../services/clinical_workflow_service.dart';
import '../../database/models/patient.dart';
import '../../database/services/data_service.dart';
import 'dart:async';

class ClinicalWorkflowScreen extends StatefulWidget {
  final String? patientId;
  final String? userId;
  
  const ClinicalWorkflowScreen({
    super.key,
    this.patientId,
    this.userId,
  });

  @override
  State<ClinicalWorkflowScreen> createState() => _ClinicalWorkflowScreenState();
}

class _ClinicalWorkflowScreenState extends State<ClinicalWorkflowScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription _workflowSubscription;
  late StreamSubscription _taskSubscription;
  
  final ClinicalWorkflowService _workflowService = ClinicalWorkflowService.instance;
  final DataService _dataService = DataService();
  
  List<ClinicalWorkflow> workflows = [];
  List<WorkflowTask> userTasks = [];
  Map<String, dynamic> statistics = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _subscribeToUpdates();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    
    try {
      await _workflowService.initialize();
      await _loadData();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadWorkflows(),
      _loadUserTasks(),
      _loadStatistics(),
    ]);
  }

  Future<void> _loadWorkflows() async {
    if (widget.patientId != null) {
      final result = await _workflowService.getPatientWorkflows(widget.patientId!);
      if (result.isSuccess) {
        setState(() => workflows = result.data ?? []);
      }
    } else {
      // Load all workflows if no specific patient
      setState(() => workflows = []);
    }
  }

  Future<void> _loadUserTasks() async {
    if (widget.userId != null) {
      final result = await _workflowService.getUserTasks(widget.userId!);
      if (result.isSuccess) {
        setState(() => userTasks = result.data ?? []);
      }
    }
  }

  Future<void> _loadStatistics() async {
    final result = await _workflowService.getWorkflowStatistics();
    if (result.isSuccess) {
      setState(() => statistics = result.data ?? {});
    }
  }

  void _subscribeToUpdates() {
    _workflowSubscription = _workflowService.workflowStream.listen((workflow) {
      if (widget.patientId == null || workflow.patientId == widget.patientId) {
        setState(() {
          final index = workflows.indexWhere((w) => w.id == workflow.id);
          if (index >= 0) {
            workflows[index] = workflow;
          } else {
            workflows.add(workflow);
          }
        });
      }
    });

    _taskSubscription = _workflowService.taskStream.listen((task) {
      if (widget.userId != null && task.assignedTo == widget.userId) {
        setState(() {
          final index = userTasks.indexWhere((t) => t.id == task.id);
          if (index >= 0) {
            userTasks[index] = task;
          } else if (task.status != WorkflowStatus.completed) {
            userTasks.add(task);
          }
          
          // Remove completed tasks
          userTasks.removeWhere((t) => t.status == WorkflowStatus.completed);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Workflows'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${workflows.where((w) => w.status != WorkflowStatus.completed).length}'),
                child: const Icon(Icons.assignment),
              ),
              text: 'Workflows',
            ),
            Tab(
              icon: Badge(
                label: Text('${userTasks.length}'),
                child: const Icon(Icons.task_alt),
              ),
              text: 'My Tasks',
            ),
            const Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkflowsTab(),
                _buildTasksTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateWorkflowDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Workflow'),
      ),
    );
  }

  Widget _buildWorkflowsTab() {
    if (workflows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No workflows found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkflows,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workflows.length,
        itemBuilder: (context, index) {
          final workflow = workflows[index];
          return _buildWorkflowCard(workflow);
        },
      ),
    );
  }

  Widget _buildWorkflowCard(ClinicalWorkflow workflow) {
    final completionPercentage = workflow.completionPercentage;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(workflow.status),
          child: Icon(
            _getWorkflowIcon(workflow.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          workflow.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workflow.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(workflow.status.name.toUpperCase()),
                  backgroundColor: _getStatusColor(workflow.status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(workflow.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(workflow.priority.name.toUpperCase()),
                  backgroundColor: _getPriorityColor(workflow.priority).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getPriorityColor(workflow.priority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress: ${(completionPercentage * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: completionPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(workflow.status),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkflowInfo(workflow),
                const SizedBox(height: 16),
                _buildTasksList(workflow.tasks),
                const SizedBox(height: 16),
                _buildWorkflowActions(workflow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowInfo(ClinicalWorkflow workflow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workflow Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Created', _formatDateTime(workflow.createdAt)),
        if (workflow.startedAt != null)
          _buildInfoRow('Started', _formatDateTime(workflow.startedAt!)),
        if (workflow.completedAt != null)
          _buildInfoRow('Completed', _formatDateTime(workflow.completedAt!)),
        if (workflow.dueDate != null)
          _buildInfoRow('Due Date', _formatDateTime(workflow.dueDate!)),
        _buildInfoRow('Initiated By', workflow.initiatedBy ?? 'System'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<WorkflowTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks (${tasks.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskListItem(task);
          },
        ),
      ],
    );
  }

  Widget _buildTaskListItem(WorkflowTask task) {
    return ListTile(
      dense: true,
      leading: Icon(
        _getTaskStatusIcon(task.status),
        color: _getStatusColor(task.status),
        size: 20,
      ),
      title: Text(
        task.name,
        style: TextStyle(
          fontSize: 14,
          decoration: task.status == WorkflowStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.assignedTo != null || task.assignedRole != null)
            Text(
              'Assigned to: ${task.assignedTo ?? task.assignedRole}',
              style: const TextStyle(fontSize: 12),
            ),
          if (task.dueDate != null)
            Text(
              'Due: ${_formatDateTime(task.dueDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: DateTime.now().isAfter(task.dueDate!) && 
                       task.status != WorkflowStatus.completed
                    ? Colors.red
                    : null,
              ),
            ),
        ],
      ),
      trailing: task.status == WorkflowStatus.inProgress && 
                task.assignedTo == widget.userId
          ? IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _completeTask(task),
            )
          : null,
    );
  }

  Widget _buildWorkflowActions(ClinicalWorkflow workflow) {
    return Row(
      children: [
        if (workflow.status == WorkflowStatus.pending)
          ElevatedButton.icon(
            onPressed: () => _startWorkflow(workflow.id),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _viewWorkflowDetails(workflow),
          icon: const Icon(Icons.visibility),
          label: const Text('View Details'),
        ),
        const Spacer(),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            if (workflow.status != WorkflowStatus.completed)
              const PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text('Cancel'),
                ),
              ),
          ],
          onSelected: (value) => _handleWorkflowAction(value as String, workflow),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    if (userTasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tasks assigned'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userTasks.length,
        itemBuilder: (context, index) {
          final task = userTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(WorkflowTask task) {
    final isOverdue = task.dueDate != null && 
                     DateTime.now().isAfter(task.dueDate!) &&
                     task.status != WorkflowStatus.completed;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(task.priority),
          child: Icon(
            _getTaskTypeIcon(task.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          task.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(task.priority.name.toUpperCase()),
                  backgroundColor: _getPriorityColor(task.priority).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getPriorityColor(task.priority),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                if (isOverdue)
                  const Chip(
                    label: Text('OVERDUE'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            if (task.dueDate != null)
              Text(
                'Due: ${_formatDateTime(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? Colors.red : Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: task.status == WorkflowStatus.inProgress
            ? ElevatedButton(
                onPressed: () => _completeTask(task),
                child: const Text('Complete'),
              )
            : null,
        onTap: () => _viewTaskDetails(task),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsCard('Workflow Overview', [
              _buildStatRow('Active Workflows', '${statistics['activeWorkflows'] ?? 0}'),
              _buildStatRow('Overdue Tasks', '${statistics['overdueTasks'] ?? 0}'),
              _buildStatRow('Avg Completion Time', 
                  '${(statistics['averageCompletionTimeMinutes'] ?? 0).toInt()} min'),
            ]),
            const SizedBox(height: 16),
            _buildStatisticsCard('Workflows by Status', 
                _buildStatusChart(statistics['workflowsByStatus'] ?? {})),
            const SizedBox(height: 16),
            _buildStatisticsCard('Tasks by Status', 
                _buildStatusChart(statistics['tasksByStatus'] ?? {})),
            const SizedBox(height: 16),
            _buildStatisticsCard('Performance Metrics', [
              _buildPerformanceMetrics(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(String title, dynamic content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            content is List ? Column(children: content as List<Widget>) : content,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart(Map<String, dynamic> statusData) {
    if (statusData.isEmpty) {
      return const Text('No data available');
    }

    return Column(
      children: statusData.entries.map((entry) {
        final count = entry.value as int;
        final total = statusData.values.fold<int>(0, (sum, value) => sum + (value as int));
        final percentage = total > 0 ? count / total : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key.toUpperCase()),
                  Text('$count (${(percentage * 100).toInt()}%)'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColorByName(entry.key),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Column(
      children: [
        _buildStatRow('Workflow Efficiency', '85%'),
        _buildStatRow('On-time Completion', '92%'),
        _buildStatRow('Average Tasks per Workflow', '6.5'),
        _buildStatRow('Automation Rate', '35%'),
      ],
    );
  }

  Color _getStatusColor(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.pending:
        return Colors.grey;
      case WorkflowStatus.inProgress:
        return Colors.blue;
      case WorkflowStatus.completed:
        return Colors.green;
      case WorkflowStatus.cancelled:
        return Colors.red;
      case WorkflowStatus.onHold:
        return Colors.orange;
      case WorkflowStatus.failed:
        return Colors.red[800]!;
    }
  }

  Color _getStatusColorByName(String statusName) {
    final status = WorkflowStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => WorkflowStatus.pending,
    );
    return _getStatusColor(status);
  }

  Color _getPriorityColor(WorkflowPriority priority) {
    switch (priority) {
      case WorkflowPriority.low:
        return Colors.green;
      case WorkflowPriority.normal:
        return Colors.blue;
      case WorkflowPriority.high:
        return Colors.orange;
      case WorkflowPriority.urgent:
        return Colors.red;
      case WorkflowPriority.critical:
        return Colors.red[900]!;
    }
  }

  IconData _getWorkflowIcon(WorkflowType type) {
    switch (type) {
      case WorkflowType.patientAdmission:
        return Icons.login;
      case WorkflowType.patientDischarge:
        return Icons.logout;
      case WorkflowType.surgicalPrep:
        return Icons.medical_services;
      case WorkflowType.labOrderProcessing:
        return Icons.science;
      case WorkflowType.medicationAdministration:
        return Icons.medication;
      case WorkflowType.emergencyProtocol:
        return Icons.emergency;
      case WorkflowType.qualityAssurance:
        return Icons.verified;
      case WorkflowType.patientTransfer:
        return Icons.transfer_within_a_station;
      case WorkflowType.documentationReview:
        return Icons.description;
      case WorkflowType.followUpCare:
        return Icons.follow_the_signs;
    }
  }

  IconData _getTaskTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.manual:
        return Icons.person;
      case TaskType.automated:
        return Icons.smart_toy;
      case TaskType.decision:
        return Icons.call_split;
      case TaskType.notification:
        return Icons.notifications;
      case TaskType.documentation:
        return Icons.description;
      case TaskType.approval:
        return Icons.approval;
      case TaskType.verification:
        return Icons.verified_user;
    }
  }

  IconData _getTaskStatusIcon(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.pending:
        return Icons.schedule;
      case WorkflowStatus.inProgress:
        return Icons.play_circle;
      case WorkflowStatus.completed:
        return Icons.check_circle;
      case WorkflowStatus.cancelled:
        return Icons.cancel;
      case WorkflowStatus.onHold:
        return Icons.pause_circle;
      case WorkflowStatus.failed:
        return Icons.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateWorkflowDialog() {
    WorkflowType? selectedType;
    var selectedPriority = WorkflowPriority.normal;
    final patientIdController = TextEditingController(text: widget.patientId);
    DateTime? dueDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Workflow'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<WorkflowType>(
                  decoration: const InputDecoration(
                    labelText: 'Workflow Type',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedType,
                  items: WorkflowType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: patientIdController,
                  decoration: const InputDecoration(
                    labelText: 'Patient ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WorkflowPriority>(
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedPriority,
                  items: WorkflowPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedPriority = value!);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Due Date (Optional)'),
                  subtitle: Text(dueDate?.toString() ?? 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() {
                          dueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedType != null && patientIdController.text.isNotEmpty
                  ? () async {
                      Navigator.of(context).pop();
                      await _createWorkflow(
                        selectedType!,
                        patientIdController.text,
                        selectedPriority,
                        dueDate,
                      );
                    }
                  : null,
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createWorkflow(
    WorkflowType type,
    String patientId,
    WorkflowPriority priority,
    DateTime? dueDate,
  ) async {
    final result = await _workflowService.createWorkflow(
      type: type,
      patientId: patientId,
      initiatedBy: widget.userId ?? 'Current User',
      priority: priority,
      dueDate: dueDate,
    );
    
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workflow created successfully')),
      );
      await _loadWorkflows();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.errorMessage}')),
      );
    }
  }

  Future<void> _startWorkflow(String workflowId) async {
    // The workflow service automatically starts workflows when created
    // This is a placeholder for any additional start logic
    await _loadWorkflows();
  }

  Future<void> _completeTask(WorkflowTask task) async {
    final result = await _workflowService.completeTask(
      taskId: task.id,
      completedBy: widget.userId ?? 'Current User',
      notes: 'Completed via mobile app',
    );
    
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task completed successfully')),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.errorMessage}')),
      );
    }
  }

  void _viewWorkflowDetails(ClinicalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workflow.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${workflow.type.name}'),
              Text('Status: ${workflow.status.name}'),
              Text('Priority: ${workflow.priority.name}'),
              Text('Patient ID: ${workflow.patientId}'),
              Text('Progress: ${(workflow.completionPercentage * 100).toInt()}%'),
              if (workflow.notes != null)
                Text('Notes: ${workflow.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewTaskDetails(WorkflowTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${task.description}'),
              Text('Type: ${task.type.name}'),
              Text('Status: ${task.status.name}'),
              Text('Priority: ${task.priority.name}'),
              if (task.assignedTo != null)
                Text('Assigned to: ${task.assignedTo}'),
              if (task.assignedRole != null)
                Text('Role: ${task.assignedRole}'),
              if (task.dueDate != null)
                Text('Due: ${_formatDateTime(task.dueDate!)}'),
              if (task.notes != null)
                Text('Notes: ${task.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (task.status == WorkflowStatus.inProgress && 
              task.assignedTo == widget.userId)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeTask(task);
              },
              child: const Text('Complete'),
            ),
        ],
      ),
    );
  }

  void _handleWorkflowAction(String action, ClinicalWorkflow workflow) {
    switch (action) {
      case 'edit':
        // Implementation for editing workflow
        break;
      case 'cancel':
        // Implementation for cancelling workflow
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workflowSubscription.cancel();
    _taskSubscription.cancel();
    super.dispose();
  }
}
