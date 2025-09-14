import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/app_export.dart';

class UrgencySelectorWidget extends StatefulWidget {
  final Function(String) onUrgencySelected;
  final String? initialUrgency;
  final String? errorText;
  final ValueNotifier<String>? symptomsNotifier;

  const UrgencySelectorWidget({
    Key? key,
    required this.onUrgencySelected,
    this.initialUrgency,
    this.errorText,
    this.symptomsNotifier,
  }) : super(key: key);

  @override
  State<UrgencySelectorWidget> createState() => _UrgencySelectorWidgetState();
}

class _UrgencySelectorWidgetState extends State<UrgencySelectorWidget>
    with TickerProviderStateMixin {
  String _selectedUrgency = '';
  late final AnimationController _pulseAnimationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _urgencyLevels = [
    {
      'level': 'Routine',
      'description': '2-4 weeks response time',
      'color': AppTheme.lightTheme.colorScheme.secondary,
      'icon': 'schedule',
      'timeframe': '2-4 weeks',
      'cost': '\$50-\$100',
      'keywords': ['follow-up', 'check-up', 'routine'],
    },
    {
      'level': 'Urgent',
      'description': '24-48 hours response time',
      'color': AppTheme.warningLight,
      'icon': 'warning',
      'timeframe': '24-48 hours',
      'cost': '\$150-\$300',
      'keywords': ['pain', 'infection', 'severe'],
    },
    {
      'level': 'Emergency',
      'description': 'Immediate response required',
      'color': AppTheme.lightTheme.colorScheme.error,
      'icon': 'emergency',
      'timeframe': 'Immediate',
      'cost': '\$500+',
      'keywords': ['chest pain', 'breathing difficulty', 'unconscious'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedUrgency = widget.initialUrgency ?? '';

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    widget.symptomsNotifier?.addListener(_autoSelectUrgency);
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _audioPlayer.dispose();
    widget.symptomsNotifier?.removeListener(_autoSelectUrgency);
    _focusNode.dispose();
    super.dispose();
  }

  void _autoSelectUrgency() {
    final symptoms = widget.symptomsNotifier?.value.toLowerCase() ?? '';
    if (symptoms.isEmpty) return;

    for (final urgency in _urgencyLevels.reversed) {
      for (final keyword in urgency['keywords'] as List<String>) {
        if (symptoms.contains(keyword)) {
          _selectUrgency(urgency['level'] as String);
          return;
        }
      }
    }
  }

  Future<void> _selectUrgency(String level) async {
    setState(() {
      _selectedUrgency = level;
    });

    HapticFeedback.selectionClick();

    if (level == 'Emergency') {
      await _audioPlayer.setAsset('assets/sounds/emergency_alert.mp3');
      _audioPlayer.play();
    }

    widget.onUrgencySelected(level);
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
                iconName: 'priority_high',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Urgency Level',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.errorText == null)
                Text(
                  '*Required',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),
          if (widget.errorText != null) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                widget.errorText!,
                style: AppTheme.lightTheme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.lightTheme.colorScheme.error),
              ),
            ),
          ],

          // Urgency level buttons
          Focus(
            focusNode: _focusNode,
            child: Column(
              children: _urgencyLevels.map((urgency) {
                final isSelected = _selectedUrgency == urgency['level'];
                final color = urgency['color'] as Color;
                final isEmergency = urgency['level'] == 'Emergency';

                Widget card = AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: urgency['icon'] as String,
                          color: color,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              urgency['level'] as String,
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? color : null,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              urgency['description'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Est. Cost: ${urgency['cost']}',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 16,
                          ),
                        )
                      else
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.outline,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  ),
                );

                if (isEmergency && isSelected) {
                  card = FadeTransition(
                    opacity:
                        Tween<double>(begin: 0.7, end: 1.0).animate(_pulseAnimationController),
                    child: card,
                  );
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: Tooltip(
                    message:
                        '${urgency['level']}: ${urgency['description']}. Estimated cost: ${urgency['cost']}',
                    child: GestureDetector(
                      onTap: () => _selectUrgency(urgency['level'] as String),
                      child: Semantics(
                        label:
                            'Urgency level: ${urgency['level']}. ${urgency['description']}. Estimated cost: ${urgency['cost']}',
                        value: isSelected ? 'Selected' : 'Not selected',
                        button: true,
                        child: card,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Additional information
          if (_selectedUrgency.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Response Time',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _urgencyLevels.firstWhere(
                            (level) => level['level'] == _selectedUrgency,
                          )['timeframe'] as String,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
