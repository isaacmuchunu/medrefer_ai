import '../models/inventory_item.dart';
import 'dao.dart';

class InventoryItemDao extends BaseDao<InventoryItem> {
  static const String _tableName = 'inventory_items';

  @override
  String get tableName => _tableName;

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'name': 'TEXT NOT NULL',
    'description': 'TEXT NOT NULL',
    'category': 'TEXT NOT NULL',
    'subcategory': 'TEXT NOT NULL',
    'sku': 'TEXT NOT NULL',
    'barcode': 'TEXT NOT NULL',
    'manufacturer': 'TEXT NOT NULL',
    'model': 'TEXT',
    'serial_number': 'TEXT',
    'current_stock': 'INTEGER NOT NULL',
    'minimum_stock': 'INTEGER NOT NULL',
    'maximum_stock': 'INTEGER NOT NULL',
    'unit': 'TEXT NOT NULL',
    'unit_cost': 'REAL NOT NULL',
    'currency': 'TEXT NOT NULL',
    'supplier': 'TEXT',
    'location': 'TEXT',
    'department_id': 'TEXT',
    'facility_id': 'TEXT',
    'expiry_date': 'TEXT',
    'status': 'TEXT NOT NULL',
    'condition': 'TEXT NOT NULL',
    'last_maintenance': 'TEXT',
    'next_maintenance': 'TEXT',
    'tags': 'TEXT',
    'specifications': 'TEXT',
    'notes': 'TEXT',
    'created_at': 'TEXT NOT NULL',
    'updated_at': 'TEXT NOT NULL',
    'is_active': 'INTEGER NOT NULL',
    'requires_maintenance': 'INTEGER NOT NULL',
  };

  @override
  InventoryItem fromMap(Map<String, dynamic> map) => InventoryItem.fromMap(map);

  @override
  Map<String, dynamic> toMap(InventoryItem item) => item.toMap();

  // Get items by category
  Future<List<InventoryItem>> getByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by subcategory
  Future<List<InventoryItem>> getBySubcategory(String subcategory) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'subcategory = ? AND is_active = 1',
      whereArgs: [subcategory],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by status
  Future<List<InventoryItem>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ? AND is_active = 1',
      whereArgs: [status],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by condition
  Future<List<InventoryItem>> getByCondition(String condition) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'condition = ? AND is_active = 1',
      whereArgs: [condition],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get low stock items
  Future<List<InventoryItem>> getLowStockItems() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'current_stock <= minimum_stock AND is_active = 1',
      orderBy: 'current_stock ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'current_stock <= 0 AND is_active = 1',
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get overstocked items
  Future<List<InventoryItem>> getOverstockedItems() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'current_stock >= maximum_stock AND is_active = 1',
      orderBy: 'current_stock DESC',
    );
    return maps.map(fromMap).toList();
  }

  // Get expired items
  Future<List<InventoryItem>> getExpiredItems() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'expiry_date < ? AND is_active = 1',
      whereArgs: [now],
      orderBy: 'expiry_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items needing maintenance
  Future<List<InventoryItem>> getItemsNeedingMaintenance() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      _tableName,
      where: 'next_maintenance < ? AND is_active = 1',
      whereArgs: [now],
      orderBy: 'next_maintenance ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by location
  Future<List<InventoryItem>> getByLocation(String location) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'location = ? AND is_active = 1',
      whereArgs: [location],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by department
  Future<List<InventoryItem>> getByDepartment(String departmentId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'department_id = ? AND is_active = 1',
      whereArgs: [departmentId],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by supplier
  Future<List<InventoryItem>> getBySupplier(String supplier) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'supplier = ? AND is_active = 1',
      whereArgs: [supplier],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Update stock level
  Future<int> updateStockLevel(String id, int currentStock) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'current_stock': currentStock,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update maintenance date
  Future<int> updateMaintenanceDate(String id, DateTime lastMaintenance, DateTime? nextMaintenance) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      {
        'last_maintenance': lastMaintenance.toIso8601String(),
        'next_maintenance': nextMaintenance?.toIso8601String(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search items
  Future<List<InventoryItem>> searchItems(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '(name LIKE ? OR description LIKE ? OR sku LIKE ? OR barcode LIKE ? OR tags LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  // Get items by barcode
  Future<InventoryItem?> getByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  // Get items by SKU
  Future<InventoryItem?> getBySKU(String sku) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'sku = ? AND is_active = 1',
      whereArgs: [sku],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  // Get inventory summary
  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await database;
    
    final totalItems = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
    final lowStockItems = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE current_stock <= minimum_stock AND is_active = 1');
    final outOfStockItems = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE current_stock <= 0 AND is_active = 1');
    final expiredItems = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE expiry_date < ? AND is_active = 1', [DateTime.now().toIso8601String()]);
    final needsMaintenance = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE next_maintenance < ? AND is_active = 1', [DateTime.now().toIso8601String()]);
    
    return {
      'total_items': totalItems.first['count'],
      'low_stock_items': lowStockItems.first['count'],
      'out_of_stock_items': outOfStockItems.first['count'],
      'expired_items': expiredItems.first['count'],
      'needs_maintenance': needsMaintenance.first['count'],
    };
  }
}