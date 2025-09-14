import '../../core/app_export.dart';

class SpecialistSelectionScreen extends StatefulWidget {
  final String? department;
  final bool isSelectionMode;
  final Function(Specialist)? onSpecialistSelected;
  
  const SpecialistSelectionScreen({
    Key? key,
    this.department,
    this.isSelectionMode = false,
    this.onSpecialistSelected,
  }) : super(key: key);

  @override
  _SpecialistSelectionScreenState createState() => _SpecialistSelectionScreenState();
}

class _SpecialistSelectionScreenState extends State<SpecialistSelectionScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Specialist> _allSpecialists = [];
  List<Specialist> _filteredSpecialists = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;
  
  final List<String> _filterOptions = ['All', 'Available', 'Highly Rated', 'Experienced'];
  final List<String> _sortOptions = ['Name', 'Rating', 'Experience', 'Availability'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSpecialists();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _loadSpecialists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final specialists = await dataService.getSpecialists(department: widget.department);
      
      setState(() {
        _allSpecialists = specialists;
        _filteredSpecialists = specialists;
        _isLoading = false;
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load specialists'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<Specialist> filtered = List.from(_allSpecialists);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((specialist) {
        return specialist.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               specialist.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               specialist.hospital.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               specialist.credentials.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply category filter
    switch (_selectedFilter) {
      case 'Available':
        filtered = filtered.where((specialist) => specialist.isAvailable).toList();
        break;
      case 'Highly Rated':
        filtered = filtered.where((specialist) => specialist.rating >= 4.5).toList();
        break;
      case 'Experienced':
        filtered = filtered.where((specialist) => specialist.yearsOfExperience >= 10).toList();
        break;
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'Name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'Rating':
          comparison = a.rating.compareTo(b.rating);
          break;
        case 'Experience':
          comparison = a.yearsOfExperience.compareTo(b.yearsOfExperience);
          break;
        case 'Availability':
          comparison = a.isAvailable == b.isAvailable ? 0 : (a.isAvailable ? -1 : 1);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredSpecialists = filtered;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isSelectionMode ? 'Select Specialist' : 'Specialists',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                // Search and Filter Section
                _buildSearchSection(theme),
                
                // Department Header
                if (widget.department != null)
                  _buildDepartmentHeader(theme),
                
                // Results Section
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(theme)
                      : _filteredSpecialists.isEmpty
                          ? _buildEmptyState(theme)
                          : _buildSpecialistList(theme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search specialists by name, specialty, or hospital...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter and Sort Row
          Row(
            children: [
              // Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: Icon(Icons.filter_list, size: 20),
                      items: _filterOptions.map((filter) {
                        return DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                        _applyFiltersAndSort();
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Sort Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: Icon(Icons.sort, size: 20),
                      items: _sortOptions.map((sort) {
                        return DropdownMenuItem(
                          value: sort,
                          child: Text(sort),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                        _applyFiltersAndSort();
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Sort Direction Button
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                    _applyFiltersAndSort();
                  },
                ),
              ),
            ],
          ),
          
          // Results Count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Text(
                    '${_filteredSpecialists.length} specialist${_filteredSpecialists.length != 1 ? 's' : ''} found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  if (_isSearching || _selectedFilter != 'All')
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedFilter = 'All';
                          _searchQuery = '';
                          _isSearching = false;
                        });
                        _applyFiltersAndSort();
                      },
                      child: Text('Clear Filters'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_hospital,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Department: ${widget.department}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading specialists...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.medical_services_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No specialists found' : 'No specialists available',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try adjusting your search criteria'
                : widget.department != null
                    ? 'No specialists available in ${widget.department}'
                    : 'No specialists available at this time',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSpecialists.length,
      itemBuilder: (context, index) {
        final specialist = _filteredSpecialists[index];
        return _buildSpecialistCard(specialist, theme);
      },
    );
  }

  Widget _buildSpecialistCard(Specialist specialist, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSpecialistTap(specialist),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Specialist Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${specialist.credentials} • ${specialist.specialty}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialist.hospital,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Availability Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: specialist.isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        specialist.isAvailable ? 'Available' : 'Busy',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: specialist.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Rating and Experience
                Row(
                  children: [
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${specialist.rating}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Experience
                    Row(
                      children: [
                        Icon(Icons.work_history, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${specialist.yearsOfExperience} years',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Action Icon
                    Icon(
                      widget.isSelectionMode ? Icons.arrow_forward_ios : Icons.more_vert,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSpecialistTap(Specialist specialist) {
    if (widget.isSelectionMode) {
      widget.onSpecialistSelected?.call(specialist);
      Navigator.pop(context, specialist);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.specialistProfileScreen,
        arguments: {'specialistId': specialist.id},
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Specialists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose filter options:'),
            const SizedBox(height: 16),
            ..._filterOptions.map((filter) => RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                _applyFiltersAndSort();
                Navigator.pop(context);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
