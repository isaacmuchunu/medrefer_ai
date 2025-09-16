
import '../../core/app_export.dart';
import './widgets/ai_recommendations_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/map_view_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/specialist_card_widget.dart';

class SpecialistDirectory extends StatefulWidget {
  const SpecialistDirectory({super.key});

  @override
  State<SpecialistDirectory> createState() => _SpecialistDirectoryState();
}

class _SpecialistDirectoryState extends State<SpecialistDirectory>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isMapView = false;
  Map<String, dynamic> _currentFilters = {};
  List<Map<String, dynamic>> _filteredSpecialists = [];
  List<Map<String, dynamic>> _aiRecommendations = [];

  final List<Map<String, dynamic>> _allSpecialists = [
    {
      "id": 1,
      "name": "Dr. Sarah Johnson",
      "credentials": "MD, FACC",
      "specialty": "Cardiology",
      "hospital": "Mayo Clinic",
      "profileImage":
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face",
      "isAvailable": true,
      "rating": 4.8,
      "distance": "2.3 km",
      "languages": ["English", "Spanish"],
      "insurance": ["Blue Cross Blue Shield", "Aetna"],
      "hospitalNetwork": "Mayo Clinic Network",
      "successRate": 94.5,
      "matchReason":
          "High success rate with cardiac referrals and excellent patient outcomes in your recent cases.",
      "latitude": 40.7589,
      "longitude": -73.9851,
    },
    {
      "id": 2,
      "name": "Dr. Michael Chen",
      "credentials": "MD, PhD",
      "specialty": "Neurology",
      "hospital": "Johns Hopkins Hospital",
      "profileImage":
          "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face",
      "isAvailable": false,
      "rating": 4.9,
      "distance": "4.1 km",
      "languages": ["English", "Chinese"],
      "insurance": ["UnitedHealthcare", "Cigna"],
      "hospitalNetwork": "Johns Hopkins",
      "successRate": 96.2,
      "matchReason":
          "Specializes in complex neurological cases similar to your recent referral patterns.",
      "latitude": 40.7505,
      "longitude": -73.9934,
    },
    {
      "id": 3,
      "name": "Dr. Emily Rodriguez",
      "credentials": "MD, MS",
      "specialty": "Orthopedics",
      "hospital": "Hospital for Special Surgery",
      "profileImage":
          "https://images.unsplash.com/photo-1594824475317-d0c5e0c4c9b1?w=400&h=400&fit=crop&crop=face",
      "isAvailable": true,
      "rating": 4.7,
      "distance": "1.8 km",
      "languages": ["English", "Spanish", "Portuguese"],
      "insurance": ["Medicare", "Medicaid", "Private Pay"],
      "hospitalNetwork": "Other",
      "successRate": 92.8,
      "matchReason":
          "Excellent track record with sports injuries and joint replacements in your patient demographic.",
      "latitude": 40.7614,
      "longitude": -73.9776,
    },
    {
      "id": 4,
      "name": "Dr. James Wilson",
      "credentials": "MD, FAAP",
      "specialty": "Pediatrics",
      "hospital": "Children's Hospital of Philadelphia",
      "profileImage":
          "https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=400&fit=crop&crop=face",
      "isAvailable": true,
      "rating": 4.6,
      "distance": "3.5 km",
      "languages": ["English", "French"],
      "insurance": ["Blue Cross Blue Shield", "Humana"],
      "hospitalNetwork": "Other",
      "successRate": 89.3,
      "matchReason":
          "Pediatric specialist with expertise in developmental disorders matching your referral needs.",
      "latitude": 40.7282,
      "longitude": -74.0776,
    },
    {
      "id": 5,
      "name": "Dr. Lisa Thompson",
      "credentials": "MD, FAAD",
      "specialty": "Dermatology",
      "hospital": "Memorial Sloan Kettering",
      "profileImage":
          "https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400&h=400&fit=crop&crop=face",
      "isAvailable": false,
      "rating": 4.9,
      "distance": "2.7 km",
      "languages": ["English", "German"],
      "insurance": ["Kaiser Permanente", "Aetna"],
      "hospitalNetwork": "Other",
      "successRate": 97.1,
      "matchReason":
          "Leading dermatologist with advanced treatment options for complex skin conditions.",
      "latitude": 40.7831,
      "longitude": -73.9712,
    },
    {
      "id": 6,
      "name": "Dr. Robert Kim",
      "credentials": "MD, MHA",
      "specialty": "Psychiatry",
      "hospital": "Mount Sinai Hospital",
      "profileImage":
          "https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?w=400&h=400&fit=crop&crop=face",
      "isAvailable": true,
      "rating": 4.5,
      "distance": "5.2 km",
      "languages": ["English", "Korean", "Japanese"],
      "insurance": ["UnitedHealthcare", "Blue Cross Blue Shield"],
      "hospitalNetwork": "Mount Sinai Health System",
      "successRate": 88.7,
      "matchReason":
          "Mental health specialist with proven success in treating anxiety and depression cases.",
      "latitude": 40.7903,
      "longitude": -73.9565,
    },
    {
      "id": 7,
      "name": "Dr. Maria Garcia",
      "credentials": "MD, FASCO",
      "specialty": "Oncology",
      "hospital": "MD Anderson Cancer Center",
      "profileImage":
          "https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=400&h=400&fit=crop&crop=face",
      "isAvailable": true,
      "rating": 4.8,
      "distance": "6.1 km",
      "languages": ["English", "Spanish", "Italian"],
      "insurance": ["Medicare", "Cigna", "Private Pay"],
      "hospitalNetwork": "MD Anderson Network",
      "successRate": 91.4,
      "matchReason":
          "Oncology expert with cutting-edge treatment protocols and compassionate patient care.",
      "latitude": 40.6892,
      "longitude": -74.0445,
    },
    {
      "id": 8,
      "name": "Dr. David Park",
      "credentials": "MD, FACG",
      "specialty": "Gastroenterology",
      "hospital": "Cleveland Clinic",
      "profileImage":
          "https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=400&fit=crop&crop=face",
      "isAvailable": false,
      "rating": 4.7,
      "distance": "3.9 km",
      "languages": ["English", "Korean"],
      "insurance": ["Humana", "Aetna", "UnitedHealthcare"],
      "hospitalNetwork": "Cleveland Clinic",
      "successRate": 93.6,
      "matchReason":
          "GI specialist with advanced endoscopic procedures and digestive disorder expertise.",
      "latitude": 40.7489,
      "longitude": -73.9680,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _filteredSpecialists = List.from(_allSpecialists);
    _aiRecommendations =
        _allSpecialists.where((s) => s['successRate'] > 90).take(3).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterSpecialists() {
    setState(() {
      _filteredSpecialists = _allSpecialists.where((specialist) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final name = (specialist['name'] ?? '').toLowerCase();
          final specialty = (specialist['specialty'] ?? '').toLowerCase();
          final hospital = (specialist['hospital'] ?? '').toLowerCase();

          if (!name.contains(searchQuery) &&
              !specialty.contains(searchQuery) &&
              !hospital.contains(searchQuery)) {
            return false;
          }
        }

        // Specialty filter
        final selectedSpecialties =
            _currentFilters['specialties'] as List<String>? ?? [];
        if (selectedSpecialties.isNotEmpty) {
          if (!selectedSpecialties.contains(specialist['specialty'])) {
            return false;
          }
        }

        // Availability filter
        if (_currentFilters['availableNow'] == true) {
          if (specialist['isAvailable'] != true) {
            return false;
          }
        }

        // Rating filter
        final minRating = _currentFilters['minRating'] ?? 0;
        if ((specialist['rating'] ?? 0) < minRating) {
          return false;
        }

        // Language filter
        final selectedLanguages =
            _currentFilters['languages'] as List<String>? ?? [];
        if (selectedLanguages.isNotEmpty) {
          final specialistLanguages =
              specialist['languages'] as List<String>? ?? [];
          if (!selectedLanguages
              .any(specialistLanguages.contains)) {
            return false;
          }
        }

        // Insurance filter
        final selectedInsurance =
            _currentFilters['insurance'] as List<String>? ?? [];
        if (selectedInsurance.isNotEmpty) {
          final specialistInsurance =
              specialist['insurance'] as List<String>? ?? [];
          if (!selectedInsurance
              .any(specialistInsurance.contains)) {
            return false;
          }
        }

        // Hospital network filter
        final selectedNetworks =
            _currentFilters['hospitalNetworks'] as List<String>? ?? [];
        if (selectedNetworks.isNotEmpty) {
          if (!selectedNetworks.contains(specialist['hospitalNetwork'])) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _filterSpecialists();
        },
      ),
    );
  }

  void _handleSpecialistTap(Map<String, dynamic> specialist) {
    // Handle specialist selection - could navigate to profile or show actions
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Actions for ${specialist['name']}',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to specialist profile
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'message',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/secure-messaging');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'schedule',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text('Check Availability'),
              onTap: () {
                Navigator.pop(context);
                // Handle availability check
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'send',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text('Create Referral'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/create-referral');
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Find Doctors',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            icon: Icon(
              _isMapView ? Icons.list : Icons.map,
              color: Colors.white,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            icon: Icon(
              Icons.home,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Directory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              SearchBarWidget(
                controller: _searchController,
                onChanged: (_) => _filterSpecialists(),
                onVoiceSearch: () {
                  // Handle voice search
                },
                onFilter: _showFilterBottomSheet,
              ),
              if (!_isMapView) ...[
                AiRecommendationsWidget(
                  recommendations: _aiRecommendations,
                  onSpecialistTap: _handleSpecialistTap,
                ),
                Expanded(
                  child: _filteredSpecialists.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredSpecialists.length,
                          itemBuilder: (context, index) {
                            final specialist = _filteredSpecialists[index];
                            return SpecialistCardWidget(
                              specialist: specialist,
                              onTap: () => _handleSpecialistTap(specialist),
                              onViewProfile: () {
                                // Handle view profile
                              },
                              onSendMessage: () {
                                Navigator.pushNamed(
                                    context, AppRoutes.secureMessaging);
                              },
                              onCheckAvailability: () {
                                // Handle check availability
                              },
                              onAddToFavorites: () {
                                // Handle add to favorites
                              },
                            );
                          },
                        ),
                ),
              ] else ...[
                Expanded(
                  child: MapViewWidget(
                    specialists: _filteredSpecialists,
                    onSpecialistTap: _handleSpecialistTap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Handle add new specialist request
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Request New Specialist'),
              content: Text(
                  'Would you like to request adding a new specialist to the directory?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle request submission
                  },
                  child: Text('Submit Request'),
                ),
              ],
            ),
          );
        },
        icon: CustomIconWidget(
          iconName: 'person_add',
          color: Colors.white,
          size: 20,
        ),
        label: Text('Add Specialist'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4, // Specialist Directory index
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/create-referral');
              break;
            case 2:
              Navigator.pushNamed(context, '/referral-tracking');
              break;
            case 3:
              Navigator.pushNamed(context, '/patient-profile');
              break;
            case 4:
              // Current screen
              break;
            case 5:
              Navigator.pushNamed(context, '/secure-messaging');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'dashboard',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'add_circle_outline',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'add_circle',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'track_changes',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'track_changes',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person_outline',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'people',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'people',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            label: 'Directory',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'message',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'message',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            label: 'Messages',
          ),
        ],
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
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'search_off',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No specialists found',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search criteria or filters to find more specialists.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _currentFilters.clear();
                  _filteredSpecialists = List.from(_allSpecialists);
                });
              },
              child: Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
