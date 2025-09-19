import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_export.dart';

class InsuranceVerification extends StatefulWidget {
  const InsuranceVerification({super.key});

  @override
  State<InsuranceVerification> createState() => _InsuranceVerificationState();
}

class _InsuranceVerificationState extends State<InsuranceVerification> {
  List<Map<String, dynamic>> _insuranceDocs = [];
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadInsuranceDocs();
  }

  Future<void> _loadInsuranceDocs() async {
    setState(() => _isLoading = true);
    final dataService = Provider.of<DataService>(context, listen: false);
    // Assume InsuranceDAO exists
    _insuranceDocs = await dataService.insuranceDAO.getInsuranceByPatientId('patientId') ?? []; // Replace with actual ID
    setState(() => _isLoading = false);
  }

  void _startScanning() {
    setState(() => _isScanning = true);
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        // Process scanned data, e.g., verify insurance
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: ${barcode.rawValue}')));
        // Implement verification logic
        setState(() => _isScanning = false);
        _loadInsuranceDocs(); // Refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Verification'),
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'refresh', size: 24),
            onPressed: _loadInsuranceDocs,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScanning,
        child: const Icon(Icons.camera_alt),
      ),
      body: _isScanning
          ? MobileScanner(
              onDetect: _onDetect,
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _insuranceDocs.length,
                  itemBuilder: (context, index) {
                    final doc = _insuranceDocs[index];
                    return ListTile(
                      title: Text(doc['provider']),
                      subtitle: Text('Policy: ${doc['policyNumber']} | Status: ${doc['status']}'),
                    );
                  },
                ),
    );
  }
}
