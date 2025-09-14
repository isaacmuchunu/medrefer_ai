import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

/// Service for managing offline-first architecture with sync capabilities
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DataService _dataService = DataService();
  final Connectivity _connectivity = Connectivity();
  
  // Sync state
  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  List<SyncQueueItem> _syncQueue = [];
  
  // Stream subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<SyncQueueItem> get syncQueue => List.unmodifiable(_syncQueue);
  int get pendingSyncItems => _syncQueue.length;

  /// Initialize the sync service
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      _isOnline = connectivityResults.any((result) => result != ConnectivityResult.none);
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) => _onConnectivityChanged(results),
      );
      
      // Load sync queue from storage
      await _loadSyncQueue();
      
      // Load last sync time
      await _loadLastSyncTime();
      
      // Start periodic sync if online
      if (_isOnline) {
        _startPeriodicSync();
      }
      
      if (kDebugMode) {
        debugPrint('SyncService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (!wasOnline && _isOnline) {
      // Just came online - start sync
      _startPeriodicSync();
      syncPendingChanges();
    } else if (wasOnline && !_isOnline) {
      // Just went offline - stop periodic sync
      _stopPeriodicSync();
    }
    
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('SyncService: Connectivity changed - Online: $_isOnline');
    }
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue({
    required String operation, // CREATE, UPDATE, DELETE
    required String entityType, // patient, referral, specialist, etc.
    required String entityId,
    required Map<String, dynamic> data,
    int priority = 1, // 1 = high, 2 = medium, 3 = low
  }) async {
    final item = SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      data: data,
      priority: priority,
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    
    _syncQueue.add(item);
    _syncQueue.sort((a, b) => a.priority.compareTo(b.priority));
    
    await _saveSyncQueue();
    notifyListeners();
    
    // Try to sync immediately if online
    if (_isOnline && !_isSyncing) {
      syncPendingChanges();
    }
    
    if (kDebugMode) {
      debugPrint('SyncService: Added to sync queue - $operation $entityType:$entityId');
    }
  }

  /// Sync pending changes to server
  Future<void> syncPendingChanges() async {
    if (_isSyncing || !_isOnline || _syncQueue.isEmpty) {
      return;
    }
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      final itemsToSync = List<SyncQueueItem>.from(_syncQueue);
      final successfulSyncs = <SyncQueueItem>[];
      
      for (final item in itemsToSync) {
        try {
          final success = await _syncItem(item);
          if (success) {
            successfulSyncs.add(item);
          } else {
            // Increment retry count
            item.retryCount++;
            if (item.retryCount >= 3) {
              // Remove after 3 failed attempts
              successfulSyncs.add(item);
              if (kDebugMode) {
                debugPrint('SyncService: Removing item after 3 failed attempts: ${item.id}');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SyncService: Error syncing item ${item.id}: $e');
          }
          item.retryCount++;
        }
      }
      
      // Remove successfully synced items
      for (final item in successfulSyncs) {
        _syncQueue.remove(item);
      }
      
      await _saveSyncQueue();
      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();
      
      if (kDebugMode) {
        debugPrint('SyncService: Synced ${successfulSyncs.length} items, ${_syncQueue.length} remaining');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Sync failed: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync individual item
  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      // In a real app, this would make API calls to sync with server
      // For now, we'll simulate the sync process
      await Future.delayed(Duration(milliseconds: 100));
      
      switch (item.operation) {
        case 'CREATE':
          return await _syncCreate(item);
        case 'UPDATE':
          return await _syncUpdate(item);
        case 'DELETE':
          return await _syncDelete(item);
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Error syncing item: $e');
      }
      return false;
    }
  }

  /// Sync create operation
  Future<bool> _syncCreate(SyncQueueItem item) async {
    // Simulate API call to create entity on server
    await Future.delayed(Duration(milliseconds: 50));
    return true; // Assume success for demo
  }

  /// Sync update operation
  Future<bool> _syncUpdate(SyncQueueItem item) async {
    // Simulate API call to update entity on server
    await Future.delayed(Duration(milliseconds: 50));
    return true; // Assume success for demo
  }

  /// Sync delete operation
  Future<bool> _syncDelete(SyncQueueItem item) async {
    // Simulate API call to delete entity on server
    await Future.delayed(Duration(milliseconds: 50));
    return true; // Assume success for demo
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _stopPeriodicSync(); // Stop existing timer
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (_isOnline && !_isSyncing) {
        syncPendingChanges();
      }
    });
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Load sync queue from storage
  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString('sync_queue');
      if (queueJson != null) {
        final queueList = jsonDecode(queueJson) as List;
        _syncQueue = queueList.map((item) => SyncQueueItem.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Error loading sync queue: $e');
      }
    }
  }

  /// Save sync queue to storage
  Future<void> _saveSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_syncQueue.map((item) => item.toJson()).toList());
      await prefs.setString('sync_queue', queueJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Error saving sync queue: $e');
      }
    }
  }

  /// Load last sync time
  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_sync_time');
      if (timestamp != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Error loading last sync time: $e');
      }
    }
  }

  /// Save last sync time
  Future<void> _saveLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setInt('last_sync_time', _lastSyncTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncService: Error saving last sync time: $e');
      }
    }
  }

  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    await _saveSyncQueue();
    notifyListeners();
  }

  /// Force sync now
  Future<void> forceSyncNow() async {
    if (_isOnline) {
      await syncPendingChanges();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
    super.dispose();
  }
}

/// Sync queue item model
class SyncQueueItem {
  final String id;
  final String operation;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
  final int priority;
  final DateTime timestamp;
  int retryCount;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.priority,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'entityType': entityType,
      'entityId': entityId,
      'data': data,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'],
      operation: json['operation'],
      entityType: json['entityType'],
      entityId: json['entityId'],
      data: Map<String, dynamic>.from(json['data']),
      priority: json['priority'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}
