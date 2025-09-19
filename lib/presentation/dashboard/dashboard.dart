import 'dart:async';

import '../../core/app_export.dart';
import './widgets/activity_item_widget.dart';
import './widgets/bottom_nav_bar_widget.dart';
import './widgets/header_widget.dart';
import './widgets/metric_card_widget.dart';
import './widgets/quick_action_card_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _isRefreshing = false;
  late AnimationController _pulseController;
  late AnimationController _emergencyController;
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;

  // Real-time updates
  Timer? _refreshTimer;
  StreamSubscription? _notificationSubscription;

  // User role and permissions
  User? _currentUser;
  UserRole _userRole = UserRole.doctor;
  List<String> _userPermissions = [];

  // Emergency alerts
  List<Map<String, dynamic>> _emergencyAlerts = [];
  bool _hasEmergencyAlerts = false;

  // Network and connectivity
  bool _isOnline = true;
  bool _isSecureConnection = true;
  String _networkStatus = 'Connected';

  // Dynamic data for dashboard metrics
  List<Map<String, dynamic>> _metricsData = [];

  // Dynamic data for recent activities
  List<Map<String, dynamic>> _recentActivities = [];

  // Performance metrics
  DateTime? _lastRefreshTime;
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUser();
    _setupRealTimeUpdates();
    _loadDashboardData();
    _checkEmergencyAlerts();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _emergencyController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  Future<void> _initializeUser() async {
    try {
      final authService = AuthService();
      _currentUser = authService.currentUser;

      if (_currentUser != null) {
        setState(() {
          _userRole = _currentUser!.role;
          _userPermissions = _getUserPermissions(_userRole);
        });
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  List<String> _getUserPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return ['create_referral', 'view_all_patients', 'manage_specialists', 'view_analytics', 'manage_users'];
      case UserRole.doctor:
        return ['create_referral', 'view_patients', 'message_specialists', 'view_referrals'];
      case UserRole.nurse:
        return ['create_referral', 'view_patients', 'update_patient_info'];
      case UserRole.specialist:
        return ['view_referrals', 'update_referral_status', 'message_doctors'];
      case UserRole.pharmacist:
        return ['view_prescriptions', 'manage_inventory', 'process_orders'];
      default:
        return ['view_referrals'];
    }
  }

  void _setupRealTimeUpdates() {
    // Set up periodic refresh for real-time data
    _refreshTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (mounted && !_isRefreshing) {
        _loadDashboardData(silent: true);
      }
    });

    // Set up notification listener
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // This would typically listen to your notification service
    // For now, we'll simulate with a timer
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkEmergencyAlerts();
      }
    });
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final stats = await dataService.getDashboardStats();
      final recentReferrals = await dataService.getReferrals();

      // Load role-specific data
      final roleSpecificData = await _loadRoleSpecificData();

      // Check network status
      await _checkNetworkStatus();

      setState(() {
        _dashboardStats = stats;
        _lastRefreshTime = DateTime.now();
        _refreshCount++;

        // Build metrics based on user role
        _metricsData = _buildRoleBasedMetrics(stats, roleSpecificData);

        // Convert recent referrals to activity format
        _recentActivities = recentReferrals.take(5).map((referral) {
          return {
            'patientName': 'Patient ${referral.patientId.substring(0, 8)}',
            'specialist': referral.specialistId != null ? 'Specialist ${referral.specialistId!.substring(0, 8)}' : 'Unassigned',
            'department': referral.department ?? 'General',
            'status': referral.status,
            'timestamp': _formatTimestamp(referral.createdAt),
            'avatarUrl': null,
            'priority': _getReferralPriority(referral),
          };
        }).toList();

        _isLoading = false;
      });

      // Show refresh success feedback
      if (!silent && _refreshCount > 1) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isOnline = false;
        _networkStatus = 'Connection Error';
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint('Error loading dashboard data: $e');
    }
  }

  List<Map<String, dynamic>> _buildRoleBasedMetrics(Map<String, dynamic> stats, Map<String, dynamic> roleData) {
    final baseMetrics = [
      {
        'title': 'Pending Referrals',
        'value': '${stats['pendingReferrals'] ?? 0}',
        'subtitle': 'Awaiting specialist review',
        'isUrgent': false,
        'icon': Icons.pending_actions,
      },
      {
        'title': 'Urgent Cases',
        'value': '${stats['urgentCases'] ?? 0}',
        'subtitle': 'Requires immediate attention',
        'isUrgent': true,
        'icon': Icons.priority_high,
      },
    ];

    // Add role-specific metrics
    switch (_userRole) {
      case UserRole.admin:
      case UserRole.superAdmin:
        baseMetrics.addAll([
          {
            'title': 'System Health',
            'value': roleData['systemHealth'] ?? 'Good',
            'subtitle': 'Overall system status',
            'isUrgent': false,
            'icon': Icons.health_and_safety,
          },
          {
            'title': 'Active Users',
            'value': '${roleData['activeUsers'] ?? 0}',
            'subtitle': 'Currently online',
            'isUrgent': false,
            'icon': Icons.people,
          },
        ]);
        break;
      case UserRole.doctor:
        baseMetrics.addAll([
          {
            'title': 'My Patients',
            'value': '${roleData['myPatients'] ?? 0}',
            'subtitle': 'Under your care',
            'isUrgent': false,
            'icon': Icons.people_outline,
          },
          {
            'title': 'Today\'s Appointments',
            'value': '${roleData['todayAppointments'] ?? 0}',
            'subtitle': 'Scheduled for today',
            'isUrgent': false,
            'icon': Icons.today,
          },
        ]);
        break;
      case UserRole.specialist:
        baseMetrics.addAll([
          {
            'title': 'Incoming Referrals',
            'value': '${roleData['incomingReferrals'] ?? 0}',
            'subtitle': 'Awaiting your review',
            'isUrgent': false,
            'icon': Icons.inbox,
          },
          {
            'title': 'Completed Today',
            'value': '${roleData['completedToday'] ?? 0}',
            'subtitle': 'Consultations finished',
            'isUrgent': false,
            'icon': Icons.check_circle,
          },
        ]);
        break;
      default:
        baseMetrics.addAll([
          {
            'title': 'Total Patients',
            'value': '${stats['totalPatients'] ?? 0}',
            'subtitle': 'Active patient records',
            'isUrgent': false,
            'icon': Icons.people,
          },
          {
            'title': 'Total Specialists',
            'value': '${stats['totalSpecialists'] ?? 0}',
            'subtitle': 'Available specialists',
            'isUrgent': false,
            'icon': Icons.medical_services,
          },
        ]);
    }

    return baseMetrics;
  }

  String _getReferralPriority(dynamic referral) {
    if (referral.urgency?.toLowerCase() == 'high' || referral.urgency?.toLowerCase() == 'urgent') {
      return 'high';
    } else if (referral.urgency?.toLowerCase() == 'medium') {
      return 'medium';
    }
    return 'low';
  }

  Future<Map<String, dynamic>> _loadRoleSpecificData() async {
    // Load data specific to user role
    switch (_userRole) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return {
          'systemHealth': 'Good',
          'activeUsers': 45,
          'systemAlerts': 2,
        };
      case UserRole.doctor:
        return {
          'myPatients': 23,
          'pendingReferrals': 5,
          'todayAppointments': 8,
        };
      case UserRole.specialist:
        return {
          'incomingReferrals': 12,
          'scheduledConsultations': 6,
          'completedToday': 4,
        };
      default:
        return {};
    }
  }

  Future<void> _checkNetworkStatus() async {
    // Simulate network check
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      _isOnline = true;
      _isSecureConnection = true;
      _networkStatus = 'Connected';
    });
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emergencyController.dispose();
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkEmergencyAlerts() async {
    try {
      // Simulate checking for emergency alerts
      // In production, this would check your backend for urgent referrals, system alerts, etc.
      final alerts = <Map<String, dynamic>>[];

      // Mock emergency alert
      if (DateTime.now().minute % 10 == 0) {
        alerts.add({
          'id': 'emergency_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'urgent_referral',
          'title': 'Urgent Referral Alert',
          'message': 'Emergency cardiac referral requires immediate attention',
          'timestamp': DateTime.now(),
          'priority': 'critical',
        });
      }

      setState(() {
        _emergencyAlerts = alerts;
        _hasEmergencyAlerts = alerts.isNotEmpty;
      });

      if (_hasEmergencyAlerts) {
        _emergencyController.repeat(reverse: true);
        HapticFeedback.heavyImpact();
      } else {
        _emergencyController.stop();
      }
    } catch (e) {
      debugPrint('Error checking emergency alerts: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Reload dashboard data
    await _loadDashboardData();

    setState(() {
      _isRefreshing = false;
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dashboard updated successfully'),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.referralTracking);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.patientProfile);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.secureMessaging);
        break;
      case 4:
        // Navigate to profile
        break;
    }
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'new_referral':
        Navigator.pushNamed(context, AppRoutes.createReferral);
        break;
      case 'emergency_referral':
        Navigator.pushNamed(context, AppRoutes.createReferral);
        break;
      case 'scan_patient':
        _showScanPatientDialog();
        break;
      case 'voice_note':
        _showVoiceNoteDialog();
        break;
      case 'pharmacy':
        Navigator.pushNamed(context, AppRoutes.pharmacyScreen);
        break;
      case 'create_referral':
        Navigator.pushNamed(context, AppRoutes.createReferral);
        break;
      case 'patient_search':
        Navigator.pushNamed(context, AppRoutes.patientSearchScreen);
        break;
      case 'book_appointment':
        Navigator.pushNamed(context, AppRoutes.appointmentSchedulingScreen);
        break;
    }
  }

  void _showScanPatientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Patient ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'qr_code_scanner',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 15.w,
              ),
              SizedBox(height: 2.h),
              const Text(
                  'Position the QR code or barcode within the frame to scan patient information.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Patient ID scanned successfully')),
                );
              },
              child: const Text('Start Scan'),
            ),
          ],
        );
      },
    );
  }

  void _showVoiceNoteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Voice Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: CustomIconWidget(
                      iconName: 'mic',
                      color: AppTheme.errorLight,
                      size: 15.w,
                    ),
                  );
                },
              ),
              SizedBox(height: 2.h),
              const Text(
                  'Tap to start recording your voice note for the referral.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Voice note recorded successfully')),
                );
              },
              child: const Text('Start Recording'),
            ),
          ],
        );
      },
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    Navigator.pushNamed(context, '/referral-tracking');
  }

  void _handleActivityLongPress(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                activity['patientName'] as String,
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
              SizedBox(height: 2.h),
              _buildBottomSheetOption(
                iconName: 'visibility',
                title: 'View Details',
                onTap: () {
                  Navigator.pop(context);
                  _handleActivityTap(activity);
                },
              ),
              _buildBottomSheetOption(
                iconName: 'message',
                title: 'Contact Specialist',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/secure-messaging');
                },
              ),
              _buildBottomSheetOption(
                iconName: 'update',
                title: 'Update Status',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Status update feature coming soon')),
                  );
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required String iconName,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 6.w,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Enhanced Header with real-time status
          HeaderWidget(
            hospitalName: 'MedRefer AI Hospital',
            userName: _currentUser?.name ?? 'User',
            userRole: _userRole.name,
          ),

          // Emergency Alerts Banner
          if (_hasEmergencyAlerts)
            AnimatedBuilder(
              animation: _emergencyController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_emergencyController.value * 0.05),
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 24),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Alert',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_emergencyAlerts.length} urgent case(s) require attention',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Navigate to emergency alerts
                            Navigator.pushNamed(context, AppRoutes.emergencyAlertsScreen);
                          },
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Metrics Cards Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Overview',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),

                    // Metrics Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 2.w,
                        mainAxisSpacing: 1.h,
                      ),
                      itemCount: _metricsData.length,
                      itemBuilder: (context, index) {
                        final metric = _metricsData[index];
                        return MetricCardWidget(
                          title: metric['title'] as String,
                          value: metric['value'] as String,
                          subtitle: metric['subtitle'] as String,
                          isUrgent: metric['isUrgent'] as bool,
                          accentColor: metric['isUrgent'] as bool
                              ? AppTheme.errorLight
                              : null,
                          onTap: () => _handleActivityTap(metric),
                        );
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Quick Actions Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Quick Actions',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),

                    // Quick Action Cards
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          QuickActionCardWidget(
                            title: 'New Referral',
                            iconName: 'add_circle',
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.primary,
                            iconColor:
                                AppTheme.lightTheme.colorScheme.onPrimary,
                            onTap: () => _handleQuickAction('new_referral'),
                          ),
                          QuickActionCardWidget(
                            title: 'Emergency Referral',
                            iconName: 'emergency',
                            backgroundColor: AppTheme.errorLight,
                            iconColor: AppTheme.lightTheme.colorScheme.onError,
                            onTap: () =>
                                _handleQuickAction('emergency_referral'),
                            isEmergency: true,
                          ),
                          QuickActionCardWidget(
                            title: 'Scan Patient ID',
                            iconName: 'qr_code_scanner',
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.surface,
                            iconColor: AppTheme.lightTheme.colorScheme.primary,
                            onTap: () => _handleQuickAction('scan_patient'),
                          ),
                          QuickActionCardWidget(
                            title: 'Voice Note',
                            iconName: 'mic',
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.surface,
                            iconColor: AppTheme.lightTheme.colorScheme.primary,
                            onTap: () => _handleQuickAction('voice_note'),
                          ),
                          PermissionWidget(
                            feature: 'pharmacy',
                            child: QuickActionCardWidget(
                              title: 'Pharmacy',
                              iconName: 'local_pharmacy',
                              backgroundColor: AppTheme.secondaryLight,
                              iconColor: Colors.white,
                              onTap: () => _handleQuickAction('pharmacy'),
                            ),
                          ),
                          PermissionWidget(
                            feature: 'referral_creation',
                            child: QuickActionCardWidget(
                              title: 'Create Referral',
                              iconName: 'send',
                              backgroundColor: AppTheme.accentLight,
                              iconColor: Colors.white,
                              onTap: () => _handleQuickAction('create_referral'),
                            ),
                          ),
                          PermissionWidget(
                            feature: 'patient_management',
                            child: QuickActionCardWidget(
                              title: 'Find Patient',
                              iconName: 'search',
                              backgroundColor: Colors.purple,
                              iconColor: Colors.white,
                              onTap: () => _handleQuickAction('patient_search'),
                            ),
                          ),
                          PermissionWidget(
                            feature: 'appointment_booking',
                            child: QuickActionCardWidget(
                              title: 'Book Appointment',
                              iconName: 'calendar_today',
                              backgroundColor: Colors.teal,
                              iconColor: Colors.white,
                              onTap: () => _handleQuickAction('book_appointment'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Recent Activity Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: AppTheme.lightTheme.textTheme.headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/referral-tracking'),
                            child: Text(
                              'View All',
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Activity List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivities.length,
                      itemBuilder: (context, index) {
                        final activity = _recentActivities[index];
                        return ActivityItemWidget(
                          activity: activity,
                          onTap: () => _handleActivityTap(activity),
                          onLongPress: () => _handleActivityLongPress(activity),
                        );
                      },
                    ),

                    SizedBox(height: 10.h), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleQuickAction('new_referral'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
        icon: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          size: 6.w,
        ),
        label: Text(
          'Create Referral',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
