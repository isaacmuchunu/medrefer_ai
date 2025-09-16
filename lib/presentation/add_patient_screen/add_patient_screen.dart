import '../../core/app_export.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _mrnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  // Form data
  DateTime? _dateOfBirth;
  String _gender = 'Male';
  String _bloodType = 'O+';
  String _maritalStatus = 'Single';
  String _emergencyContactRelation = 'Spouse';
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> _relationOptions = ['Spouse', 'Parent', 'Child', 'Sibling', 'Friend', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _mrnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _medicalHistoryController.dispose();
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
          'Add New Patient',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'Basic Info'),
            Tab(text: 'Contact'),
            Tab(text: 'Medical'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(theme),
            _buildContactTab(theme),
            _buildMedicalTab(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationButtons(theme),
    );
  }

  Widget _buildBasicInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', theme),

          // Full Name
          _buildTextFormField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter patient\'s full name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter patient\'s name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Medical Record Number
          _buildTextFormField(
            controller: _mrnController,
            label: 'Medical Record Number',
            hint: 'Enter MRN',
            icon: Icons.badge,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter MRN';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Date of Birth
          _buildDateField(theme),

          const SizedBox(height: 16),

          // Gender
          _buildDropdownField(
            label: 'Gender',
            value: _gender,
            items: _genderOptions,
            icon: Icons.wc,
            onChanged: (value) => setState(() => _gender = value!),
          ),

          const SizedBox(height: 16),

          // Blood Type
          _buildDropdownField(
            label: 'Blood Type',
            value: _bloodType,
            items: _bloodTypeOptions,
            icon: Icons.bloodtype,
            onChanged: (value) => setState(() => _bloodType = value!),
          ),

          const SizedBox(height: 16),

          // Marital Status
          _buildDropdownField(
            label: 'Marital Status',
            value: _maritalStatus,
            items: _maritalStatusOptions,
            icon: Icons.family_restroom,
            onChanged: (value) => setState(() => _maritalStatus = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Contact Information', theme),

          // Phone Number
          _buildTextFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email
          _buildTextFormField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Address
          _buildTextFormField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter full address',
            icon: Icons.location_on,
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          _buildSectionHeader('Emergency Contact', theme),

          // Emergency Contact Name
          _buildTextFormField(
            controller: _emergencyContactNameController,
            label: 'Emergency Contact Name',
            hint: 'Enter emergency contact name',
            icon: Icons.contact_emergency,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Emergency Contact Phone
          _buildTextFormField(
            controller: _emergencyContactPhoneController,
            label: 'Emergency Contact Phone',
            hint: 'Enter emergency contact phone',
            icon: Icons.phone_in_talk,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact phone';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Emergency Contact Relation
          _buildDropdownField(
            label: 'Relationship',
            value: _emergencyContactRelation,
            items: _relationOptions,
            icon: Icons.people,
            onChanged: (value) => setState(() => _emergencyContactRelation = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Medical Information', theme),

          // Allergies
          _buildTextFormField(
            controller: _allergiesController,
            label: 'Allergies',
            hint: 'List any known allergies',
            icon: Icons.warning,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Current Medications
          _buildTextFormField(
            controller: _medicationsController,
            label: 'Current Medications',
            hint: 'List current medications',
            icon: Icons.medication,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Medical History
          _buildTextFormField(
            controller: _medicalHistoryController,
            label: 'Medical History',
            hint: 'Brief medical history',
            icon: Icons.history,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
        title: Text(
          _dateOfBirth != null
              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
              : 'Select Date of Birth',
          style: _dateOfBirth != null
              ? theme.textTheme.bodyLarge
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _dateOfBirth ?? DateTime.now().subtract(Duration(days: 365 * 30)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _dateOfBirth = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: Text('Previous'),
              ),
            ),
          if (_tabController.index > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_tabController.index < 2) {
                  _tabController.animateTo(_tabController.index + 1);
                } else {
                  _savePatient();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(_tabController.index < 2 ? 'Next' : 'Save Patient'),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select date of birth'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);

      final patient = Patient(
        name: _nameController.text.trim(),
        medicalRecordNumber: _mrnController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        age: DateTime.now().difference(_dateOfBirth!).inDays ~/ 365,
        gender: _gender,
        bloodType: _bloodType,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      final patientId = await dataService.createPatient(patient);

      // Create medical history entries if provided
      if (_allergiesController.text.isNotEmpty ||
          _medicationsController.text.isNotEmpty ||
          _medicalHistoryController.text.isNotEmpty) {

        if (_allergiesController.text.isNotEmpty) {
          final allergyHistory = MedicalHistory(
            patientId: patientId,
            type: 'Allergy',
            title: 'Known Allergies',
            description: _allergiesController.text.trim(),
            date: DateTime.now(),
            provider: 'System Entry',
            location: 'Patient Registration',
          );
          await dataService.createMedicalHistory(allergyHistory);
        }

        if (_medicationsController.text.isNotEmpty) {
          final medicationHistory = MedicalHistory(
            patientId: patientId,
            type: 'Medication',
            title: 'Current Medications',
            description: _medicationsController.text.trim(),
            date: DateTime.now(),
            provider: 'System Entry',
            location: 'Patient Registration',
          );
          await dataService.createMedicalHistory(medicationHistory);
        }

        if (_medicalHistoryController.text.isNotEmpty) {
          final medHistory = MedicalHistory(
            patientId: patientId,
            type: 'History',
            title: 'Medical History',
            description: _medicalHistoryController.text.trim(),
            date: DateTime.now(),
            provider: 'System Entry',
            location: 'Patient Registration',
          );
          await dataService.createMedicalHistory(medHistory);
        }
      }

      if (mounted) {
        Navigator.pop(context, patient);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add patient: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}