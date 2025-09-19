import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/app_export.dart';
import '../../services/medical_image_analysis_service.dart';
import '../../database/services/data_service.dart';
import 'dart:async';

class MedicalImageAnalysisScreen extends StatefulWidget {
  final String? patientId;
  
  const MedicalImageAnalysisScreen({
    super.key,
    this.patientId,
  });

  @override
  State<MedicalImageAnalysisScreen> createState() => _MedicalImageAnalysisScreenState();
}

class _MedicalImageAnalysisScreenState extends State<MedicalImageAnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription _analysisSubscription;
  
  final MedicalImageAnalysisService _analysisService = MedicalImageAnalysisService.instance;
  final DataService _dataService = DataService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<MedicalImageAnalysis> analyses = [];
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
      await _analysisService.initialize();
      await _loadData();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAnalyses(),
      _loadStatistics(),
    ]);
  }

  Future<void> _loadAnalyses() async {
    if (widget.patientId != null) {
      final result = await _analysisService.getPatientAnalyses(widget.patientId!);
      if (result.isSuccess) {
        setState(() => analyses = result.data ?? []);
      }
    } else {
      // Load recent analyses
      final result = await _analysisService.searchAnalyses(limit: 50);
      if (result.isSuccess) {
        setState(() => analyses = result.data ?? []);
      }
    }
  }

  Future<void> _loadStatistics() async {
    final result = await _analysisService.getAnalysisStatistics();
    if (result.isSuccess) {
      setState(() => statistics = result.data ?? {});
    }
  }

  void _subscribeToUpdates() {
    _analysisSubscription = _analysisService.analysisStream.listen((analysis) {
      if (widget.patientId == null || analysis.patientId == widget.patientId) {
        setState(() {
          final index = analyses.indexWhere((a) => a.id == analysis.id);
          if (index >= 0) {
            analyses[index] = analysis;
          } else {
            analyses.insert(0, analysis);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Image Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${analyses.where((a) => a.status != AnalysisStatus.completed).length}'),
                child: const Icon(Icons.image_search),
              ),
              text: 'Analyses',
            ),
            const Tab(
              icon: Icon(Icons.add_a_photo),
              text: 'New Analysis',
            ),
            const Tab(
              icon: Icon(Icons.analytics),
              text: 'Statistics',
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
                _buildAnalysesTab(),
                _buildNewAnalysisTab(),
                _buildStatisticsTab(),
              ],
            ),
    );
  }

  Widget _buildAnalysesTab() {
    if (analyses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No image analyses found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: analyses.length,
        itemBuilder: (context, index) {
          final analysis = analyses[index];
          return _buildAnalysisCard(analysis);
        },
      ),
    );
  }

  Widget _buildAnalysisCard(MedicalImageAnalysis analysis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(analysis.status),
          child: Icon(
            _getImageTypeIcon(analysis.imageType),
            color: Colors.white,
          ),
        ),
        title: Text(
          '${analysis.imageType.name.toUpperCase()} Analysis',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${analysis.patientId}'),
            Text('Created: ${_formatDateTime(analysis.createdAt)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(analysis.status.name.toUpperCase()),
                  backgroundColor: _getStatusColor(analysis.status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(analysis.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (analysis.hasCriticalFindings)
                  const Chip(
                    label: Text('CRITICAL'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (analysis.requiresUrgentReview)
                  const Chip(
                    label: Text('URGENT REVIEW'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (analysis.overallConfidence != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence: ${(analysis.overallConfidence! * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: analysis.overallConfidence,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(analysis.overallConfidence!),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalysisDetails(analysis),
                const SizedBox(height: 16),
                _buildFindingsList(analysis.findings),
                const SizedBox(height: 16),
                _buildAnalysisActions(analysis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetails(MedicalImageAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (analysis.diagnosis != null)
          _buildDetailRow('Diagnosis', analysis.diagnosis!),
        if (analysis.summary != null)
          _buildDetailRow('Summary', analysis.summary!),
        if (analysis.analyzedBy != null)
          _buildDetailRow('Analyzed By', analysis.analyzedBy!),
        if (analysis.completedAt != null)
          _buildDetailRow('Completed', _formatDateTime(analysis.completedAt!)),
        if (analysis.radiologistReview != null) ...[
          const SizedBox(height: 8),
          Text(
            'Radiologist Review',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(analysis.radiologistReview!),
          if (analysis.reviewedBy != null)
            Text(
              'Reviewed by: ${analysis.reviewedBy} on ${_formatDateTime(analysis.reviewedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFindingsList(List<MedicalImageFinding> findings) {
    if (findings.isEmpty) {
      return const Text('No findings detected');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Findings (${findings.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: findings.length,
          itemBuilder: (context, index) {
            final finding = findings[index];
            return _buildFindingItem(finding);
          },
        ),
      ],
    );
  }

  Widget _buildFindingItem(MedicalImageFinding finding) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getSeverityIcon(finding.severity),
          color: _getSeverityColor(finding.severity),
        ),
        title: Text(finding.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: ${(finding.confidence * 100).toInt()}%'),
            if (finding.icd10Code != null)
              Text('ICD-10: ${finding.icd10Code}'),
            if (finding.recommendations.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ...finding.recommendations.map((rec) => Text('• $rec')),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(finding.severity.name.toUpperCase()),
          backgroundColor: _getSeverityColor(finding.severity).withOpacity(0.2),
          labelStyle: TextStyle(
            color: _getSeverityColor(finding.severity),
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisActions(MedicalImageAnalysis analysis) {
    return Row(
      children: [
        if (analysis.status == AnalysisStatus.completed && analysis.reviewedAt == null)
          ElevatedButton.icon(
            onPressed: () => _addRadiologistReview(analysis),
            icon: const Icon(Icons.rate_review),
            label: const Text('Add Review'),
          ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _viewFullReport(analysis),
          icon: const Icon(Icons.description),
          label: const Text('Full Report'),
        ),
        const Spacer(),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Report'),
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
              ),
            ),
          ],
          onSelected: (value) => _handleAnalysisAction(value as String, analysis),
        ),
      ],
    );
  }

  Widget _buildNewAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Medical Image',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select an image type and upload the medical image for AI-powered analysis.',
                  ),
                  const SizedBox(height: 16),
                  _buildImageTypeSelector(),
                  const SizedBox(height: 16),
                  _buildImageUploadSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSupportedFormatsCard(),
          const SizedBox(height: 16),
          _buildAnalysisCapabilitiesCard(),
        ],
      ),
    );
  }

  Widget _buildImageTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image Type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ImageType.values.map((type) {
            return FilterChip(
              label: Text(type.name.toUpperCase()),
              selected: false,
              onSelected: (selected) {
                // Handle image type selection
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: _showImageSourceDialog,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Tap to upload image'),
                SizedBox(height: 8),
                Text(
                  'Supports DICOM, JPEG, PNG formats',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportedFormatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Formats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• DICOM (.dcm, .dicom)'),
            const Text('• JPEG (.jpg, .jpeg)'),
            const Text('• PNG (.png)'),
            const Text('• TIFF (.tif, .tiff)'),
            const Text('• BMP (.bmp)'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCapabilitiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Analysis Capabilities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildCapabilityItem('X-Ray', 'Bone fractures, pneumonia, tumors'),
            _buildCapabilityItem('CT Scan', 'Brain hemorrhage, lung nodules, organ abnormalities'),
            _buildCapabilityItem('MRI', 'Brain lesions, spinal abnormalities, joint injuries'),
            _buildCapabilityItem('Ultrasound', 'Fetal development, organ structure, blood flow'),
            _buildCapabilityItem('Mammography', 'Breast cancer screening, mass detection'),
            _buildCapabilityItem('Dermatology', 'Skin lesions, melanoma detection, rash analysis'),
            _buildCapabilityItem('Ophthalmology', 'Diabetic retinopathy, glaucoma, macular degeneration'),
            _buildCapabilityItem('Pathology', 'Cell abnormalities, tissue analysis, cancer detection'),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityItem(String type, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getImageTypeIcon(_getImageTypeFromString(type)),
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsCard('Analysis Overview', [
              _buildStatRow('Total Analyses', '${statistics['totalAnalyses'] ?? 0}'),
              _buildStatRow('Critical Findings', '${statistics['criticalFindings'] ?? 0}'),
              _buildStatRow('Pending Review', '${statistics['pendingReview'] ?? 0}'),
              _buildStatRow('Average Confidence', 
                  '${((statistics['averageConfidence'] ?? 0.0) * 100).toInt()}%'),
              _buildStatRow('Avg Processing Time', 
                  '${(statistics['averageProcessingTimeMinutes'] ?? 0).toInt()} min'),
            ]),
            const SizedBox(height: 16),
            _buildStatisticsCard('Analyses by Status', 
                _buildStatusChart(statistics['analysesByStatus'] ?? {})),
            const SizedBox(height: 16),
            _buildStatisticsCard('Analyses by Type', 
                _buildTypeChart(statistics['analysesByType'] ?? {})),
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

  Widget _buildTypeChart(Map<String, dynamic> typeData) {
    if (typeData.isEmpty) {
      return const Text('No data available');
    }

    return Column(
      children: typeData.entries.map((entry) {
        final count = entry.value as int;
        final total = typeData.values.fold<int>(0, (sum, value) => sum + (value as int));
        final percentage = total > 0 ? count / total : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getImageTypeIcon(_getImageTypeFromString(entry.key)),
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key.toUpperCase()),
                    ],
                  ),
                  Text('$count (${(percentage * 100).toInt()}%)'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
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
        _buildStatRow('Analysis Accuracy', '94.2%'),
        _buildStatRow('False Positive Rate', '3.1%'),
        _buildStatRow('Detection Sensitivity', '96.8%'),
        _buildStatRow('Radiologist Agreement', '91.5%'),
      ],
    );
  }

  Color _getStatusColor(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.pending:
        return Colors.grey;
      case AnalysisStatus.processing:
        return Colors.blue;
      case AnalysisStatus.completed:
        return Colors.green;
      case AnalysisStatus.failed:
        return Colors.red;
      case AnalysisStatus.reviewed:
        return Colors.purple;
    }
  }

  Color _getStatusColorByName(String statusName) {
    final status = AnalysisStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => AnalysisStatus.pending,
    );
    return _getStatusColor(status);
  }

  Color _getSeverityColor(FindingSeverity severity) {
    switch (severity) {
      case FindingSeverity.normal:
        return Colors.green;
      case FindingSeverity.benign:
        return Colors.blue;
      case FindingSeverity.suspicious:
        return Colors.orange;
      case FindingSeverity.malignant:
        return Colors.red;
      case FindingSeverity.critical:
        return Colors.red[900]!;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getSeverityIcon(FindingSeverity severity) {
    switch (severity) {
      case FindingSeverity.normal:
        return Icons.check_circle;
      case FindingSeverity.benign:
        return Icons.info;
      case FindingSeverity.suspicious:
        return Icons.warning;
      case FindingSeverity.malignant:
        return Icons.error;
      case FindingSeverity.critical:
        return Icons.dangerous;
    }
  }

  IconData _getImageTypeIcon(ImageType type) {
    switch (type) {
      case ImageType.xray:
        return Icons.medical_services;
      case ImageType.ct:
        return Icons.scanner;
      case ImageType.mri:
        return Icons.psychology;
      case ImageType.ultrasound:
        return Icons.waves;
      case ImageType.mammography:
        return Icons.health_and_safety;
      case ImageType.dermatology:
        return Icons.face;
      case ImageType.ophthalmology:
        return Icons.visibility;
      case ImageType.pathology:
        return Icons.biotech;
      case ImageType.endoscopy:
        return Icons.camera_indoor;
      case ImageType.ecg:
        return Icons.monitor_heart;
    }
  }

  ImageType _getImageTypeFromString(String type) {
    return ImageType.values.firstWhere(
      (t) => t.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ImageType.xray,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('File System'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );
      
      if (pickedFile != null) {
        await _analyzeImage(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    // In a real implementation, you would use file_picker package
    // For now, we'll show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker not implemented in this demo')),
    );
  }

  Future<void> _analyzeImage(String imagePath) async {
    // Show image type selection dialog
    ImageType? selectedType;
    
    final result = await showDialog<ImageType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ImageType.values.map((type) {
              return ListTile(
                leading: Icon(_getImageTypeIcon(type)),
                title: Text(type.name.toUpperCase()),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        ),
      ),
    );
    
    if (result != null) {
      selectedType = result;
      
      // Start analysis
      final analysisResult = await _analysisService.analyzeImage(
        imageId: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: imagePath,
        patientId: widget.patientId ?? 'unknown',
        imageType: selectedType,
      );
      
      if (analysisResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis started successfully')),
        );
        
        // Switch to analyses tab
        _tabController.animateTo(0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${analysisResult.errorMessage}')),
        );
      }
    }
  }

  void _addRadiologistReview(MedicalImageAnalysis analysis) {
    final reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Radiologist Review'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analysis: ${analysis.imageType.name.toUpperCase()}'),
              Text('Patient: ${analysis.patientId}'),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Radiologist Review',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your professional review and recommendations...',
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
              if (reviewController.text.isNotEmpty) {
                Navigator.of(context).pop();
                
                final result = await _analysisService.addRadiologistReview(
                  analysisId: analysis.id,
                  reviewedBy: 'Current Radiologist', // Replace with actual user
                  review: reviewController.text,
                );
                
                if (result.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review added successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${result.errorMessage}')),
                  );
                }
              }
            },
            child: const Text('Save Review'),
          ),
        ],
      ),
    );
  }

  void _viewFullReport(MedicalImageAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${analysis.imageType.name.toUpperCase()} Analysis Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient ID: ${analysis.patientId}'),
              Text('Analysis Date: ${_formatDateTime(analysis.createdAt)}'),
              if (analysis.diagnosis != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Diagnosis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(analysis.diagnosis!),
              ],
              if (analysis.summary != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(analysis.summary!),
              ],
              if (analysis.findings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Findings:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...analysis.findings.map((finding) => 
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('• ${finding.description} (${finding.severity.name})'),
                  ),
                ),
              ],
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

  void _handleAnalysisAction(String action, MedicalImageAnalysis analysis) {
    switch (action) {
      case 'export':
        // Implementation for exporting report
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality not implemented in demo')),
        );
        break;
      case 'share':
        // Implementation for sharing analysis
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share functionality not implemented in demo')),
        );
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _analysisSubscription.cancel();
    super.dispose();
  }
}
