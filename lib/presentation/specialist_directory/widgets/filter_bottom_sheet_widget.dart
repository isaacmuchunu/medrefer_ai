
import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheetWidget({
    Key? key,
    required this.currentFilters,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;
  double _radiusValue = 10.0;

  final List<String> _specialties = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Dermatology',
    'Psychiatry',
    'Oncology',
    'Gastroenterology',
    'Endocrinology',
    'Pulmonology',
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Arabic',
    'Hindi',
  ];

  final List<String> _insuranceTypes = [
    'Blue Cross Blue Shield',
    'Aetna',
    'Cigna',
    'UnitedHealthcare',
    'Humana',
    'Kaiser Permanente',
    'Medicare',
    'Medicaid',
    'Private Pay',
    'Other',
  ];

  final List<String> _hospitalNetworks = [
    'Mayo Clinic Network',
    'Cleveland Clinic',
    'Johns Hopkins',
    'Mass General Brigham',
    'Kaiser Permanente',
    'HCA Healthcare',
    'Ascension',
    'CommonSpirit Health',
    'Trinity Health',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    _radiusValue = (_filters['radius'] ?? 10.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationSection(),
                  SizedBox(height: 3.h),
                  _buildSpecialtySection(),
                  SizedBox(height: 3.h),
                  _buildAvailabilitySection(),
                  SizedBox(height: 3.h),
                  _buildRatingSection(),
                  SizedBox(height: 3.h),
                  _buildLanguagesSection(),
                  SizedBox(height: 3.h),
                  _buildInsuranceSection(),
                  SizedBox(height: 3.h),
                  _buildHospitalNetworkSection(),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter Specialists',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location & Distance',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Radius: ${_radiusValue.toInt()} km',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
            thumbColor: AppTheme.lightTheme.colorScheme.primary,
            overlayColor:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
            inactiveTrackColor:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: _radiusValue,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            onChanged: (value) {
              setState(() {
                _radiusValue = value;
                _filters['radius'] = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialty',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _specialties.map((specialty) {
            final isSelected = (_filters['specialties'] as List<String>? ?? [])
                .contains(specialty);
            return FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final specialties =
                      (_filters['specialties'] as List<String>? ?? []).toList();
                  if (selected) {
                    specialties.add(specialty);
                  } else {
                    specialties.remove(specialty);
                  }
                  _filters['specialties'] = specialties;
                });
              },
              selectedColor: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.2),
              checkmarkColor: AppTheme.lightTheme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        CheckboxListTile(
          title: Text('Available Now'),
          value: _filters['availableNow'] ?? false,
          onChanged: (value) {
            setState(() {
              _filters['availableNow'] = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text('Available Today'),
          value: _filters['availableToday'] ?? false,
          onChanged: (value) {
            setState(() {
              _filters['availableToday'] = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text('Available This Week'),
          value: _filters['availableThisWeek'] ?? false,
          onChanged: (value) {
            setState(() {
              _filters['availableThisWeek'] = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = (_filters['minRating'] ?? 0) >= rating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _filters['minRating'] = rating;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(right: 1.w),
                child: CustomIconWidget(
                  iconName: isSelected ? 'star' : 'star_border',
                  color: isSelected
                      ? AppTheme.accentLight
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages Spoken',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _languages.map((language) {
            final isSelected = (_filters['languages'] as List<String>? ?? [])
                .contains(language);
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final languages =
                      (_filters['languages'] as List<String>? ?? []).toList();
                  if (selected) {
                    languages.add(language);
                  } else {
                    languages.remove(language);
                  }
                  _filters['languages'] = languages;
                });
              },
              selectedColor: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.2),
              checkmarkColor: AppTheme.lightTheme.colorScheme.secondary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInsuranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insurance Accepted',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _insuranceTypes.map((insurance) {
            final isSelected = (_filters['insurance'] as List<String>? ?? [])
                .contains(insurance);
            return FilterChip(
              label: Text(insurance),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final insuranceList =
                      (_filters['insurance'] as List<String>? ?? []).toList();
                  if (selected) {
                    insuranceList.add(insurance);
                  } else {
                    insuranceList.remove(insurance);
                  }
                  _filters['insurance'] = insuranceList;
                });
              },
              selectedColor: AppTheme.successLight.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.successLight,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHospitalNetworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hospital Network',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _hospitalNetworks.map((network) {
            final isSelected =
                (_filters['hospitalNetworks'] as List<String>? ?? [])
                    .contains(network);
            return FilterChip(
              label: Text(network),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final networks =
                      (_filters['hospitalNetworks'] as List<String>? ?? [])
                          .toList();
                  if (selected) {
                    networks.add(network);
                  } else {
                    networks.remove(network);
                  }
                  _filters['hospitalNetworks'] = networks;
                });
              },
              selectedColor: AppTheme.warningLight.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.warningLight,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilters(_filters);
                Navigator.pop(context);
              },
              child: Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
      _radiusValue = 10.0;
    });
  }
}
