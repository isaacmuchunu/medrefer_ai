
import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;
  DateTimeRange? _selectedDateRange;

  final List<String> _specialties = [
    'All Specialties',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Oncology',
    'Dermatology',
    'Psychiatry',
    'Radiology',
    'Emergency Medicine',
  ];

  final List<String> _urgencyLevels = [
    'All Levels',
    'Low',
    'Normal',
    'High',
    'Critical',
  ];

  final List<String> _departments = [
    'All Departments',
    'Emergency',
    'Internal Medicine',
    'Surgery',
    'Pediatrics',
    'Obstetrics',
    'ICU',
    'Outpatient',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);

    if (_filters['startDate'] != null && _filters['endDate'] != null) {
      _selectedDateRange = DateTimeRange(
        start: _filters['startDate'] as DateTime,
        end: _filters['endDate'] as DateTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Filter Referrals',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.dividerLight, height: 1),

          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  _buildSectionTitle('Date Range'),
                  SizedBox(height: 1.h),
                  _buildDateRangeSelector(),
                  SizedBox(height: 3.h),

                  // Specialty Type
                  _buildSectionTitle('Specialty Type'),
                  SizedBox(height: 1.h),
                  _buildDropdownFilter(
                    'specialty',
                    _specialties,
                    _filters['specialty'] as String? ?? 'All Specialties',
                  ),
                  SizedBox(height: 3.h),

                  // Urgency Level
                  _buildSectionTitle('Urgency Level'),
                  SizedBox(height: 1.h),
                  _buildDropdownFilter(
                    'urgency',
                    _urgencyLevels,
                    _filters['urgency'] as String? ?? 'All Levels',
                  ),
                  SizedBox(height: 3.h),

                  // Hospital Department
                  _buildSectionTitle('Hospital Department'),
                  SizedBox(height: 1.h),
                  _buildDropdownFilter(
                    'department',
                    _departments,
                    _filters['department'] as String? ?? 'All Departments',
                  ),
                  SizedBox(height: 3.h),

                  // AI Confidence Range
                  _buildSectionTitle('AI Confidence Range'),
                  SizedBox(height: 1.h),
                  _buildConfidenceRangeSlider(),
                  SizedBox(height: 3.h),

                  // Status Filters
                  _buildSectionTitle('Status Filters'),
                  SizedBox(height: 1.h),
                  _buildStatusCheckboxes(),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.dividerLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'date_range',
              color: AppTheme.textSecondaryLight,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                    : 'Select date range',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: _selectedDateRange != null
                      ? AppTheme.textPrimaryLight
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: AppTheme.textSecondaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(
      String key, List<String> options, String currentValue) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _filters[key] = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildConfidenceRangeSlider() {
    final minConfidence = _filters['minConfidence'] as double? ?? 0.0;
    final maxConfidence = _filters['maxConfidence'] as double? ?? 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(minConfidence * 100).toInt()}%',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            Text(
              '${(maxConfidence * 100).toInt()}%',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(minConfidence, maxConfidence),
          min: 0.0,
          max: 1.0,
          divisions: 10,
          labels: RangeLabels(
            '${(minConfidence * 100).toInt()}%',
            '${(maxConfidence * 100).toInt()}%',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _filters['minConfidence'] = values.start;
              _filters['maxConfidence'] = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusCheckboxes() {
    final statuses = <String>[
      'Pending',
      'Approved',
      'Completed',
      'Cancelled'
    ];
    final selectedStatuses = _filters['statuses'] as List<String>? ?? [];

    return Column(
      children: statuses.map((status) {
        final isSelected = selectedStatuses.contains(status);
        return CheckboxListTile(
          title: Text(
            status,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              final currentStatuses = List<String>.from(selectedStatuses);
              if (value == true) {
                currentStatuses.add(status);
              } else {
                currentStatuses.remove(status);
              }
              _filters['statuses'] = currentStatuses;
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryLight,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filters['startDate'] = picked.start;
        _filters['endDate'] = picked.end;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
      _selectedDateRange = null;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }
}
