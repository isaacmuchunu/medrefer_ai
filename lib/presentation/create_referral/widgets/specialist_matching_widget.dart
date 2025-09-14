
import '../../../core/app_export.dart';

class SpecialistMatchingWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSpecialistSelected;

  const SpecialistMatchingWidget({
    Key? key,
    required this.onSpecialistSelected,
  }) : super(key: key);

  @override
  State<SpecialistMatchingWidget> createState() =>
      _SpecialistMatchingWidgetState();
}

class _SpecialistMatchingWidgetState extends State<SpecialistMatchingWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Map<String, dynamic>? _selectedSpecialist;
  final List<String> _favoriteSpecialists = [];

  final List<Map<String, dynamic>> _aiMatchedSpecialists = [
    {
      "id": "S001",
      "name": "Dr. Sarah Mitchell",
      "specialty": "Cardiology",
      "rating": 4.9,
      "reviewCount": 127,
      "distance": "2.3 miles",
      "availability": "Available today",
      "hospital": "St. Mary's Medical Center",
      "experience": "15 years",
      "photo":
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face",
      "matchScore": 95,
      "specializations": ["Interventional Cardiology", "Heart Failure"],
      "nextAvailable": "Today 2:00 PM",
      "acceptsInsurance": true,
    },
    {
      "id": "S002",
      "name": "Dr. Michael Rodriguez",
      "specialty": "Cardiology",
      "rating": 4.8,
      "reviewCount": 89,
      "distance": "3.7 miles",
      "availability": "Available tomorrow",
      "hospital": "Central Hospital",
      "experience": "12 years",
      "photo":
          "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face",
      "matchScore": 92,
      "specializations": ["Cardiac Surgery", "Valve Repair"],
      "nextAvailable": "Tomorrow 9:00 AM",
      "acceptsInsurance": true,
    },
    {
      "id": "S003",
      "name": "Dr. Emily Chen",
      "specialty": "Cardiology",
      "rating": 4.7,
      "reviewCount": 156,
      "distance": "5.1 miles",
      "availability": "Available in 2 days",
      "hospital": "University Medical Center",
      "experience": "18 years",
      "photo":
          "https://images.unsplash.com/photo-1594824475317-1c5b8b9b5d3e?w=400&h=400&fit=crop&crop=face",
      "matchScore": 88,
      "specializations": ["Electrophysiology", "Arrhythmia"],
      "nextAvailable": "Aug 31, 10:00 AM",
      "acceptsInsurance": false,
    },
  ];

  void _selectSpecialist(Map<String, dynamic> specialist) {
    setState(() {
      _selectedSpecialist = specialist;
    });
    widget.onSpecialistSelected(specialist);
  }

  void _toggleFavorite(String specialistId) {
    setState(() {
      if (_favoriteSpecialists.contains(specialistId)) {
        _favoriteSpecialists.remove(specialistId);
      } else {
        _favoriteSpecialists.add(specialistId);
      }
    });
  }

  void _dismissSpecialist() {
    if (_currentIndex < _aiMatchedSpecialists.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildSpecialistCard(Map<String, dynamic> specialist) {
    final isFavorite = _favoriteSpecialists.contains(specialist['id']);
    final isSelected = _selectedSpecialist?['id'] == specialist['id'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with photo and basic info
          Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImageWidget(
                      imageUrl: specialist['photo'] as String,
                      width: 16.w,
                      height: 16.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${specialist['matchScore']}%',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialist['name'] as String,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      specialist['specialty'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: AppTheme.warningLight,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${specialist['rating']} (${specialist['reviewCount']})',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                        SizedBox(width: 3.w),
                        CustomIconWidget(
                          iconName: 'location_on',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          specialist['distance'] as String,
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFavorite(specialist['id'] as String),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isFavorite
                        ? AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFavorite
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: isFavorite ? 'favorite' : 'favorite_border',
                    color: isFavorite
                        ? AppTheme.lightTheme.colorScheme.error
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Specializations
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children:
                (specialist['specializations'] as List<String>).map((spec) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.secondary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  spec,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 3.h),

          // Details
          Container(
            padding: EdgeInsets.all(3.w),
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
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'local_hospital',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        specialist['hospital'] as String,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Next available: ${specialist['nextAvailable']}',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: specialist['acceptsInsurance'] as bool
                          ? 'check_circle'
                          : 'cancel',
                      color: specialist['acceptsInsurance'] as bool
                          ? AppTheme.lightTheme.colorScheme.secondary
                          : AppTheme.lightTheme.colorScheme.error,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        specialist['acceptsInsurance'] as bool
                            ? 'Accepts your insurance'
                            : 'Insurance not accepted',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: specialist['acceptsInsurance'] as bool
                              ? AppTheme.lightTheme.colorScheme.secondary
                              : AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismissSpecialist,
                  child: const Text('Skip'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _selectSpecialist(specialist),
                  child: Text(isSelected ? 'Selected' : 'Select'),
                ),
              ),
            ],
          ),
        ],
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
                iconName: 'auto_awesome',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'AI Specialist Matching',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.w,
                  vertical: 0.5.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_aiMatchedSpecialists.length}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Specialist cards
          SizedBox(
            height: 50.h,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _aiMatchedSpecialists.length,
              itemBuilder: (context, index) {
                return _buildSpecialistCard(_aiMatchedSpecialists[index]);
              },
            ),
          ),

          SizedBox(height: 2.h),

          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _aiMatchedSpecialists.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
