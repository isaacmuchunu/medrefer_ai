import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../database/services/data_service.dart';
import '../core/result.dart';
import 'ai_service.dart';
import 'blockchain_medical_records_service.dart';
import 'notification_service.dart';
import 'logging_service.dart';

enum ImageType {
  xray,
  ct,
  mri,
  ultrasound,
  mammography,
  dermatology,
  ophthalmology,
  pathology,
  endoscopy,
  ecg,
}

enum AnalysisStatus {
  pending,
  processing,
  completed,
  failed,
  reviewed,
}

enum FindingSeverity {
  normal,
  benign,
  suspicious,
  malignant,
  critical,
}

class MedicalImageFinding {
  final String id;
  final String description;
  final FindingSeverity severity;
  final double confidence;
  final Map<String, double> boundingBox; // x, y, width, height (normalized 0-1)
  final List<String> recommendations;
  final String? icd10Code;
  final Map<String, dynamic> metadata;

  MedicalImageFinding({
    required this.id,
    required this.description,
    required this.severity,
    required this.confidence,
    required this.boundingBox,
    required this.recommendations,
    this.icd10Code,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'severity': severity.name,
      'confidence': confidence,
      'boundingBox': boundingBox,
      'recommendations': recommendations,
      'icd10Code': icd10Code,
      'metadata': metadata,
    };
  }

  factory MedicalImageFinding.fromMap(Map<String, dynamic> map) {
    return MedicalImageFinding(
      id: map['id'],
      description: map['description'],
      severity: FindingSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => FindingSeverity.normal,
      ),
      confidence: map['confidence']?.toDouble() ?? 0.0,
      boundingBox: Map<String, double>.from(map['boundingBox'] ?? {}),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      icd10Code: map['icd10Code'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class MedicalImageAnalysis {
  final String id;
  final String imageId;
  final String patientId;
  final ImageType imageType;
  final AnalysisStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? analyzedBy;
  final double? overallConfidence;
  final List<MedicalImageFinding> findings;
  final String? diagnosis;
  final String? summary;
  final Map<String, dynamic> technicalDetails;
  final String? radiologistReview;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final Map<String, dynamic> metadata;

  MedicalImageAnalysis({
    required this.id,
    required this.imageId,
    required this.patientId,
    required this.imageType,
    this.status = AnalysisStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.analyzedBy,
    this.overallConfidence,
    this.findings = const [],
    this.diagnosis,
    this.summary,
    this.technicalDetails = const {},
    this.radiologistReview,
    this.reviewedAt,
    this.reviewedBy,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageId': imageId,
      'patientId': patientId,
      'imageType': imageType.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'analyzedBy': analyzedBy,
      'overallConfidence': overallConfidence,
      'findings': findings.map((f) => f.toMap()).toList(),
      'diagnosis': diagnosis,
      'summary': summary,
      'technicalDetails': technicalDetails,
      'radiologistReview': radiologistReview,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'metadata': metadata,
    };
  }

  factory MedicalImageAnalysis.fromMap(Map<String, dynamic> map) {
    return MedicalImageAnalysis(
      id: map['id'],
      imageId: map['imageId'],
      patientId: map['patientId'],
      imageType: ImageType.values.firstWhere(
        (e) => e.name == map['imageType'],
        orElse: () => ImageType.xray,
      ),
      status: AnalysisStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AnalysisStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      analyzedBy: map['analyzedBy'],
      overallConfidence: map['overallConfidence']?.toDouble(),
      findings: (map['findings'] as List?)
          ?.map((f) => MedicalImageFinding.fromMap(f))
          .toList() ?? [],
      diagnosis: map['diagnosis'],
      summary: map['summary'],
      technicalDetails: Map<String, dynamic>.from(map['technicalDetails'] ?? {}),
      radiologistReview: map['radiologistReview'],
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
      reviewedBy: map['reviewedBy'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  bool get requiresUrgentReview {
    return findings.any((f) => f.severity == FindingSeverity.critical ||
                             f.severity == FindingSeverity.malignant);
  }

  bool get hasCriticalFindings {
    return findings.any((f) => f.severity == FindingSeverity.critical);
  }
}

class MedicalImageAnalysisService {
  MedicalImageAnalysisService._internal();

  final DataService _dataService = DataService();
  final AIService _aiService = AIService();
  final BlockchainMedicalRecordsService _blockchainService = BlockchainMedicalRecordsService();
  final NotificationService _notificationService = NotificationService();
  final LoggingService _loggingService = LoggingService();

  final Map<String, MedicalImageAnalysis> _activeAnalyses = {};
  final StreamController<MedicalImageAnalysis> _analysisController = StreamController.broadcast();
  
  bool _isInitialized = false;
  Timer? _processingTimer;

  Stream<MedicalImageAnalysis> get analysisStream => _analysisController.stream;

  static MedicalImageAnalysisService? _instance;
  static MedicalImageAnalysisService get instance => _instance ??= MedicalImageAnalysisService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeServices();
      await _loadActiveAnalyses();
      _startProcessingEngine();
      
      _isInitialized = true;
      _loggingService.info('MedicalImageAnalysisService initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize MedicalImageAnalysisService', error: e);
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    await _aiService.initialize();
    await _blockchainService.initialize();
    await _notificationService.initialize();
  }

  Future<void> _loadActiveAnalyses() async {
    try {
      final result = await _dataService.query(
        'medical_image_analyses',
        where: 'status NOT IN (?, ?)',
        whereArgs: ['completed', 'failed'],
      );
      
      if (result.isSuccess) {
        for (final analysisMap in result.data) {
          final analysis = MedicalImageAnalysis.fromMap(analysisMap);
          _activeAnalyses[analysis.id] = analysis;
        }
      }
    } catch (e) {
      _loggingService.error('Failed to load active analyses', error: e);
    }
  }

  void _startProcessingEngine() {
    _processingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processPendingAnalyses();
    });
  }

  /// Analyze a medical image
  Future<Result<MedicalImageAnalysis>> analyzeImage({
    required String imageId,
    required String imagePath,
    required String patientId,
    required ImageType imageType,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final analysisId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final analysis = MedicalImageAnalysis(
        id: analysisId,
        imageId: imageId,
        patientId: patientId,
        imageType: imageType,
        status: AnalysisStatus.pending,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Store in database
      await _dataService.insert('medical_image_analyses', analysis.toMap());
      
      // Add to active analyses
      _activeAnalyses[analysisId] = analysis;

      // Start analysis
      await _performAnalysis(analysisId, imagePath);

      _loggingService.info(
        'Medical image analysis started',
        context: 'MedicalImageAnalysisService',
        metadata: {
          'analysisId': analysisId,
          'imageType': imageType.name,
          'patientId': patientId,
        },
      );

      return Result.success(analysis);
    } catch (e) {
      _loggingService.error('Error starting image analysis', error: e);
      return Result.error('Failed to start image analysis: ${e.toString()}');
    }
  }

  Future<void> _performAnalysis(String analysisId, String imagePath) async {
    try {
      final analysis = _activeAnalyses[analysisId];
      if (analysis == null) return;

      // Update status to processing
      await _updateAnalysisStatus(analysisId, AnalysisStatus.processing);

      // Load and preprocess image
      final imageData = await _loadAndPreprocessImage(imagePath, analysis.imageType);
      
      // Perform AI analysis based on image type
      final analysisResult = await _performAIAnalysis(
        imageData,
        analysis.imageType,
        analysis.patientId,
      );

      // Process findings
      final findings = await _processFindings(analysisResult, analysis.imageType);
      
      // Generate diagnosis and summary
      final diagnosis = await _generateDiagnosis(findings, analysis.imageType);
      final summary = await _generateSummary(findings, diagnosis);
      
      // Update analysis with results
      final completedAnalysis = MedicalImageAnalysis(
        id: analysis.id,
        imageId: analysis.imageId,
        patientId: analysis.patientId,
        imageType: analysis.imageType,
        status: AnalysisStatus.completed,
        createdAt: analysis.createdAt,
        completedAt: DateTime.now(),
        analyzedBy: 'AI System',
        overallConfidence: _calculateOverallConfidence(findings),
        findings: findings,
        diagnosis: diagnosis,
        summary: summary,
        technicalDetails: analysisResult['technical_details'] ?? {},
        metadata: analysis.metadata,
      );

      // Update in database
      await _dataService.update('medical_image_analyses', completedAnalysis.toMap(), analysisId);
      
      // Update in memory
      _activeAnalyses[analysisId] = completedAnalysis;

      // Store in blockchain for immutable record
      await _blockchainService.storeMedicalImageAnalysis(
        analysis.patientId,
        completedAnalysis.toMap(),
      );

      // Check for critical findings and send alerts
      if (completedAnalysis.hasCriticalFindings) {
        await _sendCriticalFindingAlert(completedAnalysis);
      }

      // Emit analysis update
      _analysisController.add(completedAnalysis);

      _loggingService.info(
        'Medical image analysis completed',
        context: 'MedicalImageAnalysisService',
        metadata: {
          'analysisId': analysisId,
          'findingsCount': findings.length,
          'hasCriticalFindings': completedAnalysis.hasCriticalFindings,
        },
      );

    } catch (e) {
      _loggingService.error('Error performing image analysis', error: e);
      await _updateAnalysisStatus(analysisId, AnalysisStatus.failed);
    }
  }

  Future<Uint8List> _loadAndPreprocessImage(String imagePath, ImageType imageType) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    var imageData = await file.readAsBytes();
    
    // Preprocess based on image type
    switch (imageType) {
      case ImageType.xray:
        imageData = await _preprocessXRay(imageData);
        break;
      case ImageType.ct:
        imageData = await _preprocessCT(imageData);
        break;
      case ImageType.mri:
        imageData = await _preprocessMRI(imageData);
        break;
      case ImageType.ultrasound:
        imageData = await _preprocessUltrasound(imageData);
        break;
      case ImageType.dermatology:
        imageData = await _preprocessDermatology(imageData);
        break;
      default:
        // Generic preprocessing
        imageData = await _preprocessGeneric(imageData);
        break;
    }
    
    return imageData;
  }

  Future<Uint8List> _preprocessXRay(Uint8List imageData) async {
    // X-ray specific preprocessing
    // - Contrast enhancement
    // - Noise reduction
    // - Bone structure enhancement
    return imageData; // Placeholder
  }

  Future<Uint8List> _preprocessCT(Uint8List imageData) async {
    // CT scan specific preprocessing
    // - Windowing adjustment
    // - Artifact reduction
    // - 3D reconstruction preparation
    return imageData; // Placeholder
  }

  Future<Uint8List> _preprocessMRI(Uint8List imageData) async {
    // MRI specific preprocessing
    // - Bias field correction
    // - Motion correction
    // - Tissue contrast enhancement
    return imageData; // Placeholder
  }

  Future<Uint8List> _preprocessUltrasound(Uint8List imageData) async {
    // Ultrasound specific preprocessing
    // - Speckle noise reduction
    // - Edge enhancement
    // - Doppler processing
    return imageData; // Placeholder
  }

  Future<Uint8List> _preprocessDermatology(Uint8List imageData) async {
    // Dermatology specific preprocessing
    // - Color normalization
    // - Hair removal
    // - Lesion enhancement
    return imageData; // Placeholder
  }

  Future<Uint8List> _preprocessGeneric(Uint8List imageData) async {
    // Generic image preprocessing
    // - Noise reduction
    // - Contrast adjustment
    // - Normalization
    return imageData; // Placeholder
  }

  Future<Map<String, dynamic>> _performAIAnalysis(
    Uint8List imageData,
    ImageType imageType,
    String patientId,
  ) async {
    // Use AI service to analyze the image
    switch (imageType) {
      case ImageType.xray:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.ct:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.mri:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.ultrasound:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.mammography:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.dermatology:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.ophthalmology:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.pathology:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.endoscopy:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      case ImageType.ecg:
        return await _aiService.analyzeMedicalImage(imageData, patientId);
      default:
        return await _aiService.analyzeGenericMedicalImage(imageData, patientId);
    }
  }

  Future<List<MedicalImageFinding>> _processFindings(
    Map<String, dynamic> analysisResult,
    ImageType imageType,
  ) async {
    final findings = <MedicalImageFinding>[];
    final detections = analysisResult['detections'] as List? ?? [];
    
    for (var i = 0; i < detections.length; i++) {
      final detection = detections[i] as Map<String, dynamic>;
      
      final finding = MedicalImageFinding(
        id: 'finding_${DateTime.now().millisecondsSinceEpoch}_$i',
        description: detection['description'] ?? 'Unknown finding',
        severity: _mapToFindingSeverity(detection['severity']),
        confidence: (detection['confidence'] ?? 0.0).toDouble(),
        boundingBox: Map<String, double>.from(detection['bounding_box'] ?? {}),
        recommendations: List<String>.from(detection['recommendations'] ?? []),
        icd10Code: detection['icd10_code'],
        metadata: Map<String, dynamic>.from(detection['metadata'] ?? {}),
      );
      
      findings.add(finding);
    }
    
    return findings;
  }

  FindingSeverity _mapToFindingSeverity(dynamic severity) {
    if (severity is String) {
      switch (severity.toLowerCase()) {
        case 'normal':
          return FindingSeverity.normal;
        case 'benign':
          return FindingSeverity.benign;
        case 'suspicious':
          return FindingSeverity.suspicious;
        case 'malignant':
          return FindingSeverity.malignant;
        case 'critical':
          return FindingSeverity.critical;
        default:
          return FindingSeverity.normal;
      }
    }
    return FindingSeverity.normal;
  }

  Future<String> _generateDiagnosis(
    List<MedicalImageFinding> findings,
    ImageType imageType,
  ) async {
    if (findings.isEmpty) {
      return 'No significant findings detected';
    }

    // Use AI to generate a comprehensive diagnosis
    return await _aiService.generateMedicalImageDiagnosis(findings, imageType);
  }

  Future<String> _generateSummary(
    List<MedicalImageFinding> findings,
    String diagnosis,
  ) async {
    // Generate a summary of the analysis
    return await _aiService.generateMedicalImageSummary(findings, diagnosis);
  }

  double _calculateOverallConfidence(List<MedicalImageFinding> findings) {
    if (findings.isEmpty) return 1.0;
    
    final totalConfidence = findings
        .map((f) => f.confidence)
        .reduce((a, b) => a + b);
    
    return totalConfidence / findings.length;
  }

  Future<void> _sendCriticalFindingAlert(MedicalImageAnalysis analysis) async {
    final criticalFindings = analysis.findings
        .where((f) => f.severity == FindingSeverity.critical)
        .toList();

    for (final finding in criticalFindings) {
      await _notificationService.sendCriticalFindingAlert(
        title: 'Critical Medical Image Finding',
        message: 'Critical finding detected in ${analysis.imageType.name} for patient ${analysis.patientId}: ${finding.description}',
        patientId: analysis.patientId,
        priority: 'critical',
        metadata: {
          'type': 'medical_image_critical_finding',
          'analysisId': analysis.id,
          'findingId': finding.id,
          'imageType': analysis.imageType.name,
        },
      );
    }
  }

  Future<void> _updateAnalysisStatus(String analysisId, AnalysisStatus status) async {
    final analysis = _activeAnalyses[analysisId];
    if (analysis == null) return;

    final updatedAnalysis = MedicalImageAnalysis(
      id: analysis.id,
      imageId: analysis.imageId,
      patientId: analysis.patientId,
      imageType: analysis.imageType,
      status: status,
      createdAt: analysis.createdAt,
      completedAt: status == AnalysisStatus.completed ? DateTime.now() : analysis.completedAt,
      analyzedBy: analysis.analyzedBy,
      overallConfidence: analysis.overallConfidence,
      findings: analysis.findings,
      diagnosis: analysis.diagnosis,
      summary: analysis.summary,
      technicalDetails: analysis.technicalDetails,
      radiologistReview: analysis.radiologistReview,
      reviewedAt: analysis.reviewedAt,
      reviewedBy: analysis.reviewedBy,
      metadata: analysis.metadata,
    );

    _activeAnalyses[analysisId] = updatedAnalysis;
    
    await _dataService.update('medical_image_analyses', {
      'status': status.name,
      if (status == AnalysisStatus.completed) 'completedAt': DateTime.now().toIso8601String(),
    }, analysisId);

    _analysisController.add(updatedAnalysis);
  }

  void _processPendingAnalyses() {
    for (final analysis in _activeAnalyses.values) {
      if (analysis.status == AnalysisStatus.pending) {
        // In a real implementation, you would have the image path stored
        // For now, we'll skip automatic processing
        continue;
      }
    }
  }

  /// Get analysis by ID
  Future<Result<MedicalImageAnalysis?>> getAnalysis(String analysisId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final analysis = _activeAnalyses[analysisId];
      if (analysis != null) {
        return Result.success(analysis);
      }
      
      // Try to load from database
      final result = await _dataService.queryById('medical_image_analyses', analysisId);
      if (result != null && result.isSuccess) {
        final analysis = MedicalImageAnalysis.fromMap(result.data);
        return Result.success(analysis);
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to get analysis: ${e.toString()}');
    }
  }

  /// Get analyses for a patient
  Future<Result<List<MedicalImageAnalysis>>> getPatientAnalyses(String patientId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final result = await _dataService.query(
        'medical_image_analyses',
        where: 'patientId = ?',
        whereArgs: [patientId],
        orderBy: 'createdAt DESC',
      );
      
      if (result.isSuccess) {
        final analyses = result.data
            .map((map) => MedicalImageAnalysis.fromMap(map))
            .toList();
        return Result.success(analyses);
      }
      
      return Result.error(result.errorMessage);
    } catch (e) {
      return Result.error('Failed to get patient analyses: ${e.toString()}');
    }
  }

  /// Add radiologist review
  Future<Result<void>> addRadiologistReview({
    required String analysisId,
    required String reviewedBy,
    required String review,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final analysis = _activeAnalyses[analysisId];
      if (analysis == null) {
        return Result.error('Analysis not found');
      }

      final reviewedAnalysis = MedicalImageAnalysis(
        id: analysis.id,
        imageId: analysis.imageId,
        patientId: analysis.patientId,
        imageType: analysis.imageType,
        status: AnalysisStatus.reviewed,
        createdAt: analysis.createdAt,
        completedAt: analysis.completedAt,
        analyzedBy: analysis.analyzedBy,
        overallConfidence: analysis.overallConfidence,
        findings: analysis.findings,
        diagnosis: analysis.diagnosis,
        summary: analysis.summary,
        technicalDetails: analysis.technicalDetails,
        radiologistReview: review,
        reviewedAt: DateTime.now(),
        reviewedBy: reviewedBy,
        metadata: analysis.metadata,
      );

      // Update in database
      await _dataService.update('medical_image_analyses', {
        'status': AnalysisStatus.reviewed.name,
        'radiologistReview': review,
        'reviewedAt': DateTime.now().toIso8601String(),
        'reviewedBy': reviewedBy,
      }, analysisId);

      // Update in memory
      _activeAnalyses[analysisId] = reviewedAnalysis;

      // Store in blockchain
      await _blockchainService.storeMedicalRadiologistReview(
        analysis.patientId,
        analysisId,
        {
          'reviewedBy': reviewedBy,
          'review': review,
          'reviewedAt': DateTime.now().toIso8601String(),
        },
      );

      _analysisController.add(reviewedAnalysis);

      _loggingService.info(
        'Radiologist review added',
        context: 'MedicalImageAnalysisService',
        metadata: {
          'analysisId': analysisId,
          'reviewedBy': reviewedBy,
        },
      );

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to add radiologist review: ${e.toString()}');
    }
  }

  /// Get analysis statistics
  Future<Result<Map<String, dynamic>>> getAnalysisStatistics() async {
    try {
      if (!_isInitialized) await initialize();
      
      final result = await _dataService.query('medical_image_analyses');
      if (result.isError) {
        return Result.error(result.errorMessage);
      }
      
      final analyses = result.data
          .map((map) => MedicalImageAnalysis.fromMap(map))
          .toList();
      
      final stats = <String, dynamic>{};
      
      // Total analyses
      stats['totalAnalyses'] = analyses.length;
      
      // Analyses by status
      final statusCounts = <String, int>{};
      for (final status in AnalysisStatus.values) {
        statusCounts[status.name] = analyses
            .where((a) => a.status == status)
            .length;
      }
      stats['analysesByStatus'] = statusCounts;
      
      // Analyses by image type
      final typeCounts = <String, int>{};
      for (final type in ImageType.values) {
        typeCounts[type.name] = analyses
            .where((a) => a.imageType == type)
            .length;
      }
      stats['analysesByType'] = typeCounts;
      
      // Critical findings
      stats['criticalFindings'] = analyses
          .where((a) => a.hasCriticalFindings)
          .length;
      
      // Pending review
      stats['pendingReview'] = analyses
          .where((a) => a.status == AnalysisStatus.completed && a.reviewedAt == null)
          .length;
      
      // Average confidence
      final completedAnalyses = analyses
          .where((a) => a.status == AnalysisStatus.completed && a.overallConfidence != null)
          .toList();
      
      if (completedAnalyses.isNotEmpty) {
        final totalConfidence = completedAnalyses
            .map((a) => a.overallConfidence!)
            .reduce((a, b) => a + b);
        stats['averageConfidence'] = totalConfidence / completedAnalyses.length;
      } else {
        stats['averageConfidence'] = 0.0;
      }
      
      // Processing time
      final processedAnalyses = analyses
          .where((a) => a.completedAt != null)
          .toList();
      
      if (processedAnalyses.isNotEmpty) {
        final totalTime = processedAnalyses
            .map((a) => a.completedAt!.difference(a.createdAt).inMinutes)
            .reduce((a, b) => a + b);
        stats['averageProcessingTimeMinutes'] = totalTime / processedAnalyses.length;
      } else {
        stats['averageProcessingTimeMinutes'] = 0;
      }
      
      return Result.success(stats);
    } catch (e) {
      return Result.error('Failed to get analysis statistics: ${e.toString()}');
    }
  }

  /// Search analyses
  Future<Result<List<MedicalImageAnalysis>>> searchAnalyses({
    String? patientId,
    ImageType? imageType,
    AnalysisStatus? status,
    FindingSeverity? severity,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      final whereClause = <String>[];
      final whereArgs = <dynamic>[];
      
      if (patientId != null) {
        whereClause.add('patientId = ?');
        whereArgs.add(patientId);
      }
      
      if (imageType != null) {
        whereClause.add('imageType = ?');
        whereArgs.add(imageType.name);
      }
      
      if (status != null) {
        whereClause.add('status = ?');
        whereArgs.add(status.name);
      }
      
      if (fromDate != null) {
        whereClause.add('createdAt >= ?');
        whereArgs.add(fromDate.toIso8601String());
      }
      
      if (toDate != null) {
        whereClause.add('createdAt <= ?');
        whereArgs.add(toDate.toIso8601String());
      }
      
      final result = await _dataService.query(
        'medical_image_analyses',
        where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      
      if (result.isSuccess) {
        var analyses = result.data
            .map((map) => MedicalImageAnalysis.fromMap(map))
            .toList();
        
        // Filter by severity if specified
        if (severity != null) {
          analyses = analyses
              .where((a) => a.findings.any((f) => f.severity == severity))
              .toList();
        }
        
        return Result.success(analyses);
      }
      
      return Result.error(result.errorMessage);
    } catch (e) {
      return Result.error('Failed to search analyses: ${e.toString()}');
    }
  }

  void dispose() {
    _processingTimer?.cancel();
    _analysisController.close();
  }
}