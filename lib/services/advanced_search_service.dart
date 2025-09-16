import 'dart:async';
import 'dart:math';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/database/models/search_models.dart';

/// Advanced Search Service with Elasticsearch-like capabilities
class AdvancedSearchService extends ChangeNotifier {
  static final AdvancedSearchService _instance = _AdvancedSearchService();
  factory AdvancedSearchService() => _instance;
  _AdvancedSearchService();

  late LoggingService _loggingService;
  final Map<String, List<SearchResult>> _searchIndex = {};
  final List<SavedSearch> _savedSearches = [];
  final List<SearchSuggestion> _suggestions = [];
  final List<SearchAnalytics> _searchAnalytics = [];

  // Search statistics
  int _totalSearches = 0;
  final int _totalResults = 0;
  double _averageResponseTime = 0.0;
  final Map<String, int> _popularQueries = {};

  /// Initialize the search service
  Future<void> initialize() async {
    try {
      _loggingService = LoggingService();
      
      // Initialize search index with sample data
      await _initializeSearchIndex();
      
      // Load saved searches and suggestions
      await _loadSavedSearches();
      await _loadSuggestions();
      
      _loggingService.info('Advanced Search Service initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize Advanced Search Service', error: e);
      rethrow;
    }
  }

  /// Initialize search index with sample data
  Future<void> _initializeSearchIndex() async {
    // Sample patients
    _addToIndex('patients', [
      SearchResult(
        id: 'patient_1',
        entityType: 'patient',
        entityId: '1',
        title: 'John Smith',
        description: '45-year-old male with hypertension and diabetes',
        score: 1.0,
        data: {
          'age': 45,
          'gender': 'Male',
          'conditions': ['Hypertension', 'Diabetes'],
          'lastVisit': '2024-01-15',
        },
        highlights: ['John Smith', 'hypertension', 'diabetes'],
        metadata: {'department': 'Cardiology'},
        indexedAt: DateTime.now(),
      ),
      SearchResult(
        id: 'patient_2',
        entityType: 'patient',
        entityId: '2',
        title: 'Sarah Johnson',
        description: '32-year-old female with pregnancy complications',
        score: 1.0,
        data: {
          'age': 32,
          'gender': 'Female',
          'conditions': ['Pregnancy Complications'],
          'lastVisit': '2024-01-20',
        },
        highlights: ['Sarah Johnson', 'pregnancy', 'complications'],
        metadata: {'department': 'Obstetrics'},
        indexedAt: DateTime.now(),
      ),
    ]);

    // Sample referrals
    _addToIndex('referrals', [
      SearchResult(
        id: 'referral_1',
        entityType: 'referral',
        entityId: '1',
        title: 'Cardiology Referral - John Smith',
        description: 'Referral to Dr. Wilson for cardiac evaluation',
        score: 1.0,
        data: {
          'patientId': '1',
          'specialist': 'Dr. Wilson',
          'specialty': 'Cardiology',
          'status': 'Pending',
          'priority': 'High',
        },
        highlights: ['John Smith', 'cardiology', 'Dr. Wilson'],
        metadata: {'department': 'Cardiology'},
        indexedAt: DateTime.now(),
      ),
      SearchResult(
        id: 'referral_2',
        entityType: 'referral',
        entityId: '2',
        title: 'Neurology Referral - Sarah Johnson',
        description: 'Referral to Dr. Brown for neurological assessment',
        score: 1.0,
        data: {
          'patientId': '2',
          'specialist': 'Dr. Brown',
          'specialty': 'Neurology',
          'status': 'Completed',
          'priority': 'Medium',
        },
        highlights: ['Sarah Johnson', 'neurology', 'Dr. Brown'],
        metadata: {'department': 'Neurology'},
        indexedAt: DateTime.now(),
      ),
    ]);

    // Sample users
    _addToIndex('users', [
      SearchResult(
        id: 'user_1',
        entityType: 'user',
        entityId: '1',
        title: 'Dr. Sarah Wilson',
        description: 'Senior Cardiologist with 15 years experience',
        score: 1.0,
        data: {
          'role': 'Doctor',
          'specialty': 'Cardiology',
          'department': 'Cardiology',
          'experience': 15,
        },
        highlights: ['Dr. Sarah Wilson', 'cardiologist', 'cardiology'],
        metadata: {'department': 'Cardiology'},
        indexedAt: DateTime.now(),
      ),
      SearchResult(
        id: 'user_2',
        entityType: 'user',
        entityId: '2',
        title: 'Dr. Michael Brown',
        description: 'Neurologist specializing in stroke treatment',
        score: 1.0,
        data: {
          'role': 'Doctor',
          'specialty': 'Neurology',
          'department': 'Neurology',
          'experience': 12,
        },
        highlights: ['Dr. Michael Brown', 'neurologist', 'stroke'],
        metadata: {'department': 'Neurology'},
        indexedAt: DateTime.now(),
      ),
    ]);

    // Sample documents
    _addToIndex('documents', [
      SearchResult(
        id: 'doc_1',
        entityType: 'document',
        entityId: '1',
        title: 'Lab Results - John Smith',
        description: 'Blood work results showing elevated glucose levels',
        score: 1.0,
        data: {
          'type': 'Lab Results',
          'patientId': '1',
          'date': '2024-01-10',
          'status': 'Reviewed',
        },
        highlights: ['John Smith', 'lab results', 'glucose'],
        metadata: {'department': 'Laboratory'},
        indexedAt: DateTime.now(),
      ),
    ]);
  }

  /// Add results to search index
  void _addToIndex(String entityType, List<SearchResult> results) {
    _searchIndex[entityType] = results;
  }

  /// Load saved searches
  Future<void> _loadSavedSearches() async {
    _savedSearches.addAll([
      SavedSearch(
        id: 'saved_1',
        name: 'Cardiology Patients',
        description: 'Find all cardiology patients',
        query: 'cardiology patients',
        entityTypes: ['patient'],
        filters: {'department': 'Cardiology'},
        tags: ['cardiology', 'patients'],
        lastUsed: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      SavedSearch(
        id: 'saved_2',
        name: 'Pending Referrals',
        description: 'All pending referrals',
        query: 'pending referrals',
        entityTypes: ['referral'],
        filters: {'status': 'Pending'},
        tags: ['referrals', 'pending'],
        lastUsed: DateTime.now().subtract(Duration(hours: 2)),
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ]);
  }

  /// Load search suggestions
  Future<void> _loadSuggestions() async {
    _suggestions.addAll([
      SearchSuggestion(
        id: 'suggestion_1',
        text: 'cardiology',
        type: 'query',
        frequency: 45,
        score: 0.9,
        lastUsed: DateTime.now().subtract(Duration(hours: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 10)),
      ),
      SearchSuggestion(
        id: 'suggestion_2',
        text: 'Dr. Wilson',
        type: 'entity',
        entityType: 'user',
        entityId: '1',
        frequency: 23,
        score: 0.8,
        lastUsed: DateTime.now().subtract(Duration(minutes: 30)),
        createdAt: DateTime.now().subtract(Duration(days: 5)),
      ),
      SearchSuggestion(
        id: 'suggestion_3',
        text: 'pending referrals',
        type: 'query',
        frequency: 67,
        score: 0.95,
        lastUsed: DateTime.now().subtract(Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(Duration(days: 20)),
      ),
    ]);
  }

  /// Perform advanced search
  Future<Map<String, dynamic>> search({
    required String query,
    List<String>? entityTypes,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? facets,
    String sortBy = 'score',
    String sortOrder = 'desc',
    int page = 1,
    int pageSize = 20,
    String? userId,
    String? organizationId,
  }) async {
    final startTime = DateTime.now();
    
    try {
      _totalSearches++;
      
      // Log search analytics
      final searchQuery = SearchQuery(
        id: _generateId(),
        query: query,
        userId: userId,
        organizationId: organizationId,
        entityTypes: entityTypes ?? [],
        filters: filters ?? {},
        facets: facets ?? {},
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
        pageSize: pageSize,
        createdAt: DateTime.now(),
      );

      // Perform search
      final results = await _performSearch(searchQuery);
      
      // Generate facets
      final searchFacets = await _generateFacets(entityTypes ?? [], filters ?? {});
      
      // Track analytics
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      final analytics = SearchAnalytics(
        id: _generateId(),
        query: query,
        userId: userId,
        organizationId: organizationId,
        entityTypes: entityTypes ?? [],
        resultCount: results.length,
        page: page,
        sortBy: sortBy,
        sortOrder: sortOrder,
        filters: filters ?? {},
        searchedAt: DateTime.now(),
        responseTime: responseTime,
      );
      
      _searchAnalytics.add(analytics);
      _updateSearchStatistics();
      
      // Update popular queries
      _popularQueries[query] = (_popularQueries[query] ?? 0) + 1;
      
      _loggingService.debug('Search performed', context: 'Search', metadata: {
        'query': query,
        'result_count': results.length,
        'response_time': responseTime,
      });

      return {
        'results': results,
        'facets': searchFacets,
        'total_count': results.length,
        'page': page,
        'page_size': pageSize,
        'response_time': responseTime,
        'suggestions': _getSuggestions(query),
      };
    } catch (e) {
      _loggingService.error('Search failed', error: e);
      rethrow;
    }
  }

  /// Perform the actual search
  Future<List<SearchResult>> _performSearch(SearchQuery searchQuery) async {
    final results = <SearchResult>[];
    final query = searchQuery.query.toLowerCase();
    
    // Search across entity types
    final entityTypes = searchQuery.entityTypes.isEmpty 
        ? _searchIndex.keys.toList() 
        : searchQuery.entityTypes;
    
    for (final entityType in entityTypes) {
      final entityResults = _searchIndex[entityType] ?? [];
      
      for (final result in entityResults) {
        // Text matching
        final titleMatch = result.title.toLowerCase().contains(query);
        final descriptionMatch = result.description.toLowerCase().contains(query);
        final highlightMatch = result.highlights.any((h) => h.toLowerCase().contains(query));
        
        if (titleMatch || descriptionMatch || highlightMatch) {
          // Apply filters
          if (_matchesFilters(result, searchQuery.filters)) {
            // Calculate relevance score
            double score = result.score;
            
            if (titleMatch) score += 0.3;
            if (descriptionMatch) score += 0.2;
            if (highlightMatch) score += 0.1;
            
            // Apply entity type boost
            if (entityTypes.contains(result.entityType)) {
              score += 0.1;
            }
            
            results.add(result.copyWith(score: score));
          }
        }
      }
    }
    
    // Sort results
    results.sort((a, b) {
      if (searchQuery.sortBy == 'score') {
        return searchQuery.sortOrder == 'desc' 
            ? b.score.compareTo(a.score)
            : a.score.compareTo(b.score);
      } else if (searchQuery.sortBy == 'title') {
        return searchQuery.sortOrder == 'desc'
            ? b.title.compareTo(a.title)
            : a.title.compareTo(b.title);
      }
      return 0;
    });
    
    // Apply pagination
    final startIndex = (searchQuery.page - 1) * searchQuery.pageSize;
    final endIndex = startIndex + searchQuery.pageSize;
    
    return results.sublist(
      startIndex.clamp(0, results.length),
      endIndex.clamp(0, results.length),
    );
  }

  /// Check if result matches filters
  bool _matchesFilters(SearchResult result, Map<String, dynamic> filters) {
    for (final entry in filters.entries) {
      final field = entry.key;
      final value = entry.value;
      
      if (result.data[field] != value && result.metadata[field] != value) {
        return false;
      }
    }
    return true;
  }

  /// Generate search facets
  Future<List<SearchFacet>> _generateFacets(List<String> entityTypes, Map<String, dynamic> filters) async {
    final facets = <SearchFacet>[];
    
    // Department facet
    final departmentFacet = _generateFacet('department', 'Department', entityTypes, filters);
    if (departmentFacet.values.isNotEmpty) {
      facets.add(departmentFacet);
    }
    
    // Entity type facet
    final entityTypeFacet = _generateFacet('entityType', 'Type', entityTypes, filters);
    if (entityTypeFacet.values.isNotEmpty) {
      facets.add(entityTypeFacet);
    }
    
    // Status facet (for referrals)
    final statusFacet = _generateFacet('status', 'Status', entityTypes, filters);
    if (statusFacet.values.isNotEmpty) {
      facets.add(statusFacet);
    }
    
    return facets;
  }

  /// Generate a specific facet
  SearchFacet _generateFacet(String field, String displayName, List<String> entityTypes, Map<String, dynamic> filters) {
    final valueCounts = <String, int>{};
    
    for (final entityType in entityTypes.isEmpty ? _searchIndex.keys : entityTypes) {
      final results = _searchIndex[entityType] ?? [];
      
      for (final result in results) {
        String? value;
        
        if (field == 'entityType') {
          value = result.entityType;
        } else if (field == 'department') {
          value = result.metadata['department'] as String?;
        } else if (field == 'status') {
          value = result.data['status'] as String?;
        }
        
        if (value != null) {
          valueCounts[value] = (valueCounts[value] ?? 0) + 1;
        }
      }
    }
    
    final facetValues = valueCounts.entries.map((entry) {
      return FacetValue(
        value: entry.key,
        displayValue: entry.key,
        count: entry.value,
        isSelected: filters[field] == entry.key,
      );
    }).toList();
    
    facetValues.sort((a, b) => b.count.compareTo(a.count));
    
    return SearchFacet(
      field: field,
      displayName: displayName,
      values: facetValues,
      totalCount: valueCounts.values.fold(0, (sum, count) => sum + count),
    );
  }

  /// Get search suggestions
  List<SearchSuggestion> _getSuggestions(String query) {
    if (query.isEmpty) return _suggestions.take(5).toList();
    
    return _suggestions
        .where((suggestion) => suggestion.text.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  /// Save a search
  Future<String> saveSearch({
    required String name,
    required String description,
    required String query,
    List<String>? entityTypes,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? facets,
    String? userId,
    String? organizationId,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    try {
      final savedSearch = SavedSearch(
        id: _generateId(),
        name: name,
        description: description,
        query: query,
        userId: userId,
        organizationId: organizationId,
        entityTypes: entityTypes ?? [],
        filters: filters ?? {},
        facets: facets ?? {},
        tags: tags ?? [],
        isPublic: isPublic,
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _savedSearches.add(savedSearch);
      notifyListeners();
      
      _loggingService.info('Search saved', context: 'Search', metadata: {
        'saved_search_id': savedSearch.id,
        'name': name,
      });
      
      return savedSearch.id;
    } catch (e) {
      _loggingService.error('Failed to save search', error: e);
      rethrow;
    }
  }

  /// Get saved searches
  List<SavedSearch> getSavedSearches({
    String? userId,
    String? organizationId,
  }) {
    return _savedSearches.where((search) {
      if (userId != null && search.userId != userId) return false;
      if (organizationId != null && search.organizationId != organizationId) return false;
      return true;
    }).toList();
  }

  /// Execute saved search
  Future<Map<String, dynamic>> executeSavedSearch(String savedSearchId, {
    int page = 1,
    int pageSize = 20,
    String? userId,
  }) async {
    try {
      final savedSearch = _savedSearches.firstWhere((s) => s.id == savedSearchId);
      
      // Update usage count and last used
      savedSearch.useCount++;
      savedSearch.lastUsed = DateTime.now();
      
      return await search(
        query: savedSearch.query,
        entityTypes: savedSearch.entityTypes,
        filters: savedSearch.filters,
        facets: savedSearch.facets,
        sortBy: savedSearch.sortBy,
        sortOrder: savedSearch.sortOrder,
        page: page,
        pageSize: pageSize,
        userId: userId,
      );
    } catch (e) {
      _loggingService.error('Failed to execute saved search', error: e);
      rethrow;
    }
  }

  /// Get search analytics
  Map<String, dynamic> getSearchAnalytics({
    String? userId,
    String? organizationId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredAnalytics = _searchAnalytics.where((analytics) {
      if (userId != null && analytics.userId != userId) return false;
      if (organizationId != null && analytics.organizationId != organizationId) return false;
      if (startDate != null && analytics.searchedAt.isBefore(startDate)) return false;
      if (endDate != null && analytics.searchedAt.isAfter(endDate)) return false;
      return true;
    }).toList();

    final totalSearches = filteredAnalytics.length;
    final totalResults = filteredAnalytics.fold(0, (sum, analytics) => sum + analytics.resultCount);
    final averageResponseTime = totalSearches > 0 
        ? filteredAnalytics.fold(0, (sum, analytics) => sum + analytics.responseTime) / totalSearches
        : 0.0;

    // Popular queries
    final queryCounts = <String, int>{};
    for (final analytics in filteredAnalytics) {
      queryCounts[analytics.query] = (queryCounts[analytics.query] ?? 0) + 1;
    }
    final popularQueries = queryCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_searches': totalSearches,
      'total_results': totalResults,
      'average_response_time': averageResponseTime,
      'popular_queries': popularQueries.take(10).map((e) => {
        'query': e.key,
        'count': e.value,
      }).toList(),
      'saved_searches_count': _savedSearches.length,
      'suggestions_count': _suggestions.length,
    };
  }

  /// Update search statistics
  void _updateSearchStatistics() {
    if (_searchAnalytics.isNotEmpty) {
      _averageResponseTime = _searchAnalytics.fold(0, (sum, analytics) => sum + analytics.responseTime) / 
                           _searchAnalytics.length;
    }
  }

  /// Index a document
  Future<void> indexDocument({
    required String entityType,
    required String entityId,
    required String title,
    required String description,
    Map<String, dynamic>? data,
    List<String>? highlights,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = SearchResult(
        id: _generateId(),
        entityType: entityType,
        entityId: entityId,
        title: title,
        description: description,
        score: 1.0,
        data: data ?? {},
        highlights: highlights ?? [],
        metadata: metadata ?? {},
        indexedAt: DateTime.now(),
      );

      _searchIndex[entityType] ??= [];
      _searchIndex[entityType]!.add(result);
      
      _loggingService.debug('Document indexed', context: 'Search', metadata: {
        'entity_type': entityType,
        'entity_id': entityId,
      });
    } catch (e) {
      _loggingService.error('Failed to index document', error: e);
      rethrow;
    }
  }

  /// Remove document from index
  Future<void> removeFromIndex(String entityType, String entityId) async {
    try {
      _searchIndex[entityType]?.removeWhere((result) => result.entityId == entityId);
      
      _loggingService.debug('Document removed from index', context: 'Search', metadata: {
        'entity_type': entityType,
        'entity_id': entityId,
      });
    } catch (e) {
      _loggingService.error('Failed to remove document from index', error: e);
      rethrow;
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

/// Extension for SearchResult copyWith
extension SearchResultCopyWith on SearchResult {
  SearchResult copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? title,
    String? description,
    double? score,
    Map<String, dynamic>? data,
    List<String>? highlights,
    Map<String, dynamic>? metadata,
    DateTime? indexedAt,
  }) {
    return SearchResult(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      description: description ?? this.description,
      score: score ?? this.score,
      data: data ?? this.data,
      highlights: highlights ?? this.highlights,
      metadata: metadata ?? this.metadata,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }
}