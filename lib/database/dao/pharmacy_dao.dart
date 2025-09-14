import 'package:sqflite/sqflite.dart';
import '../models/pharmacy_drug.dart';

class PharmacyDAO {
  static const String _drugsTable = 'pharmacy_drugs';
  static const String _cartTable = 'cart_items';
  static const String _ordersTable = 'pharmacy_orders';

  // Create tables
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_drugsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        generic_name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        manufacturer TEXT NOT NULL,
        price REAL NOT NULL,
        dosage TEXT NOT NULL,
        form TEXT NOT NULL,
        strength TEXT NOT NULL,
        requires_prescription INTEGER NOT NULL DEFAULT 0,
        image_url TEXT NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        is_available INTEGER NOT NULL DEFAULT 1,
        side_effects TEXT,
        contraindications TEXT,
        instructions TEXT,
        expiry_date TEXT,
        rating REAL DEFAULT 0.0,
        review_count INTEGER DEFAULT 0,
        is_popular INTEGER DEFAULT 0,
        discount REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_cartTable (
        id TEXT PRIMARY KEY,
        drug_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        prescription_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (drug_id) REFERENCES $_drugsTable (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_ordersTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        order_number TEXT NOT NULL UNIQUE,
        cart_item_ids TEXT NOT NULL,
        subtotal REAL NOT NULL,
        delivery_fee REAL NOT NULL,
        tax REAL NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        delivery_address TEXT NOT NULL,
        prescription_id TEXT,
        delivery_date TEXT,
        tracking_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_drugs_category ON $_drugsTable (category)');
    await db.execute('CREATE INDEX idx_drugs_available ON $_drugsTable (is_available)');
    await db.execute('CREATE INDEX idx_cart_user ON $_cartTable (user_id)');
    await db.execute('CREATE INDEX idx_orders_user ON $_ordersTable (user_id)');
  }

  final Database _db;

  PharmacyDAO(this._db);

  // Drug operations
  Future<List<PharmacyDrug>> getAllDrugs() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _drugsTable,
      orderBy: 'name ASC',
    );
    return maps.map((map) => PharmacyDrug.fromMap(map)).toList();
  }

  Future<List<PharmacyDrug>> getAvailableDrugs() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _drugsTable,
      where: 'is_available = ? AND stock_quantity > ?',
      whereArgs: [1, 0],
      orderBy: 'name ASC',
    );
    return maps.map((map) => PharmacyDrug.fromMap(map)).toList();
  }

  Future<List<PharmacyDrug>> getDrugsByCategory(String category) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _drugsTable,
      where: 'category = ? AND is_available = ?',
      whereArgs: [category, 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => PharmacyDrug.fromMap(map)).toList();
  }

  Future<List<PharmacyDrug>> getPopularDrugs() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _drugsTable,
      where: 'is_popular = ? AND is_available = ?',
      whereArgs: [1, 1],
      orderBy: 'rating DESC, review_count DESC',
      limit: 10,
    );
    return maps.map((map) => PharmacyDrug.fromMap(map)).toList();
  }

  Future<List<PharmacyDrug>> searchDrugs(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _drugsTable,
      where: '(name LIKE ? OR generic_name LIKE ? OR category LIKE ?) AND is_available = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => PharmacyDrug.fromMap(map)).toList();
  }

  Future<PharmacyDrug?> getDrugById(String id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _drugsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PharmacyDrug.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertDrug(PharmacyDrug drug) async {
    await _db.insert(_drugsTable, drug.toMap());
  }

  Future<void> updateDrug(PharmacyDrug drug) async {
    await _db.update(
      _drugsTable,
      drug.toMap(),
      where: 'id = ?',
      whereArgs: [drug.id],
    );
  }

  Future<void> deleteDrug(String id) async {
    await _db.delete(
      _drugsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cart operations
  Future<List<CartItem>> getCartItems(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _cartTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => CartItem.fromMap(map)).toList();
  }

  Future<CartItem?> getCartItem(String userId, String drugId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _cartTable,
      where: 'user_id = ? AND drug_id = ?',
      whereArgs: [userId, drugId],
    );
    if (maps.isNotEmpty) {
      return CartItem.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addToCart(CartItem cartItem) async {
    // Check if item already exists
    final existing = await getCartItem(cartItem.userId, cartItem.drugId);
    if (existing != null) {
      // Update quantity
      final updated = existing.copyWith(
        quantity: existing.quantity + cartItem.quantity,
        totalPrice: (existing.quantity + cartItem.quantity) * cartItem.unitPrice,
      );
      await updateCartItem(updated);
    } else {
      await _db.insert(_cartTable, cartItem.toMap());
    }
  }

  Future<void> updateCartItem(CartItem cartItem) async {
    await _db.update(
      _cartTable,
      cartItem.toMap(),
      where: 'id = ?',
      whereArgs: [cartItem.id],
    );
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _db.delete(
      _cartTable,
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> clearCart(String userId) async {
    await _db.delete(
      _cartTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<double> getCartTotal(String userId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(total_price) as total FROM $_cartTable WHERE user_id = ?',
      [userId],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<int> getCartItemCount(String userId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(quantity) as count FROM $_cartTable WHERE user_id = ?',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // Order operations
  Future<List<PharmacyOrder>> getUserOrders(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _ordersTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => PharmacyOrder.fromMap(map)).toList();
  }

  Future<PharmacyOrder?> getOrderById(String id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _ordersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PharmacyOrder.fromMap(maps.first);
    }
    return null;
  }

  Future<PharmacyOrder?> getOrderByNumber(String orderNumber) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _ordersTable,
      where: 'order_number = ?',
      whereArgs: [orderNumber],
    );
    if (maps.isNotEmpty) {
      return PharmacyOrder.fromMap(maps.first);
    }
    return null;
  }

  Future<void> createOrder(PharmacyOrder order) async {
    await _db.insert(_ordersTable, order.toMap());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.update(
      _ordersTable,
      {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> updateOrder(PharmacyOrder order) async {
    await _db.update(
      _ordersTable,
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // Utility methods
  Future<List<String>> getDrugCategories() async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT DISTINCT category FROM $_drugsTable WHERE is_available = 1 ORDER BY category ASC',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<void> updateDrugStock(String drugId, int newStock) async {
    await _db.update(
      _drugsTable,
      {
        'stock_quantity': newStock,
        'is_available': newStock > 0 ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [drugId],
    );
  }
}
