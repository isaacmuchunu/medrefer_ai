
import '../../core/app_export.dart';
import '../../database/models/models.dart';
import './widgets/active_conditions_widget.dart';
import './widgets/contact_info_widget.dart';
import './widgets/current_medications_widget.dart';
import './widgets/current_referrals_widget.dart';
import './widgets/documents_viewer_widget.dart';
import './widgets/medical_history_timeline_widget.dart';
import './widgets/patient_header_widget.dart';
import './widgets/vital_statistics_card_widget.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isPrivacyEnabled = false;
  final int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _isMetric = false;

  // Dynamic patient data
  Patient? _patient;
  List<Medication> _medications = [];
  List<Condition> _conditions = [];
  List<Referral> _referrals = [];
  List<MedicalHistory> _medicalHistory = [];
  VitalStatistics? _vitalStatistics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);

    try {
      final dataService = Provider.of<DataService>(context, listen: false);

      // Load patient data - using first patient for demo
      final patients = await dataService.getAllPatients();
      if (patients.isNotEmpty) {
        _patient = patients.first;

        // Load related data
        _medications = await dataService.getPatientMedications(_patient!.id);
        _conditions = await dataService.getPatientConditions(_patient!.id);
        _referrals = await dataService.getPatientReferrals(_patient!.id);
        _medicalHistory = await dataService.getPatientMedicalHistory(_patient!.id);

        // Load vital statistics
        final vitalStats = await dataService.getPatientVitalStatistics(_patient!.id);
        if (vitalStats.isNotEmpty) {
          _vitalStatistics = vitalStats.first;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patient data: $e')),
      );
    }
  }









  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text("Patient Profile"),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
          ),
        ),
      );
    }

    if (_patient == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text("Patient Profile"),
        ),
        body: Center(
          child: Text("No patient data available"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Patient Profile",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showContextMenu(context),
            child: Container(
              margin: EdgeInsets.all(2.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "History"),
            Tab(text: "Referrals"),
            Tab(text: "Documents"),
            Tab(text: "Contact"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Patient Header
          Container(
            padding: EdgeInsets.all(4.w),
            child: PatientHeaderWidget(
              patientData: {
                "id": _patient!.id,
                "name": _patient!.name,
                "age": DateTime.now().year - _patient!.dateOfBirth.year,
                "medicalRecordNumber": _patient!.medicalRecordNumber,
                "photo": _patient!.profileImageUrl ?? "",
                "dateOfBirth": _patient!.dateOfBirth.toIso8601String().split('T')[0],
                "gender": _patient!.gender,
                "bloodType": _patient!.bloodType ?? "Unknown",
              },
              isPrivacyEnabled: _isPrivacyEnabled,
              onPrivacyToggle: () {
                setState(() {
                  _isPrivacyEnabled = !_isPrivacyEnabled;
                });
              },
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
                _buildReferralsTab(),
                _buildDocumentsTab(),
                _buildContactTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReferral,
        icon: CustomIconWidget(
          iconName: 'send',
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          "Create Referral",
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          VitalStatisticsCardWidget(
            vitalData: _vitalStatistics != null ? {
              "bloodPressure": "${_vitalStatistics!.systolicBP}/${_vitalStatistics!.diastolicBP}",
              "heartRate": "${_vitalStatistics!.heartRate}",
              "temperature": "${_vitalStatistics!.temperature}",
              "oxygenSaturation": "${_vitalStatistics!.oxygenSaturation}",
              "lastUpdated": "Recently",
            } : {},
            isMetric: _isMetric,
            onUnitToggle: () {
              setState(() {
                _isMetric = !_isMetric;
              });
            },
          ),
          SizedBox(height: 3.h),
          CurrentMedicationsWidget(
            medications: _medications.map((med) => {
              "id": med.id,
              "name": med.name,
              "dosage": med.dosage,
              "frequency": med.frequency,
              "type": med.type,
              "status": med.isActive ? "Active" : "Inactive",
              "startDate": med.startDate?.toIso8601String().split('T')[0] ?? "",
              "prescribedBy": med.prescribedBy,
            }).toList(),
          ),
          SizedBox(height: 3.h),
          ActiveConditionsWidget(
            conditions: _conditions.map((condition) => {
              "id": condition.id,
              "name": condition.name,
              "severity": condition.severity,
              "description": condition.description,
              "diagnosedDate": condition.diagnosedDate?.toIso8601String().split('T')[0] ?? "",
              "diagnosedBy": condition.diagnosedBy,
              "icd10": condition.icd10Code,
            }).toList(),
          ),
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          MedicalHistoryTimelineWidget(
            historyData: _medicalHistory.map((history) => {
              "id": history.id,
              "type": history.type,
              "title": history.title,
              "description": history.description,
              "date": history.date.toIso8601String().split('T')[0],
              "provider": history.provider,
              "location": history.location,
            }).toList(),
          ),
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildReferralsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          CurrentReferralsWidget(
            referrals: _referrals.map((referral) => {
              "id": referral.id,
              "trackingNumber": referral.trackingNumber,
              "status": referral.status,
              "urgency": referral.urgency,
              "reason": referral.symptomsDescription,
              "referringPhysician": referral.referringPhysician,
              "createdAt": referral.createdAt.toIso8601String().split('T')[0],
            }).toList(),
            onReferralTap: (referral) {
              Navigator.pushNamed(context, '/referral-tracking');
            },
          ),
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          DocumentsViewerWidget(documents: []), // Empty for now - documents would come from database
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          ContactInfoWidget(
            contactData: {
              "phone": _patient!.phone ?? "Not provided",
              "email": _patient!.email ?? "Not provided",
              "address": _patient!.address ?? "Not provided",
            },
            emergencyContacts: [], // Empty for now - would come from database
          ),
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
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
                color: AppTheme.textSecondaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            _buildMenuOption(
              icon: 'edit',
              title: 'Edit Profile',
              onTap: () {
                Navigator.pop(context);
                // Handle edit profile
              },
            ),
            _buildMenuOption(
              icon: 'note_add',
              title: 'Add Note',
              onTap: () {
                Navigator.pop(context);
                // Handle add note
              },
            ),
            _buildMenuOption(
              icon: 'flag',
              title: 'Flag for Review',
              onTap: () {
                Navigator.pop(context);
                // Handle flag for review
              },
            ),
            _buildMenuOption(
              icon: 'share',
              title: 'Share Profile',
              onTap: () {
                Navigator.pop(context);
                // Handle share profile
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
            SizedBox(width: 4.w),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.textSecondaryLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _createReferral() {
    Navigator.pushNamed(context, '/create-referral');
  }
}
