import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class LabResults extends StatefulWidget {
  const LabResults({Key? key}) : super(key: key);

  @override
  State<LabResults> createState() => _LabResultsState();
}

class _LabResultsState extends State<LabResults> {
  List<Map<String, dynamic>> _labResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLabResults();
  }

  Future<void> _loadLabResults() async {
    setState(() => _isLoading = true);
    final dataService = Provider.of<DataService>(context, listen: false);
    // Assume LabResultDAO exists
    _labResults = await dataService.labResultDAO?.getLabResultsForPatient('patientId') ?? []; // Replace with actual ID
    setState(() => _isLoading = false);
  }

  Future<void> _uploadLabResult() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) {
      // Implement upload logic, e.g., save to database or storage
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lab result uploaded successfully')));
      _loadLabResults(); // Refresh list
    }
  }

  void _viewLabResult(Map<String, dynamic> result) {
    // Using the same hardcoded patientId as in _loadLabResults, which is a placeholder.
    Navigator.pushNamed(context, AppRoutes.documentViewerScreen, arguments: {
      'documentId': result['documentId'] ?? result['path'],
      'patientId': 'patientId',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Results'),
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'refresh', size: 24),
            onPressed: _loadLabResults,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadLabResult,
        child: const Icon(Icons.upload),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _labResults.length,
              itemBuilder: (context, index) {
                final result = _labResults[index];
                return ListTile(
                  title: Text(result['testName']),
                  subtitle: Text(result['date']),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _viewLabResult(result),
                  ),
                );
              },
            ),
    );
  }
}