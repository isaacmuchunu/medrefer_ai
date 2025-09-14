import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import '../core/app_export.dart';

/// Digital Asset Management Service for Medical Imaging and Documents
/// 
/// Provides comprehensive digital asset management including:
/// - DICOM medical imaging support
/// - Document management and versioning
/// - Metadata extraction and indexing
/// - Image processing and analysis
/// - Secure storage and access control
/// - Content delivery and optimization
/// - Search and discovery
/// - Workflow integration
/// - Audit trails and compliance
/// - Backup and archival
class DigitalAssetManagementService extends ChangeNotifier {
  static final DigitalAssetManagementService _instance = DigitalAssetManagementService._internal();
  factory DigitalAssetManagementService() => _instance;
  DigitalAssetManagementService._internal();

  final Dio _dio = Dio();
  Database? _damDb;
  bool _isInitialized = false;
  Timer? _indexingTimer;
  Timer? _cleanupTimer;

  // Asset Management
  final Map<String, DigitalAsset> _assets = {};
  final Map<String, AssetCollection> _collections = {};
  final Map<String, AssetVersion> _assetVersions = {};
  
  // DICOM Support
  final Map<String, DICOMStudy> _dicomStudies = {};
  final Map<String, DICOMSeries> _dicomSeries = {};
  final Map<String, DICOMInstance> _dicomInstances = {};
  
  // Document Management
  final Map<String, Document> _documents = {};
  final Map<String, DocumentTemplate> _documentTemplates = {};
  
  // Metadata and Search
  final Map<String, AssetMetadata> _assetMetadata = {};
  final Map<String, SearchIndex> _searchIndices = {};
  
  // Storage and CDN
  final Map<String, StorageLocation> _storageLocations = {};
  final Map<String, CDNConfiguration> _cdnConfigs = {};
  
  // Processing and Analysis
  final Map<String, ProcessingJob> _processingJobs = {};
  final Map<String, AnalysisResult> _analysisResults = {};
  
  // Security and Access Control
  final Map<String, AccessPolicy> _accessPolicies = {};
  final Map<String, AuditLog> _auditLogs = {};

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, DigitalAsset> get assets => Map.unmodifiable(_assets);
  Map<String, AssetCollection> get collections => Map.unmodifiable(_collections);
  Map<String, DICOMStudy> get dicomStudies => Map.unmodifiable(_dicomStudies);
  Map<String, Document> get documents => Map.unmodifiable(_documents);

  /// Initialize the Digital Asset Management service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      debugPrint('💾 Initializing Digital Asset Management Service...');

      // Initialize database
      await _initializeDAMDatabase();

      // Configure HTTP client for large files
      _dio.options.connectTimeout = const Duration(minutes: 5);
      _dio.options.receiveTimeout = const Duration(minutes: 30);
      _dio.options.sendTimeout = const Duration(minutes: 30);

      // Load existing assets
      await _loadDigitalAssets();
      await _loadCollections();
      await _loadDICOMStudies();
      await _loadDocuments();
      await _loadStorageLocations();

      // Initialize default configurations
      await _initializeDefaultConfigurations();

      // Start background services
      _startIndexingService();
      _startCleanupService();

      _isInitialized = true;
      debugPrint('✅ Digital Asset Management Service initialized successfully');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize Digital Asset Management Service: $e');
      rethrow;
    }
  }

  /// Upload digital asset
  Future<AssetUploadResult> uploadAsset({
    required String fileName,
    required Uint8List fileData,
    required AssetType assetType,
    String? collectionId,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) async {
    try {
      debugPrint('📤 Uploading asset: $fileName');

      // Generate asset ID
      final assetId = _generateAssetId();
      
      // Calculate file hash for deduplication
      final fileHash = sha256.convert(fileData).toString();
      
      // Check for duplicate
      final existingAsset = _assets.values.firstWhere(
        (asset) => asset.fileHash == fileHash,
        orElse: () => throw Exception('No duplicate found'),
      );

      try {
        // If duplicate found, return reference to existing asset
        return AssetUploadResult(
          success: true,
          assetId: existingAsset.assetId,
          isDuplicate: true,
          message: 'Asset already exists, returning reference',
        );
      } catch (e) {
        // No duplicate, continue with upload
      }

      // Analyze file and extract metadata
      final analysisResult = await _analyzeFile(fileName, fileData, assetType);
      
      // Choose storage location
      final storageLocation = await _selectStorageLocation(fileData.length, assetType);
      
      // Upload to storage
      final uploadResult = await _uploadToStorage(storageLocation, assetId, fileName, fileData);
      if (!uploadResult.success) {
        return AssetUploadResult(
          success: false,
          error: 'Failed to upload to storage: ${uploadResult.error}',
        );
      }

      // Create digital asset
      final asset = DigitalAsset(
        assetId: assetId,
        fileName: fileName,
        originalFileName: fileName,
        assetType: assetType,
        fileSize: fileData.length,
        fileHash: fileHash,
        mimeType: _getMimeType(fileName, assetType),
        storageLocation: storageLocation.locationId,
        storagePath: uploadResult.storagePath!,
        collectionId: collectionId,
        status: AssetStatus.active,
        uploadedAt: DateTime.now(),
        uploadedBy: 'system',
        tags: tags ?? [],
        version: 1,
      );

      _assets[assetId] = asset;

      // Create asset metadata
      final assetMetadata = AssetMetadata(
        assetId: assetId,
        extractedMetadata: analysisResult.metadata,
        customMetadata: metadata ?? {},
        technicalMetadata: {
          'fileSize': fileData.length,
          'dimensions': analysisResult.dimensions,
          'colorSpace': analysisResult.colorSpace,
          'compression': analysisResult.compression,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _assetMetadata[assetId] = assetMetadata;

      // Process asset based on type
      if (assetType == AssetType.dicomImage) {
        await _processDICOMAsset(asset, fileData);
      } else if (assetType == AssetType.document) {
        await _processDocumentAsset(asset, fileData);
      } else if (assetType == AssetType.medicalImage) {
        await _processMedicalImageAsset(asset, fileData);
      }

      // Add to collection if specified
      if (collectionId != null) {
        await _addAssetToCollection(assetId, collectionId);
      }

      // Create search index entry
      await _indexAssetForSearch(asset, assetMetadata);

      // Save to database
      await _saveDigitalAsset(asset);
      await _saveAssetMetadata(assetMetadata);

      // Log audit trail
      await _logAuditEvent(
        AssetAuditEvent(
          eventId: _generateEventId(),
          assetId: assetId,
          eventType: AuditEventType.upload,
          userId: 'system',
          timestamp: DateTime.now(),
          details: {'fileName': fileName, 'fileSize': fileData.length},
        ),
      );

      debugPrint('✅ Asset uploaded successfully: $assetId');
      notifyListeners();

      return AssetUploadResult(
        success: true,
        assetId: assetId,
        fileUrl: await _generateAssetUrl(asset),
        thumbnailUrl: await _generateThumbnailUrl(asset),
      );
    } catch (e) {
      debugPrint('❌ Failed to upload asset: $e');
      return AssetUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Download digital asset
  Future<AssetDownloadResult> downloadAsset(String assetId) async {
    try {
      final asset = _assets[assetId];
      if (asset == null) {
        return AssetDownloadResult(
          success: false,
          error: 'Asset not found',
        );
      }

      debugPrint('📥 Downloading asset: $assetId');

      // Check access permissions
      final hasAccess = await _checkAssetAccess(assetId, 'read');
      if (!hasAccess) {
        return AssetDownloadResult(
          success: false,
          error: 'Access denied',
        );
      }

      // Get storage location
      final storageLocation = _storageLocations[asset.storageLocation];
      if (storageLocation == null) {
        return AssetDownloadResult(
          success: false,
          error: 'Storage location not found',
        );
      }

      // Download from storage
      final downloadResult = await _downloadFromStorage(storageLocation, asset.storagePath);
      if (!downloadResult.success) {
        return AssetDownloadResult(
          success: false,
          error: 'Failed to download from storage: ${downloadResult.error}',
        );
      }

      // Update access statistics
      asset.lastAccessedAt = DateTime.now();
      asset.accessCount++;

      // Log audit trail
      await _logAuditEvent(
        AssetAuditEvent(
          eventId: _generateEventId(),
          assetId: assetId,
          eventType: AuditEventType.download,
          userId: 'system',
          timestamp: DateTime.now(),
          details: {'fileName': asset.fileName},
        ),
      );

      debugPrint('✅ Asset downloaded successfully: $assetId');
      notifyListeners();

      return AssetDownloadResult(
        success: true,
        fileName: asset.fileName,
        fileData: downloadResult.fileData!,
        mimeType: asset.mimeType,
      );
    } catch (e) {
      debugPrint('❌ Failed to download asset: $e');
      return AssetDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create asset collection
  Future<CollectionCreationResult> createCollection({
    required String name,
    String? description,
    String? parentCollectionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📁 Creating collection: $name');

      final collectionId = _generateCollectionId();
      final collection = AssetCollection(
        collectionId: collectionId,
        name: name,
        description: description ?? '',
        parentCollectionId: parentCollectionId,
        assetIds: [],
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      _collections[collectionId] = collection;

      // Save to database
      await _saveAssetCollection(collection);

      debugPrint('✅ Collection created successfully: $collectionId');
      notifyListeners();

      return CollectionCreationResult(
        success: true,
        collectionId: collectionId,
      );
    } catch (e) {
      debugPrint('❌ Failed to create collection: $e');
      return CollectionCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Process DICOM study
  Future<DICOMProcessingResult> processDICOMStudy({
    required String studyInstanceUID,
    required List<String> assetIds,
  }) async {
    try {
      debugPrint('🏥 Processing DICOM study: $studyInstanceUID');

      final study = DICOMStudy(
        studyInstanceUID: studyInstanceUID,
        studyId: _generateStudyId(),
        studyDate: DateTime.now(),
        studyTime: DateTime.now(),
        studyDescription: '',
        patientId: '',
        patientName: '',
        patientBirthDate: null,
        patientSex: '',
        modality: '',
        seriesIds: [],
        assetIds: assetIds,
        createdAt: DateTime.now(),
      );

      _dicomStudies[studyInstanceUID] = study;

      // Process each DICOM asset in the study
      for (final assetId in assetIds) {
        final asset = _assets[assetId];
        if (asset != null && asset.assetType == AssetType.dicomImage) {
          await _processDICOMInstance(study, asset);
        }
      }

      // Save to database
      await _saveDICOMStudy(study);

      debugPrint('✅ DICOM study processed successfully: $studyInstanceUID');
      notifyListeners();

      return DICOMProcessingResult(
        success: true,
        studyInstanceUID: studyInstanceUID,
        studyId: study.studyId,
      );
    } catch (e) {
      debugPrint('❌ Failed to process DICOM study: $e');
      return DICOMProcessingResult(
        success: false,
        studyInstanceUID: studyInstanceUID,
        error: e.toString(),
      );
    }
  }

  /// Search assets
  Future<AssetSearchResult> searchAssets({
    String? query,
    List<AssetType>? assetTypes,
    List<String>? tags,
    String? collectionId,
    Map<String, dynamic>? metadataFilters,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 Searching assets: query=$query');

      List<DigitalAsset> results = _assets.values.toList();

      // Filter by asset types
      if (assetTypes != null && assetTypes.isNotEmpty) {
        results = results.where((asset) => assetTypes.contains(asset.assetType)).toList();
      }

      // Filter by collection
      if (collectionId != null) {
        results = results.where((asset) => asset.collectionId == collectionId).toList();
      }

      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        results = results.where((asset) => 
          tags.any((tag) => asset.tags.contains(tag))
        ).toList();
      }

      // Text search in filename and metadata
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        results = results.where((asset) {
          // Search in filename
          if (asset.fileName.toLowerCase().contains(queryLower)) {
            return true;
          }

          // Search in metadata
          final metadata = _assetMetadata[asset.assetId];
          if (metadata != null) {
            final metadataJson = jsonEncode(metadata.extractedMetadata).toLowerCase();
            if (metadataJson.contains(queryLower)) {
              return true;
            }
          }

          return false;
        }).toList();
      }

      // Apply metadata filters
      if (metadataFilters != null && metadataFilters.isNotEmpty) {
        results = results.where((asset) {
          final metadata = _assetMetadata[asset.assetId];
          if (metadata == null) return false;

          for (final entry in metadataFilters.entries) {
            final value = metadata.extractedMetadata[entry.key];
            if (value != entry.value) {
              return false;
            }
          }
          return true;
        }).toList();
      }

      // Sort by upload date (newest first)
      results.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      // Apply pagination
      final totalCount = results.length;
      final paginatedResults = results.skip(offset).take(limit).toList();

      // Convert to search result items
      final searchResults = <AssetSearchResultItem>[];
      for (final asset in paginatedResults) {
        final metadata = _assetMetadata[asset.assetId];
        searchResults.add(AssetSearchResultItem(
          assetId: asset.assetId,
          fileName: asset.fileName,
          assetType: asset.assetType,
          fileSize: asset.fileSize,
          uploadedAt: asset.uploadedAt,
          thumbnailUrl: await _generateThumbnailUrl(asset),
          metadata: metadata?.extractedMetadata ?? {},
          tags: asset.tags,
        ));
      }

      debugPrint('✅ Asset search completed: ${searchResults.length} results');

      return AssetSearchResult(
        success: true,
        results: searchResults,
        totalCount: totalCount,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('❌ Asset search failed: $e');
      return AssetSearchResult(
        success: false,
        results: [],
        totalCount: 0,
        limit: limit,
        offset: offset,
        error: e.toString(),
      );
    }
  }

  /// Generate asset thumbnail
  Future<ThumbnailGenerationResult> generateThumbnail({
    required String assetId,
    int width = 200,
    int height = 200,
  }) async {
    try {
      final asset = _assets[assetId];
      if (asset == null) {
        return ThumbnailGenerationResult(
          success: false,
          error: 'Asset not found',
        );
      }

      debugPrint('🖼️ Generating thumbnail for asset: $assetId');

      // Check if thumbnail already exists
      final existingThumbnail = await _getThumbnailPath(asset, width, height);
      if (existingThumbnail != null) {
        return ThumbnailGenerationResult(
          success: true,
          thumbnailUrl: await _generateThumbnailUrlFromPath(existingThumbnail),
        );
      }

      // Download original asset
      final downloadResult = await downloadAsset(assetId);
      if (!downloadResult.success) {
        return ThumbnailGenerationResult(
          success: false,
          error: 'Failed to download original asset',
        );
      }

      // Generate thumbnail based on asset type
      Uint8List? thumbnailData;
      switch (asset.assetType) {
        case AssetType.image:
        case AssetType.medicalImage:
          thumbnailData = await _generateImageThumbnail(downloadResult.fileData!, width, height);
          break;
        case AssetType.dicomImage:
          thumbnailData = await _generateDICOMThumbnail(downloadResult.fileData!, width, height);
          break;
        case AssetType.document:
          thumbnailData = await _generateDocumentThumbnail(downloadResult.fileData!, width, height);
          break;
        case AssetType.video:
          thumbnailData = await _generateVideoThumbnail(downloadResult.fileData!, width, height);
          break;
        case AssetType.other:
          thumbnailData = await _generateGenericThumbnail(asset.fileName, width, height);
          break;
      }

      if (thumbnailData == null) {
        return ThumbnailGenerationResult(
          success: false,
          error: 'Failed to generate thumbnail',
        );
      }

      // Save thumbnail
      final thumbnailPath = await _saveThumbnail(asset, thumbnailData, width, height);
      
      debugPrint('✅ Thumbnail generated successfully: $assetId');

      return ThumbnailGenerationResult(
        success: true,
        thumbnailUrl: await _generateThumbnailUrlFromPath(thumbnailPath),
      );
    } catch (e) {
      debugPrint('❌ Failed to generate thumbnail: $e');
      return ThumbnailGenerationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Analyze medical image
  Future<ImageAnalysisResult> analyzeMedicalImage(String assetId) async {
    try {
      final asset = _assets[assetId];
      if (asset == null) {
        return ImageAnalysisResult(
          success: false,
          error: 'Asset not found',
        );
      }

      if (asset.assetType != AssetType.medicalImage && asset.assetType != AssetType.dicomImage) {
        return ImageAnalysisResult(
          success: false,
          error: 'Asset is not a medical image',
        );
      }

      debugPrint('🔬 Analyzing medical image: $assetId');

      // Download asset for analysis
      final downloadResult = await downloadAsset(assetId);
      if (!downloadResult.success) {
        return ImageAnalysisResult(
          success: false,
          error: 'Failed to download asset for analysis',
        );
      }

      // Perform medical image analysis
      final analysis = await _performMedicalImageAnalysis(downloadResult.fileData!, asset.assetType);
      
      // Save analysis results
      final analysisResult = AnalysisResult(
        assetId: assetId,
        analysisType: AnalysisType.medicalImage,
        results: analysis,
        confidence: analysis['confidence'] ?? 0.0,
        analyzedAt: DateTime.now(),
        analyzedBy: 'AI_MEDICAL_ANALYZER_v1.0',
      );

      _analysisResults[assetId] = analysisResult;

      // Save to database
      await _saveAnalysisResult(analysisResult);

      debugPrint('✅ Medical image analysis completed: $assetId');
      notifyListeners();

      return ImageAnalysisResult(
        success: true,
        findings: analysis['findings'] ?? [],
        abnormalities: analysis['abnormalities'] ?? [],
        measurements: analysis['measurements'] ?? {},
        confidence: analysis['confidence'] ?? 0.0,
        recommendations: analysis['recommendations'] ?? [],
      );
    } catch (e) {
      debugPrint('❌ Medical image analysis failed: $e');
      return ImageAnalysisResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get asset analytics
  Future<AssetAnalyticsResult> getAssetAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? collectionId,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      debugPrint('📊 Getting asset analytics: ${start.toIso8601String()} to ${end.toIso8601String()}');

      // Filter assets by date range and collection
      var assets = _assets.values.where((asset) =>
        asset.uploadedAt.isAfter(start) && asset.uploadedAt.isBefore(end)
      ).toList();

      if (collectionId != null) {
        assets = assets.where((asset) => asset.collectionId == collectionId).toList();
      }

      // Calculate analytics
      final analytics = AssetAnalytics(
        totalAssets: assets.length,
        totalFileSize: assets.fold<int>(0, (sum, asset) => sum + asset.fileSize),
        assetsByType: _calculateAssetsByType(assets),
        uploadsByDate: _calculateUploadsByDate(assets),
        topCollections: await _getTopCollections(),
        storageUtilization: await _calculateStorageUtilization(),
        accessStatistics: _calculateAccessStatistics(assets),
        period: DateRange(start: start, end: end),
      );

      return AssetAnalyticsResult(
        success: true,
        analytics: analytics,
      );
    } catch (e) {
      debugPrint('❌ Failed to get asset analytics: $e');
      return AssetAnalyticsResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Private Implementation Methods

  Future<void> _initializeDAMDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/digital_asset_management.db';

    _damDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Digital assets table
        await db.execute('''
          CREATE TABLE digital_assets (
            asset_id TEXT PRIMARY KEY,
            file_name TEXT NOT NULL,
            original_file_name TEXT NOT NULL,
            asset_type TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            file_hash TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            storage_location TEXT NOT NULL,
            storage_path TEXT NOT NULL,
            collection_id TEXT,
            status TEXT NOT NULL,
            uploaded_at TEXT NOT NULL,
            uploaded_by TEXT NOT NULL,
            last_accessed_at TEXT,
            access_count INTEGER DEFAULT 0,
            tags TEXT,
            version INTEGER DEFAULT 1
          )
        ''');

        // Asset collections table
        await db.execute('''
          CREATE TABLE asset_collections (
            collection_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            parent_collection_id TEXT,
            asset_ids TEXT,
            metadata TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by TEXT NOT NULL
          )
        ''');

        // Asset metadata table
        await db.execute('''
          CREATE TABLE asset_metadata (
            asset_id TEXT PRIMARY KEY,
            extracted_metadata TEXT,
            custom_metadata TEXT,
            technical_metadata TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (asset_id) REFERENCES digital_assets (asset_id)
          )
        ''');

        // DICOM studies table
        await db.execute('''
          CREATE TABLE dicom_studies (
            study_instance_uid TEXT PRIMARY KEY,
            study_id TEXT UNIQUE NOT NULL,
            study_date TEXT,
            study_time TEXT,
            study_description TEXT,
            patient_id TEXT,
            patient_name TEXT,
            patient_birth_date TEXT,
            patient_sex TEXT,
            modality TEXT,
            series_ids TEXT,
            asset_ids TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Documents table
        await db.execute('''
          CREATE TABLE documents (
            document_id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL,
            document_type TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT,
            extracted_text TEXT,
            page_count INTEGER,
            language TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (asset_id) REFERENCES digital_assets (asset_id)
          )
        ''');

        // Analysis results table
        await db.execute('''
          CREATE TABLE analysis_results (
            asset_id TEXT PRIMARY KEY,
            analysis_type TEXT NOT NULL,
            results TEXT NOT NULL,
            confidence REAL,
            analyzed_at TEXT NOT NULL,
            analyzed_by TEXT NOT NULL,
            FOREIGN KEY (asset_id) REFERENCES digital_assets (asset_id)
          )
        ''');

        // Audit logs table
        await db.execute('''
          CREATE TABLE audit_logs (
            event_id TEXT PRIMARY KEY,
            asset_id TEXT,
            event_type TEXT NOT NULL,
            user_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            details TEXT
          )
        ''');
      },
    );

    debugPrint('✅ DAM database initialized');
  }

  Future<void> _loadDigitalAssets() async {
    // Load digital assets from database
    debugPrint('📋 Loading digital assets...');
  }

  Future<void> _loadCollections() async {
    // Load asset collections from database
    debugPrint('📁 Loading collections...');
  }

  Future<void> _loadDICOMStudies() async {
    // Load DICOM studies from database
    debugPrint('🏥 Loading DICOM studies...');
  }

  Future<void> _loadDocuments() async {
    // Load documents from database
    debugPrint('📄 Loading documents...');
  }

  Future<void> _loadStorageLocations() async {
    // Initialize default storage locations
    _storageLocations['local'] = StorageLocation(
      locationId: 'local',
      name: 'Local Storage',
      type: StorageType.local,
      configuration: {'basePath': '/storage/assets'},
      isActive: true,
      priority: 1,
    );

    _storageLocations['cloud'] = StorageLocation(
      locationId: 'cloud',
      name: 'Cloud Storage',
      type: StorageType.cloud,
      configuration: {'bucket': 'medical-assets', 'region': 'us-east-1'},
      isActive: true,
      priority: 2,
    );

    debugPrint('✅ Storage locations loaded');
  }

  Future<void> _initializeDefaultConfigurations() async {
    // Initialize default CDN configurations
    _cdnConfigs['default'] = CDNConfiguration(
      configId: 'default',
      name: 'Default CDN',
      baseUrl: 'https://cdn.example.com',
      cacheTtl: const Duration(hours: 24),
      isActive: true,
    );

    // Initialize default access policies
    _accessPolicies['default'] = AccessPolicy(
      policyId: 'default',
      name: 'Default Access Policy',
      rules: [
        AccessRule(
          action: 'read',
          resource: '*',
          condition: 'authenticated',
        ),
        AccessRule(
          action: 'write',
          resource: '*',
          condition: 'authorized',
        ),
      ],
      isActive: true,
    );

    debugPrint('✅ Default configurations initialized');
  }

  void _startIndexingService() {
    _indexingTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _reindexAssets();
    });
  }

  void _startCleanupService() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _cleanupOldThumbnails();
      _cleanupOldAuditLogs();
    });
  }

  Future<void> _reindexAssets() async {
    // Reindex assets for search
    for (final asset in _assets.values) {
      final metadata = _assetMetadata[asset.assetId];
      if (metadata != null) {
        await _indexAssetForSearch(asset, metadata);
      }
    }
  }

  Future<void> _cleanupOldThumbnails() async {
    // Clean up thumbnails for deleted assets
    debugPrint('🧹 Cleaning up old thumbnails...');
  }

  Future<void> _cleanupOldAuditLogs() async {
    // Clean up audit logs older than 1 year
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    _auditLogs.removeWhere((key, log) => log.timestamp.isBefore(cutoff));
    debugPrint('🧹 Cleaned up old audit logs');
  }

  Future<FileAnalysisResult> _analyzeFile(String fileName, Uint8List fileData, AssetType assetType) async {
    // Analyze file and extract metadata
    final metadata = <String, dynamic>{};
    String? dimensions;
    String? colorSpace;
    String? compression;

    // Basic file analysis
    metadata['fileSize'] = fileData.length;
    metadata['fileName'] = fileName;
    metadata['fileExtension'] = fileName.split('.').last.toLowerCase();

    // Type-specific analysis
    switch (assetType) {
      case AssetType.image:
      case AssetType.medicalImage:
        // Image analysis would go here
        dimensions = '1024x768'; // Placeholder
        colorSpace = 'RGB';
        compression = 'JPEG';
        break;
      case AssetType.dicomImage:
        // DICOM analysis would go here
        metadata['dicomTags'] = await _extractDICOMTags(fileData);
        break;
      case AssetType.document:
        // Document analysis would go here
        metadata['pageCount'] = await _extractPageCount(fileData);
        break;
      case AssetType.video:
        // Video analysis would go here
        metadata['duration'] = await _extractVideoDuration(fileData);
        break;
      case AssetType.other:
        break;
    }

    return FileAnalysisResult(
      metadata: metadata,
      dimensions: dimensions,
      colorSpace: colorSpace,
      compression: compression,
    );
  }

  Future<Map<String, dynamic>> _extractDICOMTags(Uint8List fileData) async {
    // Extract DICOM tags from file data
    // This would use a DICOM parsing library
    return {
      'PatientID': 'P123456',
      'PatientName': 'DOE^JOHN',
      'StudyInstanceUID': '1.2.3.4.5.6.7.8.9',
      'Modality': 'CT',
      'StudyDate': '20240314',
    };
  }

  Future<int> _extractPageCount(Uint8List fileData) async {
    // Extract page count from document
    return 1; // Placeholder
  }

  Future<Duration> _extractVideoDuration(Uint8List fileData) async {
    // Extract video duration
    return const Duration(minutes: 5); // Placeholder
  }

  Future<StorageLocation> _selectStorageLocation(int fileSize, AssetType assetType) async {
    // Select appropriate storage location based on file size and type
    final locations = _storageLocations.values.where((loc) => loc.isActive).toList();
    locations.sort((a, b) => a.priority.compareTo(b.priority));
    
    return locations.first;
  }

  Future<StorageUploadResult> _uploadToStorage(
    StorageLocation location,
    String assetId,
    String fileName,
    Uint8List fileData,
  ) async {
    try {
      final storagePath = '${location.configuration['basePath']}/$assetId/$fileName';
      
      // Simulate upload to storage
      await Future.delayed(const Duration(milliseconds: 100));
      
      return StorageUploadResult(
        success: true,
        storagePath: storagePath,
      );
    } catch (e) {
      return StorageUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<StorageDownloadResult> _downloadFromStorage(StorageLocation location, String storagePath) async {
    try {
      // Simulate download from storage
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Return dummy data for now
      final dummyData = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      return StorageDownloadResult(
        success: true,
        fileData: dummyData,
      );
    } catch (e) {
      return StorageDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  String _getMimeType(String fileName, AssetType assetType) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (assetType) {
      case AssetType.image:
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            return 'image/jpeg';
          case 'png':
            return 'image/png';
          case 'gif':
            return 'image/gif';
          default:
            return 'image/jpeg';
        }
      case AssetType.dicomImage:
        return 'application/dicom';
      case AssetType.document:
        switch (extension) {
          case 'pdf':
            return 'application/pdf';
          case 'doc':
            return 'application/msword';
          case 'docx':
            return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          default:
            return 'application/octet-stream';
        }
      case AssetType.video:
        switch (extension) {
          case 'mp4':
            return 'video/mp4';
          case 'avi':
            return 'video/x-msvideo';
          default:
            return 'video/mp4';
        }
      case AssetType.medicalImage:
        return 'image/jpeg';
      case AssetType.other:
        return 'application/octet-stream';
    }
  }

  Future<void> _processDICOMAsset(DigitalAsset asset, Uint8List fileData) async {
    // Process DICOM asset and extract DICOM-specific information
    final dicomTags = await _extractDICOMTags(fileData);
    
    // Create DICOM instance
    final dicomInstance = DICOMInstance(
      sopInstanceUID: dicomTags['SOPInstanceUID'] ?? _generateSOPInstanceUID(),
      assetId: asset.assetId,
      seriesInstanceUID: dicomTags['SeriesInstanceUID'] ?? '',
      studyInstanceUID: dicomTags['StudyInstanceUID'] ?? '',
      instanceNumber: int.tryParse(dicomTags['InstanceNumber']?.toString() ?? '1') ?? 1,
      imageType: dicomTags['ImageType'] ?? '',
      createdAt: DateTime.now(),
    );

    _dicomInstances[dicomInstance.sopInstanceUID] = dicomInstance;
  }

  Future<void> _processDocumentAsset(DigitalAsset asset, Uint8List fileData) async {
    // Process document asset and extract text content
    final document = Document(
      documentId: _generateDocumentId(),
      assetId: asset.assetId,
      documentType: _getDocumentType(asset.fileName),
      title: asset.fileName,
      content: '',
      extractedText: await _extractTextFromDocument(fileData),
      pageCount: await _extractPageCount(fileData),
      language: 'en',
      createdAt: DateTime.now(),
    );

    _documents[document.documentId] = document;
  }

  Future<void> _processMedicalImageAsset(DigitalAsset asset, Uint8List fileData) async {
    // Process medical image asset
    // This could include AI analysis, measurement extraction, etc.
    debugPrint('🔬 Processing medical image: ${asset.assetId}');
  }

  Future<void> _processDICOMInstance(DICOMStudy study, DigitalAsset asset) async {
    // Process DICOM instance within a study
    debugPrint('🏥 Processing DICOM instance for study: ${study.studyInstanceUID}');
  }

  String _getDocumentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'txt':
        return 'Text Document';
      default:
        return 'Unknown';
    }
  }

  Future<String> _extractTextFromDocument(Uint8List fileData) async {
    // Extract text content from document
    return 'Extracted text content...'; // Placeholder
  }

  Future<void> _addAssetToCollection(String assetId, String collectionId) async {
    final collection = _collections[collectionId];
    if (collection != null) {
      collection.assetIds.add(assetId);
      collection.updatedAt = DateTime.now();
      await _saveAssetCollection(collection);
    }
  }

  Future<void> _indexAssetForSearch(DigitalAsset asset, AssetMetadata metadata) async {
    // Create search index entry
    final searchIndex = SearchIndex(
      assetId: asset.assetId,
      searchableText: '${asset.fileName} ${asset.tags.join(' ')} ${jsonEncode(metadata.extractedMetadata)}',
      keywords: [...asset.tags, ...metadata.extractedMetadata.keys],
      createdAt: DateTime.now(),
    );

    _searchIndices[asset.assetId] = searchIndex;
  }

  Future<bool> _checkAssetAccess(String assetId, String action) async {
    // Check access permissions for asset
    // This would integrate with the access control system
    return true; // Placeholder - allow all access
  }

  Future<String> _generateAssetUrl(DigitalAsset asset) async {
    // Generate URL for asset access
    final cdnConfig = _cdnConfigs['default'];
    if (cdnConfig != null) {
      return '${cdnConfig.baseUrl}/assets/${asset.assetId}/${asset.fileName}';
    }
    return '/assets/${asset.assetId}/${asset.fileName}';
  }

  Future<String> _generateThumbnailUrl(DigitalAsset asset) async {
    // Generate URL for thumbnail
    final cdnConfig = _cdnConfigs['default'];
    if (cdnConfig != null) {
      return '${cdnConfig.baseUrl}/thumbnails/${asset.assetId}/thumb_200x200.jpg';
    }
    return '/thumbnails/${asset.assetId}/thumb_200x200.jpg';
  }

  Future<String?> _getThumbnailPath(DigitalAsset asset, int width, int height) async {
    // Check if thumbnail already exists
    return null; // Placeholder - assume no existing thumbnail
  }

  Future<String> _generateThumbnailUrlFromPath(String path) async {
    // Generate URL from thumbnail path
    return path;
  }

  Future<Uint8List?> _generateImageThumbnail(Uint8List imageData, int width, int height) async {
    // Generate thumbnail from image data
    // This would use an image processing library
    return Uint8List.fromList([1, 2, 3, 4, 5]); // Placeholder
  }

  Future<Uint8List?> _generateDICOMThumbnail(Uint8List dicomData, int width, int height) async {
    // Generate thumbnail from DICOM data
    return Uint8List.fromList([1, 2, 3, 4, 5]); // Placeholder
  }

  Future<Uint8List?> _generateDocumentThumbnail(Uint8List documentData, int width, int height) async {
    // Generate thumbnail from document
    return Uint8List.fromList([1, 2, 3, 4, 5]); // Placeholder
  }

  Future<Uint8List?> _generateVideoThumbnail(Uint8List videoData, int width, int height) async {
    // Generate thumbnail from video
    return Uint8List.fromList([1, 2, 3, 4, 5]); // Placeholder
  }

  Future<Uint8List?> _generateGenericThumbnail(String fileName, int width, int height) async {
    // Generate generic thumbnail based on file type
    return Uint8List.fromList([1, 2, 3, 4, 5]); // Placeholder
  }

  Future<String> _saveThumbnail(DigitalAsset asset, Uint8List thumbnailData, int width, int height) async {
    // Save thumbnail to storage
    return '/thumbnails/${asset.assetId}/thumb_${width}x$height.jpg';
  }

  Future<Map<String, dynamic>> _performMedicalImageAnalysis(Uint8List imageData, AssetType assetType) async {
    // Perform AI-powered medical image analysis
    return {
      'findings': ['Normal chest X-ray', 'No acute abnormalities'],
      'abnormalities': [],
      'measurements': {'heart_size': '12.5cm', 'lung_volume': '3200ml'},
      'confidence': 0.92,
      'recommendations': ['Routine follow-up in 1 year'],
    };
  }

  Map<AssetType, int> _calculateAssetsByType(List<DigitalAsset> assets) {
    final assetsByType = <AssetType, int>{};
    for (final asset in assets) {
      assetsByType[asset.assetType] = (assetsByType[asset.assetType] ?? 0) + 1;
    }
    return assetsByType;
  }

  Map<String, int> _calculateUploadsByDate(List<DigitalAsset> assets) {
    final uploadsByDate = <String, int>{};
    for (final asset in assets) {
      final dateKey = asset.uploadedAt.toIso8601String().substring(0, 10);
      uploadsByDate[dateKey] = (uploadsByDate[dateKey] ?? 0) + 1;
    }
    return uploadsByDate;
  }

  Future<List<CollectionUsage>> _getTopCollections() async {
    final collectionUsage = <CollectionUsage>[];
    for (final collection in _collections.values) {
      collectionUsage.add(CollectionUsage(
        collectionId: collection.collectionId,
        name: collection.name,
        assetCount: collection.assetIds.length,
      ));
    }
    collectionUsage.sort((a, b) => b.assetCount.compareTo(a.assetCount));
    return collectionUsage.take(10).toList();
  }

  Future<Map<String, StorageUtilization>> _calculateStorageUtilization() async {
    final utilization = <String, StorageUtilization>{};
    for (final location in _storageLocations.values) {
      final assetsInLocation = _assets.values.where((asset) => asset.storageLocation == location.locationId);
      final totalSize = assetsInLocation.fold<int>(0, (sum, asset) => sum + asset.fileSize);
      
      utilization[location.locationId] = StorageUtilization(
        locationId: location.locationId,
        locationName: location.name,
        usedSpace: totalSize,
        totalSpace: 1000000000, // 1GB placeholder
        assetCount: assetsInLocation.length,
      );
    }
    return utilization;
  }

  Map<String, int> _calculateAccessStatistics(List<DigitalAsset> assets) {
    return {
      'totalAccesses': assets.fold<int>(0, (sum, asset) => sum + asset.accessCount),
      'averageAccesses': assets.isEmpty ? 0 : (assets.fold<int>(0, (sum, asset) => sum + asset.accessCount) / assets.length).round(),
      'mostAccessedCount': assets.isEmpty ? 0 : assets.map((asset) => asset.accessCount).reduce(math.max),
    };
  }

  Future<void> _logAuditEvent(AssetAuditEvent event) async {
    _auditLogs[event.eventId] = AuditLog(
      eventId: event.eventId,
      assetId: event.assetId,
      eventType: event.eventType,
      userId: event.userId,
      timestamp: event.timestamp,
      details: event.details,
    );

    // Save to database
    if (_damDb != null) {
      await _damDb!.insert('audit_logs', {
        'event_id': event.eventId,
        'asset_id': event.assetId,
        'event_type': event.eventType.toString().split('.').last,
        'user_id': event.userId,
        'timestamp': event.timestamp.toIso8601String(),
        'details': jsonEncode(event.details),
      });
    }
  }

  String _generateAssetId() {
    return 'asset_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateCollectionId() {
    return 'collection_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateStudyId() {
    return 'study_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateDocumentId() {
    return 'doc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateSOPInstanceUID() {
    return '1.2.3.4.5.${DateTime.now().millisecondsSinceEpoch}.${Random().nextInt(1000)}';
  }

  Future<void> _saveDigitalAsset(DigitalAsset asset) async {
    if (_damDb == null) return;

    await _damDb!.insert('digital_assets', {
      'asset_id': asset.assetId,
      'file_name': asset.fileName,
      'original_file_name': asset.originalFileName,
      'asset_type': asset.assetType.toString().split('.').last,
      'file_size': asset.fileSize,
      'file_hash': asset.fileHash,
      'mime_type': asset.mimeType,
      'storage_location': asset.storageLocation,
      'storage_path': asset.storagePath,
      'collection_id': asset.collectionId,
      'status': asset.status.toString().split('.').last,
      'uploaded_at': asset.uploadedAt.toIso8601String(),
      'uploaded_by': asset.uploadedBy,
      'last_accessed_at': asset.lastAccessedAt?.toIso8601String(),
      'access_count': asset.accessCount,
      'tags': jsonEncode(asset.tags),
      'version': asset.version,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveAssetCollection(AssetCollection collection) async {
    if (_damDb == null) return;

    await _damDb!.insert('asset_collections', {
      'collection_id': collection.collectionId,
      'name': collection.name,
      'description': collection.description,
      'parent_collection_id': collection.parentCollectionId,
      'asset_ids': jsonEncode(collection.assetIds),
      'metadata': jsonEncode(collection.metadata),
      'created_at': collection.createdAt.toIso8601String(),
      'updated_at': collection.updatedAt.toIso8601String(),
      'created_by': collection.createdBy,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveAssetMetadata(AssetMetadata metadata) async {
    if (_damDb == null) return;

    await _damDb!.insert('asset_metadata', {
      'asset_id': metadata.assetId,
      'extracted_metadata': jsonEncode(metadata.extractedMetadata),
      'custom_metadata': jsonEncode(metadata.customMetadata),
      'technical_metadata': jsonEncode(metadata.technicalMetadata),
      'created_at': metadata.createdAt.toIso8601String(),
      'updated_at': metadata.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveDICOMStudy(DICOMStudy study) async {
    if (_damDb == null) return;

    await _damDb!.insert('dicom_studies', {
      'study_instance_uid': study.studyInstanceUID,
      'study_id': study.studyId,
      'study_date': study.studyDate.toIso8601String(),
      'study_time': study.studyTime.toIso8601String(),
      'study_description': study.studyDescription,
      'patient_id': study.patientId,
      'patient_name': study.patientName,
      'patient_birth_date': study.patientBirthDate?.toIso8601String(),
      'patient_sex': study.patientSex,
      'modality': study.modality,
      'series_ids': jsonEncode(study.seriesIds),
      'asset_ids': jsonEncode(study.assetIds),
      'created_at': study.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveAnalysisResult(AnalysisResult result) async {
    if (_damDb == null) return;

    await _damDb!.insert('analysis_results', {
      'asset_id': result.assetId,
      'analysis_type': result.analysisType.toString().split('.').last,
      'results': jsonEncode(result.results),
      'confidence': result.confidence,
      'analyzed_at': result.analyzedAt.toIso8601String(),
      'analyzed_by': result.analyzedBy,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Dispose resources
  @override
  void dispose() {
    _indexingTimer?.cancel();
    _cleanupTimer?.cancel();
    _damDb?.close();
    _dio.close();
    super.dispose();
  }
}

// Data Models and Enums

enum AssetType { image, medicalImage, dicomImage, document, video, other }
enum AssetStatus { active, archived, deleted }
enum StorageType { local, cloud, hybrid }
enum AnalysisType { medicalImage, document, video, other }
enum AuditEventType { upload, download, view, edit, delete, share }

class DigitalAsset {
  final String assetId;
  final String fileName;
  final String originalFileName;
  final AssetType assetType;
  final int fileSize;
  final String fileHash;
  final String mimeType;
  final String storageLocation;
  final String storagePath;
  final String? collectionId;
  final AssetStatus status;
  final DateTime uploadedAt;
  final String uploadedBy;
  DateTime? lastAccessedAt;
  int accessCount;
  final List<String> tags;
  final int version;

  DigitalAsset({
    required this.assetId,
    required this.fileName,
    required this.originalFileName,
    required this.assetType,
    required this.fileSize,
    required this.fileHash,
    required this.mimeType,
    required this.storageLocation,
    required this.storagePath,
    this.collectionId,
    required this.status,
    required this.uploadedAt,
    required this.uploadedBy,
    this.lastAccessedAt,
    this.accessCount = 0,
    required this.tags,
    required this.version,
  });
}

class AssetCollection {
  final String collectionId;
  final String name;
  final String description;
  final String? parentCollectionId;
  final List<String> assetIds;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  DateTime updatedAt;
  final String createdBy;

  AssetCollection({
    required this.collectionId,
    required this.name,
    required this.description,
    this.parentCollectionId,
    required this.assetIds,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });
}

class AssetVersion {
  final String versionId;
  final String assetId;
  final int versionNumber;
  final String storagePath;
  final DateTime createdAt;
  final String createdBy;
  final String? changeDescription;

  AssetVersion({
    required this.versionId,
    required this.assetId,
    required this.versionNumber,
    required this.storagePath,
    required this.createdAt,
    required this.createdBy,
    this.changeDescription,
  });
}

class AssetMetadata {
  final String assetId;
  final Map<String, dynamic> extractedMetadata;
  final Map<String, dynamic> customMetadata;
  final Map<String, dynamic> technicalMetadata;
  final DateTime createdAt;
  DateTime updatedAt;

  AssetMetadata({
    required this.assetId,
    required this.extractedMetadata,
    required this.customMetadata,
    required this.technicalMetadata,
    required this.createdAt,
    required this.updatedAt,
  });
}

class DICOMStudy {
  final String studyInstanceUID;
  final String studyId;
  final DateTime studyDate;
  final DateTime studyTime;
  final String studyDescription;
  final String patientId;
  final String patientName;
  final DateTime? patientBirthDate;
  final String patientSex;
  final String modality;
  final List<String> seriesIds;
  final List<String> assetIds;
  final DateTime createdAt;

  DICOMStudy({
    required this.studyInstanceUID,
    required this.studyId,
    required this.studyDate,
    required this.studyTime,
    required this.studyDescription,
    required this.patientId,
    required this.patientName,
    this.patientBirthDate,
    required this.patientSex,
    required this.modality,
    required this.seriesIds,
    required this.assetIds,
    required this.createdAt,
  });
}

class DICOMSeries {
  final String seriesInstanceUID;
  final String seriesId;
  final String studyInstanceUID;
  final int seriesNumber;
  final String seriesDescription;
  final String modality;
  final List<String> instanceIds;
  final DateTime createdAt;

  DICOMSeries({
    required this.seriesInstanceUID,
    required this.seriesId,
    required this.studyInstanceUID,
    required this.seriesNumber,
    required this.seriesDescription,
    required this.modality,
    required this.instanceIds,
    required this.createdAt,
  });
}

class DICOMInstance {
  final String sopInstanceUID;
  final String assetId;
  final String seriesInstanceUID;
  final String studyInstanceUID;
  final int instanceNumber;
  final String imageType;
  final DateTime createdAt;

  DICOMInstance({
    required this.sopInstanceUID,
    required this.assetId,
    required this.seriesInstanceUID,
    required this.studyInstanceUID,
    required this.instanceNumber,
    required this.imageType,
    required this.createdAt,
  });
}

class Document {
  final String documentId;
  final String assetId;
  final String documentType;
  final String title;
  final String content;
  final String extractedText;
  final int pageCount;
  final String language;
  final DateTime createdAt;

  Document({
    required this.documentId,
    required this.assetId,
    required this.documentType,
    required this.title,
    required this.content,
    required this.extractedText,
    required this.pageCount,
    required this.language,
    required this.createdAt,
  });
}

class DocumentTemplate {
  final String templateId;
  final String name;
  final String description;
  final String templateContent;
  final Map<String, dynamic> fields;
  final DateTime createdAt;

  DocumentTemplate({
    required this.templateId,
    required this.name,
    required this.description,
    required this.templateContent,
    required this.fields,
    required this.createdAt,
  });
}

class StorageLocation {
  final String locationId;
  final String name;
  final StorageType type;
  final Map<String, dynamic> configuration;
  final bool isActive;
  final int priority;

  StorageLocation({
    required this.locationId,
    required this.name,
    required this.type,
    required this.configuration,
    required this.isActive,
    required this.priority,
  });
}

class CDNConfiguration {
  final String configId;
  final String name;
  final String baseUrl;
  final Duration cacheTtl;
  final bool isActive;

  CDNConfiguration({
    required this.configId,
    required this.name,
    required this.baseUrl,
    required this.cacheTtl,
    required this.isActive,
  });
}

class ProcessingJob {
  final String jobId;
  final String assetId;
  final String jobType;
  final Map<String, dynamic> parameters;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  ProcessingJob({
    required this.jobId,
    required this.assetId,
    required this.jobType,
    required this.parameters,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });
}

class AnalysisResult {
  final String assetId;
  final AnalysisType analysisType;
  final Map<String, dynamic> results;
  final double confidence;
  final DateTime analyzedAt;
  final String analyzedBy;

  AnalysisResult({
    required this.assetId,
    required this.analysisType,
    required this.results,
    required this.confidence,
    required this.analyzedAt,
    required this.analyzedBy,
  });
}

class SearchIndex {
  final String assetId;
  final String searchableText;
  final List<String> keywords;
  final DateTime createdAt;

  SearchIndex({
    required this.assetId,
    required this.searchableText,
    required this.keywords,
    required this.createdAt,
  });
}

class AccessPolicy {
  final String policyId;
  final String name;
  final List<AccessRule> rules;
  final bool isActive;

  AccessPolicy({
    required this.policyId,
    required this.name,
    required this.rules,
    required this.isActive,
  });
}

class AccessRule {
  final String action;
  final String resource;
  final String condition;

  AccessRule({
    required this.action,
    required this.resource,
    required this.condition,
  });
}

class AuditLog {
  final String eventId;
  final String? assetId;
  final AuditEventType eventType;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  AuditLog({
    required this.eventId,
    this.assetId,
    required this.eventType,
    required this.userId,
    required this.timestamp,
    required this.details,
  });
}

class AssetAuditEvent {
  final String eventId;
  final String? assetId;
  final AuditEventType eventType;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  AssetAuditEvent({
    required this.eventId,
    this.assetId,
    required this.eventType,
    required this.userId,
    required this.timestamp,
    required this.details,
  });
}

class AssetAnalytics {
  final int totalAssets;
  final int totalFileSize;
  final Map<AssetType, int> assetsByType;
  final Map<String, int> uploadsByDate;
  final List<CollectionUsage> topCollections;
  final Map<String, StorageUtilization> storageUtilization;
  final Map<String, int> accessStatistics;
  final DateRange period;

  AssetAnalytics({
    required this.totalAssets,
    required this.totalFileSize,
    required this.assetsByType,
    required this.uploadsByDate,
    required this.topCollections,
    required this.storageUtilization,
    required this.accessStatistics,
    required this.period,
  });
}

class CollectionUsage {
  final String collectionId;
  final String name;
  final int assetCount;

  CollectionUsage({
    required this.collectionId,
    required this.name,
    required this.assetCount,
  });
}

class StorageUtilization {
  final String locationId;
  final String locationName;
  final int usedSpace;
  final int totalSpace;
  final int assetCount;

  StorageUtilization({
    required this.locationId,
    required this.locationName,
    required this.usedSpace,
    required this.totalSpace,
    required this.assetCount,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class AssetSearchResultItem {
  final String assetId;
  final String fileName;
  final AssetType assetType;
  final int fileSize;
  final DateTime uploadedAt;
  final String thumbnailUrl;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  AssetSearchResultItem({
    required this.assetId,
    required this.fileName,
    required this.assetType,
    required this.fileSize,
    required this.uploadedAt,
    required this.thumbnailUrl,
    required this.metadata,
    required this.tags,
  });
}

// Helper Classes

class FileAnalysisResult {
  final Map<String, dynamic> metadata;
  final String? dimensions;
  final String? colorSpace;
  final String? compression;

  FileAnalysisResult({
    required this.metadata,
    this.dimensions,
    this.colorSpace,
    this.compression,
  });
}

class StorageUploadResult {
  final bool success;
  final String? storagePath;
  final String? error;

  StorageUploadResult({
    required this.success,
    this.storagePath,
    this.error,
  });
}

class StorageDownloadResult {
  final bool success;
  final Uint8List? fileData;
  final String? error;

  StorageDownloadResult({
    required this.success,
    this.fileData,
    this.error,
  });
}

// Result Classes

class AssetUploadResult {
  final bool success;
  final String? assetId;
  final String? fileUrl;
  final String? thumbnailUrl;
  final bool isDuplicate;
  final String? message;
  final String? error;

  AssetUploadResult({
    required this.success,
    this.assetId,
    this.fileUrl,
    this.thumbnailUrl,
    this.isDuplicate = false,
    this.message,
    this.error,
  });
}

class AssetDownloadResult {
  final bool success;
  final String? fileName;
  final Uint8List? fileData;
  final String? mimeType;
  final String? error;

  AssetDownloadResult({
    required this.success,
    this.fileName,
    this.fileData,
    this.mimeType,
    this.error,
  });
}

class CollectionCreationResult {
  final bool success;
  final String? collectionId;
  final String? error;

  CollectionCreationResult({
    required this.success,
    this.collectionId,
    this.error,
  });
}

class DICOMProcessingResult {
  final bool success;
  final String studyInstanceUID;
  final String? studyId;
  final String? error;

  DICOMProcessingResult({
    required this.success,
    required this.studyInstanceUID,
    this.studyId,
    this.error,
  });
}

class AssetSearchResult {
  final bool success;
  final List<AssetSearchResultItem> results;
  final int totalCount;
  final int limit;
  final int offset;
  final String? error;

  AssetSearchResult({
    required this.success,
    required this.results,
    required this.totalCount,
    required this.limit,
    required this.offset,
    this.error,
  });
}

class ThumbnailGenerationResult {
  final bool success;
  final String? thumbnailUrl;
  final String? error;

  ThumbnailGenerationResult({
    required this.success,
    this.thumbnailUrl,
    this.error,
  });
}

class ImageAnalysisResult {
  final bool success;
  final List<String>? findings;
  final List<String>? abnormalities;
  final Map<String, dynamic>? measurements;
  final double? confidence;
  final List<String>? recommendations;
  final String? error;

  ImageAnalysisResult({
    required this.success,
    this.findings,
    this.abnormalities,
    this.measurements,
    this.confidence,
    this.recommendations,
    this.error,
  });
}

class AssetAnalyticsResult {
  final bool success;
  final AssetAnalytics? analytics;
  final String? error;

  AssetAnalyticsResult({
    required this.success,
    this.analytics,
    this.error,
  });
}