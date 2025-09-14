import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../database/models/pharmacy_drug.dart';
import '../../services/pharmacy_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  Map<String, PharmacyDrug> _drugs = {};
  bool _isLoading = true;
  double _subtotal = 0.0;
  double _deliveryFee = 5.99;
  double _tax = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);
    
    try {
      final pharmacyService = Provider.of<PharmacyService>(context, listen: false);
      final cartItems = await pharmacyService.getCartItems('current_user_id');
      
      // Load drug details for each cart item
      final drugMap = <String, PharmacyDrug>{};
      for (final item in cartItems) {
        final drug = await pharmacyService.getDrugById(item.drugId);
        if (drug != null) {
          drugMap[item.drugId] = drug;
        }
      }
      
      setState(() {
        _cartItems = cartItems;
        _drugs = drugMap;
        _isLoading = false;
      });
      
      _calculateTotals();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart: $e')),
      );
    }
  }

  void _calculateTotals() {
    _subtotal = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    _deliveryFee = _subtotal >= 50.0 ? 0.0 : 5.99;
    _tax = _subtotal * 0.08; // 8% tax
    _total = _subtotal + _deliveryFee + _tax;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      feature: 'pharmacy_purchase',
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      bottomNavigationBar: _cartItems.isNotEmpty ? _buildBottomBar() : null,
    ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
      ),
    );
  }

  Widget _buildContent() {
    if (_cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        // Cart items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = _cartItems[index];
              final drug = _drugs[cartItem.drugId];
              
              if (drug == null) return SizedBox.shrink();
              
              return _buildCartItemCard(cartItem, drug);
            },
          ),
        ),
        
        // Order summary
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 3.h),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add some medicines to get started',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.pharmacyScreen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Pharmacy',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem cartItem, PharmacyDrug drug) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drug image
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: drug.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      drug.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.medication,
                          color: AppTheme.primaryLight,
                          size: 24.sp,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.medication,
                    color: AppTheme.primaryLight,
                    size: 24.sp,
                  ),
          ),
          
          SizedBox(width: 3.w),
          
          // Drug details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${drug.genericName} ${drug.strength}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '\$${cartItem.unitPrice.toStringAsFixed(2)} each',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity controls and total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _updateQuantity(cartItem, cartItem.quantity - 1),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: Icon(
                          Icons.remove,
                          size: 16.sp,
                          color: cartItem.quantity > 1 ? AppTheme.primaryLight : Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Text(
                        '${cartItem.quantity}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateQuantity(cartItem, cartItem.quantity + 1),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: Icon(
                          Icons.add,
                          size: 16.sp,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 1.h),
              
              // Total price
              Text(
                '\$${cartItem.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              
              // Remove button
              GestureDetector(
                onTap: () => _removeItem(cartItem),
                child: Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          
          _buildSummaryRow('Subtotal', _subtotal),
          _buildSummaryRow('Delivery Fee', _deliveryFee),
          if (_deliveryFee == 0.0)
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Text(
                'Free delivery on orders over \$50',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          _buildSummaryRow('Tax', _tax),
          
          Divider(height: 3.h),
          
          _buildSummaryRow('Total', _total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.primaryLight : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _proceedToCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 4.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Proceed to Checkout • \$${_total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _updateQuantity(CartItem cartItem, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(cartItem);
      return;
    }

    try {
      final pharmacyService = Provider.of<PharmacyService>(context, listen: false);
      await pharmacyService.updateCartItemQuantity(cartItem.id, newQuantity);
      await _loadCartData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: $e')),
      );
    }
  }

  Future<void> _removeItem(CartItem cartItem) async {
    try {
      final pharmacyService = Provider.of<PharmacyService>(context, listen: false);
      await pharmacyService.removeFromCart(cartItem.id);
      await _loadCartData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: $e')),
      );
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart'),
        content: Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final pharmacyService = Provider.of<PharmacyService>(context, listen: false);
        await pharmacyService.clearCart('current_user_id');
        await _loadCartData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cart: $e')),
        );
      }
    }
  }

  void _proceedToCheckout() {
    Navigator.pushNamed(
      context,
      AppRoutes.checkoutScreen,
      arguments: {
        'cartItems': _cartItems,
        'drugs': _drugs,
        'total': _total,
      },
    );
  }
}
