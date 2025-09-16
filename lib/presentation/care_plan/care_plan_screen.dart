import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/models/models.dart';
import '../../database/services/data_service.dart';

class CarePlanScreen extends StatefulWidget {
  final String patientId;
  const CarePlanScreen({super.key, required this.patientId});

  @override
  State<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends State<CarePlanScreen> {
  late Future<List<CarePlan>> _futurePlans;

  @override
  void initState() {
    super.initState();
    _futurePlans = _loadPlans(force: true);
  }

  Future<List<CarePlan>> _loadPlans({bool force = false}) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    return await dataService.getCarePlansForPatient(widget.patientId, {"forceRefresh": force}["forceRefresh"] as bool);
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePlans = _loadPlans(force: true);
    });
  }

  Future<void> _addPlan() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final goalsController = TextEditingController();
    final interventionsController = TextEditingController();
    final assigneesController = TextEditingController();
    var status = CarePlanStatus.active;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Care Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              DropdownButtonFormField<CarePlanStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: CarePlanStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                onChanged: (v) => status = v ?? CarePlanStatus.active,
              ),
              const SizedBox(height: 8),
              TextField(controller: goalsController, decoration: const InputDecoration(labelText: 'Goals (comma-separated)')),
              const SizedBox(height: 8),
              TextField(controller: interventionsController, decoration: const InputDecoration(labelText: 'Interventions (comma-separated)')),
              const SizedBox(height: 8),
              TextField(controller: assigneesController, decoration: const InputDecoration(labelText: 'Assigned To (comma-separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dataService = Provider.of<DataService>(context, listen: false);
              final plan = CarePlan(
                patientId: widget.patientId,
                title: titleController.text,
                description: descController.text,
                status: status,
                goals: BaseModel.parseStringList(goalsController.text),
                interventions: BaseModel.parseStringList(interventionsController.text),
                assignedTo: BaseModel.parseStringList(assigneesController.text),
              );
              await dataService.createCarePlan(plan);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );

    if (saved == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Plans'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _addPlan, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<CarePlan>>(
        future: _futurePlans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plans = snapshot.data ?? [];
          if (plans.isEmpty) {
            return const Center(child: Text('No care plans found'));
          }
          return ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = plans[index];
              return ListTile(
                title: Text(p.title),
                subtitle: Text('${p.status.name} • Start: ${p.startDate.toIso8601String().split('T').first}'),
                onTap: () => _showPlanDetails(p),
              );
            },
          );
        },
      ),
    );
  }

  void _showPlanDetails(CarePlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(plan.description),
              const SizedBox(height: 12),
              Text('Goals: ${plan.goals.join(', ')}'),
              const SizedBox(height: 6),
              Text('Interventions: ${plan.interventions.join(', ')}'),
              const SizedBox(height: 6),
              Text('Assigned: ${plan.assignedTo.join(', ')}'),
            ],
          ),
        ),
      ),
    );
  }
}

