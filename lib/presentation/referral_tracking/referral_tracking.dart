import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/referral_card_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/status_tab_bar_widget.dart';
import './widgets/sync_indicator_widget.dart';

class ReferralTracking extends StatefulWidget {
  const ReferralTracking({super.key});

  @override
  State<ReferralTracking> createState() => _ReferralTrackingState();
}

class _ReferralTrackingState extends State<ReferralTracking>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  int _selectedTabIndex = 0;
  String _searchQuery = '';
  Map<String, dynamic> _currentFilters = {};
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  int _pendingChanges = 0;
  bool _isRefreshing = false;

  final List<String> _statusTabs = ['All', 'Pending', 'Approved', 'Completed'];

  // Dynamic data for referrals
  List<Referral> _allReferrals = [];
  List<Patient> _patients = [];
  List<Specialist> _specialists = [];

  // Mock data for referrals (fallback)
  final List<Map<String, dynamic>> _mockReferrals = [
    {
      "id": "REF001",
      "trackingNumber": "MR-2024-08-001",
      "patient": {
        "id": "P12345",
        "name": "Sarah Johnson",
        "age": 45,
        "photo":
            "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      "specialist": {
        "name": "Dr. Michael Chen",
        "specialty": "Cardiology",
        "hospital": "City Medical Center",
      },
      "status": "Pending",
      "urgency": "High",
      "aiConfidence": 0.92,
      "estimatedTime": "2-3 days",
      "lastUpdate": DateTime.now().subtract(const Duration(hours: 2)),
      "department": "Emergency",
    },
    {
      "id": "REF002",
      "trackingNumber": "MR-2024-08-002",
      "patient": {
        "id": "P12346",
        "name": "Robert Martinez",
        "age": 62,
        "photo":
            "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      "specialist": {
        "name": "Dr. Emily Rodriguez",
        "specialty": "Neurology",
        "hospital": "General Hospital",
      },
      "status": "Approved",
      "urgency": "Normal",
      "aiConfidence": 0.87,
      "estimatedTime": "1-2 weeks",
      "lastUpdate": DateTime.now().subtract(const Duration(hours: 5)),
      "department": "Internal Medicine",
    },
    {
      "id": "REF003",
      "trackingNumber": "MR-2024-08-003",
      "patient": {
        "id": "P12347",
        "name": "Lisa Thompson",
        "age": 34,
        "photo":
            "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      "specialist": {
        "name": "Dr. James Wilson",
        "specialty": "Orthopedics",
        "hospital": "Sports Medicine Clinic",
      },
      "status": "Completed",
      "urgency": "Low",
      "aiConfidence": 0.95,
      "estimatedTime": "Completed",
      "lastUpdate": DateTime.now().subtract(const Duration(days: 1)),
      "department": "Outpatient",
    },
    {
      "id": "REF004",
      "trackingNumber": "MR-2024-08-004",
      "patient": {
        "id": "P12348",
        "name": "David Kim",
        "age": 28,
        "photo":
            "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      "specialist": {
        "name": "Dr. Anna Patel",
        "specialty": "Dermatology",
        "hospital": "Skin Care Center",
      },
      "status": "Pending",
      "urgency": "Normal",
      "aiConfidence": 0.78,
      "estimatedTime": "3-5 days",
      "lastUpdate": DateTime.now().subtract(const Duration(minutes: 30)),
      "department": "Outpatient",
    },
    {
      "id": "REF005",
      "trackingNumber": "MR-2024-08-005",
      "patient": {
        "id": "P12349",
        "name": "Maria Garcia",
        "age": 55,
        "photo":
            "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      "specialist": {
        "name": "Dr. Thomas Brown",
        "specialty": "Oncology",
        "hospital": "Cancer Treatment Center",
      },
      "status": "Approved",
      "urgency": "Critical",
      "aiConfidence": 0.98,
      "estimatedTime": "24-48 hours",
      "lastUpdate": DateTime.now().subtract(const Duration(hours: 1)),
      "department": "ICU",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));
    _checkConnectivity();
    _listenToConnectivity();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    try {
      final dataService = Provider.of<DataService>(context, listen: false);

      // Load referrals, patients, and specialists
      final referrals = await dataService.getReferrals();
      final patients = await dataService.getPatients();
      final specialists = await dataService.getSpecialists();

      setState(() {
        _allReferrals = referrals;
        _patients = patients;
        _specialists = specialists;
      });
    } catch (e) {
      debugPrint('Error loading referrals: $e');
      // Keep using mock data as fallback
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
        if (_isOnline && _pendingChanges > 0) {
          _syncPendingChanges();
        }
      });
    });
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges > 0) {
      setState(() {
        _pendingChanges = 0;
        _lastSyncTime = DateTime.now();
      });
      Fluttertoast.showToast(
        msg: "Synced pending changes",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredReferrals() {
    List<Map<String, dynamic>> filtered = List.from(_allReferrals);

    // Filter by status tab
    if (_selectedTabIndex > 0) {
      final selectedStatus = _statusTabs[_selectedTabIndex];
      filtered = filtered.where((referral) {
        return (referral['status'] as String).toLowerCase() ==
            selectedStatus.toLowerCase();
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((referral) {
        final patient = referral['patient'] as Map<String, dynamic>;
        final specialist = referral['specialist'] as Map<String, dynamic>;
        final trackingNumber = referral['trackingNumber'] as String;

        return (patient['name'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (specialist['name'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (specialist['specialty'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            trackingNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply additional filters
    if (_currentFilters.isNotEmpty) {
      filtered = _applyAdvancedFilters(filtered);
    }

    return filtered;
  }

  List<Map<String, dynamic>> _applyAdvancedFilters(
      List<Map<String, dynamic>> referrals) {
    List<Map<String, dynamic>> filtered = List.from(referrals);

    // Date range filter
    if (_currentFilters['startDate'] != null &&
        _currentFilters['endDate'] != null) {
      final startDate = _currentFilters['startDate'] as DateTime;
      final endDate = _currentFilters['endDate'] as DateTime;
      filtered = filtered.where((referral) {
        final lastUpdate = referral['lastUpdate'] as DateTime;
        return lastUpdate.isAfter(startDate) &&
            lastUpdate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    // Specialty filter
    if (_currentFilters['specialty'] != null &&
        _currentFilters['specialty'] != 'All Specialties') {
      final specialty = _currentFilters['specialty'] as String;
      filtered = filtered.where((referral) {
        final specialist = referral['specialist'] as Map<String, dynamic>;
        return (specialist['specialty'] as String) == specialty;
      }).toList();
    }

    // Urgency filter
    if (_currentFilters['urgency'] != null &&
        _currentFilters['urgency'] != 'All Levels') {
      final urgency = _currentFilters['urgency'] as String;
      filtered = filtered.where((referral) {
        return (referral['urgency'] as String) == urgency;
      }).toList();
    }

    // Department filter
    if (_currentFilters['department'] != null &&
        _currentFilters['department'] != 'All Departments') {
      final department = _currentFilters['department'] as String;
      filtered = filtered.where((referral) {
        return (referral['department'] as String) == department;
      }).toList();
    }

    // AI confidence range filter
    if (_currentFilters['minConfidence'] != null &&
        _currentFilters['maxConfidence'] != null) {
      final minConfidence = _currentFilters['minConfidence'] as double;
      final maxConfidence = _currentFilters['maxConfidence'] as double;
      filtered = filtered.where((referral) {
        final confidence = referral['aiConfidence'] as double;
        return confidence >= minConfidence && confidence <= maxConfidence;
      }).toList();
    }

    // Status filters
    if (_currentFilters['statuses'] != null &&
        (_currentFilters['statuses'] as List).isNotEmpty) {
      final selectedStatuses = _currentFilters['statuses'] as List<String>;
      filtered = filtered.where((referral) {
        return selectedStatuses.contains(referral['status'] as String);
      }).toList();
    }

    return filtered;
  }

  List<int> _getStatusCounts() {
    return _statusTabs.map((status) {
      if (status == 'All') {
        return _allReferrals.length;
      }
      return _allReferrals.where((referral) {
        return (referral['status'] as String).toLowerCase() ==
            status.toLowerCase();
      }).length;
    }).toList();
  }

  Future<void> _refreshReferrals() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
      _lastSyncTime = DateTime.now();
    });

    Fluttertoast.showToast(
      msg: "Referrals updated",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _currentFilters = filters;
          });
        },
      ),
    );
  }

  void _handleReferralAction(String action, Map<String, dynamic> referral) {
    final patientName =
        (referral['patient'] as Map<String, dynamic>)['name'] as String;

    switch (action) {
      case 'call':
        HapticFeedback.lightImpact();
        Fluttertoast.showToast(
          msg: "Calling specialist for $patientName",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        break;
      case 'message':
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/secure-messaging');
        break;
      case 'update':
        HapticFeedback.mediumImpact();
        _showUpdateStatusDialog(referral);
        break;
      case 'details':
        Navigator.pushNamed(context, '/patient-profile');
        break;
      case 'archive':
        HapticFeedback.heavyImpact();
        _archiveReferral(referral);
        break;
      case 'duplicate':
        Navigator.pushNamed(context, '/create-referral');
        break;
      case 'export':
        _exportReferralPdf(referral);
        break;
      case 'share':
        _shareReferral(referral);
        break;
    }
  }

  void _showUpdateStatusDialog(Map<String, dynamic> referral) {
    final currentStatus = referral['status'] as String;
    final statuses = ['Pending', 'Approved', 'Completed', 'Cancelled'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return RadioListTile<String>(
              title: Text(status),
              value: status,
              groupValue: currentStatus,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  _updateReferralStatus(referral, value);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _updateReferralStatus(Map<String, dynamic> referral, String newStatus) {
    setState(() {
      referral['status'] = newStatus;
      referral['lastUpdate'] = DateTime.now();
      if (!_isOnline) {
        _pendingChanges++;
      }
    });

    final patientName =
        (referral['patient'] as Map<String, dynamic>)['name'] as String;
    Fluttertoast.showToast(
      msg: "Status updated for $patientName",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _archiveReferral(Map<String, dynamic> referral) {
    final patientName =
        (referral['patient'] as Map<String, dynamic>)['name'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archive Referral'),
        content: Text(
            'Are you sure you want to archive the referral for $patientName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allReferrals.remove(referral);
              });
              Fluttertoast.showToast(
                msg: "Referral archived",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            child: Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _exportReferralPdf(Map<String, dynamic> referral) {
    final patientName =
        (referral['patient'] as Map<String, dynamic>)['name'] as String;
    Fluttertoast.showToast(
      msg: "Exporting PDF for $patientName",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _shareReferral(Map<String, dynamic> referral) {
    final patientName =
        (referral['patient'] as Map<String, dynamic>)['name'] as String;
    Fluttertoast.showToast(
      msg: "Sharing referral for $patientName",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReferrals = _getFilteredReferrals();
    final statusCounts = _getStatusCounts();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Referral Tracking'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/create-referral'),
            icon: CustomIconWidget(
              iconName: 'add',
              color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
              size: 24,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: AppTheme.dividerLight,
          ),
        ),
      ),
      body: Column(
        children: [
          // Sync indicator
          SyncIndicatorWidget(
            lastSyncTime: _lastSyncTime,
            isOnline: _isOnline,
            pendingChanges: _pendingChanges,
            onRefresh: _refreshReferrals,
          ),

          // Search bar
          SearchBarWidget(
            hintText: 'Search by patient, specialist, or tracking number...',
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            onFilterTap: _showFilterBottomSheet,
            controller: _searchController,
          ),

          // Status tabs
          StatusTabBarWidget(
            tabs: _statusTabs,
            selectedIndex: _selectedTabIndex,
            onTabChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
              _tabController.animateTo(index);
            },
            counts: statusCounts,
          ),

          // Referral list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshReferrals,
              color: AppTheme.primaryLight,
              child: filteredReferrals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredReferrals.length,
                      itemBuilder: (context, index) {
                        final referral = filteredReferrals[index];
                        return ReferralCardWidget(
                          referralData: referral,
                          onTap: () =>
                              _handleReferralAction('details', referral),
                          onCall: () => _handleReferralAction('call', referral),
                          onMessage: () =>
                              _handleReferralAction('message', referral),
                          onUpdateStatus: () =>
                              _handleReferralAction('update', referral),
                          onViewDetails: () =>
                              _handleReferralAction('details', referral),
                          onArchive: () =>
                              _handleReferralAction('archive', referral),
                          onDuplicate: () =>
                              _handleReferralAction('duplicate', referral),
                          onExportPdf: () =>
                              _handleReferralAction('export', referral),
                          onShare: () =>
                              _handleReferralAction('share', referral),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-referral'),
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Referral Tracking tab
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'dashboard',
                color: AppTheme.textSecondaryLight,
                size: 24),
            activeIcon: CustomIconWidget(
                iconName: 'dashboard', color: AppTheme.primaryLight, size: 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'add_circle_outline',
                color: AppTheme.textSecondaryLight,
                size: 24),
            activeIcon: CustomIconWidget(
                iconName: 'add_circle', color: AppTheme.primaryLight, size: 24),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'track_changes',
                color: AppTheme.textSecondaryLight,
                size: 24),
            activeIcon: CustomIconWidget(
                iconName: 'track_changes',
                color: AppTheme.primaryLight,
                size: 24),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'people',
                color: AppTheme.textSecondaryLight,
                size: 24),
            activeIcon: CustomIconWidget(
                iconName: 'people', color: AppTheme.primaryLight, size: 24),
            label: 'Specialists',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'message',
                color: AppTheme.textSecondaryLight,
                size: 24),
            activeIcon: CustomIconWidget(
                iconName: 'message', color: AppTheme.primaryLight, size: 24),
            label: 'Messages',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/create-referral');
              break;
            case 2:
              // Current screen
              break;
            case 3:
              Navigator.pushNamed(context, '/specialist-directory');
              break;
            case 4:
              Navigator.pushNamed(context, '/secure-messaging');
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.textSecondaryLight,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'No referrals found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _searchQuery.isNotEmpty || _currentFilters.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Create your first referral to get started',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            if (_searchQuery.isEmpty && _currentFilters.isEmpty)
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/create-referral'),
                child: Text('Create Referral'),
              ),
          ],
        ),
      ),
    );
  }
}
