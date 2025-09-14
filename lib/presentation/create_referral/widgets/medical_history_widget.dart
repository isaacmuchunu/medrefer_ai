
import '../../../core/app_export.dart';

class MedicalHistoryWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onHistoryUpdated;

  const MedicalHistoryWidget({
    Key? key,
    required this.onHistoryUpdated,
  }) : super(key: key);

  @override
  State<MedicalHistoryWidget> createState() => _MedicalHistoryWidgetState();
}

class _MedicalHistoryWidgetState extends State<MedicalHistoryWidget> {
  bool _isExpanded = false;
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  bool _isRecordingConditions = false;
  bool _isRecordingMedications = false;
  bool _isRecordingAllergies = false;

  final List<String> _commonConditions = [
    'Hypertension',
    'Type 2 Diabetes',
    'Hyperlipidemia',
    'Coronary Artery Disease',
    'Asthma',
    'COPD',
    'Arthritis',
    'Depression',
    'Anxiety',
    'Chronic Kidney Disease',
  ];

  final List<String> _commonMedications = [
    'Lisinopril',
    'Metformin',
    'Atorvastatin',
    'Amlodipine',
    'Omeprazole',
    'Levothyroxine',
    'Albuterol',
    'Ibuprofen',
    'Aspirin',
    'Gabapentin',
  ];

  final List<String> _commonAllergies = [
    'Penicillin',
    'Sulfa drugs',
    'Latex',
    'Shellfish',
    'Nuts',
    'Eggs',
    'Milk',
    'Soy',
    'Wheat',
    'Pollen',
  ];

  void _updateHistory() {
    final historyData = {
      'conditions': _conditionsController.text,
      'medications': _medicationsController.text,
      'allergies': _allergiesController.text,
    };
    widget.onHistoryUpdated(historyData);
  }

  void _toggleVoiceRecording(String field) {
    setState(() {
      switch (field) {
        case 'conditions':
          _isRecordingConditions = !_isRecordingConditions;
          break;
        case 'medications':
          _isRecordingMedications = !_isRecordingMedications;
          break;
        case 'allergies':
          _isRecordingAllergies = !_isRecordingAllergies;
          break;
      }
    });

    // Voice recording functionality would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Voice recording for $field ${_isRecordingConditions || _isRecordingMedications || _isRecordingAllergies ? 'started' : 'stopped'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required List<String> suggestions,
    required bool isRecording,
    required VoidCallback onVoiceToggle,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (_) => _updateHistory(),
            decoration: InputDecoration(
              hintText: 'Enter $label...',
              suffixIcon: GestureDetector(
                onTap: onVoiceToggle,
                child: Container(
                  margin: EdgeInsets.all(2.w),
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomIconWidget(
                    iconName: isRecording ? 'stop' : 'mic',
                    color: isRecording
                        ? AppTheme.lightTheme.colorScheme.error
                        : AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 2.h,
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),

        // Common suggestions
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: suggestions.take(5).map((suggestion) {
            return GestureDetector(
              onTap: () {
                final currentText = controller.text;
                final newText = currentText.isEmpty
                    ? suggestion
                    : '$currentText, $suggestion';
                controller.text = newText;
                _updateHistory();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  suggestion,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'medical_information',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Medical History',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                CustomIconWidget(
                  iconName: _isExpanded ? 'expand_less' : 'expand_more',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            SizedBox(height: 3.h),

            // Conditions
            _buildTextField(
              label: 'Current Conditions',
              controller: _conditionsController,
              suggestions: _commonConditions,
              isRecording: _isRecordingConditions,
              onVoiceToggle: () => _toggleVoiceRecording('conditions'),
            ),

            SizedBox(height: 3.h),

            // Medications
            _buildTextField(
              label: 'Current Medications',
              controller: _medicationsController,
              suggestions: _commonMedications,
              isRecording: _isRecordingMedications,
              onVoiceToggle: () => _toggleVoiceRecording('medications'),
            ),

            SizedBox(height: 3.h),

            // Allergies
            _buildTextField(
              label: 'Known Allergies',
              controller: _allergiesController,
              suggestions: _commonAllergies,
              isRecording: _isRecordingAllergies,
              onVoiceToggle: () => _toggleVoiceRecording('allergies'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _conditionsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}
