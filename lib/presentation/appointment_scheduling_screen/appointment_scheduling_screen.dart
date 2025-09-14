import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class AppointmentSchedulingScreen extends StatefulWidget {
  final String? specialistId;
  final String? patientId;
  
  const AppointmentSchedulingScreen({
    Key? key,
    this.specialistId,
    this.patientId,
  }) : super(key: key);

  @override
  _AppointmentSchedulingScreenState createState() => _AppointmentSchedulingScreenState();
}

class _AppointmentSchedulingScreenState extends State<AppointmentSchedulingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String? _selectedSpecialistId;
  String? _selectedPatientId;
  String _appointmentType = 'Consultation';
  String _notes = '';
  bool _isLoading = false;
  
  List<Specialist> _specialists = [];
  List<Patient> _patients = [];
  List<AppointmentSlot> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedSpecialistId = widget.specialistId;
    _selectedPatientId = widget.patientId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final specialists = await dataService.getAvailableSpecialists();
      final patients = await dataService.getPatients();
      
      setState(() {
        _specialists = specialists;
        _patients = patients;
        _isLoading = false;
      });
      
      if (_selectedSpecialistId != null) {
        _loadAvailableSlots();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    // Mock available slots
    final slots = [
      AppointmentSlot(
        time: TimeOfDay(hour: 9, minute: 0),
        isAvailable: true,
        duration: 30,
      ),
      AppointmentSlot(
        time: TimeOfDay(hour: 10, minute: 30),
        isAvailable: true,
        duration: 30,
      ),
      AppointmentSlot(
        time: TimeOfDay(hour: 14, minute: 0),
        isAvailable: true,
        duration: 60,
      ),
      AppointmentSlot(
        time: TimeOfDay(hour: 15, minute: 30),
        isAvailable: false,
        duration: 30,
      ),
    ];
    
    setState(() {
      _availableSlots = slots;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Schedule Appointment',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'Select'),
            Tab(text: 'Schedule'),
            Tab(text: 'Confirm'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSelectionTab(),
                _buildScheduleTab(),
                _buildConfirmationTab(),
              ],
            ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  Widget _buildSelectionTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Selection
          _buildSectionHeader('Select Patient'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedPatientId,
              decoration: InputDecoration(
                labelText: 'Patient',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _patients.map((patient) {
                return DropdownMenuItem<String>(
                  value: patient.id,
                  child: Text('${patient.name} (${patient.medicalRecordNumber})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPatientId = value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Specialist Selection
          _buildSectionHeader('Select Specialist'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSpecialistId,
              decoration: InputDecoration(
                labelText: 'Specialist',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              items: _specialists.map((specialist) {
                return DropdownMenuItem<String>(
                  value: specialist.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(specialist.name),
                      Text(
                        '${specialist.specialty} - ${specialist.hospital}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpecialistId = value;
                });
                if (value != null) {
                  _loadAvailableSlots();
                }
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appointment Type
          _buildSectionHeader('Appointment Type'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _appointmentType,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              items: [
                'Consultation',
                'Follow-up',
                'Procedure',
                'Emergency',
                'Telemedicine',
              ].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _appointmentType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selection
          _buildSectionHeader('Select Date'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 90)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadAvailableSlots();
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Time Slots
          _buildSectionHeader('Available Time Slots'),
          if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No available slots for this date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = _availableSlots[index];
                  final isSelected = _selectedTime == slot.time;
                  
                  return GestureDetector(
                    onTap: slot.isAvailable ? () {
                      setState(() {
                        _selectedTime = slot.time;
                      });
                    } : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: !slot.isAvailable
                            ? theme.colorScheme.outline.withOpacity(0.1)
                            : isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !slot.isAvailable
                              ? theme.colorScheme.outline.withOpacity(0.3)
                              : isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot.time.format(context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: !slot.isAvailable
                                ? theme.colorScheme.onSurface.withOpacity(0.4)
                                : isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationTab() {
    final theme = Theme.of(context);

    if (_selectedSpecialistId == null || _selectedPatientId == null) {
      return Center(
        child: Text('Please complete the previous steps'),
      );
    }

    final selectedSpecialist = _specialists.firstWhere(
      (s) => s.id == _selectedSpecialistId,
      orElse: () => _specialists.first,
    );
    final selectedPatient = _patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () => _patients.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Appointment Summary'),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Patient:', selectedPatient.name),
                _buildSummaryRow('Specialist:', selectedSpecialist.name),
                _buildSummaryRow('Specialty:', selectedSpecialist.specialty),
                _buildSummaryRow('Hospital:', selectedSpecialist.hospital),
                _buildSummaryRow('Date:', _formatDate(_selectedDate)),
                _buildSummaryRow('Time:', _selectedTime?.format(context) ?? 'Not selected'),
                _buildSummaryRow('Type:', _appointmentType),
                if (_notes.isNotEmpty)
                  _buildSummaryRow('Notes:', _notes),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notes Section
          _buildSectionHeader('Additional Notes'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Add any additional notes for the appointment...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 4,
              onChanged: (value) {
                setState(() {
                  _notes = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);

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
          if (_tabController.index < 2)
            Expanded(
              child: ElevatedButton(
                onPressed: _canProceedToNext() ? () {
                  _tabController.animateTo(_tabController.index + 1);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Next'),
              ),
            ),
          if (_tabController.index == 2)
            Expanded(
              child: ElevatedButton(
                onPressed: _canScheduleAppointment() ? _scheduleAppointment : null,
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
                    : Text('Schedule'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  bool _canProceedToNext() {
    switch (_tabController.index) {
      case 0:
        return _selectedPatientId != null && _selectedSpecialistId != null;
      case 1:
        return _selectedTime != null;
      default:
        return false;
    }
  }

  bool _canScheduleAppointment() {
    return _selectedPatientId != null &&
           _selectedSpecialistId != null &&
           _selectedTime != null &&
           !_isLoading;
  }

  Future<void> _scheduleAppointment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate scheduling appointment
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment scheduled successfully'),
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
          content: Text('Failed to schedule appointment'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Appointment slot model
class AppointmentSlot {
  final TimeOfDay time;
  final bool isAvailable;
  final int duration; // in minutes

  AppointmentSlot({
    required this.time,
    required this.isAvailable,
    required this.duration,
  });
}
