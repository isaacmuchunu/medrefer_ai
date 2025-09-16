import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database.dart';

/// Advanced Offline Sync Queue Service
/// Manages offline operations, conflict resolution, and intelligent retry logic
class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  // Configuration
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 30);
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _batchSize = 50;
  static const int _maxQueueSize = 1000;

  // State management
  final Queue<SyncOperation> _syncQueue = Queue<SyncOperation>();
  final Map<String, SyncOperation> _pendingOperations = {};
  final Map<String, ConflictResolution> _conflictResolutions = {};
  final List<SyncHistory> _syncHistory = [];
  
  // Connectivity and sync state
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isSyncing = false;
  bool _isInitialized = false;
  Timer? _syncTimer;
  Timer? _retryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Performance metrics
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  int _conflictsResolved = 0;
  DateTime? _lastSyncTime;
  
  // Database
  Database? _database;

  // Getters
  bool get isOnline => _connectionStatus != ConnectivityResult.none;
  bool get isSyncing => _isSyncing;
  int get queueSize => _syncQueue.length;
  int get pendingOperations => _pendingOperations.length;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncMetrics get metrics => SyncMetrics(
    successfulSyncs: _successfulSyncs,
    failedSyncs: _failedSyncs,
    conflictsResolved: _conflictsResolved,
    queueSize: _syncQueue.length,
    lastSyncTime: _lastSyncTime,
  );

  /// Initialize the offline sync service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize database
      _database = await DatabaseHelper().database;
      
      // Create sync tables if not exists
      await _createSyncTables();
      
      // Load pending operations from database
      await _loadPendingOperations();
      
      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();
      
      // Start sync timer
      _startSyncTimer();
      
      _isInitialized = true;
      debugPrint('Offline Sync Service initialized');
      
      // Perform initial sync if online
      if (isOnline) {
        await performSync();
      }
    } catch (e) {
      debugPrint('Error initializing Offline Sync Service: $e');
      throw SyncException('Failed to initialize offline sync service');
    }
  }

  /// Create sync-related database tables
  Future<void> _createSyncTables() async {
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        error_message TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS sync_history (
        id TEXT PRIMARY KEY,
        operation_id TEXT NOT NULL,
        status TEXT NOT NULL,
        sync_time INTEGER NOT NULL,
        duration_ms INTEGER,
        error_message TEXT,
        metadata TEXT
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS conflict_resolutions (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_version TEXT NOT NULL,
        remote_version TEXT NOT NULL,
        resolution_strategy TEXT NOT NULL,
        resolved_data TEXT,
        resolved_at INTEGER NOT NULL,
        resolved_by TEXT
      )
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_status 
      ON sync_queue(status)
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_timestamp 
      ON sync_queue(timestamp)
    ''');
  }

  /// Queue an operation for sync
  Future<void> queueOperation(SyncOperation operation) async {
    try {
      // Check queue size limit
      if (_syncQueue.length >= _maxQueueSize) {
        await _compactQueue();
      }
      
      // Add to queue
      _syncQueue.add(operation);
      _pendingOperations[operation.id] = operation;
      
      // Persist to database
      await _persistOperation(operation);
      
      // Notify listeners
      notifyListeners();
      
      // Attempt immediate sync if online
      if (isOnline && !_isSyncing) {
        _attemptImmediateSync();
      }
      
      debugPrint('Operation queued: ${operation.operationType} - ${operation.entityType}');
    } catch (e) {
      debugPrint('Error queuing operation: $e');
      throw SyncException('Failed to queue operation');
    }
  }

  /// Queue multiple operations as a batch
  Future<void> queueBatch(List<SyncOperation> operations) async {
    try {
      await _database!.transaction((txn) async {
        for (final operation in operations) {
          _syncQueue.add(operation);
          _pendingOperations[operation.id] = operation;
          
          await txn.insert('sync_queue', operation.toMap());
        }
      });
      
      notifyListeners();
      
      if (isOnline && !_isSyncing) {
        _attemptImmediateSync();
      }
      
      debugPrint('Batch queued: ${operations.length} operations');
    } catch (e) {
      debugPrint('Error queuing batch: $e');
      throw SyncException('Failed to queue batch operations');
    }
  }

  /// Perform synchronization
  Future<SyncResult> performSync() async {
    if (_isSyncing || !isOnline) {
      return SyncResult(
        success: false,
        message: _isSyncing ? 'Sync already in progress' : 'Device is offline',
      );
    }
    
    _isSyncing = true;
    notifyListeners();
    
    final startTime = DateTime.now();
    var successCount = 0;
    var failureCount = 0;
    final errors = <String>[];
    
    try {
      debugPrint('Starting sync with ${_syncQueue.length} operations');
      
      // Process queue in batches
      while (_syncQueue.isNotEmpty && isOnline) {
        final batch = <SyncOperation>[];
        
        // Create batch
        for (var i = 0; i < _batchSize && _syncQueue.isNotEmpty; i++) {
          batch.add(_syncQueue.removeFirst());
        }
        
        // Process batch
        final batchResult = await _processBatch(batch);
        
        successCount += batchResult.successCount;
        failureCount += batchResult.failureCount;
        errors.addAll(batchResult.errors);
        
        // Handle failed operations
        for (final failed in batchResult.failedOperations) {
          await _handleFailedOperation(failed);
        }
        
        // Handle conflicts
        for (final conflict in batchResult.conflicts) {
          await _handleConflict(conflict);
        }
      }
      
      // Update metrics
      _successfulSyncs += successCount;
      _failedSyncs += failureCount;
      _lastSyncTime = DateTime.now();
      
      // Record sync history
      final duration = DateTime.now().difference(startTime);
      await _recordSyncHistory(
        status: failureCount == 0 ? 'success' : 'partial',
        duration: duration,
        metadata: {
          'successCount': successCount,
          'failureCount': failureCount,
          'errors': errors,
        },
      );
      
      debugPrint('Sync completed: $successCount success, $failureCount failures');
      
      return SyncResult(
        success: failureCount == 0,
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
        duration: duration,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      
      await _recordSyncHistory(
        status: 'error',
        duration: DateTime.now().difference(startTime),
        errorMessage: e.toString(),
      );
      
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Process a batch of operations
  Future<BatchResult> _processBatch(List<SyncOperation> batch) async {
    final result = BatchResult();
    
    for (final operation in batch) {
      try {
        // Check for conflicts before processing
        final hasConflict = await _checkForConflict(operation);
        
        if (hasConflict) {
          final conflict = await _detectConflict(operation);
          result.conflicts.add(conflict);
          continue;
        }
        
        // Process operation based on type
        final success = await _processOperation(operation);
        
        if (success) {
          result.successCount++;
          await _markOperationComplete(operation);
        } else {
          result.failureCount++;
          result.failedOperations.add(operation);
        }
      } catch (e) {
        result.failureCount++;
        result.failedOperations.add(operation);
        result.errors.add('${operation.id}: $e');
        debugPrint('Error processing operation ${operation.id}: $e');
      }
    }
    
    return result;
  }

  /// Process a single operation
  Future<bool> _processOperation(SyncOperation operation) async {
    try {
      switch (operation.operationType) {
        case OperationType.create:
          return await _processCreate(operation);
        case OperationType.update:
          return await _processUpdate(operation);
        case OperationType.delete:
          return await _processDelete(operation);
        case OperationType.custom:
          return await _processCustom(operation);
      }
    } catch (e) {
      debugPrint('Error in _processOperation: $e');
      return false;
    }
  }

  /// Process create operation
  Future<bool> _processCreate(SyncOperation operation) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 100));
    
    // In production, this would make actual API calls
    // based on entity type and data
    
    // Check for duplicate creation
    if (operation.entityId != null) {
      final exists = await _checkEntityExists(
        operation.entityType,
        operation.entityId!,
      );
      
      if (exists) {
        // Convert to update if entity already exists
        operation.operationType = OperationType.update;
        return await _processUpdate(operation);
      }
    }
    
    // Perform creation
    // ... API call logic
    
    return true;
  }

  /// Process update operation
  Future<bool> _processUpdate(SyncOperation operation) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 100));
    
    // In production, implement actual update logic
    // with proper conflict detection and resolution
    
    return true;
  }

  /// Process delete operation
  Future<bool> _processDelete(SyncOperation operation) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 100));
    
    // In production, implement actual delete logic
    // with cascade handling
    
    return true;
  }

  /// Process custom operation
  Future<bool> _processCustom(SyncOperation operation) async {
    // Handle custom operations based on metadata
    final customType = operation.metadata?['customType'];
    
    switch (customType) {
      case 'bulk_update':
        return await _processBulkUpdate(operation);
      case 'merge':
        return await _processMerge(operation);
      default:
        return false;
    }
  }

  /// Check for conflicts
  Future<bool> _checkForConflict(SyncOperation operation) async {
    if (operation.operationType != OperationType.update) {
      return false;
    }
    
    // Check if remote version is different from local version
    final localVersion = operation.metadata?['version'];
    if (localVersion == null) return false;
    
    // Simulate remote version check
    final remoteVersion = await _getRemoteVersion(
      operation.entityType,
      operation.entityId!,
    );
    
    return localVersion != remoteVersion;
  }

  /// Detect conflict details
  Future<SyncConflict> _detectConflict(SyncOperation operation) async {
    final localData = operation.data;
    
    // Fetch remote data
    final remoteData = await _fetchRemoteData(
      operation.entityType,
      operation.entityId!,
    );
    
    // Analyze differences
    final differences = _analyzeDifferences(localData, remoteData);
    
    return SyncConflict(
      id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
      operationId: operation.id,
      entityType: operation.entityType,
      entityId: operation.entityId!,
      localData: localData,
      remoteData: remoteData,
      differences: differences,
      detectedAt: DateTime.now(),
    );
  }

  /// Handle conflict resolution
  Future<void> _handleConflict(SyncConflict conflict) async {
    try {
      // Determine resolution strategy
      final strategy = _determineResolutionStrategy(conflict);
      
      // Apply resolution
      final resolution = await _resolveConflict(conflict, strategy);
      
      // Store resolution
      _conflictResolutions[conflict.id] = resolution;
      await _persistConflictResolution(resolution);
      
      // Update metrics
      _conflictsResolved++;
      
      // Notify about conflict resolution
      notifyListeners();
      
      debugPrint('Conflict resolved: ${conflict.entityType} - ${conflict.entityId}');
    } catch (e) {
      debugPrint('Error handling conflict: $e');
      throw SyncException('Failed to resolve conflict');
    }
  }

  /// Determine conflict resolution strategy
  ConflictStrategy _determineResolutionStrategy(SyncConflict conflict) {
    // Implement intelligent strategy selection based on:
    // - Entity type
    // - Data differences
    // - User preferences
    // - Business rules
    
    final entityType = conflict.entityType;
    
    // Critical medical data - require manual resolution
    if (entityType == 'medication' || entityType == 'diagnosis') {
      return ConflictStrategy.manual;
    }
    
    // Timestamps - use most recent
    if (conflict.differences.length == 1 && 
        conflict.differences.first.field.contains('timestamp')) {
      return ConflictStrategy.remoteWins;
    }
    
    // Non-critical updates - attempt merge
    if (conflict.differences.length <= 3) {
      return ConflictStrategy.merge;
    }
    
    // Default to local wins for user-generated content
    return ConflictStrategy.localWins;
  }

  /// Resolve conflict based on strategy
  Future<ConflictResolution> _resolveConflict(
    SyncConflict conflict,
    ConflictStrategy strategy,
  ) async {
    Map<String, dynamic> resolvedData;
    
    switch (strategy) {
      case ConflictStrategy.localWins:
        resolvedData = conflict.localData;
        break;
      
      case ConflictStrategy.remoteWins:
        resolvedData = conflict.remoteData;
        break;
      
      case ConflictStrategy.merge:
        resolvedData = _mergeData(conflict.localData, conflict.remoteData);
        break;
      
      case ConflictStrategy.manual:
        // Queue for manual resolution
        await _queueManualResolution(conflict);
        resolvedData = conflict.localData; // Keep local until manual resolution
        break;
      
      case ConflictStrategy.custom:
        resolvedData = await _customResolution(conflict);
        break;
    }
    
    return ConflictResolution(
      id: 'resolution_${DateTime.now().millisecondsSinceEpoch}',
      conflictId: conflict.id,
      strategy: strategy,
      resolvedData: resolvedData,
      resolvedAt: DateTime.now(),
    );
  }

  /// Merge data intelligently
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(remote);
    
    // Apply intelligent merging rules
    for (final key in local.keys) {
      if (!remote.containsKey(key)) {
        // Add local-only fields
        merged[key] = local[key];
      } else if (local[key] != remote[key]) {
        // Handle conflicts based on field type
        merged[key] = _mergeField(key, local[key], remote[key]);
      }
    }
    
    return merged;
  }

  /// Merge individual field
  dynamic _mergeField(String field, dynamic localValue, dynamic remoteValue) {
    // List fields - combine unique values
    if (localValue is List && remoteValue is List) {
      return {...localValue, ...remoteValue}.toList();
    }
    
    // Timestamp fields - use most recent
    if (field.contains('timestamp') || field.contains('date')) {
      try {
        final localDate = DateTime.parse(localValue.toString());
        final remoteDate = DateTime.parse(remoteValue.toString());
        return localDate.isAfter(remoteDate) ? localValue : remoteValue;
      } catch (_) {
        return remoteValue;
      }
    }
    
    // Numeric fields - use maximum for counts/quantities
    if (localValue is num && remoteValue is num) {
      if (field.contains('count') || field.contains('quantity')) {
        return localValue > remoteValue ? localValue : remoteValue;
      }
    }
    
    // Default to remote value
    return remoteValue;
  }

  /// Handle failed operation
  Future<void> _handleFailedOperation(SyncOperation operation) async {
    operation.retryCount++;
    operation.status = SyncStatus.failed;
    operation.lastError = 'Sync failed at ${DateTime.now()}';
    
    if (operation.retryCount < _maxRetries) {
      // Schedule retry
      operation.status = SyncStatus.pending;
      operation.nextRetryTime = DateTime.now().add(
        _retryDelay * operation.retryCount,
      );
      
      _syncQueue.add(operation);
      await _updateOperation(operation);
      
      debugPrint('Operation ${operation.id} scheduled for retry (${operation.retryCount}/$_maxRetries)');
    } else {
      // Max retries exceeded
      operation.status = SyncStatus.failed;
      await _updateOperation(operation);
      
      // Move to dead letter queue
      await _moveToDeadLetterQueue(operation);
      
      debugPrint('Operation ${operation.id} moved to dead letter queue');
    }
  }

  /// Attempt immediate sync for high-priority operations
  void _attemptImmediateSync() {
    if (!isOnline || _isSyncing) return;
    
    // Check for high-priority operations
    final hasPriority = _syncQueue.any((op) => 
      op.priority == SyncPriority.high || 
      op.priority == SyncPriority.critical
    );
    
    if (hasPriority) {
      performSync();
    }
  }

  /// Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOffline = !isOnline;
        _connectionStatus = results.isNotEmpty ? results.first : ConnectivityResult.none;
        
        debugPrint('Connectivity changed: ${results.isNotEmpty ? results.first : ConnectivityResult.none}');
        
        if (wasOffline && isOnline) {
          debugPrint('Device came online, starting sync');
          await performSync();
        }
        
        notifyListeners();
      },
    );
    
    // Get initial connectivity status
    final connectivityResults = await Connectivity().checkConnectivity();
    _connectionStatus = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
  }

  /// Start sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (isOnline && !_isSyncing && _syncQueue.isNotEmpty) {
        performSync();
      }
    });
  }

  /// Compact queue by removing duplicates and optimizing operations
  Future<void> _compactQueue() async {
    final compacted = <String, SyncOperation>{};
    
    for (final operation in _syncQueue) {
      final key = '${operation.entityType}_${operation.entityId}';
      
      if (compacted.containsKey(key)) {
        // Merge operations on same entity
        final existing = compacted[key]!;
        compacted[key] = _mergeOperations(existing, operation);
      } else {
        compacted[key] = operation;
      }
    }
    
    _syncQueue.clear();
    _syncQueue.addAll(compacted.values);
    
    debugPrint('Queue compacted: ${compacted.length} operations remaining');
  }

  /// Merge two operations on the same entity
  SyncOperation _mergeOperations(SyncOperation op1, SyncOperation op2) {
    // If one is delete, use delete
    if (op1.operationType == OperationType.delete || 
        op2.operationType == OperationType.delete) {
      return op1.operationType == OperationType.delete ? op1 : op2;
    }
    
    // If one is create and other is update, use create with updated data
    if (op1.operationType == OperationType.create && 
        op2.operationType == OperationType.update) {
      op1.data.addAll(op2.data);
      return op1;
    }
    
    // Both updates - merge data
    if (op1.operationType == OperationType.update && 
        op2.operationType == OperationType.update) {
      op1.data.addAll(op2.data);
      op1.timestamp = op2.timestamp;
      return op1;
    }
    
    // Default to newer operation
    return op2.timestamp.isAfter(op1.timestamp) ? op2 : op1;
  }

  /// Load pending operations from database
  Future<void> _loadPendingOperations() async {
    final results = await _database!.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );
    
    for (final row in results) {
      final operation = SyncOperation.fromMap(row);
      _syncQueue.add(operation);
      _pendingOperations[operation.id] = operation;
    }
    
    debugPrint('Loaded ${results.length} pending operations');
  }

  /// Persist operation to database
  Future<void> _persistOperation(SyncOperation operation) async {
    await _database!.insert(
      'sync_queue',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update operation in database
  Future<void> _updateOperation(SyncOperation operation) async {
    await _database!.update(
      'sync_queue',
      operation.toMap(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  /// Mark operation as complete
  Future<void> _markOperationComplete(SyncOperation operation) async {
    operation.status = SyncStatus.completed;
    operation.completedAt = DateTime.now();
    
    await _database!.update(
      'sync_queue',
      {'status': 'completed', 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [operation.id],
    );
    
    _pendingOperations.remove(operation.id);
  }

  /// Move operation to dead letter queue
  Future<void> _moveToDeadLetterQueue(SyncOperation operation) async {
    // In production, implement dead letter queue for manual intervention
    debugPrint('Operation ${operation.id} requires manual intervention');
  }

  /// Persist conflict resolution
  Future<void> _persistConflictResolution(ConflictResolution resolution) async {
    await _database!.insert(
      'conflict_resolutions',
      resolution.toMap(),
    );
  }

  /// Record sync history
  Future<void> _recordSyncHistory({
    required String status,
    required Duration duration,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    final history = SyncHistory(
      id: 'history_${DateTime.now().millisecondsSinceEpoch}',
      status: status,
      syncTime: DateTime.now(),
      duration: duration,
      errorMessage: errorMessage,
      metadata: metadata,
    );
    
    _syncHistory.add(history);
    
    await _database!.insert(
      'sync_history',
      history.toMap(),
    );
    
    // Keep only recent history
    if (_syncHistory.length > 100) {
      _syncHistory.removeRange(0, 20);
    }
  }

  /// Check if entity exists remotely
  Future<bool> _checkEntityExists(String entityType, String entityId) async {
    // Simulate API check
    await Future.delayed(Duration(milliseconds: 50));
    return false; // In production, make actual API call
  }

  /// Get remote version of entity
  Future<String> _getRemoteVersion(String entityType, String entityId) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 50));
    return 'v${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Fetch remote data
  Future<Map<String, dynamic>> _fetchRemoteData(String entityType, String entityId) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 50));
    return {
      'id': entityId,
      'type': entityType,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Analyze differences between local and remote data
  List<DataDifference> _analyzeDifferences(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final differences = <DataDifference>[];
    
    final allKeys = {...local.keys, ...remote.keys};
    
    for (final key in allKeys) {
      if (!local.containsKey(key)) {
        differences.add(DataDifference(
          field: key,
          localValue: null,
          remoteValue: remote[key],
          type: DifferenceType.added,
        ));
      } else if (!remote.containsKey(key)) {
        differences.add(DataDifference(
          field: key,
          localValue: local[key],
          remoteValue: null,
          type: DifferenceType.removed,
        ));
      } else if (local[key] != remote[key]) {
        differences.add(DataDifference(
          field: key,
          localValue: local[key],
          remoteValue: remote[key],
          type: DifferenceType.modified,
        ));
      }
    }
    
    return differences;
  }

  /// Queue for manual resolution
  Future<void> _queueManualResolution(SyncConflict conflict) async {
    // Store conflict for manual resolution
    // In production, notify user or admin
    debugPrint('Conflict requires manual resolution: ${conflict.entityType}');
  }

  /// Custom conflict resolution
  Future<Map<String, dynamic>> _customResolution(SyncConflict conflict) async {
    // Implement custom resolution logic based on entity type
    return conflict.localData;
  }

  /// Process bulk update operation
  Future<bool> _processBulkUpdate(SyncOperation operation) async {
    final entities = operation.data['entities'] as List;
    
    for (final entity in entities) {
      // Process each entity
      // ... implementation
    }
    
    return true;
  }

  /// Process merge operation
  Future<bool> _processMerge(SyncOperation operation) async {
    // Implement merge logic
    return true;
  }

  /// Clear sync queue
  Future<void> clearQueue() async {
    _syncQueue.clear();
    _pendingOperations.clear();
    
    await _database!.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    
    notifyListeners();
  }

  /// Get sync statistics
  Future<SyncStatistics> getStatistics() async {
    final pending = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      ['pending'],
    );
    
    final completed = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      ['completed'],
    );
    
    final failed = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      ['failed'],
    );
    
    return SyncStatistics(
      pendingCount: pending.first['count'] as int,
      completedCount: completed.first['count'] as int,
      failedCount: failed.first['count'] as int,
      conflictsResolved: _conflictsResolved,
      lastSyncTime: _lastSyncTime,
      averageSyncTime: _calculateAverageSyncTime(),
    );
  }

  /// Calculate average sync time
  Duration _calculateAverageSyncTime() {
    if (_syncHistory.isEmpty) return Duration.zero;
    
    final totalMs = _syncHistory
        .map((h) => h.duration?.inMilliseconds ?? 0)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ _syncHistory.length);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Data Models

class SyncOperation {
  String id;
  OperationType operationType;
  String entityType;
  String? entityId;
  Map<String, dynamic> data;
  DateTime timestamp;
  SyncPriority priority;
  SyncStatus status;
  int retryCount;
  DateTime? nextRetryTime;
  DateTime? completedAt;
  String? lastError;
  Map<String, dynamic>? metadata;

  SyncOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    this.entityId,
    required this.data,
    required this.timestamp,
    this.priority = SyncPriority.normal,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.nextRetryTime,
    this.completedAt,
    this.lastError,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'operation_type': operationType.toString(),
    'entity_type': entityType,
    'entity_id': entityId,
    'data': jsonEncode(data),
    'timestamp': timestamp.millisecondsSinceEpoch,
    'retry_count': retryCount,
    'status': status.toString().split('.').last,
    'error_message': lastError,
    'created_at': timestamp.millisecondsSinceEpoch,
    'updated_at': DateTime.now().millisecondsSinceEpoch,
  };

  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
    id: map['id'],
    operationType: OperationType.values.firstWhere(
      (t) => t.toString() == map['operation_type'],
    ),
    entityType: map['entity_type'],
    entityId: map['entity_id'],
    data: jsonDecode(map['data']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    retryCount: map['retry_count'] ?? 0,
    status: SyncStatus.values.firstWhere(
      (s) => s.toString().split('.').last == map['status'],
    ),
    lastError: map['error_message'],
  );
}

enum OperationType {
  create,
  update,
  delete,
  custom,
}

enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

enum SyncStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class SyncConflict {
  final String id;
  final String operationId;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final List<DataDifference> differences;
  final DateTime detectedAt;

  SyncConflict({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.differences,
    required this.detectedAt,
  });
}

class DataDifference {
  final String field;
  final dynamic localValue;
  final dynamic remoteValue;
  final DifferenceType type;

  DataDifference({
    required this.field,
    this.localValue,
    this.remoteValue,
    required this.type,
  });
}

enum DifferenceType {
  added,
  removed,
  modified,
}

class ConflictResolution {
  final String id;
  final String conflictId;
  final ConflictStrategy strategy;
  final Map<String, dynamic> resolvedData;
  final DateTime resolvedAt;
  String? resolvedBy;

  ConflictResolution({
    required this.id,
    required this.conflictId,
    required this.strategy,
    required this.resolvedData,
    required this.resolvedAt,
    this.resolvedBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'entity_type': '', // Will be set from conflict
    'entity_id': '', // Will be set from conflict
    'local_version': jsonEncode({}), // Will be set from conflict
    'remote_version': jsonEncode({}), // Will be set from conflict
    'resolution_strategy': strategy.toString().split('.').last,
    'resolved_data': jsonEncode(resolvedData),
    'resolved_at': resolvedAt.millisecondsSinceEpoch,
    'resolved_by': resolvedBy,
  };
}

enum ConflictStrategy {
  localWins,
  remoteWins,
  merge,
  manual,
  custom,
}

class BatchResult {
  int successCount = 0;
  int failureCount = 0;
  final List<SyncOperation> failedOperations = [];
  final List<SyncConflict> conflicts = [];
  final List<String> errors = [];
}

class SyncResult {
  final bool success;
  final String? message;
  final int? successCount;
  final int? failureCount;
  final List<String>? errors;
  final Duration? duration;

  SyncResult({
    required this.success,
    this.message,
    this.successCount,
    this.failureCount,
    this.errors,
    this.duration,
  });
}

class SyncHistory {
  final String id;
  final String status;
  final DateTime syncTime;
  final Duration? duration;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  SyncHistory({
    required this.id,
    required this.status,
    required this.syncTime,
    this.duration,
    this.errorMessage,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'operation_id': '', // Will be set if specific to operation
    'status': status,
    'sync_time': syncTime.millisecondsSinceEpoch,
    'duration_ms': duration?.inMilliseconds,
    'error_message': errorMessage,
    'metadata': metadata != null ? jsonEncode(metadata) : null,
  };
}

class SyncMetrics {
  final int successfulSyncs;
  final int failedSyncs;
  final int conflictsResolved;
  final int queueSize;
  final DateTime? lastSyncTime;

  SyncMetrics({
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.conflictsResolved,
    required this.queueSize,
    this.lastSyncTime,
  });
}

class SyncStatistics {
  final int pendingCount;
  final int completedCount;
  final int failedCount;
  final int conflictsResolved;
  final DateTime? lastSyncTime;
  final Duration averageSyncTime;

  SyncStatistics({
    required this.pendingCount,
    required this.completedCount,
    required this.failedCount,
    required this.conflictsResolved,
    this.lastSyncTime,
    required this.averageSyncTime,
  });
}

class SyncException implements Exception {
  final String message;
  SyncException(this.message);
  
  @override
  String toString() => 'SyncException: $message';
}