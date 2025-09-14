
import '../../../core/app_export.dart';

class SymptomsDescriptionWidget extends StatefulWidget {
  final Function(String) onSymptomsUpdated;

  const SymptomsDescriptionWidget({
    Key? key,
    required this.onSymptomsUpdated,
  }) : super(key: key);

  @override
  State<SymptomsDescriptionWidget> createState() =>
      _SymptomsDescriptionWidgetState();
}

class _SymptomsDescriptionWidgetState extends State<SymptomsDescriptionWidget> {
  final TextEditingController _symptomsController = TextEditingController();
  bool _isRecording = false;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  final List<String> _medicalTerms = [
    'chest pain',
    'shortness of breath',
    'abdominal pain',
    'headache',
    'dizziness',
    'nausea',
    'vomiting',
    'fever',
    'fatigue',
    'joint pain',
    'muscle weakness',
    'palpitations',
    'syncope',
    'dyspnea',
    'orthopnea',
    'paroxysmal nocturnal dyspnea',
    'claudication',
    'edema',
    'cyanosis',
    'diaphoresis',
    'hemoptysis',
    'dysphagia',
    'melena',
    'hematuria',
    'polyuria',
    'polydipsia',
    'weight loss',
    'weight gain',
    'night sweats',
    'tremor',
    'seizure',
    'confusion',
    'memory loss',
    'visual disturbance',
    'hearing loss',
    'tinnitus',
    'vertigo',
    'rash',
    'pruritus',
    'jaundice',
    'lymphadenopathy',
  ];

  void _onTextChanged(String text) {
    widget.onSymptomsUpdated(text);

    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Get the last word being typed
    final words = text.toLowerCase().split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';

    if (lastWord.length >= 2) {
      final matchingSuggestions = _medicalTerms
          .where((term) => term.toLowerCase().contains(lastWord))
          .take(5)
          .toList();

      setState(() {
        _suggestions = matchingSuggestions;
        _showSuggestions = matchingSuggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _applySuggestion(String suggestion) {
    final text = _symptomsController.text;
    final words = text.split(' ');

    if (words.isNotEmpty) {
      words[words.length - 1] = suggestion;
      final newText = '${words.join(' ')} ';
      _symptomsController.text = newText;
      _symptomsController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }

    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });

    widget.onSymptomsUpdated(_symptomsController.text);
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    // Voice recording functionality would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Voice recording ${_isRecording ? 'started' : 'stopped'}'),
        duration: const Duration(seconds: 2),
      ),
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'description',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Symptoms Description',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '*Required',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // AI-powered text input
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _symptomsController,
                  onChanged: _onTextChanged,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Describe the patient\'s symptoms in detail...\n\nAI will suggest medical terminology as you type.',
                    suffixIcon: GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: Container(
                        margin: EdgeInsets.all(2.w),
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.1)
                              : AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomIconWidget(
                          iconName: _isRecording ? 'stop' : 'mic',
                          color: _isRecording
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

                // AI Suggestions
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.05),
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'auto_awesome',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'AI Suggestions',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: _suggestions.map((suggestion) {
                            return GestureDetector(
                              onTap: () => _applySuggestion(suggestion),
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
                                    color: AppTheme
                                        .lightTheme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  suggestion,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Character count and tips
          Row(
            children: [
              Text(
                '${_symptomsController.text.length}/1000 characters',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              CustomIconWidget(
                iconName: 'info_outline',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                'Be specific for better AI matching',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }
}
