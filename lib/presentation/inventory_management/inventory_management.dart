import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../database/models/inventory_item.dart';
import '../../theme/app_theme.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItem> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _inventoryService.getAllItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load inventory items: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<InventoryItem> get _filteredItems {
    var filtered = _items;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.barcode.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    switch (_selectedFilter) {
      case 'low_stock':
        filtered = filtered.where((i) => i.isLowStock).toList();
        break;
      case 'out_of_stock':
        filtered = filtered.where((i) => i.isOutOfStock).toList();
        break;
      case 'expired':
        filtered = filtered.where((i) => i.isExpired).toList();
        break;
      case 'maintenance':
        filtered = filtered.where((i) => i.needsMaintenance).toList();
        break;
      case 'equipment':
        filtered = filtered.where((i) => i.category == 'equipment').toList();
        break;
      case 'supplies':
        filtered = filtered.where((i) => i.category == 'supplies').toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Items'),
            Tab(text: 'Alerts'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildItemsList(),
                _buildAlertsView(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateItemDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                _buildFilterChip('low_stock', 'Low Stock'),
                _buildFilterChip('out_of_stock', 'Out of Stock'),
                _buildFilterChip('expired', 'Expired'),
                _buildFilterChip('maintenance', 'Maintenance'),
                _buildFilterChip('equipment', 'Equipment'),
                _buildFilterChip('supplies', 'Supplies'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        selectedColor: AppTheme.primary.withOpacity(0.2),
        checkmarkColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _inventoryService.getInventoryDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final dashboard = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(dashboard),
              const SizedBox(height: 24),
              _buildStockHealthIndicator(dashboard['stock_health_score']),
              const SizedBox(height: 24),
              _buildLowStockItems(dashboard['low_stock_items']),
              const SizedBox(height: 24),
              _buildOutOfStockItems(dashboard['out_of_stock_items']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> dashboard) {
    final summary = dashboard['summary'] as Map<String, dynamic>;
    
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Items',
            summary['total_items'].toString(),
            Icons.inventory,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Low Stock',
            summary['low_stock_items'].toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Out of Stock',
            summary['out_of_stock_items'].toString(),
            Icons.error,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Expired',
            summary['expired_items'].toString(),
            Icons.schedule,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHealthIndicator(double healthScore) {
    Color color;
    String status;
    
    if (healthScore >= 90) {
      color = Colors.green;
      status = 'Excellent';
    } else if (healthScore >= 70) {
      color = Colors.blue;
      status = 'Good';
    } else if (healthScore >= 50) {
      color = Colors.orange;
      status = 'Fair';
    } else {
      color = Colors.red;
      status = 'Poor';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock Health Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${healthScore.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        status,
                        style: TextStyle(fontSize: 16, color: color),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: healthScore / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockItems(List<InventoryItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Low Stock Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No low stock items', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...items.take(5).map(_buildItemItem),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfStockItems(List<InventoryItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Out of Stock Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No out of stock items', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...items.take(5).map(_buildItemItem),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(item.status),
                _buildConditionChip(item.condition),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${item.category} - ${item.subcategory}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('SKU: ${item.sku}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current: ${item.currentStock} ${item.unit}'),
                      Text('Min: ${item.minimumStock} | Max: ${item.maximumStock}'),
                      Text('Cost: ${item.unitCost} ${item.currency}'),
                    ],
                  ),
                ),
                _buildStockIndicator(item),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: item.stockPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                item.isOutOfStock ? Colors.red :
                item.isLowStock ? Colors.orange :
                item.isOverstocked ? Colors.purple : Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Location: ${item.location ?? 'Not specified'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => _showItemDetails(item),
                  child: const Text('View Details'),
                ),
                if (item.isLowStock || item.isOutOfStock)
                  ElevatedButton(
                    onPressed: () => _reorderItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reorder'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemItem(InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.currentStock}/${item.maximumStock} ${item.unit}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildStockIndicator(item),
        ],
      ),
    );
  }

  Widget _buildAlertsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _inventoryService.getInventoryAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final alerts = snapshot.data!;
        
        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No inventory alerts', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertCard(alert);
          },
        );
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    Color color;
    IconData icon;
    
    switch (severity) {
      case 'high':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'low':
        color = Colors.blue;
        icon = Icons.info;
        break;
      default:
        color = Colors.grey;
        icon = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['title'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['message'] as String,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(alert['timestamp'] as DateTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color),
              ),
              child: Text(
                severity.toUpperCase(),
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _inventoryService.getInventoryTrends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final trends = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrendsCard(trends),
              const SizedBox(height: 24),
              _buildCategoryDistribution(trends['category_distribution']),
              const SizedBox(height: 24),
              _buildStatusDistribution(trends['status_distribution']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsCard(Map<String, dynamic> trends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrendStat(
                    'Total Items',
                    trends['total_recent_items'].toString(),
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildTrendStat(
                    'Avg Stock Level',
                    '${trends['average_stock_level'].toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution(Map<String, int> categoryDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...categoryDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution(Map<String, int> statusDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items by Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...statusDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int value) {
    final total = _items.length;
    final percentage = total > 0 ? (value / total) * 100 : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$value (${percentage.toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      case 'discontinued':
        color = Colors.red;
        break;
      case 'maintenance':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    Color color;
    switch (condition) {
      case 'new':
        color = Colors.green;
        break;
      case 'good':
        color = Colors.blue;
        break;
      case 'fair':
        color = Colors.orange;
        break;
      case 'poor':
        color = Colors.red;
        break;
      case 'damaged':
        color = Colors.red[800]!;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        condition.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStockIndicator(InventoryItem item) {
    Color color;
    String text;
    
    if (item.isOutOfStock) {
      color = Colors.red;
      text = 'OUT';
    } else if (item.isLowStock) {
      color = Colors.orange;
      text = 'LOW';
    } else if (item.isOverstocked) {
      color = Colors.purple;
      text = 'HIGH';
    } else {
      color = Colors.green;
      text = 'OK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Inventory Item'),
        content: const Text('This feature will be implemented in the next version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${item.description}'),
              const SizedBox(height: 8),
              Text('Category: ${item.category} - ${item.subcategory}'),
              const SizedBox(height: 8),
              Text('SKU: ${item.sku}'),
              const SizedBox(height: 8),
              Text('Barcode: ${item.barcode}'),
              const SizedBox(height: 8),
              Text('Manufacturer: ${item.manufacturer}'),
              const SizedBox(height: 8),
              Text('Current Stock: ${item.currentStock} ${item.unit}'),
              const SizedBox(height: 8),
              Text('Min Stock: ${item.minimumStock} | Max Stock: ${item.maximumStock}'),
              const SizedBox(height: 8),
              Text('Unit Cost: ${item.unitCost} ${item.currency}'),
              const SizedBox(height: 8),
              Text('Location: ${item.location ?? 'Not specified'}'),
              const SizedBox(height: 8),
              Text('Status: ${item.status}'),
              const SizedBox(height: 8),
              Text('Condition: ${item.condition}'),
              if (item.expiryDate != null)
                Text('Expiry Date: ${_formatDate(item.expiryDate!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reorderItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Item'),
        content: Text('Are you sure you want to reorder "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reorder request submitted!')),
              );
            },
            child: const Text('Reorder'),
          ),
        ],
      ),
    );
  }
}