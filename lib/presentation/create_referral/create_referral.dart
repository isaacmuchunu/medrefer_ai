
import '../../core/app_export.dart';
import './widgets/document_upload_widget.dart';
import './widgets/medical_history_widget.dart';
import './widgets/patient_selection_widget.dart';
import './widgets/specialist_matching_widget.dart';
import './widgets/symptoms_description_widget.dart';
import './widgets/urgency_selector_widget.dart';

class CreateReferral extends StatefulWidget {
  const CreateReferral({Key? key}) : super(key: key);

  @override
  State<CreateReferral> createState() => _CreateReferralState();
}

class _CreateReferralState extends State<CreateReferral> {
  final ScrollController _scrollController = ScrollController();

  // Form data
  Map<String, dynamic>? _selectedPatient;
  Map<String, dynamic> _medicalHistory = {};
  String _symptomsDescription = '';
  String _urgencyLevel = '';
  Map<String, dynamic>? _selectedSpecialist;
  List<Map<String, dynamic>> _uploadedDocuments = [];

  bool _isFormValid = false;
  bool _isSaving = false;

  void _validateForm() {
    setState(() {
      _isFormValid = _selectedPatient != null &&
          _symptomsDescription.isNotEmpty &&
          _urgencyLevel.isNotEmpty &&
          _selectedSpecialist != null;
    });
  }

  void _onPatientSelected(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
    });
    _validateForm();
  }

  void _onHistoryUpdated(Map<String, dynamic> history) {
    setState(() {
      _medicalHistory = history;
    });
  }

  void _onSymptomsUpdated(String symptoms) {
    setState(() {
      _symptomsDescription = symptoms;
    });
    _validateForm();
  }

  void _onUrgencySelected(String urgency) {
    setState(() {
      _urgencyLevel = urgency;
    });
    _validateForm();
  }

  void _onSpecialistSelected(Map<String, dynamic> specialist) {
    setState(() {
      _selectedSpecialist = specialist;
    });
    _validateForm();
  }

  void _onDocumentsUpdated(List<Map<String, dynamic>> documents) {
    setState(() {
      _uploadedDocuments = documents;
    });
  }

  Future<void> _saveDraft() async {
    setState(() {
      _isSaving = true;
    });

    // Simulate saving draft
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _previewReferral() {
    if (!_isFormValid) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPreviewBottomSheet(),
    );
  }

  Widget _buildPreviewBottomSheet() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  'Referral Preview',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Preview content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient info
                  _buildPreviewSection(
                    'Patient Information',
                    '${_selectedPatient!['name']} (${_selectedPatient!['mrn']})\nAge: ${_selectedPatient!['age']} • ${_selectedPatient!['gender']}',
                  ),

                  // Symptoms
                  _buildPreviewSection('Symptoms', _symptomsDescription),

                  // Urgency
                  _buildPreviewSection('Urgency Level', _urgencyLevel),

                  // Specialist
                  _buildPreviewSection(
                    'Selected Specialist',
                    '${_selectedSpecialist!['name']}\n${_selectedSpecialist!['specialty']} • ${_selectedSpecialist!['hospital']}',
                  ),

                  // Documents
                  if (_uploadedDocuments.isNotEmpty)
                    _buildPreviewSection(
                      'Documents',
                      '${_uploadedDocuments.length} document(s) attached',
                    ),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReferral,
                child: const Text('Submit Referral'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _submitReferral() async {
    Navigator.pop(context); // Close preview

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 2.h),
            const Text('Submitting referral...'),
          ],
        ),
      ),
    );

    // Simulate submission
    await Future.delayed(const Duration(seconds: 2));

    Navigator.pop(context); // Close loading dialog

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.secondary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Text('Referral Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your referral has been successfully submitted.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracking Number',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Estimated Response Time',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _urgencyLevel == 'Emergency'
                        ? 'Immediate'
                        : _urgencyLevel == 'Urgent'
                            ? '24-48 hours'
                            : '2-4 weeks',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/referral-tracking');
            },
            child: const Text('Track Referral'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Referral'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'close',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDraft,
            child: _isSaving
                ? SizedBox(
                    width: 4.w,
                    height: 4.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Complete all required fields',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_getCompletionPercentage()}% Complete',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: _getCompletionPercentage() / 100,
                  backgroundColor: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Patient Selection
                  PatientSelectionWidget(
                    onPatientSelected: _onPatientSelected,
                  ),
                  SizedBox(height: 4.h),

                  // Medical History
                  MedicalHistoryWidget(
                    onHistoryUpdated: _onHistoryUpdated,
                  ),
                  SizedBox(height: 4.h),

                  // Symptoms Description
                  SymptomsDescriptionWidget(
                    onSymptomsUpdated: _onSymptomsUpdated,
                  ),
                  SizedBox(height: 4.h),

                  // Urgency Level
                  UrgencySelectorWidget(
                    onUrgencySelected: _onUrgencySelected,
                  ),
                  SizedBox(height: 4.h),

                  // AI Specialist Matching
                  if (_symptomsDescription.isNotEmpty &&
                      _urgencyLevel.isNotEmpty) ...[
                    SpecialistMatchingWidget(
                      onSpecialistSelected: _onSpecialistSelected,
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // Document Upload
                  DocumentUploadWidget(
                    onDocumentsUpdated: _onDocumentsUpdated,
                  ),

                  SizedBox(height: 10.h), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom sticky buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isFormValid ? _previewReferral : null,
                  child: const Text('Preview Referral'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isFormValid ? _previewReferral : null,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCompletionPercentage() {
    int completed = 0;
    int total = 4; // Required fields: patient, symptoms, urgency, specialist

    if (_selectedPatient != null) completed++;
    if (_symptomsDescription.isNotEmpty) completed++;
    if (_urgencyLevel.isNotEmpty) completed++;
    if (_selectedSpecialist != null) completed++;

    return ((completed / total) * 100).round();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
