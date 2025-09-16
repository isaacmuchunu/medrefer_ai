import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../database/services/data_service.dart';

/// Service for handling search functionality across the application
class SearchService extends ChangeNotifier {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DataService _dataService = DataService();
  
  // Search state
  bool _isSearching = false;
  String _currentQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  
  // Getters
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;
  List<Map<String, dynamic>> get searchResults => List.unmodifiable(_searchResults);
  
  /// Initialize the search service
  Future<void> initialize() async {
    try {
      await _dataService.initialize();
      
      if (kDebugMode) {
        debugPrint('SearchService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SearchService: Initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Perform a global search across all data types
  Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      notifyListeners();
      return _searchResults;
    }
    
    _isSearching = true;
    _currentQuery = query;
    notifyListeners();
    
    try {
      final results = <Map<String, dynamic>>[];
      
      // Search patients
      final patients = await _searchPatients(query);
      results.addAll(patients);
      
      // Search specialists
      final specialists = await _searchSpecialists(query);
      results.addAll(specialists);
      
      // Search referrals
      final referrals = await _searchReferrals(query);
      results.addAll(referrals);
      
      _searchResults = results;
      
      if (kDebugMode) {
        debugPrint('SearchService: Found ${results.length} results for "$query"');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SearchService: Search error: $e');
      }
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
    
    return _searchResults;
  }
  
  /// Search patients
  Future<List<Map<String, dynamic>>> _searchPatients(String query) async {
    try {
      final patients = await _dataService.searchPatients(query);
      return patients.map((patient) => {
        'type': 'patient',
        'id': patient.id,
        'title': patient.name,
        'subtitle': 'Patient • ${patient.email ?? 'No email'}',
        'data': patient.toMap(),
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SearchService: Error searching patients: $e');
      }
      return [];
    }
  }
  
  /// Search specialists
  Future<List<Map<String, dynamic>>> _searchSpecialists(String query) async {
    try {
      final specialists = await _dataService.searchSpecialists(query);
      return specialists.map((specialist) => {
        'type': 'specialist',
        'id': specialist.id,
        'title': specialist.name,
        'subtitle': '${specialist.specialty} • ${specialist.hospital}',
        'data': specialist.toMap(),
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SearchService: Error searching specialists: $e');
      }
      return [];
    }
  }
  
  /// Search referrals
  Future<List<Map<String, dynamic>>> _searchReferrals(String query) async {
    try {
      final referrals = await _dataService.searchReferrals(query);
      return referrals.map((referral) => {
        'type': 'referral',
        'id': referral.id,
        'title': 'Referral #${referral.trackingNumber}',
        'subtitle': '${referral.status} • ${referral.urgency}',
        'data': referral.toMap(),
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SearchService: Error searching referrals: $e');
      }
      return [];
    }
  }
  
  /// Search by specific type
  Future<List<Map<String, dynamic>>> searchByType(String query, String type) async {
    switch (type.toLowerCase()) {
      case 'patient':
        return await _searchPatients(query);
      case 'specialist':
        return await _searchSpecialists(query);
      case 'referral':
        return await _searchReferrals(query);
      default:
        return await search(query);
    }
  }
  
  /// Get search suggestions based on partial query
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) return [];
    
    try {
      final suggestions = <String>[];
      
      // Get patient name suggestions
      final patients = await _dataService.searchPatients(partialQuery);
      suggestions.addAll(patients.take(3).map((p) => p.name));
      
      // Get specialist name suggestions
      final specialists = await _dataService.searchSpecialists(partialQuery);
      suggestions.addAll(specialists.take(3).map((s) => s.name));
      
      return suggestions.take(6).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SearchService: Error getting suggestions: $e');
      }
      return [];
    }
  }
  
  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    _isSearching = false;
    notifyListeners();
  }
  
  /// Get recent searches (placeholder for future implementation)
  List<String> getRecentSearches() {
    // TODO: Implement persistent storage for recent searches
    return [];
  }
  
  /// Save search to recent searches (placeholder for future implementation)
  void saveRecentSearch(String query) {
    // TODO: Implement persistent storage for recent searches
    if (kDebugMode) {
      debugPrint('SearchService: Saving recent search: $query');
    }
  }
}
