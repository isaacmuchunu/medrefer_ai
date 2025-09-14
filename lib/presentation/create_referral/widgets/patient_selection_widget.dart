import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';

class PatientSelectionWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onPatientSelected;
  final Function()? onAddNewPatient;
  final String? errorText;

  const PatientSelectionWidget({
    Key? key,
    required this.onPatientSelected,
    this.onAddNewPatient,
    this.errorText,
  }) : super(key: key);

  @override
  State<PatientSelectionWidget> createState() => _PatientSelectionWidgetState();
}

class _PatientSelectionWidgetState extends State<PatientSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedPatient;
  List<Map<String, dynamic>> _filteredPatients = [];
  List<Map<String, dynamic>> _recentPatients = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _isLoading = false;
  Timer? _debounce;

  final List<Map<String, dynamic>> _mockPatients = [
    {
      "id": "P001",
      "name": "Sarah Johnson",
      "age": 45,
      "gender": "Female",
      "mrn": "MRN-2024-001",
      "phone": "+1 (555) 123-4567",
      "email": "sarah.johnson@email.com",
      "lastVisit": "2024-08-25",
      "conditions": ["Hypertension", "Type 2 Diabetes"],
      "status": "Active",
      "photoUrl": "https://randomuser.me/api/portraits/women/44.jpg",
    },
    {
      "id": "P002",
      "name": "Michael Chen",
      "age": 62,
      "gender": "Male",
      "mrn": "MRN-2024-002",
      "phone": "+1 (555) 234-5678",
      "email": "michael.chen@email.com",
      "lastVisit": "2024-08-28",
      "conditions": ["Coronary Artery Disease", "Hyperlipidemia"],
      "status": "Active",
      "photoUrl": "https://randomuser.me/api/portraits/men/44.jpg",
    },
    {
      "id": "P003",
      "name": "Emily Rodriguez",
      "age": 34,
      "gender": "Female",
      "mrn": "MRN-2024-003",
      "phone": "+1 (555) 345-6789",
      "email": "emily.rodriguez@email.com",
      "lastVisit": "2024-08-27",
      "conditions": ["Asthma", "Allergic Rhinitis"],
      "status": "Inactive",
      "photoUrl": "https://randomuser.me/api/portraits/women/45.jpg",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentPatientsAndHistory();
    _filteredPatients = _mockPatients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentPatientsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('patient_search_history') ?? [];
      // For demo, recent patients are just the first few mock patients
      _recentPatients = _mockPatients.take(2).toList();
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 5) {
        _searchHistory = _searchHistory.sublist(0, 5);
      }
      await prefs.setStringList('patient_search_history', _searchHistory);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterPatients(query);
    });
  }

  void _filterPatients(String query, {int? age, String? condition}) {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      setState(() {
        _isSearching = query.isNotEmpty || age != null || condition != null;
        if (!_isSearching) {
          _filteredPatients = _mockPatients;
        } else {
          _filteredPatients = _mockPatients.where((patient) {
            final name = (patient['name'] as String).toLowerCase();
            final mrn = (patient['mrn'] as String).toLowerCase();
            final searchQuery = query.toLowerCase();

            final nameMatch = name.contains(searchQuery);
            final mrnMatch = mrn.contains(searchQuery);
            final ageMatch = age == null || patient['age'] == age;
            final conditionMatch = condition == null ||
                (patient['conditions'] as List)
                    .any((c) => (c as String).toLowerCase().contains(condition.toLowerCase()));

            return (nameMatch || mrnMatch) && ageMatch && conditionMatch;
          }).toList();
        }
        _isLoading = false;
      });
    });
  }

  Future<void> _scanQRCode() async {
    try {
      final qrCode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.QR,
      );

      if (!mounted || qrCode == '-1') return;

      // Assuming QR code contains patient MRN
      _searchController.text = qrCode;
      _filterPatients(qrCode);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to scan QR code: $e');
      }
    }
  }

  void _selectPatient(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Patient'),
        content: Text('Are you sure you want to select ${patient['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPatient = patient;
                _searchController.text = patient['name'] as String;
                _isSearching = false;
              });
              widget.onPatientSelected(patient);
              _saveSearchHistory(_searchController.text);
            },
            child: const Text('Confirm'),
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
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Patient Selection',
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

          // Search Bar with Scanner
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
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or MRN...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                suffixIcon: GestureDetector(
                  onTap: _scanQRCode,
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'qr_code_scanner',
                      color: AppTheme.lightTheme.colorScheme.primary,
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

          // Search Results, Recents, or Selected Patient
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_isSearching) ...[
            if (_filteredPatients.isNotEmpty)
              _buildPatientList(_filteredPatients)
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No patients found.'),
              )
          ] else if (_selectedPatient != null) ...[
            SizedBox(height: 2.h),
            _buildSelectedPatientCard(_selectedPatient!),
          ] else ...[
            SizedBox(height: 2.h),
            if (_recentPatients.isNotEmpty) ...[
              Text('Recent Patients', style: AppTheme.lightTheme.textTheme.titleSmall),
              _buildPatientList(_recentPatients, isRecent: true),
            ],
            if (_searchHistory.isNotEmpty) ...[
              Text('Search History', style: AppTheme.lightTheme.textTheme.titleSmall),
              Wrap(
                spacing: 2.w,
                children: _searchHistory
                    .map((query) => ActionChip(
                          label: Text(query),
                          onPressed: () {
                            _searchController.text = query;
                            _filterPatients(query);
                          },
                        ))
                    .toList(),
              ),
            ],
          ],
          if (widget.onAddNewPatient != null) ...[
            SizedBox(height: 2.h),
            OutlinedButton.icon(
              onPressed: widget.onAddNewPatient,
              icon: const Icon(Icons.add),
              label: const Text('Add New Patient'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPatientList(List<Map<String, dynamic>> patients, {bool isRecent = false}) {
    return Container(
      constraints: BoxConstraints(maxHeight: isRecent ? 20.h : 30.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: patients.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppTheme.lightTheme.colorScheme.outline,
        ),
        itemBuilder: (context, index) {
          final patient = patients[index];
          final statusColor = patient['status'] == 'Active' ? Colors.green : Colors.grey;
          return Semantics(
            label: 'Patient: ${patient['name']}, MRN: ${patient['mrn']}',
            button: true,
            child: ListTile(
              onTap: () => _selectPatient(patient),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(patient['photoUrl'] as String),
                backgroundColor:
                    AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              title: Text(
                patient['name'] as String,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MRN: ${patient['mrn']} • Age: ${patient['age']} • ${patient['gender']}',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  if ((patient['conditions'] as List).isNotEmpty)
                    Text(
                      'Conditions: ${(patient['conditions'] as List).join(', ')}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedPatientCard(Map<String, dynamic> patient) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(patient['photoUrl'] as String),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['name'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'MRN: ${patient['mrn']} • Age: ${patient['age']} • ${patient['gender']}',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                if ((patient['conditions'] as List).isNotEmpty)
                  Text(
                    'Conditions: ${(patient['conditions'] as List).join(', ')}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'check_circle',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
