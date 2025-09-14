import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../database/models/models.dart';
import '../../database/services/data_service.dart';

/// Service for managing real-time updates across the application
class RealtimeService extends ChangeNotifier {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final DataService _dataService = DataService();
  
  // Dashboard stats stream
  final StreamController<Map<String, dynamic>> _dashboardStatsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream for external access
  Stream<Map<String, dynamic>> get dashboardStatsStream => _dashboardStatsController.stream;
  
  // Timers for periodic updates
  Timer? _dashboardUpdateTimer;
  
  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  /// Initialize the real-time service
  Future<void> initialize() async {
    try {
      await _dataService.initialize();
      _isConnected = true;
      
      // Start periodic updates
      _startPeriodicUpdates();
      
      if (kDebugMode) {
        debugPrint('RealtimeService: Initialized successfully');
      }
      
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      if (kDebugMode) {
        debugPrint('RealtimeService: Initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Start periodic data updates
  void _startPeriodicUpdates() {
    // Update dashboard stats every 30 seconds
    _dashboardUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateDashboardStats();
    });
    
    // Initial update
    _updateDashboardStats();
  }
  
  /// Update dashboard statistics
  Future<void> _updateDashboardStats() async {
    try {
      final stats = await _getDashboardStats();
      _dashboardStatsController.add(stats);
      
      if (kDebugMode) {
        debugPrint('RealtimeService: Dashboard stats updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RealtimeService: Error updating dashboard stats: $e');
      }
    }
  }
  
  /// Get dashboard statistics
  Future<Map<String, dynamic>> _getDashboardStats() async {
    try {
      // Get basic counts from database
      final referralCount = await _dataService.getTotalReferrals();
      final patientCount = await _dataService.getTotalPatients();
      
      return {
        'totalReferrals': referralCount,
        'totalPatients': patientCount,
        'pendingReferrals': 0, // TODO: Implement when referral status is available
        'completedReferrals': 0, // TODO: Implement when referral status is available
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RealtimeService: Error getting dashboard stats: $e');
      }
      return {
        'totalReferrals': 0,
        'totalPatients': 0,
        'pendingReferrals': 0,
        'completedReferrals': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Manually trigger dashboard update
  Future<void> refreshDashboard() async {
    await _updateDashboardStats();
  }
  
  /// Simulate real-time notification
  void simulateNotification(String type, Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('RealtimeService: Simulated notification - Type: $type, Data: $data');
    }
    
    // In a real implementation, this would handle WebSocket messages
    // For now, we just trigger a dashboard refresh
    _updateDashboardStats();
  }
  
  /// Stop the service
  void stop() {
    _dashboardUpdateTimer?.cancel();
    _dashboardStatsController.close();
    _isConnected = false;
    
    if (kDebugMode) {
      debugPrint('RealtimeService: Stopped');
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
