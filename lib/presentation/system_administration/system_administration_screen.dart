import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class SystemAdministrationScreen extends StatefulWidget {
  const SystemAdministrationScreen({super.key});

  @override
  State<SystemAdministrationScreen> createState() => _SystemAdministrationScreenState();
}

class _SystemAdministrationScreenState extends State<SystemAdministrationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // System data
  Map<String, dynamic> _systemHealth = {};
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _systemLogs = [];
  Map<String, dynamic> _systemConfig = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSystemData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemData() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate loading system data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _systemHealth = {
          'cpuUsage': 65.2,
          'memoryUsage': 78.5,
          'diskUsage': 45.8,
          'networkLatency': 12.3,
          'uptime': '15 days, 8 hours',
          'activeConnections': 1247,
          'systemLoad': 2.1,
          'temperature': 62.5,
        };
        
        _activeUsers = [
          {'name': 'Dr. Smith', 'role': 'Doctor', 'lastActive': '2 min ago', 'status': 'online'},
          {'name': 'Nurse Johnson', 'role': 'Nurse', 'lastActive': '5 min ago', 'status': 'online'},
          {'name': 'Admin Wilson', 'role': 'Admin', 'lastActive': '1 hour ago', 'status': 'away'},
          {'name': 'Dr. Brown', 'role': 'Doctor', 'lastActive': '3 hours ago', 'status': 'offline'},
        ];
        
        _systemLogs = [
          {'level': 'INFO', 'message': 'User login successful', 'timestamp': DateTime.now().subtract(const Duration(minutes: 2))},
          {'level': 'WARN', 'message': 'High memory usage detected', 'timestamp': DateTime.now().subtract(const Duration(minutes: 15))},
          {'level': 'ERROR', 'message': 'Database connection timeout', 'timestamp': DateTime.now().subtract(const Duration(hours: 1))},
          {'level': 'INFO', 'message': 'Backup completed successfully', 'timestamp': DateTime.now().subtract(const Duration(hours: 2))},
        ];
        
        _systemConfig = {
          'maxUsers': 1000,
          'sessionTimeout': 30,
          'backupFrequency': 'Daily',
          'logRetention': 90,
          'maintenanceWindow': '02:00 - 04:00',
        };
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load system data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'System Administration',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show system alerts
            },
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildAdminContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading system data...'),
        ],
      ),
    );
  }

  Widget _buildAdminContent() {
    return Column(
      children: [
        // System Health Overview
        _buildSystemHealthSection(),
        
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'System Logs'),
              Tab(text: 'Configuration'),
              Tab(text: 'Security'),
              Tab(text: 'Maintenance'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersTab(),
              _buildSystemLogsTab(),
              _buildConfigurationTab(),
              _buildSecurityTab(),
              _buildMaintenanceTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemHealthSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'System Health',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Healthy',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHealthMetric('CPU Usage', '${_systemHealth['cpuUsage']}%', Icons.memory, _getHealthColor(_systemHealth['cpuUsage'])),
                _buildHealthMetric('Memory', '${_systemHealth['memoryUsage']}%', Icons.storage, _getHealthColor(_systemHealth['memoryUsage'])),
                _buildHealthMetric('Disk Space', '${_systemHealth['diskUsage']}%', Icons.hard_drive, _getHealthColor(_systemHealth['diskUsage'])),
                _buildHealthMetric('Network', '${_systemHealth['networkLatency']}ms', Icons.network_check, Colors.green),
                _buildHealthMetric('Uptime', _systemHealth['uptime'], Icons.access_time, Colors.blue),
                _buildHealthMetric('Connections', '${_systemHealth['activeConnections']}', Icons.people, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 80) return Colors.orange;
    return Colors.red;
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // User Statistics
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildUserStatCard('Total Users', '${_activeUsers.length}', Icons.people, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserStatCard('Online Now', '${_activeUsers.where((u) => u['status'] == 'online').length}', Icons.circle, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserStatCard('Active Today', '156', Icons.today, Colors.orange),
              ),
            ],
          ),
        ),
        
        // User List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _activeUsers.length,
            itemBuilder: (context, index) {
              final user = _activeUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(user['status']).withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: _getStatusColor(user['status']),
                    ),
                  ),
                  title: Text(user['name']),
                  subtitle: Text('${user['role']} • Last active: ${user['lastActive']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(user['status']),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user['status'],
                        style: TextStyle(
                          color: _getStatusColor(user['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Profile')),
                          const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
                          const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                        ],
                        onSelected: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${value.toString().toUpperCase()} ${user['name']}')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online': return Colors.green;
      case 'away': return Colors.orange;
      case 'offline': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildSystemLogsTab() {
    return Column(
      children: [
        // Log Controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: 'ALL',
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Levels')),
                  DropdownMenuItem(value: 'ERROR', child: Text('Errors')),
                  DropdownMenuItem(value: 'WARN', child: Text('Warnings')),
                  DropdownMenuItem(value: 'INFO', child: Text('Info')),
                ],
                onChanged: (value) {
                  // Filter logs by level
                },
              ),
            ],
          ),
        ),
        
        // Log Entries
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _systemLogs.length,
            itemBuilder: (context, index) {
              final log = _systemLogs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getLogLevelColor(log['level']).withOpacity(0.1),
                    child: Text(
                      log['level'][0],
                      style: TextStyle(
                        color: _getLogLevelColor(log['level']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(log['message']),
                  subtitle: Text(_formatTimestamp(log['timestamp'])),
                  trailing: Chip(
                    label: Text(log['level']),
                    backgroundColor: _getLogLevelColor(log['level']).withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getLogLevelColor(String level) {
    switch (level) {
      case 'ERROR': return Colors.red;
      case 'WARN': return Colors.orange;
      case 'INFO': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildConfigurationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConfigSection('System Settings', [
          _buildConfigItem('Max Users', '${_systemConfig['maxUsers']}', Icons.people),
          _buildConfigItem('Session Timeout', '${_systemConfig['sessionTimeout']} minutes', Icons.timer),
          _buildConfigItem('Backup Frequency', _systemConfig['backupFrequency'], Icons.backup),
          _buildConfigItem('Log Retention', '${_systemConfig['logRetention']} days', Icons.history),
        ]),
        const SizedBox(height: 16),
        _buildConfigSection('Maintenance', [
          _buildConfigItem('Maintenance Window', _systemConfig['maintenanceWindow'], Icons.build),
          _buildConfigItem('Auto Updates', 'Enabled', Icons.system_update),
          _buildConfigItem('Monitoring', 'Active', Icons.monitor),
        ]),
      ],
    );
  }

  Widget _buildConfigSection(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        // Edit configuration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit $title')),
        );
      },
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSecurityCard('Authentication', [
          {'title': 'Multi-Factor Authentication', 'status': 'Enabled', 'color': Colors.green},
          {'title': 'Password Policy', 'status': 'Strong', 'color': Colors.green},
          {'title': 'Session Management', 'status': 'Active', 'color': Colors.green},
        ]),
        const SizedBox(height: 16),
        _buildSecurityCard('Encryption', [
          {'title': 'Data at Rest', 'status': 'AES-256', 'color': Colors.green},
          {'title': 'Data in Transit', 'status': 'TLS 1.3', 'color': Colors.green},
          {'title': 'Database Encryption', 'status': 'Enabled', 'color': Colors.green},
        ]),
        const SizedBox(height: 16),
        _buildSecurityCard('Access Control', [
          {'title': 'Role-Based Access', 'status': 'Active', 'color': Colors.green},
          {'title': 'API Rate Limiting', 'status': 'Enabled', 'color': Colors.green},
          {'title': 'Audit Logging', 'status': 'Comprehensive', 'color': Colors.green},
        ]),
      ],
    );
  }

  Widget _buildSecurityCard(String title, List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => ListTile(
              leading: Icon(Icons.security, color: item['color']),
              title: Text(item['title']),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(
                    color: item['color'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMaintenanceCard('System Maintenance', [
          _buildMaintenanceAction('Run System Diagnostics', Icons.bug_report, Colors.blue),
          _buildMaintenanceAction('Clear Cache', Icons.clear_all, Colors.orange),
          _buildMaintenanceAction('Optimize Database', Icons.storage, Colors.green),
          _buildMaintenanceAction('Update System', Icons.system_update, Colors.purple),
        ]),
        const SizedBox(height: 16),
        _buildMaintenanceCard('Backup & Recovery', [
          _buildMaintenanceAction('Create Backup', Icons.backup, Colors.blue),
          _buildMaintenanceAction('Restore from Backup', Icons.restore, Colors.orange),
          _buildMaintenanceAction('Verify Backup Integrity', Icons.verified, Colors.green),
          _buildMaintenanceAction('Schedule Backup', Icons.schedule, Colors.purple),
        ]),
        const SizedBox(height: 16),
        _buildMaintenanceCard('Performance', [
          _buildMaintenanceAction('Performance Analysis', Icons.analytics, Colors.blue),
          _buildMaintenanceAction('Memory Cleanup', Icons.memory, Colors.orange),
          _buildMaintenanceAction('Disk Cleanup', Icons.cleaning_services, Colors.green),
          _buildMaintenanceAction('Network Diagnostics', Icons.network_check, Colors.purple),
        ]),
      ],
    );
  }

  Widget _buildMaintenanceCard(String title, List<Widget> actions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceAction(String title, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Executing: $title')),
          );
        },
        child: const Text('Run'),
      ),
    );
  }
}