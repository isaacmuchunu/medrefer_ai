import '../../core/app_export.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  
  const PatientProfileScreen({
    super.key,
    required this.patientId,
  });

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Patient? _patient;
  List<Referral> _patientReferrals = [];
  List<MedicalHistory> _medicalHistory = [];
  List<Condition> _conditions = [];
  List<Medication> _medications = [];
  List<Document> _documents = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<VitalStatistics> _vitalStatistics = [];
  bool _isLoading = true;
  final bool _isEmergencyContact = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPatientData();
  }

  void _initializeAnimations() {
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      
      // Load patient details
      final patient = await dataService.getPatientById(widget.patientId);
      
      // Load related data
      final referrals = await dataService.getReferralsByPatientId(widget.patientId);
      final history = await dataService.getMedicalHistoryByPatientId(widget.patientId);
      final conditions = await dataService.getConditionsByPatientId(widget.patientId);
      final medications = await dataService.getMedicationsByPatientId(widget.patientId);
      final documents = await dataService.getDocumentsByPatientId(widget.patientId);
      final emergencyContacts = await dataService.getEmergencyContactsByPatientId(widget.patientId);
      final vitalStatistics = await dataService.getVitalStatisticsByPatientId(widget.patientId);
      
      setState(() {
        _patient = patient;
        _patientReferrals = referrals;
        _medicalHistory = history;
        _conditions = conditions;
        _medications = medications;
        _documents = documents;
        _emergencyContacts = emergencyContacts;
        _vitalStatistics = vitalStatistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load patient data'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_patient == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Patient not found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: theme.colorScheme.primary,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.editPatientScreen,
                            arguments: {'patientId': widget.patientId},
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onSelected: _handleMenuAction,
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'referral', child: Text('Create Referral')),
                          PopupMenuItem(value: 'message', child: Text('Send Message')),
                          PopupMenuItem(value: 'appointment', child: Text('Schedule Appointment')),
                          PopupMenuItem(value: 'emergency', child: Text('Emergency Contact')),
                          PopupMenuItem(value: 'share', child: Text('Share Profile')),
                        ],
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: _buildPatientHeader(theme),
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  // Tab Bar
                  Container(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                      indicatorColor: theme.colorScheme.primary,
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'History'),
                        Tab(text: 'Documents'),
                        Tab(text: 'Referrals'),
                      ],
                    ),
                  ),
                  
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(theme),
                        _buildHistoryTab(theme),
                        _buildDocumentsTab(theme),
                        _buildReferralsTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.createReferralScreen,
            arguments: {'patientId': widget.patientId},
          );
        },
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.assignment_add),
        label: Text('Create Referral'),
      ),
    );
  }

  Widget _buildPatientHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Patient Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Patient Name
          Text(
            _patient!.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Patient Details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'MRN: ${_patient!.medicalRecordNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_patient!.age} years',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat('Referrals', '${_patientReferrals.length}', Icons.assignment),
              _buildQuickStat('Documents', '${_documents.length}', Icons.description),
              _buildQuickStat('History', '${_medicalHistory.length}', Icons.history),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Card
          _buildInfoCard(
            'Personal Information',
            [
              _buildInfoRow('Full Name', _patient!.name),
              _buildInfoRow('Date of Birth', _formatDate(_patient!.dateOfBirth)),
              _buildInfoRow('Age', '${_patient!.age} years'),
              _buildInfoRow('Gender', _patient!.gender),
              _buildInfoRow('Blood Type', _patient!.bloodType),
            ],
            theme,
          ),

          const SizedBox(height: 16),

          // Contact Information Card
          _buildInfoCard(
            'Contact Information',
            [
              if (_patient!.phone != null) _buildInfoRow('Phone', _patient!.phone!),
              if (_patient!.email != null) _buildInfoRow('Email', _patient!.email!),
              if (_patient!.address != null) _buildInfoRow('Address', _patient!.address!),
            ],
            theme,
          ),
          const SizedBox(height: 16),
          // Emergency Contacts
          _buildInfoCard(
            'Emergency Contacts',
            _emergencyContacts.map((contact) => _buildInfoRow(contact.name, '${contact.relationship} - ${contact.phone}')).toList(),
            theme,
          ),
          const SizedBox(height: 16),
          // Latest Vitals
          if (_vitalStatistics.isNotEmpty)
            _buildInfoCard(
              'Latest Vital Statistics',
              [
                _buildInfoRow('Blood Pressure', _vitalStatistics.last.bloodPressure),
                _buildInfoRow('Heart Rate', '${_vitalStatistics.last.heartRate} bpm'),
                _buildInfoRow('Temperature', '${_vitalStatistics.last.temperature} °C'),
                _buildInfoRow('Oxygen Saturation', '${_vitalStatistics.last.oxygenSaturation}%'),
                _buildInfoRow('BMI', '${_vitalStatistics.last.bmi}'),
                _buildInfoRow('Recorded', _formatDate(_vitalStatistics.last.recordedDate)),
              ],
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_medicalHistory.isNotEmpty) ...[
            Text('Medical History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._medicalHistory.map((history) => _buildHistoryCard(history, theme)),
            const SizedBox(height: 16),
          ],
          if (_conditions.isNotEmpty) ...[
            Text('Conditions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._conditions.map((condition) => _buildConditionCard(condition, theme)),
            const SizedBox(height: 16),
          ],
          if (_medications.isNotEmpty) ...[
            Text('Medications', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._medications.map((med) => _buildMedicationCard(med, theme)),
            const SizedBox(height: 16),
          ],
          if (_vitalStatistics.isNotEmpty) ...[
            Text('Vital Statistics History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._vitalStatistics.map((vitals) => _buildVitalsCard(vitals, theme)),
          ],
          if (_medicalHistory.isEmpty && _conditions.isEmpty && _medications.isEmpty && _vitalStatistics.isEmpty)
            _buildEmptyState('No history available', Icons.history, theme),
        ],
      ),
    );
  }

  Widget _buildConditionCard(Condition condition, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(condition.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                Text(_formatDate(condition.diagnosisDate), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            if (condition.description != null) ...[const SizedBox(height: 8), Text(condition.description!, style: theme.textTheme.bodyMedium)],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication med, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(med.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                Text(_formatDate(med.startDate), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dosage: ${med.dosage}', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard(VitalStatistics vitals, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Vitals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                Text(_formatDate(vitals.recordedDate), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 8),
            Text('BP: ${vitals.bloodPressure} | HR: ${vitals.heartRate} | Temp: ${vitals.temperature} | O2: ${vitals.oxygenSaturation}% | BMI: ${vitals.bmi}', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab(ThemeData theme) {
    return _documents.isEmpty
        ? _buildEmptyState('No documents available', Icons.description, theme)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              final document = _documents[index];
              return _buildDocumentCard(document, theme);
            },
          );
  }

  Widget _buildReferralsTab(ThemeData theme) {
    return _patientReferrals.isEmpty
        ? _buildEmptyState('No referrals available', Icons.assignment, theme)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _patientReferrals.length,
            itemBuilder: (context, index) {
              final referral = _patientReferrals[index];
              return _buildReferralCard(referral, theme);
            },
          );
  }

  Widget _buildInfoCard(String title, List<Widget> children, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(MedicalHistory history, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    history.condition,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(history.diagnosisDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            if (history.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                history.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Document document, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.documentViewerScreen,
              arguments: {
                'documentId': document.id,
                'patientId': widget.patientId,
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _getDocumentIcon(document.type),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.type} • ${document.formattedFileSize}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCard(Referral referral, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.referralDetailsScreen,
              arguments: {'referralId': referral.id},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(referral.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        referral.status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(referral.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(referral.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tracking: ${referral.trackingNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lab':
        return Icons.science;
      case 'image':
        return Icons.image;
      case 'prescription':
        return Icons.medication;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'referral':
        Navigator.pushNamed(
          context,
          AppRoutes.createReferralScreen,
          arguments: {'patientId': widget.patientId},
        );
        break;
      case 'message':
        Navigator.pushNamed(
          context,
          AppRoutes.chatScreen,
          arguments: {'patientId': widget.patientId},
        );
        break;
      case 'appointment':
        Navigator.pushNamed(
          context,
          AppRoutes.appointmentSchedulingScreen,
          arguments: {'patientId': widget.patientId},
        );
        break;
    }
  }
}
