import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../database/models/pharmacy_drug.dart';
import '../../services/pharmacy_service.dart';
import 'widgets/drug_card_widget.dart';
import 'widgets/category_chip_widget.dart';
import 'widgets/search_bar_widget.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<PharmacyDrug> _drugs = [];
  List<PharmacyDrug> _filteredDrugs = [];
  List<String> _categories = ['All'];
  bool _isLoading = true;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final pharmacyService = Provider.of<PharmacyService>(context, listen: false);
      
      // Load drugs and categories
      final drugs = await pharmacyService.getAllDrugs();
      final categories = await pharmacyService.getCategories();
      final cartCount = await pharmacyService.getCartItemCount('current_user_id');
      
      setState(() {
        _drugs = drugs;
        _filteredDrugs = drugs;
        _categories = ['All', ...categories];
        _cartItemCount = cartCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pharmacy data: $e')),
      );
    }
  }

  void _filterDrugs() {
    setState(() {
      _filteredDrugs = _drugs.where((drug) {
        final matchesSearch = _searchController.text.isEmpty ||
            drug.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            drug.genericName.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'All' || drug.category == _selectedCategory;
        
        return matchesSearch && matchesCategory && drug.isAvailable;
      }).toList();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      feature: 'pharmacy',
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Pharmacy',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
        ),
      ),
      backgroundColor: AppTheme.primaryLight,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.cartScreen);
              },
              icon: Icon(Icons.shopping_cart, color: Colors.white),
            ),
            if (_cartItemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_cartItemCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading pharmacy...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search and filters
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.05),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Search bar
              SearchBarWidget(
                controller: _searchController,
                onChanged: (value) => _filterDrugs(),
                hintText: 'Search medicines...',
              ),
              SizedBox(height: 2.h),
              
              // Category chips
              SizedBox(
                height: 5.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 2.w),
                      child: CategoryChipWidget(
                        label: category,
                        isSelected: _selectedCategory == category,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _filterDrugs();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Popular drugs section
        if (_selectedCategory == 'All') ...[
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Medicines',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show all popular medicines
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(
            height: 25.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _filteredDrugs.where((d) => d.isPopular).length,
              itemBuilder: (context, index) {
                final popularDrugs = _filteredDrugs.where((d) => d.isPopular).toList();
                if (index >= popularDrugs.length) return SizedBox.shrink();
                
                return Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: SizedBox(
                    width: 40.w,
                    child: DrugCardWidget(
                      drug: popularDrugs[index],
                      onTap: () => _navigateToDrugDetail(popularDrugs[index]),
                      onAddToCart: () => _addToCart(popularDrugs[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 2.h),
        ],
        
        // All medicines section
        Expanded(
          child: _filteredDrugs.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: EdgeInsets.all(4.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                  ),
                  itemCount: _filteredDrugs.length,
                  itemBuilder: (context, index) {
                    return DrugCardWidget(
                      drug: _filteredDrugs[index],
                      onTap: () => _navigateToDrugDetail(_filteredDrugs[index]),
                      onAddToCart: () => _addToCart(_filteredDrugs[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2.h),
          Text(
            'No medicines found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDrugDetail(PharmacyDrug drug) {
    Navigator.pushNamed(
      context,
      AppRoutes.drugDetailScreen,
      arguments: {'drug': drug},
    );
  }

  Future<void> _addToCart(PharmacyDrug drug) async {
    try {
      final pharmacyService = Provider.of<PharmacyService>(context, listen: false);
      await pharmacyService.addToCart(
        drugId: drug.id,
        userId: 'current_user_id',
        quantity: 1,
        unitPrice: drug.discountedPrice,
      );
      
      setState(() {
        _cartItemCount++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${drug.name} added to cart'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cartScreen);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
