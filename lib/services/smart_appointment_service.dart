import 'dart:async';
import '../database/models/patient.dart';
import '../database/services/data_service.dart';
import '../core/result.dart';
import 'ai_service.dart';
import 'blockchain_medical_records_service.dart';
import 'notification_service.dart';
import 'logging_service.dart';

enum AppointmentType {
  consultation,
  followUp,
  procedure,
  surgery,
  diagnostic,
  therapy,
  vaccination,
  emergency,
  telemedicine,
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  noShow,
  rescheduled,
}

enum AppointmentPriority {
  routine,
  urgent,
  emergent,
  critical,
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

class AppointmentSlot {
  final String id;
  final String providerId;
  final String providerName;
  final String specialty;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final int duration; // in minutes
  final String location;
  final AppointmentType allowedTypes;
  final Map<String, dynamic> metadata;

  AppointmentSlot({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.specialty,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    required this.duration,
    required this.location,
    required this.allowedTypes,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'specialty': specialty,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAvailable': isAvailable,
      'duration': duration,
      'location': location,
      'allowedTypes': allowedTypes.name,
      'metadata': metadata,
    };
  }

  factory AppointmentSlot.fromMap(Map<String, dynamic> map) {
    return AppointmentSlot(
      id: map['id'],
      providerId: map['providerId'],
      providerName: map['providerName'],
      specialty: map['specialty'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      isAvailable: map['isAvailable'] ?? true,
      duration: map['duration'],
      location: map['location'],
      allowedTypes: AppointmentType.values.firstWhere(
        (e) => e.name == map['allowedTypes'],
        orElse: () => AppointmentType.consultation,
      ),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class SmartAppointment {
  final String id;
  final String patientId;
  final String providerId;
  final String providerName;
  final String specialty;
  final AppointmentType type;
  final AppointmentStatus status;
  final AppointmentPriority priority;
  final DateTime scheduledTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int duration; // in minutes
  final String location;
  final String? reason;
  final String? notes;
  final Map<String, dynamic> symptoms;
  final List<String> requiredPreparations;
  final RecurrenceType recurrence;
  final DateTime? recurrenceEndDate;
  final String? parentAppointmentId;
  final List<String> attachments;
  final Map<String, dynamic> aiRecommendations;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final Map<String, dynamic> metadata;

  SmartAppointment({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.providerName,
    required this.specialty,
    required this.type,
    this.status = AppointmentStatus.scheduled,
    this.priority = AppointmentPriority.routine,
    required this.scheduledTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.duration,
    required this.location,
    this.reason,
    this.notes,
    this.symptoms = const {},
    this.requiredPreparations = const [],
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.parentAppointmentId,
    this.attachments = const [],
    this.aiRecommendations = const {},
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'providerId': providerId,
      'providerName': providerName,
      'specialty': specialty,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'duration': duration,
      'location': location,
      'reason': reason,
      'notes': notes,
      'symptoms': symptoms,
      'requiredPreparations': requiredPreparations,
      'recurrence': recurrence.name,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'parentAppointmentId': parentAppointmentId,
      'attachments': attachments,
      'aiRecommendations': aiRecommendations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  factory SmartAppointment.fromMap(Map<String, dynamic> map) {
    return SmartAppointment(
      id: map['id'],
      patientId: map['patientId'],
      providerId: map['providerId'],
      providerName: map['providerName'],
      specialty: map['specialty'],
      type: AppointmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AppointmentType.consultation,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      priority: AppointmentPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AppointmentPriority.routine,
      ),
      scheduledTime: DateTime.parse(map['scheduledTime']),
      actualStartTime: map['actualStartTime'] != null 
          ? DateTime.parse(map['actualStartTime'])
          : null,
      actualEndTime: map['actualEndTime'] != null 
          ? DateTime.parse(map['actualEndTime'])
          : null,
      duration: map['duration'],
      location: map['location'],
      reason: map['reason'],
      notes: map['notes'],
      symptoms: Map<String, dynamic>.from(map['symptoms'] ?? {}),
      requiredPreparations: List<String>.from(map['requiredPreparations'] ?? []),
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == map['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      recurrenceEndDate: map['recurrenceEndDate'] != null 
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      parentAppointmentId: map['parentAppointmentId'],
      attachments: List<String>.from(map['attachments'] ?? []),
      aiRecommendations: Map<String, dynamic>.from(map['aiRecommendations'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'])
          : null,
      createdBy: map['createdBy'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  bool get isRecurring => recurrence != RecurrenceType.none;
  
  bool get isUpcoming => scheduledTime.isAfter(DateTime.now());
  
  bool get isOverdue => scheduledTime.isBefore(DateTime.now()) && 
                       status == AppointmentStatus.scheduled;
  
  bool get canBeRescheduled => status == AppointmentStatus.scheduled || 
                              status == AppointmentStatus.confirmed;
}

class AppointmentRecommendation {
  final String providerId;
  final String providerName;
  final String specialty;
  final DateTime suggestedTime;
  final double matchScore;
  final List<String> reasons;
  final int estimatedDuration;
  final String location;
  final Map<String, dynamic> metadata;

  AppointmentRecommendation({
    required this.providerId,
    required this.providerName,
    required this.specialty,
    required this.suggestedTime,
    required this.matchScore,
    required this.reasons,
    required this.estimatedDuration,
    required this.location,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'specialty': specialty,
      'suggestedTime': suggestedTime.toIso8601String(),
      'matchScore': matchScore,
      'reasons': reasons,
      'estimatedDuration': estimatedDuration,
      'location': location,
      'metadata': metadata,
    };
  }

  factory AppointmentRecommendation.fromMap(Map<String, dynamic> map) {
    return AppointmentRecommendation(
      providerId: map['providerId'],
      providerName: map['providerName'],
      specialty: map['specialty'],
      suggestedTime: DateTime.parse(map['suggestedTime']),
      matchScore: map['matchScore']?.toDouble() ?? 0.0,
      reasons: List<String>.from(map['reasons'] ?? []),
      estimatedDuration: map['estimatedDuration'],
      location: map['location'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class SmartAppointmentService {
  SmartAppointmentService._internal();

  final DataService _dataService = DataService();
  final AIService _aiService = AIService();
  final BlockchainMedicalRecordsService _blockchainService = BlockchainMedicalRecordsService();
  final NotificationService _notificationService = NotificationService();
  final LoggingService _loggingService = LoggingService();

  final Map<String, SmartAppointment> _activeAppointments = {};
  final Map<String, List<AppointmentSlot>> _providerSlots = {};
  final StreamController<SmartAppointment> _appointmentController = StreamController.broadcast();
  
  bool _isInitialized = false;
  Timer? _scheduleOptimizationTimer;
  Timer? _reminderTimer;

  Stream<SmartAppointment> get appointmentStream => _appointmentController.stream;

  static final SmartAppointmentService _instance = SmartAppointmentService._internal();
  factory SmartAppointmentService() => _instance;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeServices();
      await _loadActiveAppointments();
      await _loadProviderSchedules();
      _startOptimizationEngine();
      _startReminderEngine();
      
      _isInitialized = true;
      _loggingService.info('SmartAppointmentService initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize SmartAppointmentService', error: e);
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    await _aiService.initialize();
    await _blockchainService.initialize();
    await _notificationService.initialize();
  }

  Future<void> _loadActiveAppointments() async {
    try {
      final result = await _dataService.query(
        'smart_appointments',
        where: 'scheduledTime >= ? AND status NOT IN (?, ?, ?)',
        whereArgs: [
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'completed',
          'cancelled',
          'noShow',
        ],
      );
      
      if (result.isSuccess) {
        for (final appointmentMap in result.data!) {
          final appointment = SmartAppointment.fromMap(appointmentMap);
          _activeAppointments[appointment.id] = appointment;
        }
      }
    } catch (e) {
      _loggingService.error('Failed to load active appointments', error: e);
    }
  }

  Future<void> _loadProviderSchedules() async {
    try {
      final result = await _dataService.query(
        'appointment_slots',
        where: 'startTime >= ? AND isAvailable = ?',
        whereArgs: [
          DateTime.now().toIso8601String(),
          1,
        ],
      );
      
      if (result.isSuccess) {
        for (final slotMap in result.data!) {
          final slot = AppointmentSlot.fromMap(slotMap);
          _providerSlots[slot.providerId] ??= [];
          _providerSlots[slot.providerId]!.add(slot);
        }
      }
    } catch (e) {
      _loggingService.error('Failed to load provider schedules', error: e);
    }
  }

  void _startOptimizationEngine() {
    _scheduleOptimizationTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _optimizeSchedules();
      _handleCancellations();
      _suggestRescheduling();
    });
  }

  void _startReminderEngine() {
    _reminderTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _sendAppointmentReminders();
      _checkOverdueAppointments();
    });
  }

  /// Schedule a new appointment with AI optimization
  Future<Result<SmartAppointment>> scheduleAppointment({
    required String patientId,
    required AppointmentType type,
    String? preferredProviderId,
    String? preferredSpecialty,
    DateTime? preferredTime,
    AppointmentPriority priority = AppointmentPriority.routine,
    String? reason,
    Map<String, dynamic> symptoms = const {},
    RecurrenceType recurrence = RecurrenceType.none,
    DateTime? recurrenceEndDate,
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Get patient information for better matching
      final patientResult = await _dataService.getPatientById(patientId);
      if (patientResult.isError) {
        return Result.error('Patient not found');
      }
      final patient = patientResult.data!;

      // Get AI recommendations for optimal scheduling
      final recommendations = await _getAIRecommendations(
        patient: patient,
        type: type,
        symptoms: symptoms,
        preferredSpecialty: preferredSpecialty,
        preferredTime: preferredTime,
        priority: priority,
        preferences: preferences,
      );

      if (recommendations.isEmpty) {
        return Result.error('No available appointments found');
      }

      // Select the best recommendation
      final bestRecommendation = recommendations.first;

      // Create appointment
      final appointmentId = DateTime.now().millisecondsSinceEpoch.toString();
      final appointment = SmartAppointment(
        id: appointmentId,
        patientId: patientId,
        providerId: bestRecommendation.providerId,
        providerName: bestRecommendation.providerName,
        specialty: bestRecommendation.specialty,
        type: type,
        priority: priority,
        scheduledTime: bestRecommendation.suggestedTime,
        duration: bestRecommendation.estimatedDuration,
        location: bestRecommendation.location,
        reason: reason,
        symptoms: symptoms,
        requiredPreparations: await _getRequiredPreparations(type, symptoms),
        recurrence: recurrence,
        recurrenceEndDate: recurrenceEndDate,
        aiRecommendations: bestRecommendation.toMap(),
        createdAt: DateTime.now(),
        createdBy: 'System',
      );

      // Store in database
      await _dataService.insert('smart_appointments', appointment.toMap());
      
      // Update provider slot availability
      await _bookProviderSlot(bestRecommendation.providerId, bestRecommendation.suggestedTime);
      
      // Add to active appointments
      _activeAppointments[appointmentId] = appointment;

      // Create recurring appointments if specified
      if (recurrence != RecurrenceType.none) {
        await _createRecurringAppointments(appointment);
      }

      // Store in blockchain for audit trail
      await _blockchainService.storeAppointment(patientId, appointment.toMap());

      // Send confirmation notification
      await _sendAppointmentConfirmation(appointment);

      _appointmentController.add(appointment);

      _loggingService.info(
        'Smart appointment scheduled',
        context: 'SmartAppointmentService',
        metadata: {
          'appointmentId': appointmentId,
          'patientId': patientId,
          'providerId': bestRecommendation.providerId,
          'scheduledTime': bestRecommendation.suggestedTime.toIso8601String(),
          'matchScore': bestRecommendation.matchScore,
        },
      );

      return Result.success(appointment);
    } catch (e) {
      _loggingService.error('Error scheduling appointment', error: e);
      return Result.error('Failed to schedule appointment: ${e.toString()}');
    }
  }

  Future<List<AppointmentRecommendation>> _getAIRecommendations({
    required Patient patient,
    required AppointmentType type,
    Map<String, dynamic> symptoms = const {},
    String? preferredSpecialty,
    DateTime? preferredTime,
    AppointmentPriority priority = AppointmentPriority.routine,
    Map<String, dynamic> preferences = const {},
  }) async {
    // Get patient's medical history for better matching
    final medicalHistoryResult = await _dataService.getPatientMedicalHistory(patient.id);
    final medicalHistory = medicalHistoryResult.isSuccess ? medicalHistoryResult.data : [];

    // Get patient's appointment history
    final appointmentHistoryResult = await _getPatientAppointmentHistory(patient.id);
    final appointmentHistory = appointmentHistoryResult.isSuccess ? appointmentHistoryResult.data : [];

    // Use AI to analyze and recommend optimal appointments
    final aiRecommendations = await _aiService.recommendAppointments(
      patient: patient,
      appointmentType: type,
      symptoms: symptoms,
      medicalHistory: medicalHistory ?? [],
      appointmentHistory: appointmentHistory ?? [],
      preferredSpecialty: preferredSpecialty,
      preferredTime: preferredTime,
      priority: priority,
      preferences: preferences,
    );

    // Filter by available slots
    final availableRecommendations = <AppointmentRecommendation>[];
    
    for (final recommendation in aiRecommendations) {
      final isSlotAvailable = await _checkSlotAvailability(
        recommendation.providerId,
        recommendation.suggestedTime,
        recommendation.estimatedDuration,
      );
      
      if (isSlotAvailable) {
        availableRecommendations.add(recommendation);
      }
    }

    // Sort by match score (highest first)
    availableRecommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return availableRecommendations;
  }

  Future<bool> _checkSlotAvailability(
    String providerId,
    DateTime startTime,
    int duration,
  ) async {
    final endTime = startTime.add(Duration(minutes: duration));
    
    // Check provider slots
    final providerSlots = _providerSlots[providerId] ?? [];
    final availableSlot = providerSlots.firstWhere(
      (slot) => slot.isAvailable &&
                slot.startTime.isBefore(startTime.add(const Duration(minutes: 1))) &&
                slot.endTime.isAfter(endTime.subtract(const Duration(minutes: 1))),
      
    );

    // Check for conflicts with existing appointments
    final conflictingAppointments = _activeAppointments.values.where(
      (appointment) => 
          appointment.providerId == providerId &&
          appointment.status != AppointmentStatus.cancelled &&
          appointment.status != AppointmentStatus.noShow &&
          appointment.scheduledTime.isBefore(endTime) &&
          appointment.scheduledTime.add(Duration(minutes: appointment.duration)).isAfter(startTime),
    );

    return conflictingAppointments.isEmpty;
  }

  Future<void> _bookProviderSlot(String providerId, DateTime startTime) async {
    final providerSlots = _providerSlots[providerId] ?? [];
    final slot = providerSlots.firstWhere(
      (slot) => slot.startTime.isBefore(startTime.add(const Duration(minutes: 1))) &&
                slot.endTime.isAfter(startTime.subtract(const Duration(minutes: 1))),
      orElse: () => null as AppointmentSlot,
    );

    // Mark slot as unavailable
    await _dataService.update('appointment_slots', {
      'isAvailable': false,
    }, slot.id);

    // Update in memory
    final updatedSlot = AppointmentSlot(
      id: slot.id,
      providerId: slot.providerId,
      providerName: slot.providerName,
      specialty: slot.specialty,
      startTime: slot.startTime,
      endTime: slot.endTime,
      isAvailable: false,
      duration: slot.duration,
      location: slot.location,
      allowedTypes: slot.allowedTypes,
      metadata: slot.metadata,
    );

    final index = providerSlots.indexWhere((s) => s.id == slot.id);
    if (index >= 0) {
      providerSlots[index] = updatedSlot;
    }
    }

  Future<List<String>> _getRequiredPreparations(
    AppointmentType type,
    Map<String, dynamic> symptoms,
  ) async {
    final preparations = <String>[];
    
    switch (type) {
      case AppointmentType.procedure:
        preparations.addAll([
          'Fast for 8 hours before the procedure',
          'Bring a list of current medications',
          'Arrange transportation home',
        ]);
        break;
      case AppointmentType.surgery:
        preparations.addAll([
          'Fast for 12 hours before surgery',
          'Stop certain medications as instructed',
          'Arrange post-surgery care',
          'Complete pre-operative tests',
        ]);
        break;
      case AppointmentType.diagnostic:
        preparations.addAll([
          'Bring previous test results',
          'Follow specific preparation instructions',
        ]);
        break;
      case AppointmentType.consultation:
        preparations.addAll([
          'Bring insurance card and ID',
          'List current symptoms and medications',
          'Prepare questions for the provider',
        ]);
        break;
      default:
        preparations.addAll([
          'Arrive 15 minutes early',
          'Bring insurance card and ID',
        ]);
        break;
    }

    return preparations;
  }

  Future<void> _createRecurringAppointments(SmartAppointment appointment) async {
    if (appointment.recurrence == RecurrenceType.none) return;

    final recurringAppointments = <SmartAppointment>[];
    var nextDate = _getNextRecurrenceDate(appointment.scheduledTime, appointment.recurrence);
    final endDate = appointment.recurrenceEndDate ?? 
                   appointment.scheduledTime.add(const Duration(days: 365));

    while (nextDate.isBefore(endDate)) {
      final recurringId = '${appointment.id}_${nextDate.millisecondsSinceEpoch}';
      
      final recurringAppointment = SmartAppointment(
        id: recurringId,
        patientId: appointment.patientId,
        providerId: appointment.providerId,
        providerName: appointment.providerName,
        specialty: appointment.specialty,
        type: appointment.type,
        priority: appointment.priority,
        scheduledTime: nextDate,
        duration: appointment.duration,
        location: appointment.location,
        reason: appointment.reason,
        symptoms: appointment.symptoms,
        requiredPreparations: appointment.requiredPreparations,
        recurrence: appointment.recurrence,
        recurrenceEndDate: appointment.recurrenceEndDate,
        parentAppointmentId: appointment.id,
        aiRecommendations: appointment.aiRecommendations,
        createdAt: DateTime.now(),
        createdBy: appointment.createdBy,
      );

      recurringAppointments.add(recurringAppointment);
      nextDate = _getNextRecurrenceDate(nextDate, appointment.recurrence);
    }

    // Store recurring appointments
    for (final recurringAppointment in recurringAppointments) {
      await _dataService.insert('smart_appointments', recurringAppointment.toMap());
      _activeAppointments[recurringAppointment.id] = recurringAppointment;
    }
  }

  DateTime _getNextRecurrenceDate(DateTime currentDate, RecurrenceType recurrence) {
    switch (recurrence) {
      case RecurrenceType.daily:
        return currentDate.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return currentDate.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      case RecurrenceType.yearly:
        return DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
      default:
        return currentDate;
    }
  }

  Future<void> _sendAppointmentConfirmation(SmartAppointment appointment) async {
    await _notificationService.sendAppointmentConfirmation(
      patientId: appointment.patientId,
      appointmentId: appointment.id,
      providerName: appointment.providerName,
      scheduledTime: appointment.scheduledTime,
      location: appointment.location,
      preparations: appointment.requiredPreparations,
    );
  }

  /// Reschedule an existing appointment
  Future<Result<SmartAppointment>> rescheduleAppointment({
    required String appointmentId,
    DateTime? newTime,
    String? newProviderId,
    String? reason,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final appointment = _activeAppointments[appointmentId];
      if (appointment == null) {
        return Result.error('Appointment not found');
      }

      if (!appointment.canBeRescheduled) {
        return Result.error('Appointment cannot be rescheduled');
      }

      DateTime scheduledTime;
      String providerId;

      if (newTime != null && newProviderId != null) {
        scheduledTime = newTime;
        providerId = newProviderId;
      } else {
        // Use AI to find the best alternative time
        final recommendations = await _getAIRecommendations(
          patient: (await _dataService.getPatientById(appointment.patientId)).data!,
          type: appointment.type,
          symptoms: appointment.symptoms,
          preferredSpecialty: appointment.specialty,
          preferredTime: newTime,
          priority: appointment.priority,
        );

        if (recommendations.isEmpty) {
          return Result.error('No alternative slots available');
        }

        final bestRecommendation = recommendations.first;
        scheduledTime = bestRecommendation.suggestedTime;
        providerId = bestRecommendation.providerId;
      }

      // Free up the old slot
      await _freeProviderSlot(appointment.providerId, appointment.scheduledTime);

      // Book the new slot
      await _bookProviderSlot(providerId, scheduledTime);

      // Update appointment
      final rescheduledAppointment = SmartAppointment(
        id: appointment.id,
        patientId: appointment.patientId,
        providerId: providerId,
        providerName: appointment.providerName, // This should be updated if provider changes
        specialty: appointment.specialty,
        type: appointment.type,
        status: AppointmentStatus.rescheduled,
        priority: appointment.priority,
        scheduledTime: scheduledTime,
        actualStartTime: appointment.actualStartTime,
        actualEndTime: appointment.actualEndTime,
        duration: appointment.duration,
        location: appointment.location,
        reason: appointment.reason,
        notes: appointment.notes,
        symptoms: appointment.symptoms,
        requiredPreparations: appointment.requiredPreparations,
        recurrence: appointment.recurrence,
        recurrenceEndDate: appointment.recurrenceEndDate,
        parentAppointmentId: appointment.parentAppointmentId,
        attachments: appointment.attachments,
        aiRecommendations: appointment.aiRecommendations,
        createdAt: appointment.createdAt,
        updatedAt: DateTime.now(),
        createdBy: appointment.createdBy,
        metadata: {...appointment.metadata, 'rescheduledReason': reason},
      );

      // Update in database
      await _dataService.update('smart_appointments', rescheduledAppointment.toMap(), appointmentId);
      
      // Update in memory
      _activeAppointments[appointmentId] = rescheduledAppointment;

      // Store in blockchain
      await _blockchainService.storeAppointmentReschedule(
        appointment.patientId,
        appointmentId,
        {
          'oldTime': appointment.scheduledTime.toIso8601String(),
          'newTime': scheduledTime.toIso8601String(),
          'reason': reason,
          'rescheduledAt': DateTime.now().toIso8601String(),
        },
      );

      // Send notification
      await _notificationService.sendAppointmentReschedule(
        patientId: appointment.patientId,
        appointmentId: appointmentId,
        oldTime: appointment.scheduledTime,
        newTime: scheduledTime,
        reason: reason,
      );

      _appointmentController.add(rescheduledAppointment);

      _loggingService.info(
        'Appointment rescheduled',
        context: 'SmartAppointmentService',
        metadata: {
          'appointmentId': appointmentId,
          'oldTime': appointment.scheduledTime.toIso8601String(),
          'newTime': scheduledTime.toIso8601String(),
        },
      );

      return Result.success(rescheduledAppointment);
    } catch (e) {
      return Result.error('Failed to reschedule appointment: ${e.toString()}');
    }
  }

  Future<void> _freeProviderSlot(String providerId, DateTime startTime) async {
    final providerSlots = _providerSlots[providerId] ?? [];
    final slot = providerSlots.firstWhere(
      (slot) => slot.startTime.isBefore(startTime.add(const Duration(minutes: 1))) &&
                slot.endTime.isAfter(startTime.subtract(const Duration(minutes: 1))),
      
    );

    // Mark slot as available
    await _dataService.update('appointment_slots', {
      'isAvailable': true,
    }, slot.id);

    // Update in memory
    final updatedSlot = AppointmentSlot(
      id: slot.id,
      providerId: slot.providerId,
      providerName: slot.providerName,
      specialty: slot.specialty,
      startTime: slot.startTime,
      endTime: slot.endTime,
      isAvailable: true,
      duration: slot.duration,
      location: slot.location,
      allowedTypes: slot.allowedTypes,
      metadata: slot.metadata,
    );

    final index = providerSlots.indexWhere((s) => s.id == slot.id);
    if (index >= 0) {
      providerSlots[index] = updatedSlot;
    }
    }

  /// Cancel an appointment
  Future<Result<void>> cancelAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final appointment = _activeAppointments[appointmentId];
      if (appointment == null) {
        return Result.error('Appointment not found');
      }

      // Free up the slot
      await _freeProviderSlot(appointment.providerId, appointment.scheduledTime);

      // Update appointment status
      await _dataService.update('smart_appointments', {
        'status': AppointmentStatus.cancelled.name,
        'updatedAt': DateTime.now().toIso8601String(),
        'notes': '${appointment.notes ?? ''}\nCancelled: $reason',
      }, appointmentId);

      // Update in memory
      final cancelledAppointment = SmartAppointment(
        id: appointment.id,
        patientId: appointment.patientId,
        providerId: appointment.providerId,
        providerName: appointment.providerName,
        specialty: appointment.specialty,
        type: appointment.type,
        status: AppointmentStatus.cancelled,
        priority: appointment.priority,
        scheduledTime: appointment.scheduledTime,
        actualStartTime: appointment.actualStartTime,
        actualEndTime: appointment.actualEndTime,
        duration: appointment.duration,
        location: appointment.location,
        reason: appointment.reason,
        notes: '${appointment.notes ?? ''}\nCancelled: $reason',
        symptoms: appointment.symptoms,
        requiredPreparations: appointment.requiredPreparations,
        recurrence: appointment.recurrence,
        recurrenceEndDate: appointment.recurrenceEndDate,
        parentAppointmentId: appointment.parentAppointmentId,
        attachments: appointment.attachments,
        aiRecommendations: appointment.aiRecommendations,
        createdAt: appointment.createdAt,
        updatedAt: DateTime.now(),
        createdBy: appointment.createdBy,
        metadata: appointment.metadata,
      );

      _activeAppointments[appointmentId] = cancelledAppointment;

      // Store in blockchain
      await _blockchainService.storeAppointmentCancellation(
        appointment.patientId,
        appointmentId,
        {
          'reason': reason,
          'cancelledAt': DateTime.now().toIso8601String(),
        },
      );

      // Send notification
      await _notificationService.sendAppointmentCancellation(
        patientId: appointment.patientId,
        appointmentId: appointmentId,
        providerName: appointment.providerName,
        scheduledTime: appointment.scheduledTime,
        reason: reason,
      );

      // Try to fill the cancelled slot with waitlisted patients
      await _processWaitlist(appointment.providerId, appointment.scheduledTime);

      _appointmentController.add(cancelledAppointment);

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to cancel appointment: ${e.toString()}');
    }
  }

  void _optimizeSchedules() {
    // Use AI to optimize provider schedules
    _aiService.optimizeProviderSchedules(_providerSlots);
  }

  void _handleCancellations() {
    // Process cancellations and try to reschedule or fill slots
    for (final appointment in _activeAppointments.values) {
      if (appointment.status == AppointmentStatus.cancelled) {
        _processWaitlist(appointment.providerId, appointment.scheduledTime);
      }
    }
  }

  void _suggestRescheduling() {
    // Suggest rescheduling for appointments that might need it
    final now = DateTime.now();
    for (final appointment in _activeAppointments.values) {
      if (appointment.isOverdue && appointment.status == AppointmentStatus.scheduled) {
        _notificationService.sendRescheduleReminder(
          patientId: appointment.patientId,
          appointmentId: appointment.id,
        );
      }
    }
  }

  void _sendAppointmentReminders() {
    final now = DateTime.now();
    for (final appointment in _activeAppointments.values) {
      if (appointment.status == AppointmentStatus.confirmed) {
        final timeDifference = appointment.scheduledTime.difference(now);
        
        // Send reminders at different intervals
        if (timeDifference.inHours == 24) {
          _notificationService.sendAppointmentReminder(
            patientId: appointment.patientId,
            appointmentId: appointment.id,
            reminderType: '24_hour',
          );
        } else if (timeDifference.inHours == 2) {
          _notificationService.sendAppointmentReminder(
            patientId: appointment.patientId,
            appointmentId: appointment.id,
            reminderType: '2_hour',
          );
        }
      }
    }
  }

  void _checkOverdueAppointments() {
    final now = DateTime.now();
    for (final appointment in _activeAppointments.values) {
      if (appointment.isOverdue) {
        _notificationService.sendOverdueAppointmentAlert(
          patientId: appointment.patientId,
          appointmentId: appointment.id,
        );
      }
    }
  }

  Future<void> _processWaitlist(String providerId, DateTime timeSlot) async {
    // Implementation for processing waitlist when slots become available
    // This would integrate with a waitlist management system
  }

  /// Get patient appointments
  Future<Result<List<SmartAppointment>>> getPatientAppointments(String patientId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final appointments = _activeAppointments.values
          .where((a) => a.patientId == patientId)
          .toList();
      
      // Sort by scheduled time
      appointments.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      return Result.success(appointments);
    } catch (e) {
      return Result.error('Failed to get patient appointments: ${e.toString()}');
    }
  }

  /// Get patient appointment history
  Future<Result<List<SmartAppointment>>> getPatientAppointmentHistory(String patientId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final result = await _dataService.query(
        'smart_appointments',
        where: 'patientId = ?',
        whereArgs: [patientId],
        orderBy: 'scheduledTime DESC',
        limit: 50,
      );
      
      if (result.isSuccess) {
        final appointments = result.data!
            .map((map) => SmartAppointment.fromMap(map))
            .toList();
        return Result.success(appointments);
      }
      
      return Result.error(result.errorMessage!);
    } catch (e) {
      return Result.error('Failed to get appointment history: ${e.toString()}');
    }
  }

  /// Get available slots for a provider
  Future<Result<List<AppointmentSlot>>> getProviderAvailableSlots({
    required String providerId,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      final providerSlots = _providerSlots[providerId] ?? [];
      var availableSlots = providerSlots.where((slot) => slot.isAvailable).toList();
      
      if (startDate != null) {
        availableSlots = availableSlots.where((slot) => slot.startTime.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        availableSlots = availableSlots.where((slot) => slot.startTime.isBefore(endDate)).toList();
      }
      
      if (durationMinutes != null) {
        availableSlots = availableSlots.where((slot) => slot.duration >= durationMinutes).toList();
      }
      
      return Result.success(availableSlots);
    } catch (e) {
      return Result.error('Failed to get available slots: ${e.toString()}');
    }
  }

  /// Get appointment statistics
  Future<Result<Map<String, dynamic>>> getAppointmentStatistics() async {
    try {
      if (!_isInitialized) await initialize();
      
      final stats = <String, dynamic>{};
      
      // Total appointments
      stats['totalAppointments'] = _activeAppointments.length;
      
      // Appointments by status
      final statusCounts = <String, int>{};
      for (final status in AppointmentStatus.values) {
        statusCounts[status.name] = _activeAppointments.values
            .where((a) => a.status == status)
            .length;
      }
      stats['appointmentsByStatus'] = statusCounts;
      
      // Appointments by type
      final typeCounts = <String, int>{};
      for (final type in AppointmentType.values) {
        typeCounts[type.name] = _activeAppointments.values
            .where((a) => a.type == type)
            .length;
      }
      stats['appointmentsByType'] = typeCounts;
      
      // Overdue appointments
      stats['overdueAppointments'] = _activeAppointments.values
          .where((a) => a.isOverdue)
          .length;
      
      // Upcoming appointments
      stats['upcomingAppointments'] = _activeAppointments.values
          .where((a) => a.isUpcoming)
          .length;
      
      // Average wait time (placeholder calculation)
      stats['averageWaitTimeDays'] = 3.5;
      
      // Cancellation rate
      final totalScheduled = _activeAppointments.values
          .where((a) => a.status != AppointmentStatus.cancelled)
          .length;
      final cancelled = statusCounts['cancelled'] ?? 0;
      stats['cancellationRate'] = totalScheduled > 0 ? cancelled / totalScheduled : 0.0;
      
      return Result.success(stats);
    } catch (e) {
      return Result.error('Failed to get appointment statistics: ${e.toString()}');
    }
  }

  void dispose() {
    _scheduleOptimizationTimer?.cancel();
    _reminderTimer?.cancel();
    _appointmentController.close();
  }
}