import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../services/drug_interaction_service.dart';
import '../../database/models/medication.dart';
import '../../database/models/patient.dart';
import '../../database/services/data_service.dart';
import 'dart:async';

class DrugInteractionScreen extends StatefulWidget {
  final String patientId;
  
  const DrugInteractionScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<DrugInteractionScreen> createState() => _DrugInteractionScreenState();
}

class _DrugInteractionScreenState extends State<DrugInteractionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription _alertSubscription;
  
  final DrugInteractionService _interactionService = DrugInteractionService.instance;
  final DataService _dataService = DataService();
  
  Patient? patient;
  List<Medication> medications = [];
  List<DrugInteractionAlert> alerts = [];
  List<DrugInteraction> interactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _subscribeToAlerts();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    
    try {
      await _interactionService.initialize();
      await _loadPatientData();
      await _loadMedications();
      await _loadAlerts();
      await _checkInteractions();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPatientData() async {
    final result = await _dataService.getPatientById(widget.patientId);
    if (result.isSuccess) {
      setState(() => patient = result.data);
    }
  }

  Future<void> _loadMedications() async {
    final result = await _dataService.getPatientMedications(widget.patientId);
    if (result.isSuccess) {
      setState(() => medications = result.data ?? []);
    }
  }

  Future<void> _loadAlerts() async {
    final result = await _interactionService.getPatientAlerts(widget.patientId);
    if (result.isSuccess) {
      setState(() => alerts = result.data ?? []);
    }
  }

  Future<void> _checkInteractions() async {
    if (medications.isNotEmpty) {
      final result = await _interactionService.checkMedicationListInteractions(
        patientId: widget.patientId,
        medications: medications,
      );
      if (result.isSuccess) {
        setState(() => interactions = result.data ?? []);
      }
    }
  }

  void _subscribeToAlerts() {
    _alertSubscription = _interactionService.alertStream.listen((alert) {
      if (alert.patientId == widget.patientId) {
        setState(() {
          alerts.add(alert);
        });
        _showNewAlertDialog(alert);
      }
    });
  }

  void _showNewAlertDialog(DrugInteractionAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getSeverityIcon(alert.interaction.severity),
              color: _getSeverityColor(alert.interaction.severity),
            ),
            const SizedBox(width: 8),
            const Text('Drug Interaction Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.interaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Drugs: ${alert.interaction.drugA} + ${alert.interaction.drugB}'),
            Text('Severity: ${alert.interaction.severity.name.toUpperCase()}'),
            const SizedBox(height: 8),
            const Text('Recommendations:'),
            ...alert.interaction.recommendations.map((rec) => Text('• $rec')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _acknowledgeAlert(alert.id);
            },
            child: const Text('Acknowledge'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    await _interactionService.acknowledgeAlert(
      alertId: alertId,
      acknowledgedBy: 'Current User', // Replace with actual user
      notes: 'Acknowledged via mobile app',
    );
    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drug Interactions - ${patient?.name ?? 'Loading...'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${alerts.where((a) => !a.acknowledged).length}'),
                child: const Icon(Icons.warning),
              ),
              text: 'Alerts',
            ),
            const Tab(
              icon: Icon(Icons.medication),
              text: 'Medications',
            ),
            const Tab(
              icon: Icon(Icons.analytics),
              text: 'Analysis',
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsTab(),
                _buildMedicationsTab(),
                _buildAnalysisTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No active drug interaction alerts'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildAlertCard(DrugInteractionAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          _getSeverityIcon(alert.interaction.severity),
          color: _getSeverityColor(alert.interaction.severity),
        ),
        title: Text(
          '${alert.interaction.drugA} + ${alert.interaction.drugB}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.interaction.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(alert.interaction.severity.name.toUpperCase()),
                  backgroundColor: _getSeverityColor(alert.interaction.severity).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getSeverityColor(alert.interaction.severity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (alert.acknowledged)
                  const Chip(
                    label: Text('ACKNOWLEDGED'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
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
                _buildInfoSection('Mechanism', alert.interaction.mechanism),
                const SizedBox(height: 12),
                _buildInfoSection('Symptoms to Watch', alert.interaction.symptoms.join(', ')),
                const SizedBox(height: 12),
                _buildInfoSection('Recommendations', ''),
                ...alert.interaction.recommendations.map((rec) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!alert.acknowledged) ...[
                      ElevatedButton.icon(
                        onPressed: () => _acknowledgeAlert(alert.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Acknowledge'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _showInteractionDetails(alert.interaction),
                      icon: const Icon(Icons.info),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    return RefreshIndicator(
      onRefresh: _loadMedications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medications.length,
        itemBuilder: (context, index) {
          final medication = medications[index];
          return _buildMedicationCard(medication);
        },
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    // Find interactions for this medication
    final medicationInteractions = interactions.where(
      (interaction) => 
          interaction.drugA.toLowerCase() == medication.name.toLowerCase() ||
          interaction.drugB.toLowerCase() == medication.name.toLowerCase(),
    ).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${medication.dosage} - ${medication.frequency}'),
            if (medicationInteractions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: _getHighestSeverityColor(medicationInteractions),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${medicationInteractions.length} interaction(s)',
                      style: TextStyle(
                        color: _getHighestSeverityColor(medicationInteractions),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'check',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Check Interactions'),
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove'),
              ),
            ),
          ],
          onSelected: (value) => _handleMedicationAction(value as String, medication),
        ),
        onTap: () => _showMedicationInteractions(medication),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisCard(
            'Interaction Summary',
            Column(
              children: [
                _buildStatRow('Total Medications', medications.length.toString()),
                _buildStatRow('Active Interactions', interactions.length.toString()),
                _buildStatRow('Critical Alerts', 
                    alerts.where((a) => a.interaction.severity == InteractionSeverity.contraindicated).length.toString()),
                _buildStatRow('Unacknowledged Alerts', 
                    alerts.where((a) => !a.acknowledged).length.toString()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisCard(
            'Risk Assessment',
            Column(
              children: [
                _buildRiskMeter(),
                const SizedBox(height: 16),
                Text(_getRiskAssessment()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisCard(
            'Recommendations',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getGeneralRecommendations().map((rec) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            content,
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

  Widget _buildRiskMeter() {
    final riskScore = _calculateRiskScore();
    final color = _getRiskColor(riskScore);
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: riskScore,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 8),
        Text(
          '${(riskScore * 100).toInt()}% Risk Score',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (content.isNotEmpty)
          Text(content),
      ],
    );
  }

  IconData _getSeverityIcon(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return Icons.info;
      case InteractionSeverity.moderate:
        return Icons.warning;
      case InteractionSeverity.major:
        return Icons.error;
      case InteractionSeverity.contraindicated:
        return Icons.dangerous;
    }
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return Colors.blue;
      case InteractionSeverity.moderate:
        return Colors.orange;
      case InteractionSeverity.major:
        return Colors.red;
      case InteractionSeverity.contraindicated:
        return Colors.red[900]!;
    }
  }

  Color _getHighestSeverityColor(List<DrugInteraction> interactions) {
    if (interactions.isEmpty) return Colors.grey;
    
    final maxSeverity = interactions
        .map((i) => i.severity.index)
        .reduce((a, b) => a > b ? a : b);
    
    return _getSeverityColor(InteractionSeverity.values[maxSeverity]);
  }

  double _calculateRiskScore() {
    if (interactions.isEmpty) return 0.0;
    
    var totalScore = 0.0;
    for (final interaction in interactions) {
      switch (interaction.severity) {
        case InteractionSeverity.minor:
          totalScore += 0.1;
          break;
        case InteractionSeverity.moderate:
          totalScore += 0.3;
          break;
        case InteractionSeverity.major:
          totalScore += 0.6;
          break;
        case InteractionSeverity.contraindicated:
          totalScore += 1.0;
          break;
      }
    }
    
    return (totalScore / interactions.length).clamp(0.0, 1.0);
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore < 0.3) return Colors.green;
    if (riskScore < 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getRiskAssessment() {
    final riskScore = _calculateRiskScore();
    
    if (riskScore < 0.3) {
      return 'Low risk - Current medication regimen appears safe with minimal interactions.';
    } else if (riskScore < 0.6) {
      return 'Moderate risk - Some interactions present. Monitor patient closely and consider alternatives.';
    } else {
      return 'High risk - Significant interactions detected. Immediate review and modification recommended.';
    }
  }

  List<String> _getGeneralRecommendations() {
    final recommendations = <String>[];
    
    if (interactions.any((i) => i.severity == InteractionSeverity.contraindicated)) {
      recommendations.add('Immediately review contraindicated drug combinations');
    }
    
    if (interactions.any((i) => i.severity == InteractionSeverity.major)) {
      recommendations.add('Consider alternative medications for major interactions');
    }
    
    if (alerts.any((a) => !a.acknowledged)) {
      recommendations.add('Review and acknowledge all pending alerts');
    }
    
    recommendations.add('Regular medication review with clinical pharmacist');
    recommendations.add('Patient education on drug interaction symptoms');
    
    return recommendations;
  }

  void _handleMedicationAction(String action, Medication medication) {
    switch (action) {
      case 'check':
        _checkSingleMedication(medication);
        break;
      case 'edit':
        _editMedication(medication);
        break;
      case 'remove':
        _removeMedication(medication);
        break;
    }
  }

  Future<void> _checkSingleMedication(Medication medication) async {
    final result = await _interactionService.checkMedicationInteractions(
      patientId: widget.patientId,
      newMedication: medication,
    );
    
    if (result.isSuccess) {
      _showInteractionResults(medication.name, result.data ?? []);
    }
  }

  void _showInteractionResults(String medicationName, List<DrugInteraction> interactions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Interactions for $medicationName'),
        content: interactions.isEmpty
            ? const Text('No interactions found.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: interactions.map((interaction) => 
                    ListTile(
                      leading: Icon(
                        _getSeverityIcon(interaction.severity),
                        color: _getSeverityColor(interaction.severity),
                      ),
                      title: Text(interaction.drugB),
                      subtitle: Text(interaction.description),
                    ),
                  ).toList(),
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

  void _showMedicationInteractions(Medication medication) {
    final medicationInteractions = interactions.where(
      (interaction) => 
          interaction.drugA.toLowerCase() == medication.name.toLowerCase() ||
          interaction.drugB.toLowerCase() == medication.name.toLowerCase(),
    ).toList();
    
    _showInteractionResults(medication.name, medicationInteractions);
  }

  void _showInteractionDetails(DrugInteraction interaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${interaction.drugA} + ${interaction.drugB}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('Severity', interaction.severity.name.toUpperCase()),
              const SizedBox(height: 12),
              _buildInfoSection('Description', interaction.description),
              const SizedBox(height: 12),
              _buildInfoSection('Mechanism', interaction.mechanism),
              const SizedBox(height: 12),
              _buildInfoSection('Symptoms', interaction.symptoms.join(', ')),
              const SizedBox(height: 12),
              _buildInfoSection('Recommendations', ''),
              ...interaction.recommendations.map((rec) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $rec'),
                ),
              ),
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

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newMedication = Medication(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  patientId: widget.patientId,
                  name: nameController.text,
                  dosage: dosageController.text,
                  frequency: frequencyController.text,
                  startDate: DateTime.now(),
                  prescribedBy: 'Current User',
                );
                
                // Check interactions before adding
                final result = await _interactionService.checkMedicationInteractions(
                  patientId: widget.patientId,
                  newMedication: newMedication,
                );
                
                Navigator.of(context).pop();
                
                if (result.isSuccess && result.data!.isNotEmpty) {
                  _showInteractionResults(newMedication.name, result.data!);
                }
                
                // Add medication and refresh
                await _dataService.insert('medications', newMedication.toMap());
                await _loadMedications();
                await _checkInteractions();
              }
            },
            child: const Text('Add & Check'),
          ),
        ],
      ),
    );
  }

  void _editMedication(Medication medication) {
    // Implementation for editing medication
  }

  void _removeMedication(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medication'),
        content: Text('Are you sure you want to remove ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dataService.delete('medications', medication.id);
              Navigator.of(context).pop();
              await _loadMedications();
              await _checkInteractions();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alertSubscription.cancel();
    super.dispose();
  }
}