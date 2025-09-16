import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';

/// Advanced AI/ML Service for Medical Intelligence
/// Provides diagnostic suggestions, predictive analytics, and smart recommendations
class AIService extends ChangeNotifier {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // ML Model configurations
  static const double _confidenceThreshold = 0.75;
  static const int _maxRecommendations = 10;
  
  // Caches for performance
  final Map<String, DiagnosticPrediction> _predictionCache = {};
  final Map<String, List<SpecialistRecommendation>> _recommendationCache = {};
  final Map<String, RiskAssessment> _riskCache = {};
  
  // Analytics data
  final List<PredictionAccuracy> _accuracyHistory = [];
  Timer? _learningTimer;

  /// Initialize AI Service with pre-trained models
  Future<void> initialize() async {
    try {
      await _loadModels();
      await _initializeLearningLoop();
      debugPrint('AI Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AI Service: $e');
    }
  }

  /// Load pre-trained ML models
  Future<void> _loadModels() async {
    // In production, this would load actual TensorFlow Lite or ONNX models
    await Future.delayed(Duration(milliseconds: 500));
    debugPrint('ML models loaded');
  }

  /// Initialize continuous learning loop
  Future<void> _initializeLearningLoop() async {
    _learningTimer?.cancel();
    _learningTimer = Timer.periodic(Duration(hours: 6), (_) {
      _updateModels();
    });
  }

  /// AI-Powered Diagnostic Suggestions
  Future<DiagnosticPrediction> getDiagnosticSuggestions({
    required List<String> symptoms,
    required Patient patient,
    List<MedicalHistory>? medicalHistory,
    List<Medication>? currentMedications,
    VitalStatistics? vitals,
  }) async {
    try {
      // Generate cache key
      final cacheKey = _generateCacheKey({
        'symptoms': symptoms,
        'patientId': patient.id,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 300000, // 5-minute cache
      });

      // Check cache
      if (_predictionCache.containsKey(cacheKey)) {
        return _predictionCache[cacheKey]!;
      }

      // Feature extraction
      final features = _extractFeatures(
        symptoms: symptoms,
        patient: patient,
        medicalHistory: medicalHistory,
        medications: currentMedications,
        vitals: vitals,
      );

      // Run inference
      final predictions = await _runDiagnosticInference(features);
      
      // Apply clinical rules and guidelines
      final refinedPredictions = _applyClinicalRules(predictions, patient);
      
      // Generate explanations
      final explanations = _generateExplanations(refinedPredictions, features);
      
      // Create prediction result
      final prediction = DiagnosticPrediction(
        id: 'pred_${DateTime.now().millisecondsSinceEpoch}',
        conditions: refinedPredictions,
        confidence: _calculateOverallConfidence(refinedPredictions),
        explanations: explanations,
        recommendedTests: _recommendTests(refinedPredictions),
        urgencyLevel: _assessUrgency(refinedPredictions, symptoms),
        timestamp: DateTime.now(),
      );

      // Cache result
      _predictionCache[cacheKey] = prediction;
      
      // Store for learning
      _storeForLearning(prediction, features);
      
      notifyListeners();
      return prediction;
    } catch (e) {
      debugPrint('Error in diagnostic suggestions: $e');
      throw AIException('Failed to generate diagnostic suggestions: $e');
    }
  }

  /// Specialist Matching with AI
  Future<List<SpecialistRecommendation>> getSpecialistRecommendations({
    required DiagnosticPrediction diagnosis,
    required Patient patient,
    required String location,
    List<String>? preferences,
    bool considerInsurance = true,
  }) async {
    try {
      final cacheKey = _generateCacheKey({
        'diagnosisId': diagnosis.id,
        'patientId': patient.id,
        'location': location,
      });

      if (_recommendationCache.containsKey(cacheKey)) {
        return _recommendationCache[cacheKey]!;
      }

      // Get available specialists
      final specialists = await _getAvailableSpecialists(location);
      
      // Score each specialist
      final scoredSpecialists = <SpecialistRecommendation>[];
      
      for (final specialist in specialists) {
        final score = _scoreSpecialist(
          specialist: specialist,
          diagnosis: diagnosis,
          patient: patient,
          preferences: preferences,
          considerInsurance: considerInsurance,
        );
        
        if (score.totalScore > 0.5) {
          scoredSpecialists.add(SpecialistRecommendation(
            specialist: specialist,
            matchScore: score.totalScore,
            reasons: score.reasons,
            estimatedWaitTime: _estimateWaitTime(specialist),
            successRate: _calculateSuccessRate(specialist, diagnosis),
          ));
        }
      }
      
      // Sort by match score
      scoredSpecialists.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      
      // Take top recommendations
      final recommendations = scoredSpecialists.take(_maxRecommendations).toList();
      
      // Cache results
      _recommendationCache[cacheKey] = recommendations;
      
      return recommendations;
    } catch (e) {
      debugPrint('Error in specialist recommendations: $e');
      throw AIException('Failed to generate specialist recommendations: $e');
    }
  }

  /// Predictive Risk Assessment
  Future<RiskAssessment> assessPatientRisk({
    required Patient patient,
    required List<Condition> conditions,
    required List<Medication> medications,
    VitalStatistics? vitals,
    List<MedicalHistory>? history,
  }) async {
    try {
      final cacheKey = _generateCacheKey({
        'patientId': patient.id,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 3600000, // 1-hour cache
      });

      if (_riskCache.containsKey(cacheKey)) {
        return _riskCache[cacheKey]!;
      }

      // Calculate various risk factors
      final cardiovascularRisk = _calculateCardiovascularRisk(patient, vitals, conditions);
      final diabetesRisk = _calculateDiabetesRisk(patient, vitals, conditions);
      final readmissionRisk = _calculateReadmissionRisk(patient, history, conditions);
      final medicationRisk = _assessMedicationInteractions(medications);
      final fallRisk = _calculateFallRisk(patient, medications, conditions);
      
      // Combine risks using weighted model
      final overallRisk = _combineRisks([
        cardiovascularRisk,
        diabetesRisk,
        readmissionRisk,
        medicationRisk,
        fallRisk,
      ]);
      
      // Generate recommendations
      final recommendations = _generateRiskMitigationRecommendations(
        cardiovascularRisk: cardiovascularRisk,
        diabetesRisk: diabetesRisk,
        readmissionRisk: readmissionRisk,
        medicationRisk: medicationRisk,
        fallRisk: fallRisk,
      );
      
      final assessment = RiskAssessment(
        id: 'risk_${DateTime.now().millisecondsSinceEpoch}',
        patientId: patient.id,
        overallRisk: overallRisk,
        cardiovascularRisk: cardiovascularRisk,
        diabetesRisk: diabetesRisk,
        readmissionRisk: readmissionRisk,
        medicationRisk: medicationRisk,
        fallRisk: fallRisk,
        recommendations: recommendations,
        nextAssessmentDate: DateTime.now().add(Duration(days: 30)),
        timestamp: DateTime.now(),
      );
      
      // Cache result
      _riskCache[cacheKey] = assessment;
      
      return assessment;
    } catch (e) {
      debugPrint('Error in risk assessment: $e');
      throw AIException('Failed to assess patient risk: $e');
    }
  }

  /// Treatment Outcome Prediction
  Future<TreatmentPrediction> predictTreatmentOutcome({
    required String treatmentPlan,
    required Patient patient,
    required List<Condition> conditions,
    List<MedicalHistory>? history,
  }) async {
    try {
      // Extract treatment features
      final features = _extractTreatmentFeatures(
        treatmentPlan: treatmentPlan,
        patient: patient,
        conditions: conditions,
        history: history,
      );
      
      // Run prediction model
      final successProbability = await _predictTreatmentSuccess(features);
      final expectedDuration = _estimateTreatmentDuration(features);
      final possibleComplications = _predictComplications(features);
      final alternativeTreatments = await _suggestAlternatives(treatmentPlan, features);
      
      return TreatmentPrediction(
        id: 'treat_${DateTime.now().millisecondsSinceEpoch}',
        treatmentPlan: treatmentPlan,
        successProbability: successProbability,
        expectedDuration: expectedDuration,
        possibleComplications: possibleComplications,
        alternativeTreatments: alternativeTreatments,
        confidence: _calculateConfidence(features),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error in treatment prediction: $e');
      throw AIException('Failed to predict treatment outcome: $e');
    }
  }

  /// Anomaly Detection in Patient Data
  Future<List<DataAnomaly>> detectAnomalies({
    required Patient patient,
    required List<VitalStatistics> vitalHistory,
    required List<LabResult> labResults,
  }) async {
    try {
      final anomalies = <DataAnomaly>[];
      
      // Check vital signs anomalies
      final vitalAnomalies = _detectVitalAnomalies(vitalHistory);
      anomalies.addAll(vitalAnomalies);
      
      // Check lab result anomalies
      final labAnomalies = _detectLabAnomalies(labResults);
      anomalies.addAll(labAnomalies);
      
      // Check pattern anomalies
      final patternAnomalies = _detectPatternAnomalies(vitalHistory, labResults);
      anomalies.addAll(patternAnomalies);
      
      // Sort by severity
      anomalies.sort((a, b) => b.severity.index.compareTo(a.severity.index));
      
      return anomalies;
    } catch (e) {
      debugPrint('Error in anomaly detection: $e');
      throw AIException('Failed to detect anomalies: $e');
    }
  }

  /// Natural Language Processing for Medical Notes
  Future<MedicalNoteAnalysis> analyzeMedicalNote(String noteText) async {
    try {
      // Extract medical entities
      final entities = _extractMedicalEntities(noteText);
      
      // Sentiment analysis
      final sentiment = _analyzeSentiment(noteText);
      
      // Extract key findings
      final keyFindings = _extractKeyFindings(noteText);
      
      // Identify action items
      final actionItems = _extractActionItems(noteText);
      
      // Generate summary
      final summary = _generateNoteSummary(noteText, entities, keyFindings);
      
      return MedicalNoteAnalysis(
        entities: entities,
        sentiment: sentiment,
        keyFindings: keyFindings,
        actionItems: actionItems,
        summary: summary,
        confidence: _calculateNLPConfidence(entities),
      );
    } catch (e) {
      debugPrint('Error in medical note analysis: $e');
      throw AIException('Failed to analyze medical note: $e');
    }
  }

  // Private helper methods

  Map<String, dynamic> _extractFeatures({
    required List<String> symptoms,
    required Patient patient,
    List<MedicalHistory>? medicalHistory,
    List<Medication>? medications,
    VitalStatistics? vitals,
  }) {
    return {
      'symptoms': symptoms,
      'age': _calculateAge(patient.dateOfBirth),
      'gender': patient.gender,
      'medicalHistoryCount': medicalHistory?.length ?? 0,
      'medicationCount': medications?.length ?? 0,
      'hasChronicConditions': _hasChronicConditions(medicalHistory),
      'vitalAbnormalities': _checkVitalAbnormalities(vitals),
      'symptomSeverity': _calculateSymptomSeverity(symptoms),
      'symptomDuration': _estimateSymptomDuration(symptoms),
    };
  }

  Future<List<PossibleCondition>> _runDiagnosticInference(Map<String, dynamic> features) async {
    // Simulate ML inference with realistic medical conditions
    await Future.delayed(Duration(milliseconds: 200));
    
    final conditions = <PossibleCondition>[];
    final symptoms = features['symptoms'] as List<String>;
    
    // Pattern matching for common conditions
    if (_containsSymptoms(symptoms, ['fever', 'cough', 'fatigue'])) {
      conditions.add(PossibleCondition(
        name: 'Upper Respiratory Infection',
        icd10Code: 'J06.9',
        probability: 0.82,
        severity: 'Mild',
      ));
    }
    
    if (_containsSymptoms(symptoms, ['chest pain', 'shortness of breath'])) {
      conditions.add(PossibleCondition(
        name: 'Possible Cardiac Event',
        icd10Code: 'I20.9',
        probability: 0.65,
        severity: 'Severe',
      ));
    }
    
    if (_containsSymptoms(symptoms, ['headache', 'nausea', 'dizziness'])) {
      conditions.add(PossibleCondition(
        name: 'Migraine',
        icd10Code: 'G43.909',
        probability: 0.73,
        severity: 'Moderate',
      ));
    }
    
    // Add more condition patterns...
    
    return conditions;
  }

  List<PossibleCondition> _applyClinicalRules(
    List<PossibleCondition> predictions,
    Patient patient,
  ) {
    // Apply clinical guidelines and rules
    final age = _calculateAge(patient.dateOfBirth);
    
    return predictions.map((condition) {
      var adjustedProbability = condition.probability;
      
      // Age-based adjustments
      if (condition.name.contains('Cardiac') && age < 30) {
        adjustedProbability *= 0.7; // Lower probability for young patients
      }
      
      // Gender-based adjustments
      if (condition.name.contains('Pregnancy') && patient.gender != 'Female') {
        adjustedProbability = 0.0;
      }
      
      return PossibleCondition(
        name: condition.name,
        icd10Code: condition.icd10Code,
        probability: adjustedProbability,
        severity: condition.severity,
      );
    }).where((c) => c.probability > 0.3).toList();
  }

  Map<String, String> _generateExplanations(
    List<PossibleCondition> predictions,
    Map<String, dynamic> features,
  ) {
    final explanations = <String, String>{};
    
    for (final condition in predictions) {
      final symptoms = features['symptoms'] as List<String>;
      explanations[condition.name] = 
        'Based on symptoms: ${symptoms.join(", ")}, '
        'patient demographics, and medical history patterns. '
        'Confidence: ${(condition.probability * 100).toStringAsFixed(1)}%';
    }
    
    return explanations;
  }

  List<String> _recommendTests(List<PossibleCondition> predictions) {
    final tests = <String>{};
    
    for (final condition in predictions) {
      if (condition.name.contains('Respiratory')) {
        tests.addAll(['Chest X-Ray', 'Complete Blood Count', 'Pulse Oximetry']);
      }
      if (condition.name.contains('Cardiac')) {
        tests.addAll(['ECG', 'Troponin Test', 'Chest X-Ray', 'Echocardiogram']);
      }
      if (condition.name.contains('Diabetes')) {
        tests.addAll(['Fasting Glucose', 'HbA1c', 'Lipid Panel']);
      }
      // Add more test recommendations...
    }
    
    return tests.toList();
  }

  String _assessUrgency(List<PossibleCondition> predictions, List<String> symptoms) {
    // Check for emergency symptoms
    final emergencySymptoms = [
      'chest pain', 'difficulty breathing', 'unconscious',
      'severe bleeding', 'stroke symptoms', 'severe allergic reaction'
    ];
    
    if (symptoms.any((s) => emergencySymptoms.any((e) => s.toLowerCase().contains(e)))) {
      return 'Emergency';
    }
    
    // Check condition severity
    if (predictions.any((c) => c.severity == 'Severe')) {
      return 'Urgent';
    }
    
    if (predictions.any((c) => c.severity == 'Moderate')) {
      return 'Semi-Urgent';
    }
    
    return 'Routine';
  }

  double _calculateOverallConfidence(List<PossibleCondition> predictions) {
    if (predictions.isEmpty) return 0.0;
    
    final maxProbability = predictions.map((c) => c.probability).reduce(max);
    final avgProbability = predictions.map((c) => c.probability).reduce((a, b) => a + b) / predictions.length;
    
    return maxProbability * 0.7 + avgProbability * 0.3;
  }

  void _storeForLearning(DiagnosticPrediction prediction, Map<String, dynamic> features) {
    // Store prediction for continuous learning
    _accuracyHistory.add(PredictionAccuracy(
      predictionId: prediction.id,
      features: features,
      prediction: prediction,
      timestamp: DateTime.now(),
    ));
    
    // Keep only recent history
    if (_accuracyHistory.length > 1000) {
      _accuracyHistory.removeRange(0, 100);
    }
  }

  Future<void> _updateModels() async {
    // Continuous learning - update models based on feedback
    debugPrint('Updating ML models with ${_accuracyHistory.length} samples');
    
    // In production, this would retrain or fine-tune models
    await Future.delayed(Duration(seconds: 5));
    
    debugPrint('ML models updated successfully');
  }

  double _calculateCardiovascularRisk(
    Patient patient,
    VitalStatistics? vitals,
    List<Condition> conditions,
  ) {
    var risk = 0.0;
    final age = _calculateAge(patient.dateOfBirth);
    
    // Age factor
    if (age > 65) {
      risk += 0.3;
    } else if (age > 50) risk += 0.2;
    else if (age > 40) risk += 0.1;
    
    // Vital signs
    if (vitals != null) {
      final systolic = vitals.bloodPressureSystolic ?? 0;
      final diastolic = vitals.bloodPressureDiastolic ?? 0;
      final heartRate = vitals.heartRate ?? 0;
      
      if (systolic > 140) risk += 0.2;
      if (diastolic > 90) risk += 0.15;
      if (heartRate > 100 || heartRate < 60) risk += 0.1;
    }
    
    // Existing conditions
    if (conditions.any((c) => c.name.toLowerCase().contains('hypertension'))) risk += 0.25;
    if (conditions.any((c) => c.name.toLowerCase().contains('diabetes'))) risk += 0.2;
    if (conditions.any((c) => c.name.toLowerCase().contains('cholesterol'))) risk += 0.15;
    
    return min(risk, 1.0);
  }

  double _calculateDiabetesRisk(
    Patient patient,
    VitalStatistics? vitals,
    List<Condition> conditions,
  ) {
    var risk = 0.0;
    final age = _calculateAge(patient.dateOfBirth);
    
    // Age factor
    if (age > 45) risk += 0.15;
    
    // BMI factor (if available)
    if (vitals != null && vitals.weight != null && vitals.height != null) {
      final bmi = vitals.weight! / pow(vitals.height! / 100, 2);
      if (bmi > 30) {
        risk += 0.3;
      } else if (bmi > 25) risk += 0.15;
    }
    
    // Family history and existing conditions
    if (conditions.any((c) => c.name.toLowerCase().contains('prediabetes'))) risk += 0.4;
    if (conditions.any((c) => c.name.toLowerCase().contains('hypertension'))) risk += 0.1;
    
    return min(risk, 1.0);
  }

  double _calculateReadmissionRisk(
    Patient patient,
    List<MedicalHistory>? history,
    List<Condition> conditions,
  ) {
    var risk = 0.0;
    
    // Previous admissions
    if (history != null) {
      final recentAdmissions = history.where((h) => 
        h.type == 'Admission' && 
        h.date.isAfter(DateTime.now().subtract(Duration(days: 180)))
      ).length;
      
      risk += recentAdmissions * 0.15;
    }
    
    // Chronic conditions
    final chronicConditions = conditions.where((c) => c.isActive).length;
    risk += chronicConditions * 0.1;
    
    return min(risk, 1.0);
  }

  double _assessMedicationInteractions(List<Medication> medications) {
    var risk = 0.0;
    
    // Check for known interactions (simplified)
    final medicationNames = medications.map((m) => m.name.toLowerCase()).toList();
    
    // Example interaction checks
    if (medicationNames.contains('warfarin') && medicationNames.contains('aspirin')) {
      risk += 0.3;
    }
    
    // Polypharmacy risk
    if (medications.length > 10) {
      risk += 0.3;
    } else if (medications.length > 5) risk += 0.15;
    
    return min(risk, 1.0);
  }

  double _calculateFallRisk(
    Patient patient,
    List<Medication> medications,
    List<Condition> conditions,
  ) {
    var risk = 0.0;
    final age = _calculateAge(patient.dateOfBirth);
    
    // Age factor
    if (age > 75) {
      risk += 0.3;
    } else if (age > 65) risk += 0.2;
    
    // Medications that increase fall risk
    final riskMedications = ['benzodiazepine', 'antipsychotic', 'sedative', 'hypnotic'];
    for (final med in medications) {
      if (riskMedications.any((r) => med.name.toLowerCase().contains(r))) {
        risk += 0.15;
      }
    }
    
    // Conditions that increase fall risk
    if (conditions.any((c) => c.name.toLowerCase().contains('parkinson'))) risk += 0.25;
    if (conditions.any((c) => c.name.toLowerCase().contains('neuropathy'))) risk += 0.2;
    
    return min(risk, 1.0);
  }

  double _combineRisks(List<double> risks) {
    if (risks.isEmpty) return 0.0;
    
    // Weighted average with emphasis on highest risks
    risks.sort((a, b) => b.compareTo(a));
    var combinedRisk = 0.0;
    var weight = 0.5;
    
    for (final risk in risks) {
      combinedRisk += risk * weight;
      weight *= 0.7;
    }
    
    return min(combinedRisk, 1.0);
  }

  List<String> _generateRiskMitigationRecommendations({
    required double cardiovascularRisk,
    required double diabetesRisk,
    required double readmissionRisk,
    required double medicationRisk,
    required double fallRisk,
  }) {
    final recommendations = <String>[];
    
    if (cardiovascularRisk > 0.5) {
      recommendations.add('Schedule cardiovascular screening');
      recommendations.add('Monitor blood pressure regularly');
      recommendations.add('Consider lifestyle modifications (diet, exercise)');
    }
    
    if (diabetesRisk > 0.5) {
      recommendations.add('Regular glucose monitoring');
      recommendations.add('Nutritionist consultation recommended');
      recommendations.add('Increase physical activity');
    }
    
    if (readmissionRisk > 0.5) {
      recommendations.add('Enhanced discharge planning needed');
      recommendations.add('Schedule follow-up within 7 days');
      recommendations.add('Consider home health services');
    }
    
    if (medicationRisk > 0.5) {
      recommendations.add('Medication review by pharmacist');
      recommendations.add('Check for drug interactions');
      recommendations.add('Consider medication reconciliation');
    }
    
    if (fallRisk > 0.5) {
      recommendations.add('Fall risk assessment needed');
      recommendations.add('Home safety evaluation');
      recommendations.add('Consider physical therapy');
    }
    
    return recommendations;
  }

  Future<List<Specialist>> _getAvailableSpecialists(String location) async {
    // In production, this would query the database
    return [];
  }

  SpecialistScore _scoreSpecialist({
    required Specialist specialist,
    required DiagnosticPrediction diagnosis,
    required Patient patient,
    List<String>? preferences,
    required bool considerInsurance,
  }) {
    var score = 0.0;
    final reasons = <String>[];
    
    // Specialty match
    final requiredSpecialties = _getRequiredSpecialties(diagnosis);
    if (requiredSpecialties.contains(specialist.specialty)) {
      score += 0.3;
      reasons.add('Specialty matches diagnosis');
    }
    
    // Experience and rating
    if (specialist.rating! > 4.5) {
      score += 0.2;
      reasons.add('Highly rated specialist');
    }
    
    // Availability
    if (specialist.isAvailable) {
      score += 0.15;
      reasons.add('Currently available');
    }
    
    // Insurance compatibility
    if (considerInsurance && patient.insurance != null) {
      // Check insurance compatibility
      score += 0.1;
    }
    
    // Distance/location
    if (specialist.distance != null && specialist.distance!.contains('km')) {
      final distance = double.tryParse(specialist.distance!.replaceAll(' km', '')) ?? 100;
      if (distance < 10) {
        score += 0.15;
        reasons.add('Nearby location');
      }
    }
    
    // Patient preferences
    if (preferences != null) {
      for (final pref in preferences) {
        if (specialist.languages.contains(pref) ?? false) {
          score += 0.05;
          reasons.add('Language preference matched');
        }
      }
    }
    
    return SpecialistScore(totalScore: min(score, 1.0), reasons: reasons);
  }

  List<String> _getRequiredSpecialties(DiagnosticPrediction diagnosis) {
    final specialties = <String>{};
    
    for (final condition in diagnosis.conditions) {
      if (condition.name.contains('Cardiac')) {
        specialties.add('Cardiology');
      }
      if (condition.name.contains('Respiratory')) {
        specialties.add('Pulmonology');
      }
      if (condition.name.contains('Diabetes')) {
        specialties.add('Endocrinology');
      }
      // Add more specialty mappings...
    }
    
    return specialties.toList();
  }

  Duration _estimateWaitTime(Specialist specialist) {
    // Estimate based on availability and current load
    if (!specialist.isAvailable) {
      return Duration(days: 7);
    }
    
    // Random estimation for demo
    final days = Random().nextInt(5) + 1;
    return Duration(days: days);
  }

  double _calculateSuccessRate(Specialist specialist, DiagnosticPrediction diagnosis) {
    // Base success rate
    var rate = specialist.successRate ?? 0.85;
    
    // Adjust based on specialty match
    final requiredSpecialties = _getRequiredSpecialties(diagnosis);
    if (requiredSpecialties.contains(specialist.specialty)) {
      rate += 0.1;
    }
    
    return min(rate, 0.99);
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _hasChronicConditions(List<MedicalHistory>? history) {
    if (history == null) return false;
    
    final chronicKeywords = ['chronic', 'diabetes', 'hypertension', 'asthma', 'copd'];
    return history.any((h) => 
      chronicKeywords.any((k) => h.description?.toLowerCase().contains(k) ?? false)
    );
  }

  Map<String, bool> _checkVitalAbnormalities(VitalStatistics? vitals) {
    if (vitals == null) return {};
    
    final systolic = vitals.bloodPressureSystolic ?? 0;
    final diastolic = vitals.bloodPressureDiastolic ?? 0;
    final heartRate = vitals.heartRate ?? 0;
    final temperature = vitals.temperature ?? 0;
    final oxygenSat = vitals.oxygenSaturation ?? 0;
    
    return {
      'highBP': systolic > 140 || diastolic > 90,
      'lowBP': systolic < 90 || diastolic < 60,
      'highHR': heartRate > 100,
      'lowHR': heartRate < 60,
      'fever': temperature > 38.0,
      'lowO2': oxygenSat > 0 && oxygenSat < 95,
    };
  }

  double _calculateSymptomSeverity(List<String> symptoms) {
    final severeSymptoms = ['severe', 'acute', 'intense', 'unbearable', 'extreme'];
    final moderateSymptoms = ['moderate', 'persistent', 'recurring', 'frequent'];
    
    var severity = 0.3; // Base severity
    
    for (final symptom in symptoms) {
      if (severeSymptoms.any((s) => symptom.toLowerCase().contains(s))) {
        severity += 0.2;
      } else if (moderateSymptoms.any((s) => symptom.toLowerCase().contains(s))) {
        severity += 0.1;
      }
    }
    
    return min(severity, 1.0);
  }

  Duration _estimateSymptomDuration(List<String> symptoms) {
    // Parse duration from symptoms if mentioned
    for (final symptom in symptoms) {
      if (symptom.contains('days')) {
        final match = RegExp(r'(\d+)\s*days').firstMatch(symptom);
        if (match != null) {
          return Duration(days: int.parse(match.group(1)!));
        }
      }
      if (symptom.contains('weeks')) {
        final match = RegExp(r'(\d+)\s*weeks').firstMatch(symptom);
        if (match != null) {
          return Duration(days: int.parse(match.group(1)!) * 7);
        }
      }
    }
    
    return Duration(days: 3); // Default estimate
  }

  bool _containsSymptoms(List<String> symptoms, List<String> targetSymptoms) {
    final lowerSymptoms = symptoms.map((s) => s.toLowerCase()).toList();
    return targetSymptoms.every((target) => 
      lowerSymptoms.any((s) => s.contains(target.toLowerCase()))
    );
  }

  Map<String, dynamic> _extractTreatmentFeatures({
    required String treatmentPlan,
    required Patient patient,
    required List<Condition> conditions,
    List<MedicalHistory>? history,
  }) {
    return {
      'treatmentType': _classifyTreatment(treatmentPlan),
      'patientAge': _calculateAge(patient.dateOfBirth),
      'conditionCount': conditions.length,
      'chronicConditions': conditions.where((c) => c.isActive).length,
      'previousTreatments': history?.where((h) => h.type == 'Treatment').length ?? 0,
    };
  }

  String _classifyTreatment(String treatmentPlan) {
    if (treatmentPlan.toLowerCase().contains('surgery')) return 'Surgical';
    if (treatmentPlan.toLowerCase().contains('medication')) return 'Pharmaceutical';
    if (treatmentPlan.toLowerCase().contains('therapy')) return 'Therapeutic';
    return 'Conservative';
  }

  Future<double> _predictTreatmentSuccess(Map<String, dynamic> features) async {
    // Simulate ML prediction
    await Future.delayed(Duration(milliseconds: 100));
    
    // Base success rate
    var success = 0.7;
    
    // Adjust based on features
    final treatmentType = features['treatmentType'];
    if (treatmentType == 'Surgical') {
      success -= 0.1; // Surgery has more risks
    }
    
    final age = features['patientAge'] as int;
    if (age < 50) {
      success += 0.1; // Younger patients typically respond better
    }
    
    return min(success, 0.95);
  }

  Duration _estimateTreatmentDuration(Map<String, dynamic> features) {
    final treatmentType = features['treatmentType'];
    
    switch (treatmentType) {
      case 'Surgical':
        return Duration(days: 60); // Recovery period
      case 'Pharmaceutical':
        return Duration(days: 30);
      case 'Therapeutic':
        return Duration(days: 90);
      default:
        return Duration(days: 14);
    }
  }

  List<String> _predictComplications(Map<String, dynamic> features) {
    final complications = <String>[];
    final treatmentType = features['treatmentType'];
    final age = features['patientAge'] as int;
    
    if (treatmentType == 'Surgical') {
      complications.add('Post-operative infection risk');
      complications.add('Anesthesia complications');
      if (age > 65) {
        complications.add('Extended recovery time');
      }
    }
    
    if (treatmentType == 'Pharmaceutical') {
      complications.add('Potential drug interactions');
      complications.add('Side effects monitoring needed');
    }
    
    return complications;
  }

  Future<List<String>> _suggestAlternatives(
    String treatmentPlan,
    Map<String, dynamic> features,
  ) async {
    final alternatives = <String>[];
    final treatmentType = features['treatmentType'];
    
    if (treatmentType == 'Surgical') {
      alternatives.add('Conservative management with medication');
      alternatives.add('Minimally invasive procedure');
    } else if (treatmentType == 'Pharmaceutical') {
      alternatives.add('Lifestyle modifications');
      alternatives.add('Physical therapy');
      alternatives.add('Alternative medication regimen');
    }
    
    return alternatives;
  }

  double _calculateConfidence(Map<String, dynamic> features) {
    // Base confidence
    var confidence = 0.75;
    
    // Adjust based on data completeness
    if (features['previousTreatments'] != null && features['previousTreatments'] > 0) {
      confidence += 0.1;
    }
    
    return min(confidence, 0.95);
  }

  List<DataAnomaly> _detectVitalAnomalies(List<VitalStatistics> vitalHistory) {
    final anomalies = <DataAnomaly>[];
    
    for (var i = 0; i < vitalHistory.length; i++) {
      final vital = vitalHistory[i];
      
      // Check for out-of-range values
      final heartRate = double.tryParse(vital.heartRate ?? '0') ?? 0;
      final systolic = double.tryParse(vital.bloodPressureSystolic ?? '0') ?? 0;
      final diastolic = double.tryParse(vital.bloodPressureDiastolic ?? '0') ?? 0;
      
      if (heartRate < 40 || heartRate > 150) {
        anomalies.add(DataAnomaly(
          type: 'Vital Sign',
          description: 'Abnormal heart rate: ${heartRate} bpm',
          severity: AnomalySeverity.high,
          timestamp: vital.timestamp,
        ));
      }
      
      if (systolic > 180 || diastolic > 120) {
        anomalies.add(DataAnomaly(
          type: 'Vital Sign',
          description: 'Hypertensive crisis: ${systolic}/${diastolic}',
          severity: AnomalySeverity.critical,
          timestamp: vital.timestamp,
        ));
      }
      
      // Check for sudden changes
      if (i > 0) {
        final prevVital = vitalHistory[i - 1];
        final prevHeartRate = double.tryParse(prevVital.heartRate ?? '0') ?? 0;
        final hrChange = (heartRate - prevHeartRate).abs();
        
        if (hrChange > 30) {
          anomalies.add(DataAnomaly(
            type: 'Trend',
            description: 'Sudden heart rate change: ${hrChange} bpm',
            severity: AnomalySeverity.medium,
            timestamp: vital.timestamp,
          ));
        }
      }
    }
    
    return anomalies;
  }

  List<DataAnomaly> _detectLabAnomalies(List<LabResult> labResults) {
    final anomalies = <DataAnomaly>[];
    
    for (final result in labResults) {
      // Check for critical values
      if (result.isCritical) {
        anomalies.add(DataAnomaly(
          type: 'Lab Result',
          description: 'Critical lab value: ${result.testName}',
          severity: AnomalySeverity.critical,
          timestamp: result.performedAt,
        ));
      }
      
      // Check for out-of-range values
      if (result.value != null && result.normalRange != null) {
        final value = double.tryParse(result.value!) ?? 0;
        final range = result.normalRange!.split('-');
        if (range.length == 2) {
          final min = double.tryParse(range[0]) ?? 0;
          final max = double.tryParse(range[1]) ?? double.infinity;
          
          if (value < min || value > max) {
            anomalies.add(DataAnomaly(
              type: 'Lab Result',
              description: 'Out of range: ${result.testName} = ${result.value} (Normal: ${result.normalRange})',
              severity: AnomalySeverity.medium,
              timestamp: result.performedAt,
            ));
          }
        }
      }
    }
    
    return anomalies;
  }

  List<DataAnomaly> _detectPatternAnomalies(
    List<VitalStatistics> vitalHistory,
    List<LabResult> labResults,
  ) {
    final anomalies = <DataAnomaly>[];
    
    // Detect deteriorating trends
    if (vitalHistory.length >= 3) {
      var deteriorating = true;
      for (var i = 2; i < vitalHistory.length && i < 5; i++) {
        final currentSystolic = double.tryParse(vitalHistory[i].bloodPressureSystolic ?? '0') ?? 0;
        final prevSystolic = double.tryParse(vitalHistory[i - 1].bloodPressureSystolic ?? '0') ?? 0;
        
        if (currentSystolic <= prevSystolic) {
          deteriorating = false;
          break;
        }
      }
      
      if (deteriorating) {
        anomalies.add(DataAnomaly(
          type: 'Pattern',
          description: 'Deteriorating blood pressure trend',
          severity: AnomalySeverity.high,
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return anomalies;
  }

  List<MedicalEntity> _extractMedicalEntities(String text) {
    final entities = <MedicalEntity>[];
    
    // Simple pattern matching for demo
    // In production, would use NER models
    
    // Extract medications
    final medicationPattern = RegExp(r'\b(aspirin|ibuprofen|metformin|lisinopril|atorvastatin)\b', caseSensitive: false);
    final medicationMatches = medicationPattern.allMatches(text);
    for (final match in medicationMatches) {
      entities.add(MedicalEntity(
        type: 'Medication',
        value: match.group(0)!,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    // Extract symptoms
    final symptomPattern = RegExp(r'\b(pain|fever|cough|headache|nausea|fatigue)\b', caseSensitive: false);
    final symptomMatches = symptomPattern.allMatches(text);
    for (final match in symptomMatches) {
      entities.add(MedicalEntity(
        type: 'Symptom',
        value: match.group(0)!,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    // Extract diagnoses
    final diagnosisPattern = RegExp(r'\b(diabetes|hypertension|pneumonia|covid|flu)\b', caseSensitive: false);
    final diagnosisMatches = diagnosisPattern.allMatches(text);
    for (final match in diagnosisMatches) {
      entities.add(MedicalEntity(
        type: 'Diagnosis',
        value: match.group(0)!,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    return entities;
  }

  String _analyzeSentiment(String text) {
    // Simple sentiment analysis
    final positiveWords = ['improved', 'better', 'stable', 'good', 'excellent'];
    final negativeWords = ['worse', 'deteriorating', 'concerning', 'critical', 'severe'];
    
    var positiveCount = 0;
    var negativeCount = 0;
    
    for (final word in positiveWords) {
      if (text.toLowerCase().contains(word)) positiveCount++;
    }
    
    for (final word in negativeWords) {
      if (text.toLowerCase().contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) return 'Positive';
    if (negativeCount > positiveCount) return 'Negative';
    return 'Neutral';
  }

  List<String> _extractKeyFindings(String text) {
    final findings = <String>[];
    
    // Extract sentences with medical significance
    final sentences = text.split(RegExp(r'[.!?]'));
    for (final sentence in sentences) {
      if (sentence.contains(RegExp(r'diagnosed|found|revealed|showed|indicates', caseSensitive: false))) {
        findings.add(sentence.trim());
      }
    }
    
    return findings.take(5).toList(); // Limit to top 5 findings
  }

  List<String> _extractActionItems(String text) {
    final actionItems = <String>[];
    
    // Look for action words
    final actionPattern = RegExp(r'(should|must|need to|recommend|schedule|follow up)', caseSensitive: false);
    final sentences = text.split(RegExp(r'[.!?]'));
    
    for (final sentence in sentences) {
      if (actionPattern.hasMatch(sentence)) {
        actionItems.add(sentence.trim());
      }
    }
    
    return actionItems;
  }

  String _generateNoteSummary(
    String text,
    List<MedicalEntity> entities,
    List<String> keyFindings,
  ) {
    final medications = entities.where((e) => e.type == 'Medication').map((e) => e.value).toSet();
    final symptoms = entities.where((e) => e.type == 'Symptom').map((e) => e.value).toSet();
    final diagnoses = entities.where((e) => e.type == 'Diagnosis').map((e) => e.value).toSet();
    
    var summary = '';
    
    if (symptoms.isNotEmpty) {
      summary += 'Symptoms: ${symptoms.join(", ")}. ';
    }
    
    if (diagnoses.isNotEmpty) {
      summary += 'Diagnoses: ${diagnoses.join(", ")}. ';
    }
    
    if (medications.isNotEmpty) {
      summary += 'Medications: ${medications.join(", ")}. ';
    }
    
    if (keyFindings.isNotEmpty) {
      summary += 'Key finding: ${keyFindings.first}';
    }
    
    return summary.isEmpty ? 'Medical note processed.' : summary;
  }

  double _calculateNLPConfidence(List<MedicalEntity> entities) {
    // Base confidence on entity extraction
    if (entities.isEmpty) return 0.5;
    if (entities.length < 3) return 0.6;
    if (entities.length < 5) return 0.7;
    if (entities.length < 10) return 0.8;
    return 0.9;
  }

  String _generateCacheKey(Map<String, dynamic> params) {
    final json = jsonEncode(params);
    final bytes = utf8.encode(json);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void dispose() {
    _learningTimer?.cancel();
    super.dispose();
  }
}

// Data Models for AI Service

class DiagnosticPrediction {
  final String id;
  final List<PossibleCondition> conditions;
  final double confidence;
  final Map<String, String> explanations;
  final List<String> recommendedTests;
  final String urgencyLevel;
  final DateTime timestamp;

  DiagnosticPrediction({
    required this.id,
    required this.conditions,
    required this.confidence,
    required this.explanations,
    required this.recommendedTests,
    required this.urgencyLevel,
    required this.timestamp,
  });
}

class PossibleCondition {
  final String name;
  final String icd10Code;
  final double probability;
  final String severity;

  PossibleCondition({
    required this.name,
    required this.icd10Code,
    required this.probability,
    required this.severity,
  });
}

class SpecialistRecommendation {
  final Specialist specialist;
  final double matchScore;
  final List<String> reasons;
  final Duration estimatedWaitTime;
  final double successRate;

  SpecialistRecommendation({
    required this.specialist,
    required this.matchScore,
    required this.reasons,
    required this.estimatedWaitTime,
    required this.successRate,
  });
}

class SpecialistScore {
  final double totalScore;
  final List<String> reasons;

  SpecialistScore({
    required this.totalScore,
    required this.reasons,
  });
}

class RiskAssessment {
  final String id;
  final String patientId;
  final double overallRisk;
  final double cardiovascularRisk;
  final double diabetesRisk;
  final double readmissionRisk;
  final double medicationRisk;
  final double fallRisk;
  final List<String> recommendations;
  final DateTime nextAssessmentDate;
  final DateTime timestamp;

  RiskAssessment({
    required this.id,
    required this.patientId,
    required this.overallRisk,
    required this.cardiovascularRisk,
    required this.diabetesRisk,
    required this.readmissionRisk,
    required this.medicationRisk,
    required this.fallRisk,
    required this.recommendations,
    required this.nextAssessmentDate,
    required this.timestamp,
  });
}

class TreatmentPrediction {
  final String id;
  final String treatmentPlan;
  final double successProbability;
  final Duration expectedDuration;
  final List<String> possibleComplications;
  final List<String> alternativeTreatments;
  final double confidence;
  final DateTime timestamp;

  TreatmentPrediction({
    required this.id,
    required this.treatmentPlan,
    required this.successProbability,
    required this.expectedDuration,
    required this.possibleComplications,
    required this.alternativeTreatments,
    required this.confidence,
    required this.timestamp,
  });
}

class DataAnomaly {
  final String type;
  final String description;
  final AnomalySeverity severity;
  final DateTime timestamp;

  DataAnomaly({
    required this.type,
    required this.description,
    required this.severity,
    required this.timestamp,
  });
}

enum AnomalySeverity {
  low,
  medium,
  high,
  critical
}

class MedicalNoteAnalysis {
  final List<MedicalEntity> entities;
  final String sentiment;
  final List<String> keyFindings;
  final List<String> actionItems;
  final String summary;
  final double confidence;

  MedicalNoteAnalysis({
    required this.entities,
    required this.sentiment,
    required this.keyFindings,
    required this.actionItems,
    required this.summary,
    required this.confidence,
  });
}

class MedicalEntity {
  final String type;
  final String value;
  final int startIndex;
  final int endIndex;

  MedicalEntity({
    required this.type,
    required this.value,
    required this.startIndex,
    required this.endIndex,
  });
}

class PredictionAccuracy {
  final String predictionId;
  final Map<String, dynamic> features;
  final DiagnosticPrediction prediction;
  final DateTime timestamp;
  double? actualAccuracy;
  String? feedback;

  PredictionAccuracy({
    required this.predictionId,
    required this.features,
    required this.prediction,
    required this.timestamp,
    this.actualAccuracy,
    this.feedback,
  });
}

class LabResult {
  final String id;
  final String testName;
  final String? value;
  final String? unit;
  final String? normalRange;
  final bool isCritical;
  final DateTime performedAt;

  LabResult({
    required this.id,
    required this.testName,
    this.value,
    this.unit,
    this.normalRange,
    required this.isCritical,
    required this.performedAt,
  });
}

class AIException implements Exception {
  final String message;
  AIException(this.message);
  
  @override
  String toString() => 'AIException: $message';
}