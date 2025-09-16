import 'package:flutter/material.dart';
import '../../services/emergency_service.dart';
import '../../database/models/emergency_protocol.dart';
import '../../theme/app_theme.dart';

class EmergencyResponseSystem extends StatefulWidget {
  const EmergencyResponseSystem({super.key});

  @override
  State<EmergencyResponseSystem> createState() => _EmergencyResponseSystemState();
}

class _EmergencyResponseSystemState extends State<EmergencyResponseSystem>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyProtocol> _protocols = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProtocols();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProtocols() async {
    setState(() => _isLoading = true);
    try {
      final protocols = await _emergencyService.getAllProtocols();
      setState(() {
        _protocols = protocols;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load emergency protocols: $e');
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

  List<EmergencyProtocol> get _filteredProtocols {
    var filtered = _protocols;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((protocol) =>
          protocol.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          protocol.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          protocol.emergencyType.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    switch (_selectedFilter) {
      case 'medical':
        filtered = filtered.where((p) => p.emergencyType == 'medical').toList();
        break;
      case 'fire':
        filtered = filtered.where((p) => p.emergencyType == 'fire').toList();
        break;
      case 'security':
        filtered = filtered.where((p) => p.emergencyType == 'security').toList();
        break;
      case 'critical':
        filtered = filtered.where((p) => p.isCritical).toList();
        break;
      case 'active':
        filtered = filtered.where((p) => p.status == 'active').toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Emergency Response'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Protocols'),
            Tab(text: 'Critical'),
            Tab(text: 'Alerts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProtocols,
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
                _buildProtocolsList(),
                _buildCriticalProtocolsWidget(),
                _buildAlertsView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProtocolDialog,
        backgroundColor: Colors.red,
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
              hintText: 'Search protocols...',
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
                _buildFilterChip('medical', 'Medical'),
                _buildFilterChip('fire', 'Fire'),
                _buildFilterChip('security', 'Security'),
                _buildFilterChip('critical', 'Critical'),
                _buildFilterChip('active', 'Active'),
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
        selectedColor: Colors.red.withOpacity(0.2),
        checkmarkColor: Colors.red,
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _emergencyService.getEmergencyDashboard(),
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
              _buildCriticalProtocols(dashboard['critical_protocols']),
              const SizedBox(height: 24),
              _buildProtocolsNeedingReview(dashboard['protocols_needing_review']),
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
            'Total Protocols',
            summary['total_protocols'].toString(),
            Icons.emergency,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Active',
            summary['active_count'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Critical',
            summary['critical_count'].toString(),
            Icons.priority_high,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Need Review',
            summary['needs_review_count'].toString(),
            Icons.warning,
            Colors.yellow[700]!,
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

  Widget _buildCriticalProtocols(List<EmergencyProtocol> protocols) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Critical Protocols',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (protocols.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No critical protocols', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...protocols.take(5).map(_buildProtocolItem),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolsNeedingReview(List<EmergencyProtocol> protocols) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Protocols Needing Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (protocols.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No protocols need review', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...protocols.take(5).map(_buildProtocolItem),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredProtocols = _filteredProtocols;

    if (filteredProtocols.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No protocols found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProtocols.length,
      itemBuilder: (context, index) {
        final protocol = filteredProtocols[index];
        return _buildProtocolCard(protocol);
      },
    );
  }

  Widget _buildProtocolCard(EmergencyProtocol protocol) {
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
                    protocol.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(protocol.status),
                _buildSeverityChip(protocol.severity),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              protocol.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${protocol.emergencyType} - ${protocol.category}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Created by: ${protocol.createdBy}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last reviewed: ${_formatDate(protocol.lastReviewed)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                if (protocol.needsReview)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'NEEDS REVIEW',
                      style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Steps: ${protocol.steps.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => _showProtocolDetails(protocol),
                  child: const Text('View Details'),
                ),
                if (protocol.status == 'draft')
                  TextButton(
                    onPressed: () => _approveProtocol(protocol),
                    child: const Text('Approve'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolItem(EmergencyProtocol protocol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protocol.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${protocol.emergencyType} - ${protocol.category}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (protocol.isCritical)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: const Text(
                'CRITICAL',
                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCriticalProtocolsWidget() {
    return FutureBuilder<List<EmergencyProtocol>>(
      future: _emergencyService.getCriticalProtocols(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final criticalProtocols = snapshot.data!;
        
        if (criticalProtocols.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.priority_high, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No critical protocols', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: criticalProtocols.length,
          itemBuilder: (context, index) {
            final protocol = criticalProtocols[index];
            return _buildCriticalProtocolCard(protocol);
          },
        );
      },
    );
  }

  Widget _buildCriticalProtocolCard(EmergencyProtocol protocol) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.priority_high, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      protocol.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                  _buildSeverityChip(protocol.severity),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                protocol.description,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${protocol.emergencyType} - ${protocol.category}', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.list, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${protocol.steps.length} steps', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Required Equipment: ${protocol.requiredEquipment.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showProtocolDetails(protocol),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Protocol'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _emergencyService.getEmergencyAlerts(),
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
                Text('No emergency alerts', style: TextStyle(fontSize: 18, color: Colors.grey)),
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      case 'archived':
        color = Colors.red;
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

  Widget _buildSeverityChip(String severity) {
    Color color;
    switch (severity) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.yellow[700]!;
        break;
      case 'low':
        color = Colors.green;
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
        severity.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateProtocolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Emergency Protocol'),
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

  void _showProtocolDetails(EmergencyProtocol protocol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(protocol.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${protocol.description}'),
              const SizedBox(height: 8),
              Text('Emergency Type: ${protocol.emergencyType}'),
              const SizedBox(height: 8),
              Text('Category: ${protocol.category}'),
              const SizedBox(height: 8),
              Text('Severity: ${protocol.severity}'),
              const SizedBox(height: 8),
              Text('Status: ${protocol.status}'),
              const SizedBox(height: 8),
              Text('Steps: ${protocol.steps.length}'),
              const SizedBox(height: 8),
              Text('Required Equipment: ${protocol.requiredEquipment.length}'),
              const SizedBox(height: 8),
              Text('Required Personnel: ${protocol.requiredPersonnel.length}'),
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

  Future<void> _approveProtocol(EmergencyProtocol protocol) async {
    try {
      await _emergencyService.approveProtocol(protocol.id, 'current_user');
      _loadProtocols();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Protocol approved successfully')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to approve protocol: $e');
    }
  }
}