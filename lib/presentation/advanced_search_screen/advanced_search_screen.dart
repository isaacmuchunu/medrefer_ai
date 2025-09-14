import 'package:flutter/material.dart';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/services/advanced_search_service.dart';
import 'package:medrefer_ai/database/models/search_models.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with TickerProviderStateMixin {
  late AdvancedSearchService _searchService;
  late TabController _tabController;
  late TextEditingController _searchController;
  
  List<SearchResult> _searchResults = [];
  List<SearchFacet> _facets = [];
  List<SearchSuggestion> _suggestions = [];
  List<SavedSearch> _savedSearches = [];
  Map<String, dynamic> _currentFilters = {};
  List<String> _selectedEntityTypes = [];
  
  bool _isLoading = false;
  bool _showSuggestions = false;
  String _sortBy = 'score';
  String _sortOrder = 'desc';
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalResults = 0;

  @override
  void initState() {
    super.initState();
    _searchService = AdvancedSearchService();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _searchService.initialize();
      await _loadSavedSearches();
      _searchService.addListener(_onSearchUpdate);
    } catch (e) {
      debugPrint('Error initializing advanced search screen: $e');
    }
  }

  void _onSearchUpdate() {
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    final savedSearches = _searchService.getSavedSearches();
    setState(() => _savedSearches = savedSearches);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.gray50,
      appBar: AppBar(
        title: Text(
          'Advanced Search',
          style: AppStyle.txtInterBold24,
        ),
        backgroundColor: ColorConstant.whiteA700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _showSearchAnalytics,
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _showSaveSearchDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Saved', icon: Icon(Icons.bookmark)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildSavedSearchesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? _buildEmptyState()
                  : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: ColorConstant.whiteA700,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients, referrals, users, documents...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showSuggestions = false;
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            onChanged: _onSearchTextChanged,
            onSubmitted: _performSearch,
            onTap: () {
              setState(() => _showSuggestions = true);
            },
          ),
          if (_showSuggestions && _suggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8.h),
              decoration: BoxDecoration(
                color: ColorConstant.whiteA700,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _suggestions.map((suggestion) => ListTile(
                  leading: Icon(_getSuggestionIcon(suggestion.type)),
                  title: Text(suggestion.text),
                  subtitle: Text(suggestion.type),
                  onTap: () {
                    _searchController.text = suggestion.text;
                    setState(() => _showSuggestions = false);
                    _performSearch(suggestion.text);
                  },
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: ColorConstant.whiteA700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filters', style: AppStyle.txtInterBold16),
              Spacer(),
              if (_currentFilters.isNotEmpty || _selectedEntityTypes.isNotEmpty)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text('Clear All'),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildEntityTypeFilter(),
              _buildSortFilter(),
              _buildPageSizeFilter(),
            ],
          ),
          if (_facets.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text('Facets', style: AppStyle.txtInterBold14),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _facets.map((facet) => _buildFacetChip(facet)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntityTypeFilter() {
    return FilterChip(
      label: Text('Entity Types'),
      selected: _selectedEntityTypes.isNotEmpty,
      onSelected: (selected) {
        if (selected) {
          _showEntityTypeDialog();
        } else {
          setState(() => _selectedEntityTypes = []);
          _performSearch();
        }
      },
    );
  }

  Widget _buildSortFilter() {
    return FilterChip(
      label: Text('Sort: $_sortBy'),
      selected: _sortBy != 'score',
      onSelected: (selected) {
        _showSortDialog();
      },
    );
  }

  Widget _buildPageSizeFilter() {
    return FilterChip(
      label: Text('Page Size: $_pageSize'),
      selected: _pageSize != 20,
      onSelected: (selected) {
        _showPageSizeDialog();
      },
    );
  }

  Widget _buildFacetChip(SearchFacet facet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          facet.displayName,
          style: AppStyle.txtInterBold12,
        ),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 4.w,
          runSpacing: 4.h,
          children: facet.values.take(5).map((value) => 
            ActionChip(
              label: Text('${value.displayValue} (${value.count})'),
              onPressed: () => _toggleFacetFilter(facet.field, value.value),
              backgroundColor: value.isSelected 
                  ? ColorConstant.blue600.withOpacity(0.2)
                  : null,
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: ColorConstant.whiteA700,
          child: Row(
            children: [
              Text(
                '$_totalResults results found',
                style: AppStyle.txtInterMedium14,
              ),
              Spacer(),
              Text(
                'Page $_currentPage',
                style: AppStyle.txtInterRegular12.copyWith(
                  color: ColorConstant.gray600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildSearchResultCard(result);
            },
          ),
        ),
        if (_searchResults.length >= _pageSize)
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                if (_currentPage > 1)
                  ElevatedButton(
                    onPressed: _loadPreviousPage,
                    child: Text('Previous'),
                  ),
                Spacer(),
                ElevatedButton(
                  onPressed: _loadNextPage,
                  child: Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEntityTypeColor(result.entityType),
          child: Icon(
            _getEntityTypeIcon(result.entityType),
            color: Colors.white,
          ),
        ),
        title: Text(
          result.title,
          style: AppStyle.txtInterMedium14.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.description,
              style: AppStyle.txtInterRegular12,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _buildEntityTypeChip(result.entityType),
                SizedBox(width: 8.w),
                if (result.metadata['department'] != null)
                  _buildDepartmentChip(result.metadata['department']),
                Spacer(),
                Text(
                  'Score: ${result.score.toStringAsFixed(2)}',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
            if (result.highlights.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                'Highlights: ${result.highlights.join(', ')}',
                style: AppStyle.txtInterRegular10.copyWith(
                  color: ColorConstant.blue600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onSearchResultAction(value, result),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('View Details')),
            PopupMenuItem(value: 'save', child: Text('Save Search')),
            PopupMenuItem(value: 'share', child: Text('Share')),
          ],
        ),
        onTap: () => _onSearchResultTap(result),
      ),
    );
  }

  Widget _buildEntityTypeChip(String entityType) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _getEntityTypeColor(entityType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _getEntityTypeColor(entityType).withOpacity(0.3)),
      ),
      child: Text(
        entityType.toUpperCase(),
        style: AppStyle.txtInterBold10.copyWith(
          color: _getEntityTypeColor(entityType),
        ),
      ),
    );
  }

  Widget _buildDepartmentChip(String department) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ColorConstant.gray600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorConstant.gray600.withOpacity(0.3)),
      ),
      child: Text(
        department,
        style: AppStyle.txtInterBold10.copyWith(
          color: ColorConstant.gray600,
        ),
      ),
    );
  }

  Widget _buildSavedSearchesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _savedSearches.length,
      itemBuilder: (context, index) {
        final savedSearch = _savedSearches[index];
        return _buildSavedSearchCard(savedSearch);
      },
    );
  }

  Widget _buildSavedSearchCard(SavedSearch savedSearch) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Icon(Icons.bookmark, color: ColorConstant.blue600),
        title: Text(
          savedSearch.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              savedSearch.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  'Query: ${savedSearch.query}',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray600,
                  ),
                ),
                Spacer(),
                Text(
                  'Used ${savedSearch.useCount} times',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
            if (savedSearch.tags.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Wrap(
                spacing: 4.w,
                children: savedSearch.tags.map((tag) => 
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ColorConstant.blue600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      tag,
                      style: AppStyle.txtInterBold10.copyWith(
                        color: ColorConstant.blue600,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onSavedSearchAction(value, savedSearch),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'execute', child: Text('Execute')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'share', child: Text('Share')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _executeSavedSearch(savedSearch),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 10, // Mock history count
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.history),
          title: Text('Search Query ${index + 1}'),
          subtitle: Text('2 hours ago'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Implement history search execution
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: ColorConstant.gray400),
          SizedBox(height: 16.h),
          Text(
            'No search results',
            style: AppStyle.txtInterBold18.copyWith(color: ColorConstant.gray400),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search terms or filters',
            style: AppStyle.txtInterRegular14.copyWith(color: ColorConstant.gray500),
          ),
        ],
      ),
    );
  }

  Color _getEntityTypeColor(String entityType) {
    switch (entityType) {
      case 'patient':
        return Colors.blue;
      case 'referral':
        return Colors.green;
      case 'user':
        return Colors.orange;
      case 'document':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getEntityTypeIcon(String entityType) {
    switch (entityType) {
      case 'patient':
        return Icons.person;
      case 'referral':
        return Icons.assignment;
      case 'user':
        return Icons.account_circle;
      case 'document':
        return Icons.description;
      default:
        return Icons.help;
    }
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'query':
        return Icons.search;
      case 'entity':
        return Icons.person;
      case 'filter':
        return Icons.filter_list;
      default:
        return Icons.help;
    }
  }

  void _onSearchTextChanged(String text) {
    if (text.isNotEmpty) {
      // Get suggestions
      final suggestions = _searchService.getSuggestions(text);
      setState(() => _suggestions = suggestions);
    } else {
      setState(() => _suggestions = []);
    }
  }

  Future<void> _performSearch([String? query]) async {
    final searchQuery = query ?? _searchController.text;
    if (searchQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      final results = await _searchService.search(
        query: searchQuery,
        entityTypes: _selectedEntityTypes.isEmpty ? null : _selectedEntityTypes,
        filters: _currentFilters,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _searchResults = results['results'] as List<SearchResult>;
        _facets = results['facets'] as List<SearchFacet>;
        _totalResults = results['total_count'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = {};
      _selectedEntityTypes = [];
    });
    _performSearch();
  }

  void _toggleFacetFilter(String field, String value) {
    setState(() {
      if (_currentFilters[field] == value) {
        _currentFilters.remove(field);
      } else {
        _currentFilters[field] = value;
      }
    });
    _performSearch();
  }

  void _showEntityTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Entity Types'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Patients'),
                  value: _selectedEntityTypes.contains('patient'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedEntityTypes.add('patient');
                      } else {
                        _selectedEntityTypes.remove('patient');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Referrals'),
                  value: _selectedEntityTypes.contains('referral'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedEntityTypes.add('referral');
                      } else {
                        _selectedEntityTypes.remove('referral');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Users'),
                  value: _selectedEntityTypes.contains('user'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedEntityTypes.add('user');
                      } else {
                        _selectedEntityTypes.remove('user');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Documents'),
                  value: _selectedEntityTypes.contains('document'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedEntityTypes.add('document');
                      } else {
                        _selectedEntityTypes.remove('document');
                      }
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Relevance'),
              value: 'score',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _performSearch();
              },
            ),
            RadioListTile<String>(
              title: Text('Title'),
              value: 'title',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _performSearch();
              },
            ),
            RadioListTile<String>(
              title: Text('Date'),
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _performSearch();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPageSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Page Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [10, 20, 50, 100].map((size) => 
            RadioListTile<int>(
              title: Text('$size results'),
              value: size,
              groupValue: _pageSize,
              onChanged: (value) {
                setState(() => _pageSize = value!);
                Navigator.pop(context);
                _performSearch();
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  void _showSaveSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement save search
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSearchAnalytics() {
    final analytics = _searchService.getSearchAnalytics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Analytics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsRow('Total Searches', analytics['total_searches'].toString()),
              _buildAnalyticsRow('Total Results', analytics['total_results'].toString()),
              _buildAnalyticsRow('Average Response Time', '${analytics['average_response_time'].toStringAsFixed(2)}ms'),
              _buildAnalyticsRow('Saved Searches', analytics['saved_searches_count'].toString()),
              _buildAnalyticsRow('Suggestions', analytics['suggestions_count'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyle.txtInterMedium14),
          Text(value, style: AppStyle.txtInterBold14.copyWith(color: ColorConstant.blue600)),
        ],
      ),
    );
  }

  void _onSearchResultAction(String action, SearchResult result) {
    switch (action) {
      case 'view':
        _onSearchResultTap(result);
        break;
      case 'save':
        _showSaveSearchDialog();
        break;
      case 'share':
        // Implement share functionality
        break;
    }
  }

  void _onSearchResultTap(SearchResult result) {
    // Implement result tap navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${result.title}')),
    );
  }

  void _onSavedSearchAction(String action, SavedSearch savedSearch) {
    switch (action) {
      case 'execute':
        _executeSavedSearch(savedSearch);
        break;
      case 'edit':
        _showEditSavedSearchDialog(savedSearch);
        break;
      case 'share':
        // Implement share functionality
        break;
      case 'delete':
        _showDeleteSavedSearchDialog(savedSearch);
        break;
    }
  }

  void _executeSavedSearch(SavedSearch savedSearch) {
    _searchController.text = savedSearch.query;
    _selectedEntityTypes = savedSearch.entityTypes;
    _currentFilters = savedSearch.filters;
    _sortBy = savedSearch.sortBy;
    _sortOrder = savedSearch.sortOrder;
    
    _performSearch(savedSearch.query);
    _tabController.animateTo(0);
  }

  void _showEditSavedSearchDialog(SavedSearch savedSearch) {
    // Implement edit saved search dialog
  }

  void _showDeleteSavedSearchDialog(SavedSearch savedSearch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Saved Search'),
        content: Text('Are you sure you want to delete "${savedSearch.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement delete functionality
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _loadPreviousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      _performSearch();
    }
  }

  void _loadNextPage() {
    setState(() => _currentPage++);
    _performSearch();
  }

  @override
  void dispose() {
    _searchService.removeListener(_onSearchUpdate);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}