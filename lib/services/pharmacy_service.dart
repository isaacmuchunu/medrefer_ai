import 'package:flutter/foundation.dart';
import '../database/database.dart';

class PharmacyService extends ChangeNotifier {
  final DataService _dataService;
  late PharmacyDAO _pharmacyDAO;
  
  bool _isInitialized = false;
  List<PharmacyDrug> _drugs = [];
  List<CartItem> _cartItems = [];
  List<PharmacyOrder> _orders = [];

  PharmacyService(this._dataService);

  // Getters
  bool get isInitialized => _isInitialized;
  List<PharmacyDrug> get drugs => List.unmodifiable(_drugs);
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  List<PharmacyOrder> get orders => List.unmodifiable(_orders);

  /// Initialize the pharmacy service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _dataService.initialize();
      final db = await _dataService.getDatabase();
      _pharmacyDAO = PharmacyDAO(db);
      
      // Seed initial data if needed
      await _seedInitialData();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('PharmacyService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PharmacyService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Seed initial pharmacy data
  Future<void> _seedInitialData() async {
    // Initialize drug inventory - data will be loaded from external pharmacy APIs
    await _loadDrugInventoryFromAPIs();
  }

  /// Get all available drugs
  Future<List<PharmacyDrug>> getAllDrugs() async {
    _drugs = await _pharmacyDAO.getAvailableDrugs();
    notifyListeners();
    return _drugs;
  }

  /// Get drugs by category
  Future<List<PharmacyDrug>> getDrugsByCategory(String category) async {
    return await _pharmacyDAO.getDrugsByCategory(category);
  }

  /// Get popular drugs
  Future<List<PharmacyDrug>> getPopularDrugs() async {
    return await _pharmacyDAO.getPopularDrugs();
  }

  /// Search drugs
  Future<List<PharmacyDrug>> searchDrugs(String query) async {
    return await _pharmacyDAO.searchDrugs(query);
  }

  /// Get drug by ID
  Future<PharmacyDrug?> getDrugById(String id) async {
    return await _pharmacyDAO.getDrugById(id);
  }

  /// Get all categories
  Future<List<String>> getCategories() async {
    return await _pharmacyDAO.getDrugCategories();
  }

  /// Add drug to cart
  Future<void> addToCart({
    required String drugId,
    required String userId,
    required int quantity,
    required double unitPrice,
    String? prescriptionId,
  }) async {
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      drugId: drugId,
      userId: userId,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      prescriptionId: prescriptionId,
    );

    await _pharmacyDAO.addToCart(cartItem);
    await _loadCartItems(userId);
    
    if (kDebugMode) {
      debugPrint('PharmacyService: Added to cart - Drug: $drugId, Quantity: $quantity');
    }
  }

  /// Get cart items for user
  Future<List<CartItem>> getCartItems(String userId) async {
    _cartItems = await _pharmacyDAO.getCartItems(userId);
    notifyListeners();
    return _cartItems;
  }

  /// Load cart items
  Future<void> _loadCartItems(String userId) async {
    _cartItems = await _pharmacyDAO.getCartItems(userId);
    notifyListeners();
  }

  /// Update cart item quantity
  Future<void> updateCartItemQuantity(String cartItemId, int newQuantity) async {
    final cartItem = _cartItems.firstWhere((item) => item.id == cartItemId);
    final updatedItem = cartItem.copyWith(
      quantity: newQuantity,
      totalPrice: newQuantity * cartItem.unitPrice,
    );
    
    await _pharmacyDAO.updateCartItem(updatedItem);
    await _loadCartItems(cartItem.userId);
  }

  /// Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    final cartItem = _cartItems.firstWhere((item) => item.id == cartItemId);
    await _pharmacyDAO.removeFromCart(cartItemId);
    await _loadCartItems(cartItem.userId);
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    await _pharmacyDAO.clearCart(userId);
    await _loadCartItems(userId);
  }

  /// Get cart total
  Future<double> getCartTotal(String userId) async {
    return await _pharmacyDAO.getCartTotal(userId);
  }

  /// Get cart item count
  Future<int> getCartItemCount(String userId) async {
    return await _pharmacyDAO.getCartItemCount(userId);
  }

  /// Create order
  Future<PharmacyOrder> createOrder({
    required String userId,
    required String deliveryAddress,
    String? prescriptionId,
    String? notes,
  }) async {
    final cartItems = await getCartItems(userId);
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final subtotal = await getCartTotal(userId);
    final deliveryFee = _calculateDeliveryFee(subtotal);
    final tax = _calculateTax(subtotal);
    final totalAmount = subtotal + deliveryFee + tax;

    final order = PharmacyOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      orderNumber: _generateOrderNumber(),
      cartItemIds: cartItems.map((item) => item.id).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      prescriptionId: prescriptionId,
      notes: notes,
    );

    await _pharmacyDAO.createOrder(order);
    await clearCart(userId);
    await _loadOrders(userId);

    if (kDebugMode) {
      debugPrint('PharmacyService: Order created - ${order.orderNumber}');
    }

    return order;
  }

  /// Get user orders
  Future<List<PharmacyOrder>> getUserOrders(String userId) async {
    _orders = await _pharmacyDAO.getUserOrders(userId);
    notifyListeners();
    return _orders;
  }

  /// Load orders
  Future<void> _loadOrders(String userId) async {
    _orders = await _pharmacyDAO.getUserOrders(userId);
    notifyListeners();
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _pharmacyDAO.updateOrderStatus(orderId, status);
    // Reload orders for the user
    final order = await _pharmacyDAO.getOrderById(orderId);
    if (order != null) {
      await _loadOrders(order.userId);
    }
  }

  /// Get order by ID
  Future<PharmacyOrder?> getOrderById(String id) async {
    return await _pharmacyDAO.getOrderById(id);
  }

  /// Calculate delivery fee
  double _calculateDeliveryFee(double subtotal) {
    if (subtotal >= 50.0) return 0.0; // Free delivery over $50
    return 5.99;
  }

  /// Calculate tax
  double _calculateTax(double subtotal) {
    return subtotal * 0.08; // 8% tax
  }

  /// Generate order number
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD${timestamp.toString().substring(8)}';
  }

  /// Load drug inventory from external APIs
  Future<void> _loadDrugInventoryFromAPIs() async {
    try {
      // In production, this would fetch from real pharmacy APIs
      // Example: FDA Drug Database, RxNorm, etc.
      debugPrint('Loading drug inventory from external APIs...');
      
      // For now, check if we have any existing drugs in the database
      final existingDrugs = await _pharmacyDAO.getAllDrugs();
      if (existingDrugs.isNotEmpty) {
        debugPrint('Drug inventory already loaded: ${existingDrugs.length} drugs');
        return;
      }
      
      // In production, implement API calls here:
      // final apiDrugs = await _fetchDrugsFromAPI();
      // for (final drug in apiDrugs) {
      //   await _pharmacyDAO.insertDrug(drug);
      // }
      
      debugPrint('Drug inventory loading completed');
    } catch (e) {
      debugPrint('Error loading drug inventory: $e');
    }
  }

  /// Get sample drugs for seeding (deprecated - use API loading)
  @Deprecated('Use _loadDrugInventoryFromAPIs instead')
  List<PharmacyDrug> _getSampleDrugs() {
    return [
      PharmacyDrug(
        id: 'drug_1',
        name: 'Paracetamol',
        genericName: 'Acetaminophen',
        description: 'Pain reliever and fever reducer',
        category: 'Pain Relief',
        manufacturer: 'MedCorp',
        price: 12.99,
        dosage: '500mg',
        form: 'Tablet',
        strength: '500mg',
        requiresPrescription: false,
        imageUrl: 'https://via.placeholder.com/150x150/0EBE7F/FFFFFF?text=Paracetamol',
        stockQuantity: 100,
        isAvailable: true,
        sideEffects: ['Nausea', 'Stomach upset'],
        contraindications: ['Liver disease'],
        instructions: 'Take 1-2 tablets every 4-6 hours as needed',
        rating: 4.5,
        reviewCount: 150,
        isPopular: true,
        discount: 10.0,
      ),
      PharmacyDrug(
        id: 'drug_2',
        name: 'Ibuprofen',
        genericName: 'Ibuprofen',
        description: 'Anti-inflammatory pain reliever',
        category: 'Pain Relief',
        manufacturer: 'HealthPlus',
        price: 15.99,
        dosage: '400mg',
        form: 'Tablet',
        strength: '400mg',
        requiresPrescription: false,
        imageUrl: 'https://via.placeholder.com/150x150/0165FC/FFFFFF?text=Ibuprofen',
        stockQuantity: 75,
        isAvailable: true,
        sideEffects: ['Stomach irritation', 'Dizziness'],
        contraindications: ['Stomach ulcers', 'Kidney disease'],
        instructions: 'Take 1 tablet every 6-8 hours with food',
        rating: 4.3,
        reviewCount: 89,
        isPopular: true,
        discount: 5.0,
      ),
      PharmacyDrug(
        id: 'drug_3',
        name: 'Amoxicillin',
        genericName: 'Amoxicillin',
        description: 'Antibiotic for bacterial infections',
        category: 'Antibiotics',
        manufacturer: 'PharmaTech',
        price: 24.99,
        dosage: '500mg',
        form: 'Capsule',
        strength: '500mg',
        requiresPrescription: true,
        imageUrl: 'https://via.placeholder.com/150x150/FF7F50/FFFFFF?text=Amoxicillin',
        stockQuantity: 50,
        isAvailable: true,
        sideEffects: ['Diarrhea', 'Nausea', 'Rash'],
        contraindications: ['Penicillin allergy'],
        instructions: 'Take 1 capsule every 8 hours for 7-10 days',
        rating: 4.7,
        reviewCount: 203,
        isPopular: false,
        discount: 0.0,
      ),
      PharmacyDrug(
        id: 'drug_4',
        name: 'Vitamin D3',
        genericName: 'Cholecalciferol',
        description: 'Vitamin D supplement for bone health',
        category: 'Vitamins',
        manufacturer: 'NutriCare',
        price: 18.99,
        dosage: '1000 IU',
        form: 'Tablet',
        strength: '1000 IU',
        requiresPrescription: false,
        imageUrl: 'https://via.placeholder.com/150x150/0EBE7F/FFFFFF?text=Vitamin+D3',
        stockQuantity: 200,
        isAvailable: true,
        sideEffects: ['Constipation', 'Kidney stones (high doses)'],
        contraindications: ['Hypercalcemia'],
        instructions: 'Take 1 tablet daily with food',
        rating: 4.6,
        reviewCount: 312,
        isPopular: true,
        discount: 15.0,
      ),
      PharmacyDrug(
        id: 'drug_5',
        name: 'Cough Syrup',
        genericName: 'Dextromethorphan',
        description: 'Cough suppressant syrup',
        category: 'Cold & Flu',
        manufacturer: 'CoughCare',
        price: 9.99,
        dosage: '15ml',
        form: 'Syrup',
        strength: '15mg/5ml',
        requiresPrescription: false,
        imageUrl: 'https://via.placeholder.com/150x150/0165FC/FFFFFF?text=Cough+Syrup',
        stockQuantity: 80,
        isAvailable: true,
        sideEffects: ['Drowsiness', 'Dizziness'],
        contraindications: ['MAO inhibitor use'],
        instructions: 'Take 15ml every 4 hours as needed',
        rating: 4.2,
        reviewCount: 67,
        isPopular: false,
        discount: 0.0,
      ),
    ];
  }
}
