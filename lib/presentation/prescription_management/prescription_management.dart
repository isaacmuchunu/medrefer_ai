import '../../core/app_export.dart';

class PrescriptionManagement extends StatefulWidget {
  const PrescriptionManagement({super.key});

  @override
  State<PrescriptionManagement> createState() => _PrescriptionManagementState();
}

class _PrescriptionManagementState extends State<PrescriptionManagement> {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    final dataService = Provider.of<DataService>(context, listen: false);
    // Assume PrescriptionDAO exists
    _prescriptions = await dataService.prescriptionDAO.getPrescriptionsByPatientId('patientId') ?? []; // Replace with actual ID
    setState(() => _isLoading = false);
  }

  void _requestRefill(Map<String, dynamic> prescription) {
    // Implement refill request logic, e.g., API call or database update
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refill requested for ${prescription['name']}')));
  }

  void _setReminder(Map<String, dynamic> prescription) {
    // Implement reminder setup, e.g., local notifications
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${prescription['name']}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Management'),
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'refresh', size: 24),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                final presc = _prescriptions[index];
                return ListTile(
                  title: Text(presc['name']),
                  subtitle: Text('Dosage: ${presc['dosage']} | Refills left: ${presc['refills']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.alarm),
                        onPressed: () => _setReminder(presc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _requestRefill(presc),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
