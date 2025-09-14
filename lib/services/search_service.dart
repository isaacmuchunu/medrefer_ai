import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database.dart';

/// Advanced Search Service with full-text search, filtering, and AI-powered features
class SearchService extends ChangeNotifier {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  // Configuration
  static const int _maxSearchResults = 100;
  static const int _maxSuggestions = 10;
  static const double _fuzzyThreshold = 0.7;
  static const int _recentSearchLimit = 20;
  
  // Search state
  final List<SearchResult> _currentResults = [];
  final List<String> _recentSearches = [];
  final Map<String, SavedSearch> _savedSearches = {};
  final Map<String, SearchIndex> _searchIndexes = {};
  final List<SearchFilter> _activeFilters = [];
  
  // Search suggestions
  final List<String> _suggestions = [];
  Timer? _suggestionDebouncer;
  
  // Analytics
  final Map<String, int> _searchFrequency = {};
  final List<SearchAnalytics> _searchHistory = [];
  int _totalSearches = 0;
  
  // Database
  Database? _database;
  bool _isInitialized = false;

  // Getters
  List<SearchResult> get currentResults => List.unmodifiable(_currentResults);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  List<SearchFilter> get activeFilters => List.unmodifiable(_activeFilters);
  Map<String, SavedSearch> get savedSearches => Map.unmodifiable(_savedSearches);

  /// Initialize search service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _database = await DatabaseHelper().database;
      await _createSearchTables();
      await _buildSearchIndexes();
      await _loadRecentSearches();
      await _loadSavedSearches();
      
      _isInitialized = true;
      debugPrint('Search Service initialized');
    } catch (e) {
      debugPrint('Error initializing Search Service: $e');
      throw SearchException('Failed to initialize search service');
    }
  }

  /// Create search database tables
  Future<void> _createSearchTables() async {
    // Full-text search virtual table
    await _database!.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
        entity_id,
        entity_type,
        title,
        content,
        tags,
        metadata,
        tokenize = 'porter unicode61'
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS recent_searches (
        id TEXT PRIMARY KEY,
        query TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        result_count INTEGER,
        user_id TEXT
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS saved_searches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        query TEXT NOT NULL,
        filters TEXT,
        sort_by TEXT,
        user_id TEXT,
        created_at INTEGER NOT NULL,
        last_used INTEGER
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS search_analytics (
        id TEXT PRIMARY KEY,
        query TEXT NOT NULL,
        result_count INTEGER,
        clicked_results TEXT,
        duration_ms INTEGER,
        user_id TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_recent_timestamp 
      ON recent_searches(timestamp DESC)
    ''');

    await _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_saved_user 
      ON saved_searches(user_id, created_at DESC)
    ''');
  }

  /// Perform search with advanced features
  Future<SearchResults> search({
    required String query,
    List<SearchFilter>? filters,
    SearchSort? sortBy,
    int? limit,
    int? offset,
    bool enableFuzzy = true,
    bool enableSynonyms = true,
    bool saveToHistory = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Clean and prepare query
      final cleanedQuery = _cleanQuery(query);
      
      if (cleanedQuery.isEmpty && (filters?.isEmpty ?? true)) {
        return SearchResults(results: [], totalCount: 0, query: query);
      }
      
      // Expand query with synonyms if enabled
      final expandedQuery = enableSynonyms ? _expandWithSynonyms(cleanedQuery) : cleanedQuery;
      
      // Perform search
      List<SearchResult> results = await _performFullTextSearch(expandedQuery, filters);
      
      // Apply fuzzy matching if enabled and results are limited
      if (enableFuzzy && results.length < 5) {
        final fuzzyResults = await _performFuzzySearch(cleanedQuery, filters);
        results = _mergeResults(results, fuzzyResults);
      }
      
      // Apply filters
      if (filters != null && filters.isNotEmpty) {
        results = _applyFilters(results, filters);
      }
      
      // Apply sorting
      if (sortBy != null) {
        results = _sortResults(results, sortBy);
      }
      
      // Apply pagination
      final totalCount = results.length;
      if (offset != null) {
        results = results.skip(offset).toList();
      }
      if (limit != null) {
        results = results.take(limit).toList();
      }
      
      // Update state
      _currentResults.clear();
      _currentResults.addAll(results);
      
      // Save to history
      if (saveToHistory) {
        await _saveToHistory(query, results.length);
      }
      
      // Track analytics
      await _trackSearch(query, results.length, stopwatch.elapsedMilliseconds);
      
      notifyListeners();
      
      return SearchResults(
        results: results,
        totalCount: totalCount,
        query: query,
        executionTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      debugPrint('Error performing search: $e');
      throw SearchException('Search failed: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// Get search suggestions
  Future<List<SearchSuggestion>> getSuggestions({
    required String query,
    int limit = 10,
  }) async {
    if (query.length < 2) return [];
    
    try {
      final suggestions = <SearchSuggestion>[];
      
      // Get suggestions from recent searches
      final recentSuggestions = _recentSearches
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .take(limit ~/ 2)
          .map((s) => SearchSuggestion(
                text: s,
                type: SuggestionType.recent,
                score: 0.8,
              ))
          .toList();
      
      suggestions.addAll(recentSuggestions);
      
      // Get suggestions from index
      final indexSuggestions = await _getIndexSuggestions(query, limit - suggestions.length);
      suggestions.addAll(indexSuggestions);
      
      // Get AI-powered suggestions
      if (suggestions.length < limit) {
        final aiSuggestions = await _getAISuggestions(query, limit - suggestions.length);
        suggestions.addAll(aiSuggestions);
      }
      
      // Sort by score
      suggestions.sort((a, b) => b.score.compareTo(a.score));
      
      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      return [];
    }
  }

  /// Apply faceted search
  Future<FacetedSearchResults> facetedSearch({
    required String query,
    required List<SearchFacet> facets,
    Map<String, List<String>>? selectedFacets,
  }) async {
    try {
      // Perform base search
      final searchResults = await search(query: query);
      
      // Calculate facet counts
      final facetResults = <String, FacetResult>{};
      
      for (final facet in facets) {
        final counts = await _calculateFacetCounts(
          searchResults.results,
          facet,
          selectedFacets,
        );
        
        facetResults[facet.field] = FacetResult(
          facet: facet,
          values: counts,
        );
      }
      
      // Apply selected facets
      List<SearchResult> filteredResults = searchResults.results;
      if (selectedFacets != null && selectedFacets.isNotEmpty) {
        filteredResults = _applyFacetFilters(filteredResults, selectedFacets);
      }
      
      return FacetedSearchResults(
        results: filteredResults,
        facets: facetResults,
        totalCount: filteredResults.length,
        query: query,
      );
    } catch (e) {
      debugPrint('Error in faceted search: $e');
      throw SearchException('Faceted search failed: $e');
    }
  }

  /// Save search for later use
  Future<void> saveSearch({
    required String name,
    required String query,
    List<SearchFilter>? filters,
    SearchSort? sortBy,
    String? userId,
  }) async {
    try {
      final savedSearch = SavedSearch(
        id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        query: query,
        filters: filters,
        sortBy: sortBy,
        userId: userId,
        createdAt: DateTime.now(),
      );
      
      _savedSearches[savedSearch.id] = savedSearch;
      
      // Save to database
      await _database!.insert('saved_searches', savedSearch.toMap());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving search: $e');
      throw SearchException('Failed to save search');
    }
  }

  /// Execute saved search
  Future<SearchResults> executeSavedSearch(String savedSearchId) async {
    final savedSearch = _savedSearches[savedSearchId];
    if (savedSearch == null) {
      throw SearchException('Saved search not found');
    }
    
    // Update last used timestamp
    savedSearch.lastUsed = DateTime.now();
    await _database!.update(
      'saved_searches',
      {'last_used': savedSearch.lastUsed!.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [savedSearchId],
    );
    
    return await search(
      query: savedSearch.query,
      filters: savedSearch.filters,
      sortBy: savedSearch.sortBy,
    );
  }

  /// Add search filter
  void addFilter(SearchFilter filter) {
    _activeFilters.add(filter);
    notifyListeners();
  }

  /// Remove search filter
  void removeFilter(SearchFilter filter) {
    _activeFilters.remove(filter);
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _activeFilters.clear();
    notifyListeners();
  }

  /// Get search analytics
  SearchAnalyticsSummary getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredHistory = _searchHistory.where((h) {
      if (startDate != null && h.timestamp.isBefore(startDate)) return false;
      if (endDate != null && h.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
    
    // Calculate top queries
    final queryFrequency = <String, int>{};
    for (final item in filteredHistory) {
      queryFrequency[item.query] = (queryFrequency[item.query] ?? 0) + 1;
    }
    
    final topQueries = queryFrequency.entries
        .map((e) => QueryFrequency(query: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    
    // Calculate average metrics
    final avgResultCount = filteredHistory.isEmpty 
        ? 0.0 
        : filteredHistory.map((h) => h.resultCount).reduce((a, b) => a + b) / filteredHistory.length;
    
    final avgDuration = filteredHistory.isEmpty
        ? 0
        : filteredHistory.map((h) => h.durationMs).reduce((a, b) => a + b) ~/ filteredHistory.length;
    
    return SearchAnalyticsSummary(
      totalSearches: filteredHistory.length,
      topQueries: topQueries.take(10).toList(),
      averageResultCount: avgResultCount,
      averageDuration: avgDuration,
    );
  }

  // Private helper methods

  Future<List<SearchResult>> _performFullTextSearch(
    String query,
    List<SearchFilter>? filters,
  ) async {
    try {
      // Build FTS5 query
      final ftsQuery = _buildFTSQuery(query);
      
      // Execute search
      final results = await _database!.rawQuery('''
        SELECT 
          entity_id,
          entity_type,
          title,
          snippet(search_index, 3, '<b>', '</b>', '...', 30) as snippet,
          rank
        FROM search_index
        WHERE search_index MATCH ?
        ORDER BY rank
        LIMIT ?
      ''', [ftsQuery, _maxSearchResults]);
      
      return results.map((row) => SearchResult(
        id: row['entity_id'] as String,
        type: row['entity_type'] as String,
        title: row['title'] as String,
        snippet: row['snippet'] as String?,
        score: _calculateScore(row['rank'] as double),
        metadata: {},
      )).toList();
    } catch (e) {
      debugPrint('Full-text search error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _performFuzzySearch(
    String query,
    List<SearchFilter>? filters,
  ) async {
    try {
      // Get all potential matches
      final allResults = await _database!.query(
        'search_index',
        columns: ['entity_id', 'entity_type', 'title', 'content'],
        limit: 1000,
      );
      
      final fuzzyResults = <SearchResult>[];
      
      for (final row in allResults) {
        final title = row['title'] as String;
        final content = row['content'] as String;
        
        // Calculate fuzzy match score
        final titleScore = _calculateFuzzyScore(query, title);
        final contentScore = _calculateFuzzyScore(query, content);
        
        final maxScore = max(titleScore, contentScore);
        
        if (maxScore >= _fuzzyThreshold) {
          fuzzyResults.add(SearchResult(
            id: row['entity_id'] as String,
            type: row['entity_type'] as String,
            title: title,
            snippet: _extractSnippet(content, query),
            score: maxScore,
            metadata: {'fuzzy': true},
          ));
        }
      }
      
      // Sort by score
      fuzzyResults.sort((a, b) => b.score.compareTo(a.score));
      
      return fuzzyResults.take(_maxSearchResults).toList();
    } catch (e) {
      debugPrint('Fuzzy search error: $e');
      return [];
    }
  }

  double _calculateFuzzyScore(String query, String text) {
    // Levenshtein distance-based scoring
    final distance = _levenshteinDistance(
      query.toLowerCase(),
      text.toLowerCase(),
    );
    
    final maxLength = max(query.length, text.length);
    if (maxLength == 0) return 0;
    
    return 1 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }
    
    return matrix[s1.length][s2.length];
  }

  List<SearchResult> _mergeResults(
    List<SearchResult> primary,
    List<SearchResult> secondary,
  ) {
    final merged = <String, SearchResult>{};
    
    // Add primary results
    for (final result in primary) {
      merged[result.id] = result;
    }
    
    // Add secondary results if not already present
    for (final result in secondary) {
      if (!merged.containsKey(result.id)) {
        merged[result.id] = result;
      }
    }
    
    // Sort by score
    final results = merged.values.toList();
    results.sort((a, b) => b.score.compareTo(a.score));
    
    return results;
  }

  List<SearchResult> _applyFilters(
    List<SearchResult> results,
    List<SearchFilter> filters,
  ) {
    var filtered = results;
    
    for (final filter in filters) {
      filtered = filtered.where((result) {
        switch (filter.type) {
          case FilterType.equals:
            return result.metadata[filter.field] == filter.value;
          case FilterType.contains:
            final fieldValue = result.metadata[filter.field]?.toString() ?? '';
            return fieldValue.contains(filter.value.toString());
          case FilterType.range:
            final value = result.metadata[filter.field];
            if (value == null) return false;
            final rangeFilter = filter.value as RangeValue;
            return value >= rangeFilter.min && value <= rangeFilter.max;
          case FilterType.dateRange:
            final dateValue = result.metadata[filter.field];
            if (dateValue == null) return false;
            final dateFilter = filter.value as DateRangeValue;
            final date = DateTime.parse(dateValue.toString());
            return date.isAfter(dateFilter.start) && date.isBefore(dateFilter.end);
          default:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  List<SearchResult> _sortResults(List<SearchResult> results, SearchSort sort) {
    final sorted = List<SearchResult>.from(results);
    
    sorted.sort((a, b) {
      dynamic aValue = a.metadata[sort.field] ?? a.score;
      dynamic bValue = b.metadata[sort.field] ?? b.score;
      
      int comparison = 0;
      if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }
      
      return sort.ascending ? comparison : -comparison;
    });
    
    return sorted;
  }

  String _cleanQuery(String query) {
    return query.trim().toLowerCase();
  }

  String _expandWithSynonyms(String query) {
    // Simple synonym expansion
    final synonyms = {
      'doctor': ['physician', 'md', 'doc'],
      'patient': ['client', 'case'],
      'appointment': ['meeting', 'visit', 'consultation'],
      'urgent': ['emergency', 'critical', 'immediate'],
    };
    
    String expanded = query;
    
    for (final entry in synonyms.entries) {
      if (query.contains(entry.key)) {
        final synonymList = entry.value.join(' OR ');
        expanded = expanded.replaceAll(entry.key, '(${entry.key} OR $synonymList)');
      }
    }
    
    return expanded;
  }

  String _buildFTSQuery(String query) {
    // Build FTS5 query with proper syntax
    final terms = query.split(' ').where((t) => t.isNotEmpty);
    
    if (terms.isEmpty) return '*';
    
    // Use NEAR operator for multi-term queries
    if (terms.length > 1) {
      return terms.join(' NEAR ');
    }
    
    // Use prefix search for single terms
    return '${terms.first}*';
  }

  double _calculateScore(double rank) {
    // Convert FTS5 rank to a 0-1 score
    return 1 / (1 + (-rank));
  }

  String _extractSnippet(String content, String query, {int maxLength = 150}) {
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();
    
    final index = contentLower.indexOf(queryLower);
    if (index == -1) {
      return content.length > maxLength 
          ? '${content.substring(0, maxLength)}...'
          : content;
    }
    
    final start = (index - 50).clamp(0, content.length);
    final end = (index + query.length + 100).clamp(0, content.length);
    
    String snippet = content.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';
    
    return snippet;
  }

  Future<List<SearchSuggestion>> _getIndexSuggestions(String query, int limit) async {
    try {
      final results = await _database!.rawQuery('''
        SELECT DISTINCT title
        FROM search_index
        WHERE title LIKE ?
        LIMIT ?
      ''', ['%$query%', limit]);
      
      return results.map((row) => SearchSuggestion(
        text: row['title'] as String,
        type: SuggestionType.content,
        score: 0.6,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchSuggestion>> _getAISuggestions(String query, int limit) async {
    // Simulated AI suggestions based on patterns
    final suggestions = <SearchSuggestion>[];
    
    // Medical specialty suggestions
    if (query.contains('card')) {
      suggestions.add(SearchSuggestion(
        text: 'cardiology',
        type: SuggestionType.ai,
        score: 0.9,
      ));
      suggestions.add(SearchSuggestion(
        text: 'cardiac surgeon',
        type: SuggestionType.ai,
        score: 0.85,
      ));
    }
    
    // Status suggestions
    if (query.contains('pend')) {
      suggestions.add(SearchSuggestion(
        text: 'pending referrals',
        type: SuggestionType.ai,
        score: 0.9,
      ));
    }
    
    return suggestions.take(limit).toList();
  }

  Future<Map<String, int>> _calculateFacetCounts(
    List<SearchResult> results,
    SearchFacet facet,
    Map<String, List<String>>? selectedFacets,
  ) async {
    final counts = <String, int>{};
    
    for (final result in results) {
      final value = result.metadata[facet.field]?.toString();
      if (value != null) {
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  List<SearchResult> _applyFacetFilters(
    List<SearchResult> results,
    Map<String, List<String>> selectedFacets,
  ) {
    var filtered = results;
    
    for (final entry in selectedFacets.entries) {
      final field = entry.key;
      final values = entry.value;
      
      if (values.isNotEmpty) {
        filtered = filtered.where((result) {
          final resultValue = result.metadata[field]?.toString();
          return resultValue != null && values.contains(resultValue);
        }).toList();
      }
    }
    
    return filtered;
  }

  Future<void> _buildSearchIndexes() async {
    // Build indexes for different entity types
    await _indexPatients();
    await _indexReferrals();
    await _indexDoctors();
  }

  Future<void> _indexPatients() async {
    try {
      final patients = await _database!.query('patients');
      
      for (final patient in patients) {
        await _database!.insert('search_index', {
          'entity_id': patient['patient_id'],
          'entity_type': 'patient',
          'title': '${patient['first_name']} ${patient['last_name']}',
          'content': '${patient['email']} ${patient['phone']} ${patient['medical_history']}',
          'tags': patient['tags'],
          'metadata': jsonEncode({
            'created_at': patient['created_at'],
            'status': patient['status'],
          }),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Error indexing patients: $e');
    }
  }

  Future<void> _indexReferrals() async {
    try {
      final referrals = await _database!.query('referrals');
      
      for (final referral in referrals) {
        await _database!.insert('search_index', {
          'entity_id': referral['referral_id'],
          'entity_type': 'referral',
          'title': 'Referral ${referral['referral_id']}',
          'content': '${referral['reason']} ${referral['notes']}',
          'tags': referral['urgency'],
          'metadata': jsonEncode({
            'created_at': referral['created_at'],
            'status': referral['status'],
            'priority': referral['urgency'],
          }),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Error indexing referrals: $e');
    }
  }

  Future<void> _indexDoctors() async {
    try {
      final doctors = await _database!.query('doctors');
      
      for (final doctor in doctors) {
        await _database!.insert('search_index', {
          'entity_id': doctor['doctor_id'],
          'entity_type': 'doctor',
          'title': '${doctor['first_name']} ${doctor['last_name']}',
          'content': '${doctor['specialization']} ${doctor['hospital']}',
          'tags': doctor['specialization'],
          'metadata': jsonEncode({
            'experience': doctor['experience_years'],
            'rating': doctor['rating'],
          }),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Error indexing doctors: $e');
    }
  }

  Future<void> _saveToHistory(String query, int resultCount) async {
    try {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      
      if (_recentSearches.length > _recentSearchLimit) {
        _recentSearches.removeLast();
      }
      
      await _database!.insert('recent_searches', {
        'id': 'recent_${DateTime.now().millisecondsSinceEpoch}',
        'query': query,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'result_count': resultCount,
      });
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  Future<void> _trackSearch(String query, int resultCount, int durationMs) async {
    try {
      _totalSearches++;
      _searchFrequency[query] = (_searchFrequency[query] ?? 0) + 1;
      
      final analytics = SearchAnalytics(
        id: 'analytics_${DateTime.now().millisecondsSinceEpoch}',
        query: query,
        resultCount: resultCount,
        durationMs: durationMs,
        timestamp: DateTime.now(),
      );
      
      _searchHistory.add(analytics);
      
      await _database!.insert('search_analytics', analytics.toMap());
    } catch (e) {
      debugPrint('Error tracking search: $e');
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final results = await _database!.query(
        'recent_searches',
        orderBy: 'timestamp DESC',
        limit: _recentSearchLimit,
      );
      
      _recentSearches.clear();
      _recentSearches.addAll(results.map((r) => r['query'] as String));
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _loadSavedSearches() async {
    try {
      final results = await _database!.query('saved_searches');
      
      for (final row in results) {
        final savedSearch = SavedSearch.fromMap(row);
        _savedSearches[savedSearch.id] = savedSearch;
      }
    } catch (e) {
      debugPrint('Error loading saved searches: $e');
    }
  }

  @override
  void dispose() {
    _suggestionDebouncer?.cancel();
    super.dispose();
  }
}

// Data Models

class SearchResults {
  final List<SearchResult> results;
  final int totalCount;
  final String query;
  final int? executionTime;

  SearchResults({
    required this.results,
    required this.totalCount,
    required this.query,
    this.executionTime,
  });
}

class SearchResult {
  final String id;
  final String type;
  final String title;
  final String? snippet;
  final double score;
  final Map<String, dynamic> metadata;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.snippet,
    required this.score,
    required this.metadata,
  });
}

class SearchFilter {
  final String field;
  final FilterType type;
  final dynamic value;

  SearchFilter({
    required this.field,
    required this.type,
    required this.value,
  });
}

enum FilterType {
  equals,
  contains,
  range,
  dateRange,
}

class SearchSort {
  final String field;
  final bool ascending;

  SearchSort({
    required this.field,
    this.ascending = true,
  });
}

class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final double score;

  SearchSuggestion({
    required this.text,
    required this.type,
    required this.score,
  });
}

enum SuggestionType {
  recent,
  content,
  ai,
}

class SavedSearch {
  final String id;
  final String name;
  final String query;
  final List<SearchFilter>? filters;
  final SearchSort? sortBy;
  final String? userId;
  final DateTime createdAt;
  DateTime? lastUsed;

  SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    this.filters,
    this.sortBy,
    this.userId,
    required this.createdAt,
    this.lastUsed,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'query': query,
    'filters': filters != null ? jsonEncode(filters!.map((f) => {
      'field': f.field,
      'type': f.type.toString(),
      'value': f.value,
    }).toList()) : null,
    'sort_by': sortBy != null ? jsonEncode({
      'field': sortBy!.field,
      'ascending': sortBy!.ascending,
    }) : null,
    'user_id': userId,
    'created_at': createdAt.millisecondsSinceEpoch,
    'last_used': lastUsed?.millisecondsSinceEpoch,
  };

  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    List<SearchFilter>? filters;
    if (map['filters'] != null) {
      final filterList = jsonDecode(map['filters']) as List;
      filters = filterList.map((f) => SearchFilter(
        field: f['field'],
        type: FilterType.values.firstWhere((t) => t.toString() == f['type']),
        value: f['value'],
      )).toList();
    }
    
    SearchSort? sortBy;
    if (map['sort_by'] != null) {
      final sortData = jsonDecode(map['sort_by']);
      sortBy = SearchSort(
        field: sortData['field'],
        ascending: sortData['ascending'],
      );
    }
    
    return SavedSearch(
      id: map['id'],
      name: map['name'],
      query: map['query'],
      filters: filters,
      sortBy: sortBy,
      userId: map['user_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUsed: map['last_used'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used'])
          : null,
    );
  }
}

class SearchFacet {
  final String field;
  final String label;
  final FacetType type;

  SearchFacet({
    required this.field,
    required this.label,
    required this.type,
  });
}

enum FacetType {
  string,
  number,
  date,
  boolean,
}

class FacetResult {
  final SearchFacet facet;
  final Map<String, int> values;

  FacetResult({
    required this.facet,
    required this.values,
  });
}

class FacetedSearchResults {
  final List<SearchResult> results;
  final Map<String, FacetResult> facets;
  final int totalCount;
  final String query;

  FacetedSearchResults({
    required this.results,
    required this.facets,
    required this.totalCount,
    required this.query,
  });
}

class SearchAnalytics {
  final String id;
  final String query;
  final int resultCount;
  final int durationMs;
  final DateTime timestamp;

  SearchAnalytics({
    required this.id,
    required this.query,
    required this.resultCount,
    required this.durationMs,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'query': query,
    'result_count': resultCount,
    'duration_ms': durationMs,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
}

class SearchAnalyticsSummary {
  final int totalSearches;
  final List<QueryFrequency> topQueries;
  final double averageResultCount;
  final int averageDuration;

  SearchAnalyticsSummary({
    required this.totalSearches,
    required this.topQueries,
    required this.averageResultCount,
    required this.averageDuration,
  });
}

class QueryFrequency {
  final String query;
  final int count;

  QueryFrequency({
    required this.query,
    required this.count,
  });
}

class RangeValue {
  final num min;
  final num max;

  RangeValue({
    required this.min,
    required this.max,
  });
}

class DateRangeValue {
  final DateTime start;
  final DateTime end;

  DateRangeValue({
    required this.start,
    required this.end,
  });
}

class SearchIndex {
  final String entityType;
  final int documentCount;
  final DateTime lastUpdated;

  SearchIndex({
    required this.entityType,
    required this.documentCount,
    required this.lastUpdated,
  });
}

class SearchException implements Exception {
  final String message;
  SearchException(this.message);
  
  @override
  String toString() => 'SearchException: $message';
}