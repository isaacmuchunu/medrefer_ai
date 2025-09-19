import 'dart:async';
import '../database/models/medication.dart';
import '../database/models/patient.dart';
import '../database/services/data_service.dart';
import '../core/result.dart';
import 'ai_service.dart';
import 'blockchain_medical_records_service.dart' hide Patient, Referral;
import 'notification_service.dart';
import 'logging_service.dart';

enum InteractionSeverity {
  minor,
  moderate,
  major,
  contraindicated,
}

enum InteractionType {
  drugDrug,
  drugFood,
  drugDisease,
  drugAllergy,
  drugAge,
  drugPregnancy,
}

class DrugInteraction {
  DrugInteraction({
    required this.id,
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.type,
    required this.description,
    required this.mechanism,
    required this.symptoms,
    required this.recommendations,
    required this.confidenceScore,
    required this.detectedAt,
    this.metadata = const {},
  });

  factory DrugInteraction.fromMap(Map<String, dynamic> map) {
    return DrugInteraction(
      id: map['id'],
      drugA: map['drugA'],
      drugB: map['drugB'],
      severity: InteractionSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => InteractionSeverity.minor,
      ),
      type: InteractionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InteractionType.drugDrug,
      ),
      description: map['description'],
      mechanism: map['mechanism'],
      symptoms: List<String>.from(map['symptoms'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      confidenceScore: map['confidenceScore']?.toDouble() ?? 0.0,
      detectedAt: DateTime.parse(map['detectedAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  final String id;
  final String drugA;
  final String drugB;
  final InteractionSeverity severity;
  final InteractionType type;
  final String description;
  final String mechanism;
  final List<String> symptoms;
  final List<String> recommendations;
  final double confidenceScore;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drugA': drugA,
      'drugB': drugB,
      'severity': severity.name,
      'type': type.name,
      'description': description,
      'mechanism': mechanism,
      'symptoms': symptoms,
      'recommendations': recommendations,
      'confidenceScore': confidenceScore,
      'detectedAt': detectedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class DrugInteractionAlert {
  DrugInteractionAlert({
    required this.id,
    required this.patientId,
    required this.interaction,
    this.isActive = true,
    this.acknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.notes,
  });

  factory DrugInteractionAlert.fromMap(Map<String, dynamic> map) {
    return DrugInteractionAlert(
      id: map['id'],
      patientId: map['patientId'],
      interaction: DrugInteraction.fromMap(map['interaction']),
      isActive: map['isActive'] ?? true,
      acknowledged: map['acknowledged'] ?? false,
      acknowledgedBy: map['acknowledgedBy'],
      acknowledgedAt: map['acknowledgedAt'] != null
          ? DateTime.parse(map['acknowledgedAt'])
          : null,
      notes: map['notes'],
    );
  }

  final String id;
  final String patientId;
  final DrugInteraction interaction;
  final bool isActive;
  final bool acknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'interaction': interaction.toMap(),
      'isActive': isActive,
      'acknowledged': acknowledged,
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

class DrugInteractionService {
  DrugInteractionService._internal();

  static final DrugInteractionService _instance =
      DrugInteractionService._internal();

  static DrugInteractionService get instance => _instance;

  final DataService _dataService = DataService();
  final AIService _aiService = AIService();
  final BlockchainMedicalRecordsService _blockchainService = BlockchainMedicalRecordsService();
  final NotificationService _notificationService = NotificationService();
  final LoggingService _loggingService = LoggingService();

  // Drug interaction database
  final Map<String, Map<String, DrugInteraction>> _interactionDatabase = {};
  final Map<String, List<DrugInteractionAlert>> _activeAlerts = {};
  final StreamController<DrugInteractionAlert> _alertController = StreamController.broadcast();

  bool _isInitialized = false;

  Stream<DrugInteractionAlert> get alertStream => _alertController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadInteractionDatabase();
      await _loadActiveAlerts();
      await _initializeServices();
      
      _isInitialized = true;
      _loggingService.info('DrugInteractionService initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize DrugInteractionService', error: e);
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    await _aiService.initialize();
    await _blockchainService.initialize();
    await _notificationService.initialize();
  }

  Future<void> _loadInteractionDatabase() async {
    // Load comprehensive drug interaction database
    // This would typically be loaded from a medical database or API
    _loadKnownInteractions();
  }

  void _loadKnownInteractions() {
    // Sample critical drug interactions
    final interactions = [
      DrugInteraction(
        id: 'warfarin_aspirin',
        drugA: 'warfarin',
        drugB: 'aspirin',
        severity: InteractionSeverity.major,
        type: InteractionType.drugDrug,
        description: 'Increased risk of bleeding when warfarin is combined with aspirin',
        mechanism: 'Both drugs affect blood clotting mechanisms',
        symptoms: ['Unusual bleeding', 'Easy bruising', 'Blood in urine/stool'],
        recommendations: [
          'Monitor INR closely',
          'Consider alternative pain management',
          'Educate patient on bleeding signs',
        ],
        confidenceScore: 0.95,
        detectedAt: DateTime.now(),
      ),
      DrugInteraction(
        id: 'digoxin_furosemide',
        drugA: 'digoxin',
        drugB: 'furosemide',
        severity: InteractionSeverity.major,
        type: InteractionType.drugDrug,
        description: 'Furosemide can increase digoxin toxicity by causing hypokalemia',
        mechanism: 'Furosemide-induced hypokalemia increases digoxin sensitivity',
        symptoms: ['Nausea', 'Vomiting', 'Cardiac arrhythmias', 'Visual disturbances'],
        recommendations: [
          'Monitor serum potassium levels',
          'Monitor digoxin levels',
          'Consider potassium supplementation',
        ],
        confidenceScore: 0.92,
        detectedAt: DateTime.now(),
      ),
      DrugInteraction(
        id: 'metformin_contrast',
        drugA: 'metformin',
        drugB: 'iodinated contrast',
        severity: InteractionSeverity.contraindicated,
        type: InteractionType.drugDrug,
        description: 'Risk of lactic acidosis when metformin is used with contrast agents',
        mechanism: 'Contrast agents can impair kidney function, leading to metformin accumulation',
        symptoms: ['Lactic acidosis', 'Kidney dysfunction', 'Metabolic acidosis'],
        recommendations: [
          'Discontinue metformin 48 hours before contrast',
          'Check kidney function before restarting',
          'Monitor for lactic acidosis symptoms',
        ],
        confidenceScore: 0.98,
        detectedAt: DateTime.now(),
      ),
      DrugInteraction(
        id: 'simvastatin_grapefruit',
        drugA: 'simvastatin',
        drugB: 'grapefruit',
        severity: InteractionSeverity.moderate,
        type: InteractionType.drugFood,
        description: 'Grapefruit juice increases simvastatin levels, increasing risk of myopathy',
        mechanism: 'Grapefruit inhibits CYP3A4 enzyme that metabolizes simvastatin',
        symptoms: ['Muscle pain', 'Weakness', 'Dark urine', 'Liver problems'],
        recommendations: [
          'Avoid grapefruit juice',
          'Monitor for muscle symptoms',
          'Consider alternative statin if needed',
        ],
        confidenceScore: 0.88,
        detectedAt: DateTime.now(),
      ),
    ];

    for (final interaction in interactions) {
      _interactionDatabase[interaction.drugA] ??= {};
      _interactionDatabase[interaction.drugA]![interaction.drugB] = interaction;
      
      _interactionDatabase[interaction.drugB] ??= {};
      _interactionDatabase[interaction.drugB]![interaction.drugA] = interaction;
    }
  }

  Future<void> _loadActiveAlerts() async {
    // Load active alerts from database
    try {
      final result = await _dataService.query('drug_interaction_alerts', 
          where: 'isActive = ?', whereArgs: [1]);
      
      if (result.isSuccess) {
        final alerts = result.data!
            .map((map) => DrugInteractionAlert.fromMap(map))
            .toList();
        
        for (final alert in alerts) {
          _activeAlerts[alert.patientId] ??= [];
          _activeAlerts[alert.patientId]!.add(alert);
        }
      }
    } catch (e) {
      _loggingService.error('Failed to load active alerts', error: e);
    }
  }

  /// Check for drug interactions when adding a new medication
  Future<Result<List<DrugInteraction>>> checkMedicationInteractions({
    required String patientId,
    required Medication newMedication,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Get patient's current medications
      final currentMedications = await _dataService.getPatientMedications(patientId);
      final interactions = <DrugInteraction>[];

      // Check against current medications
      for (final medication in currentMedications) {
        final interaction = await _findInteraction(
          newMedication.name,
          medication.name,
        );
        if (interaction != null) {
          interactions.add(interaction);
        }
      }

      // Get patient information for additional checks
      final patient = await _dataService.getPatientById(patientId);
      if (patient != null) {
        
        // Check for disease-drug interactions
        final diseaseInteractions = await _checkDiseaseInteractions(
          newMedication,
          patient,
        );
        interactions.addAll(diseaseInteractions);

        // Check for age-related interactions
        final ageInteractions = await _checkAgeInteractions(
          newMedication,
          patient.age,
        );
        interactions.addAll(ageInteractions);

        // Check for allergy interactions
        final allergyInteractions = await _checkAllergyInteractions(
          newMedication,
          patient.allergies ?? [],
        );
        interactions.addAll(allergyInteractions);
      }

      // Use AI to find additional potential interactions
      final aiInteractions = await _aiService.predictDrugInteractions(
        newMedication: newMedication,
        currentMedications: currentMedications,
        patientId: patientId,
      );
      interactions.addAll(aiInteractions);

      // Create alerts for significant interactions
      await _createInteractionAlerts(patientId, interactions);

      // Log the interaction check
      _loggingService.info(
        'Drug interaction check completed',
        context: 'DrugInteractionService',
        metadata: {
          'patientId': patientId,
          'newMedication': newMedication.name,
          'interactionsFound': interactions.length,
        },
      );

      return Result.success(interactions);
    } catch (e) {
      _loggingService.error('Error checking drug interactions', error: e);
      return Result.error('Failed to check drug interactions: ${e.toString()}');
    }
  }

  /// Check interactions for an entire medication list
  Future<Result<List<DrugInteraction>>> checkMedicationListInteractions({
    required String patientId,
    required List<Medication> medications,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final allInteractions = <DrugInteraction>[];

      // Check each medication against all others
      for (var i = 0; i < medications.length; i++) {
        for (var j = i + 1; j < medications.length; j++) {
          final interaction = await _findInteraction(
            medications[i].name,
            medications[j].name,
          );
          if (interaction != null) {
            allInteractions.add(interaction);
          }
        }
      }

      // Get patient for additional checks
      final patient = await _dataService.getPatientById(patientId);
      if (patient != null) {
        
        for (final medication in medications) {
          // Disease interactions
          final diseaseInteractions = await _checkDiseaseInteractions(
            medication,
            patient,
          );
          allInteractions.addAll(diseaseInteractions);

          // Age interactions
          final ageInteractions = await _checkAgeInteractions(
            medication,
            patient.age,
          );
          allInteractions.addAll(ageInteractions);

          // Allergy interactions
          final allergyInteractions = await _checkAllergyInteractions(
            medication,
            patient.allergies ?? [],
          );
          allInteractions.addAll(allergyInteractions);
        }
      }

      // Remove duplicates
      final uniqueInteractions = allInteractions.toSet().toList();

      // Create alerts
      await _createInteractionAlerts(patientId, uniqueInteractions);

      return Result.success(uniqueInteractions);
    } catch (e) {
      _loggingService.error('Error checking medication list interactions', error: e);
      return Result.error('Failed to check medication interactions: ${e.toString()}');
    }
  }

  Future<DrugInteraction?> _findInteraction(String drugA, String drugB) async {
    final normalizedA = drugA.toLowerCase().trim();
    final normalizedB = drugB.toLowerCase().trim();

    // Check direct interactions
    if (_interactionDatabase[normalizedA]?.containsKey(normalizedB) == true) {
      return _interactionDatabase[normalizedA]![normalizedB];
    }

    // Check reverse interactions
    if (_interactionDatabase[normalizedB]?.containsKey(normalizedA) == true) {
      return _interactionDatabase[normalizedB]![normalizedA];
    }

    // Use AI to predict potential interactions
    return await _aiService.predictInteraction(drugA, drugB);
  }

  Future<List<DrugInteraction>> _checkDiseaseInteractions(
    Medication medication,
    Patient patient,
  ) async {
    final interactions = <DrugInteraction>[];
    
    // Get patient's medical conditions
    final conditions = await _dataService.getPatientConditions(patient.id);
    for (final condition in conditions) {
      final interaction = await _findDiseaseInteraction(medication.name, condition.name);
      if (interaction != null) {
        interactions.add(interaction);
      }
    }

    return interactions;
  }

  Future<List<DrugInteraction>> _checkAgeInteractions(
    Medication medication,
    int age,
  ) async {
    final interactions = <DrugInteraction>[];
    
    // Check for age-specific contraindications
    if (age >= 65) {
      // Beers Criteria for potentially inappropriate medications in older adults
      final ageInteraction = await _checkBeersListMedication(medication);
      if (ageInteraction != null) {
        interactions.add(ageInteraction);
      }
    }
    
    if (age < 18) {
      // Pediatric contraindications
      final pediatricInteraction = await _checkPediatricContraindication(medication);
      if (pediatricInteraction != null) {
        interactions.add(pediatricInteraction);
      }
    }

    return interactions;
  }

  Future<List<DrugInteraction>> _checkAllergyInteractions(
    Medication medication,
    List<String> allergies,
  ) async {
    final interactions = <DrugInteraction>[];
    
    for (final allergy in allergies) {
      if (_isAllergyInteraction(medication.name, allergy)) {
        interactions.add(DrugInteraction(
          id: '${medication.name}_${allergy}_allergy',
          drugA: medication.name,
          drugB: allergy,
          severity: InteractionSeverity.contraindicated,
          type: InteractionType.drugAllergy,
          description: 'Patient has documented allergy to ${allergy}',
          mechanism: 'Known allergic reaction',
          symptoms: ['Allergic reaction', 'Anaphylaxis', 'Skin rash'],
          recommendations: [
            'Do not administer',
            'Find alternative medication',
            'Update allergy list',
          ],
          confidenceScore: 1.0,
          detectedAt: DateTime.now(),
        ));
      }
    }

    return interactions;
  }

  Future<DrugInteraction?> _findDiseaseInteraction(String drugName, String conditionName) async {
    // Check for known disease-drug interactions
    final key = '${drugName.toLowerCase()}_${conditionName.toLowerCase()}';
    
    // This would be loaded from a comprehensive database
    final knownInteractions = {
      'metformin_kidney_disease': DrugInteraction(
        id: 'metformin_kidney_disease',
        drugA: 'metformin',
        drugB: 'kidney disease',
        severity: InteractionSeverity.contraindicated,
        type: InteractionType.drugDisease,
        description: 'Metformin is contraindicated in kidney disease due to risk of lactic acidosis',
        mechanism: 'Reduced kidney clearance leads to metformin accumulation',
        symptoms: ['Lactic acidosis', 'Kidney dysfunction'],
        recommendations: [
          'Use alternative diabetes medication',
          'Monitor kidney function',
        ],
        confidenceScore: 0.95,
        detectedAt: DateTime.now(),
      ),
    };

    return knownInteractions[key];
  }

  Future<DrugInteraction?> _checkBeersListMedication(Medication medication) async {
    // Check against Beers Criteria
    final beersListMedications = [
      'diphenhydramine',
      'promethazine',
      'hydroxyzine',
      'diazepam',
      'lorazepam',
      'alprazolam',
    ];

    if (beersListMedications.contains(medication.name.toLowerCase())) {
      return DrugInteraction(
        id: '${medication.name}_elderly',
        drugA: medication.name,
        drugB: 'elderly patient',
        severity: InteractionSeverity.moderate,
        type: InteractionType.drugAge,
        description: 'Potentially inappropriate medication for elderly patients',
        mechanism: 'Increased sensitivity and adverse effects in elderly',
        symptoms: ['Sedation', 'Falls risk', 'Cognitive impairment'],
        recommendations: [
          'Consider alternative medication',
          'Use lowest effective dose',
          'Monitor closely for adverse effects',
        ],
        confidenceScore: 0.85,
        detectedAt: DateTime.now(),
      );
    }

    return null;
  }

  Future<DrugInteraction?> _checkPediatricContraindication(Medication medication) async {
    // Check for pediatric contraindications
    final pediatricContraindications = [
      'aspirin',
      'tetracycline',
      'fluoroquinolones',
    ];

    if (pediatricContraindications.contains(medication.name.toLowerCase())) {
      return DrugInteraction(
        id: '${medication.name}_pediatric',
        drugA: medication.name,
        drugB: 'pediatric patient',
        severity: InteractionSeverity.contraindicated,
        type: InteractionType.drugAge,
        description: 'Contraindicated in pediatric patients',
        mechanism: 'Age-specific toxicity or developmental concerns',
        symptoms: ['Age-specific adverse effects'],
        recommendations: [
          'Use pediatric-appropriate alternative',
          'Consult pediatric specialist',
        ],
        confidenceScore: 0.95,
        detectedAt: DateTime.now(),
      );
    }

    return null;
  }

  bool _isAllergyInteraction(String medicationName, String allergy) {
    // Check for cross-allergies and direct matches
    final medication = medicationName.toLowerCase();
    final allergyLower = allergy.toLowerCase();
    
    // Direct match
    if (medication.contains(allergyLower) || allergyLower.contains(medication)) {
      return true;
    }

    // Cross-allergies
    final crossAllergies = {
      'penicillin': ['amoxicillin', 'ampicillin', 'penicillin'],
      'sulfa': ['sulfamethoxazole', 'sulfadiazine'],
      'cephalosporin': ['cephalexin', 'ceftriaxone'],
    };

    for (final entry in crossAllergies.entries) {
      if (allergyLower.contains(entry.key)) {
        for (final crossAllergy in entry.value) {
          if (medication.contains(crossAllergy)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  Future<void> _createInteractionAlerts(
    String patientId,
    List<DrugInteraction> interactions,
  ) async {
    for (final interaction in interactions) {
      // Check if alert already exists
      final existingAlert = _activeAlerts[patientId]?.firstWhere(
        (alert) => alert.interaction.id == interaction.id,
        orElse: () => null as DrugInteractionAlert,
      );

      if (existingAlert == null) {
        final alert = DrugInteractionAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientId: patientId,
          interaction: interaction,
        );

        // Store in database
        await _dataService.insert('drug_interaction_alerts', alert.toMap());
        
        // Add to active alerts
        _activeAlerts[patientId] ??= [];
        _activeAlerts[patientId]!.add(alert);

        // Send notification
        await _sendInteractionNotification(alert);

        // Store in blockchain for audit trail
        await _blockchainService.storeInteractionAlert(patientId, alert.toMap());

        // Emit alert
        _alertController.add(alert);
      }
    }
  }

  Future<void> _sendInteractionNotification(DrugInteractionAlert alert) async {
    var priority = 'medium';
    if (alert.interaction.severity == InteractionSeverity.major ||
        alert.interaction.severity == InteractionSeverity.contraindicated) {
      priority = 'high';
    }

    await _notificationService.sendAlert(
      title: 'Drug Interaction Alert',
      message: '${alert.interaction.severity.name.toUpperCase()}: ${alert.interaction.description}',
      patientId: alert.patientId,
      priority: priority,
      metadata: {
        'type': 'drug_interaction',
        'interactionId': alert.interaction.id,
        'severity': alert.interaction.severity.name,
      },
    );
  }

  /// Get active alerts for a patient
  Future<Result<List<DrugInteractionAlert>>> getPatientAlerts(String patientId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final alerts = _activeAlerts[patientId] ?? [];
      return Result.success(alerts);
    } catch (e) {
      return Result.error('Failed to get patient alerts: ${e.toString()}');
    }
  }

  /// Acknowledge an alert
  Future<Result<void>> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
    String? notes,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Find the alert
      DrugInteractionAlert? targetAlert;
      String? patientId;

      for (final entry in _activeAlerts.entries) {
        final alert = entry.value.firstWhere(
          (a) => a.id == alertId,
          orElse: () => null as DrugInteractionAlert,
        );
        if (alert != null) {
          targetAlert = alert;
          patientId = entry.key;
          break;
        }
      }

      if (targetAlert == null) {
        return Result.error('Alert not found');
      }

      // Update alert
      final updatedAlert = DrugInteractionAlert(
        id: targetAlert.id,
        patientId: targetAlert.patientId,
        interaction: targetAlert.interaction,
        isActive: false, // Mark as inactive
        acknowledged: true,
        acknowledgedBy: acknowledgedBy,
        acknowledgedAt: DateTime.now(),
        notes: notes,
      );

      // Update in database
      await _dataService.update(
        'drug_interaction_alerts',
        updatedAlert.toMap(),
        alertId,
      );

      // Update in memory
      _activeAlerts[patientId]!.removeWhere((a) => a.id == alertId);
      _activeAlerts[patientId]!.add(updatedAlert);


      // Store in blockchain
      await _blockchainService.storeInteractionAlert(patientId!, updatedAlert.toMap());

      _loggingService.info(
        'Drug interaction alert acknowledged',
        context: 'DrugInteractionService',
        metadata: {
          'alertId': alertId,
          'acknowledgedBy': acknowledgedBy,
        },
      );

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to acknowledge alert: ${e.toString()}');
    }
  }

  /// Dismiss an alert
  Future<Result<void>> dismissAlert(String alertId) async {
    try {
      if (!_isInitialized) await initialize();

      // Find and remove the alert
      String? patientId;
      _activeAlerts.forEach((key, value) {
        if (value.any((alert) => alert.id == alertId)) {
          patientId = key;
        }
      });

      if (patientId != null) {
        _activeAlerts[patientId]!.removeWhere((alert) => alert.id == alertId);
      }


      // Update in database
      await _dataService.update(
        'drug_interaction_alerts',
        {'isActive': false},
        alertId,
      );

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to dismiss alert: ${e.toString()}');
    }
  }

  /// Get interaction details
  Future<Result<DrugInteraction?>> getInteractionDetails({
    required String drugA,
    required String drugB,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      final interaction = await _findInteraction(drugA, drugB);
      return Result.success(interaction);
    } catch (e) {
      return Result.error('Failed to get interaction details: ${e.toString()}');
    }
  }

  /// Update interaction database
  Future<void> updateInteractionDatabase() async {
    try {
      // This would fetch updated interaction data from external sources
      // For now, we'll simulate an update
      _loggingService.info('Drug interaction database updated');
    } catch (e) {
      _loggingService.error('Failed to update interaction database', error: e);
    }
  }

  void dispose() {
    _alertController.close();
  }
}
