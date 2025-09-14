import '../../core/app_export.dart';

class CreateReferralScreen extends StatefulWidget {
  final String? patientId;
  final String? specialistId;
  
  const CreateReferralScreen({
    Key? key,
    this.patientId,
    this.specialistId,
  }) : super(key: key);

  @override
  _CreateReferralScreenState createState() => _CreateReferralScreenState();
}

class _CreateReferralScreenState extends State<CreateReferralScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  // Controllers
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // State variables
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Form data
  Patient? _selectedPatient;
  Specialist? _selectedSpecialist;
  String _selectedUrgency = 'Medium';
  String _selectedDepartment = 'General Medicine';
  DateTime? _preferredDate;
  List<String> _attachedDocuments = [];
  bool _requiresTranslation = false;
  bool _hasInsurance = true;
  String _insuranceType = 'Primary';
  
  // Options
  final List<String> _urgencyLevels = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _departments = [
    'General Medicine',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Psychiatry',
    'Emergency Medicine',
    'Radiology',
  ];
  final List<String> _insuranceTypes = ['Primary', 'Secondary', 'Self-Pay', 'Medicare', 'Medicaid'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      
      // Load patient if provided
      if (widget.patientId != null) {
        final patient = await dataService.getPatientById(widget.patientId!);
        setState(() {
          _selectedPatient = patient;
        });
      }
      
      // Load specialist if provided
      if (widget.specialistId != null) {
        final specialist = await dataService.getSpecialistById(widget.specialistId!);
        setState(() {
          _selectedSpecialist = specialist;
          if (specialist != null) {
            _selectedDepartment = specialist.specialty;
          }
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load initial data';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Referral',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _saveDraft,
              child: Text('Save Draft'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(theme),
                
                // Form Content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(theme)
                      : PageView(
                          controller: _pageController,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildPatientSelectionStep(theme),
                            _buildSpecialistSelectionStep(theme),
                            _buildReferralDetailsStep(theme),
                            _buildReviewStep(theme),
                          ],
                        ),
                ),
                
                // Navigation Buttons
                _buildNavigationButtons(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : isActive
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : theme.colorScheme.outline.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          )
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                  if (index < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading referral data...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelectionStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Patient',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the patient for this referral',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          // Error Message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          
          // Selected Patient Card or Selection Button
          if (_selectedPatient != null)
            _buildSelectedPatientCard(_selectedPatient!, theme)
          else
            _buildPatientSelectionCard(theme),
        ],
      ),
    );
  }

  Widget _buildSelectedPatientCard(Patient patient, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MRN: ${patient.medicalRecordNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${patient.age} years • ${patient.gender}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedPatient = null;
              });
            },
            icon: Icon(Icons.close, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelectionCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Patient Selected',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search and select a patient to create a referral',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _selectPatient,
            icon: Icon(Icons.search),
            label: Text('Search Patients'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistSelectionStep(ThemeData theme) {
    return Center(child: Text('Specialist selection step - to be implemented'));
  }

  Widget _buildReferralDetailsStep(ThemeData theme) {
    return Center(child: Text('Referral details step - to be implemented'));
  }

  Widget _buildReviewStep(ThemeData theme) {
    return Center(child: Text('Review step - to be implemented'));
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : Text(_currentStep == 3 ? 'Submit Referral' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitReferral();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectPatient() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.patientSearchScreen,
      arguments: {'isSelectionMode': true},
    );

    if (result is Patient) {
      setState(() {
        _selectedPatient = result;
        _errorMessage = null;
      });
    }
  }

  Future<void> _selectSpecialist() async {
    // Mock specialist selection
    setState(() {
      _selectedSpecialist = Specialist(
        id: 'spec_1',
        name: 'Dr. John Smith',
        credentials: 'MD, PhD',
        specialty: _selectedDepartment,
        hospital: 'MedRefer AI Hospital',
        phone: '+1-555-0123',
        email: 'dr.smith@medrefer.com',
        isAvailable: true,
        rating: 4.8,
        yearsOfExperience: 15,
        createdAt: DateTime.now(),
      );
      _errorMessage = null;
    });
  }

  Future<void> _submitReferral() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);

      final referral = Referral(
        id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
        patientId: _selectedPatient!.id,
        specialistId: _selectedSpecialist?.id,
        trackingNumber: 'TRK${DateTime.now().millisecondsSinceEpoch}',
        status: 'Pending',
        urgency: _selectedUrgency,
        department: _selectedDepartment,
        reason: _reasonController.text,
        symptoms: _symptomsController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dataService.createReferral(referral);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral created successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create referral. Please try again.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft saved'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
