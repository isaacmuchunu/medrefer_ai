import 'dart:async';
import '../database/dao/inventory_item_dao.dart';
import '../database/models/inventory_item.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final InventoryItemDao _dao = InventoryItemDao();
  final StreamController<List<InventoryItem>> _inventoryController = 
      StreamController<List<InventoryItem>>.broadcast();

  Stream<List<InventoryItem>> get inventoryStream => _inventoryController.stream;

  // Create a new inventory item
  Future<InventoryItem> createItem(InventoryItem item) async {
    try {
      final createdItem = await _dao.insert(item);
      await _refreshInventory();
      return createdItem;
    } catch (e) {
      throw Exception('Failed to create inventory item: $e');
    }
  }

  // Get all items
  Future<List<InventoryItem>> getAllItems() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw Exception('Failed to get inventory items: $e');
    }
  }

  // Get items by category
  Future<List<InventoryItem>> getItemsByCategory(String category) async {
    try {
      return await _dao.getByCategory(category);
    } catch (e) {
      throw Exception('Failed to get items by category: $e');
    }
  }

  // Get items by subcategory
  Future<List<InventoryItem>> getItemsBySubcategory(String subcategory) async {
    try {
      return await _dao.getBySubcategory(subcategory);
    } catch (e) {
      throw Exception('Failed to get items by subcategory: $e');
    }
  }

  // Get items by status
  Future<List<InventoryItem>> getItemsByStatus(String status) async {
    try {
      return await _dao.getByStatus(status);
    } catch (e) {
      throw Exception('Failed to get items by status: $e');
    }
  }

  // Get items by condition
  Future<List<InventoryItem>> getItemsByCondition(String condition) async {
    try {
      return await _dao.getByCondition(condition);
    } catch (e) {
      throw Exception('Failed to get items by condition: $e');
    }
  }

  // Get low stock items
  Future<List<InventoryItem>> getLowStockItems() async {
    try {
      return await _dao.getLowStockItems();
    } catch (e) {
      throw Exception('Failed to get low stock items: $e');
    }
  }

  // Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems() async {
    try {
      return await _dao.getOutOfStockItems();
    } catch (e) {
      throw Exception('Failed to get out of stock items: $e');
    }
  }

  // Get overstocked items
  Future<List<InventoryItem>> getOverstockedItems() async {
    try {
      return await _dao.getOverstockedItems();
    } catch (e) {
      throw Exception('Failed to get overstocked items: $e');
    }
  }

  // Get expired items
  Future<List<InventoryItem>> getExpiredItems() async {
    try {
      return await _dao.getExpiredItems();
    } catch (e) {
      throw Exception('Failed to get expired items: $e');
    }
  }

  // Get items needing maintenance
  Future<List<InventoryItem>> getItemsNeedingMaintenance() async {
    try {
      return await _dao.getItemsNeedingMaintenance();
    } catch (e) {
      throw Exception('Failed to get items needing maintenance: $e');
    }
  }

  // Get items by location
  Future<List<InventoryItem>> getItemsByLocation(String location) async {
    try {
      return await _dao.getByLocation(location);
    } catch (e) {
      throw Exception('Failed to get items by location: $e');
    }
  }

  // Get items by department
  Future<List<InventoryItem>> getItemsByDepartment(String departmentId) async {
    try {
      return await _dao.getByDepartment(departmentId);
    } catch (e) {
      throw Exception('Failed to get items by department: $e');
    }
  }

  // Get items by supplier
  Future<List<InventoryItem>> getItemsBySupplier(String supplier) async {
    try {
      return await _dao.getBySupplier(supplier);
    } catch (e) {
      throw Exception('Failed to get items by supplier: $e');
    }
  }

  // Update stock level
  Future<bool> updateStockLevel(String id, int currentStock) async {
    try {
      final result = await _dao.updateStockLevel(id, currentStock);
      await _refreshInventory();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update stock level: $e');
    }
  }

  // Update maintenance date
  Future<bool> updateMaintenanceDate(String id, DateTime lastMaintenance, DateTime? nextMaintenance) async {
    try {
      final result = await _dao.updateMaintenanceDate(id, lastMaintenance, nextMaintenance);
      await _refreshInventory();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update maintenance date: $e');
    }
  }

  // Search items
  Future<List<InventoryItem>> searchItems(String query) async {
    try {
      return await _dao.searchItems(query);
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  // Get item by barcode
  Future<InventoryItem?> getItemByBarcode(String barcode) async {
    try {
      return await _dao.getByBarcode(barcode);
    } catch (e) {
      throw Exception('Failed to get item by barcode: $e');
    }
  }

  // Get item by SKU
  Future<InventoryItem?> getItemBySKU(String sku) async {
    try {
      return await _dao.getBySKU(sku);
    } catch (e) {
      throw Exception('Failed to get item by SKU: $e');
    }
  }

  // Get inventory dashboard
  Future<Map<String, dynamic>> getInventoryDashboard() async {
    try {
      final summary = await _dao.getInventorySummary();
      final lowStockItems = await getLowStockItems();
      final outOfStockItems = await getOutOfStockItems();
      final expiredItems = await getExpiredItems();
      final itemsNeedingMaintenance = await getItemsNeedingMaintenance();
      
      return {
        'summary': summary,
        'low_stock_items': lowStockItems,
        'out_of_stock_items': outOfStockItems,
        'expired_items': expiredItems,
        'items_needing_maintenance': itemsNeedingMaintenance,
        'total_items': summary['total_items'],
        'low_stock_count': summary['low_stock_items'],
        'out_of_stock_count': summary['out_of_stock_items'],
        'expired_count': summary['expired_items'],
        'maintenance_count': summary['needs_maintenance'],
        'stock_health_score': _calculateStockHealthScore(summary),
      };
    } catch (e) {
      throw Exception('Failed to get inventory dashboard: $e');
    }
  }

  double _calculateStockHealthScore(Map<String, dynamic> summary) {
    final totalItems = summary['total_items'] as int;
    final lowStockItems = summary['low_stock_items'] as int;
    final outOfStockItems = summary['out_of_stock_items'] as int;
    final expiredItems = summary['expired_items'] as int;
    
    if (totalItems == 0) return 100.0;
    
    final healthyItems = totalItems - lowStockItems - outOfStockItems - expiredItems;
    return (healthyItems / totalItems) * 100;
  }

  // Get inventory alerts
  Future<List<Map<String, dynamic>>> getInventoryAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];
      
      final outOfStockItems = await getOutOfStockItems();
      final lowStockItems = await getLowStockItems();
      final expiredItems = await getExpiredItems();
      final itemsNeedingMaintenance = await getItemsNeedingMaintenance();
      
      // Add out of stock alerts
      for (final item in outOfStockItems) {
        alerts.add({
          'type': 'out_of_stock',
          'severity': 'high',
          'title': 'Out of Stock',
          'message': '${item.name} is out of stock',
          'item': item,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add low stock alerts
      for (final item in lowStockItems) {
        alerts.add({
          'type': 'low_stock',
          'severity': 'medium',
          'title': 'Low Stock',
          'message': '${item.name} is running low (${item.currentStock} remaining)',
          'item': item,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add expired alerts
      for (final item in expiredItems) {
        alerts.add({
          'type': 'expired',
          'severity': 'high',
          'title': 'Expired Item',
          'message': '${item.name} has expired',
          'item': item,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add maintenance alerts
      for (final item in itemsNeedingMaintenance) {
        alerts.add({
          'type': 'maintenance',
          'severity': 'medium',
          'title': 'Maintenance Required',
          'message': '${item.name} needs maintenance',
          'item': item,
          'timestamp': DateTime.now(),
        });
      }
      
      return alerts;
    } catch (e) {
      throw Exception('Failed to get inventory alerts: $e');
    }
  }

  // Get inventory trends
  Future<Map<String, dynamic>> getInventoryTrends({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final allItems = await _dao.getAll();
      final recentItems = allItems.where((i) => 
        i.createdAt.isAfter(startDate) && i.createdAt.isBefore(endDate)
      ).toList();
      
      final categoryDistribution = <String, int>{};
      final statusDistribution = <String, int>{};
      final conditionDistribution = <String, int>{};
      final locationDistribution = <String, int>{};
      final supplierDistribution = <String, int>{};
      final stockLevels = <String, double>{};
      
      for (final item in recentItems) {
        // Category distribution
        categoryDistribution[item.category] = (categoryDistribution[item.category] ?? 0) + 1;
        
        // Status distribution
        statusDistribution[item.status] = (statusDistribution[item.status] ?? 0) + 1;
        
        // Condition distribution
        conditionDistribution[item.condition] = (conditionDistribution[item.condition] ?? 0) + 1;
        
        // Location distribution
        if (item.location != null) {
          locationDistribution[item.location!] = (locationDistribution[item.location!] ?? 0) + 1;
        }
        
        // Supplier distribution
        if (item.supplier != null) {
          supplierDistribution[item.supplier!] = (supplierDistribution[item.supplier!] ?? 0) + 1;
        }
        
        // Stock levels
        stockLevels[item.id] = item.stockPercentage;
      }
      
      return {
        'category_distribution': categoryDistribution,
        'status_distribution': statusDistribution,
        'condition_distribution': conditionDistribution,
        'location_distribution': locationDistribution,
        'supplier_distribution': supplierDistribution,
        'stock_levels': stockLevels,
        'total_recent_items': recentItems.length,
        'average_stock_level': stockLevels.values.isNotEmpty ? 
          stockLevels.values.reduce((a, b) => a + b) / stockLevels.values.length : 0,
      };
    } catch (e) {
      throw Exception('Failed to get inventory trends: $e');
    }
  }

  // Get inventory insights
  Future<List<Map<String, dynamic>>> getInventoryInsights() async {
    try {
      final insights = <Map<String, dynamic>>[];
      
      final outOfStockItems = await getOutOfStockItems();
      final lowStockItems = await getLowStockItems();
      final expiredItems = await getExpiredItems();
      final itemsNeedingMaintenance = await getItemsNeedingMaintenance();
      
      // Out of stock insights
      if (outOfStockItems.isNotEmpty) {
        insights.add({
          'type': 'out_of_stock',
          'title': 'Out of Stock Items',
          'message': '${outOfStockItems.length} items are out of stock',
          'priority': 'high',
          'data': outOfStockItems,
        });
      }
      
      // Low stock insights
      if (lowStockItems.isNotEmpty) {
        insights.add({
          'type': 'low_stock',
          'title': 'Low Stock Items',
          'message': '${lowStockItems.length} items are running low',
          'priority': 'medium',
          'data': lowStockItems,
        });
      }
      
      // Expired items insights
      if (expiredItems.isNotEmpty) {
        insights.add({
          'type': 'expired',
          'title': 'Expired Items',
          'message': '${expiredItems.length} items have expired',
          'priority': 'high',
          'data': expiredItems,
        });
      }
      
      // Maintenance insights
      if (itemsNeedingMaintenance.isNotEmpty) {
        insights.add({
          'type': 'maintenance',
          'title': 'Maintenance Required',
          'message': '${itemsNeedingMaintenance.length} items need maintenance',
          'priority': 'medium',
          'data': itemsNeedingMaintenance,
        });
      }
      
      return insights;
    } catch (e) {
      throw Exception('Failed to get inventory insights: $e');
    }
  }

  // Refresh inventory stream
  Future<void> _refreshInventory() async {
    try {
      final items = await _dao.getAll();
      _inventoryController.add(items);
    } catch (e) {
      _inventoryController.addError(e);
    }
  }

  // Dispose resources
  void dispose() {
    _inventoryController.close();
  }
}