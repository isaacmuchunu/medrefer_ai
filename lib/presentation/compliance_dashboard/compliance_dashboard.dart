import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/compliance_service.dart';
import '../../database/models/compliance_audit.dart';
import '../../theme/app_theme.dart';

class ComplianceDashboard extends StatefulWidget {
  const ComplianceDashboard({super.key});

  @override
  State<ComplianceDashboard> createState() => _ComplianceDashboardState();
}

class _ComplianceDashboardState extends State<ComplianceDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ComplianceService _complianceService = ComplianceService();
  List<ComplianceAudit> _audits = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAudits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAudits() async {
    setState(() => _isLoading = true);
    try {
      final audits = await _complianceService.getAllAudits();
      setState(() {
        _audits = audits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load compliance audits: $e');
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

  List<ComplianceAudit> get _filteredAudits {
    var filtered = _audits;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((audit) =>
          audit.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          audit.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          audit.auditType.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    switch (_selectedFilter) {
      case 'scheduled':
        filtered = filtered.where((a) => a.status == 'scheduled').toList();
        break;
      case 'in_progress':
        filtered = filtered.where((a) => a.status == 'in_progress').toList();
        break;
      case 'completed':
        filtered = filtered.where((a) => a.status == 'completed').toList();
        break;
      case 'overdue':
        filtered = filtered.where((a) => a.isOverdue).toList();
        break;
      case 'non_compliant':
        filtered = filtered.where((a) => !a.isCompliant).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Compliance Dashboard'),
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
            Tab(text: 'Audits'),
            Tab(text: 'Alerts'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAudits,
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
                _buildAuditsList(),
                _buildAlertsView(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAuditDialog,
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
              hintText: 'Search audits...',
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
                _buildFilterChip('scheduled', 'Scheduled'),
                _buildFilterChip('in_progress', 'In Progress'),
                _buildFilterChip('completed', 'Completed'),
                _buildFilterChip('overdue', 'Overdue'),
                _buildFilterChip('non_compliant', 'Non-Compliant'),
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
      future: _complianceService.getComplianceDashboard(),
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
              _buildComplianceChart(),
              const SizedBox(height: 24),
              _buildOverdueAudits(dashboard['overdue_audits']),
              const SizedBox(height: 24),
              _buildNonCompliantAudits(dashboard['non_compliant_audits']),
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
            'Total Audits',
            summary['total_audits'].toString(),
            Icons.assignment,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Completed',
            summary['completed_audits'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Non-Compliant',
            summary['non_compliant_audits'].toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Overdue',
            summary['overdue_audits'].toString(),
            Icons.error,
            Colors.red,
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

  Widget _buildComplianceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compliance Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildCompliancePieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildCompliancePieChartSections() {
    final completed = _audits.where((a) => a.status == 'completed').length;
    final inProgress = _audits.where((a) => a.status == 'in_progress').length;
    final scheduled = _audits.where((a) => a.status == 'scheduled').length;
    final overdue = _audits.where((a) => a.isOverdue).length;

    return [
      PieChartSectionData(
        color: Colors.green,
        value: completed.toDouble(),
        title: 'Completed\n$completed',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: inProgress.toDouble(),
        title: 'In Progress\n$inProgress',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: scheduled.toDouble(),
        title: 'Scheduled\n$scheduled',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: overdue.toDouble(),
        title: 'Overdue\n$overdue',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ];
  }

  Widget _buildOverdueAudits(List<ComplianceAudit> audits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overdue Audits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (audits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No overdue audits', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...audits.take(5).map(_buildAuditItem),
          ],
        ),
      ),
    );
  }

  Widget _buildNonCompliantAudits(List<ComplianceAudit> audits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Non-Compliant Audits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (audits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No non-compliant audits', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...audits.take(5).map(_buildAuditItem),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredAudits = _filteredAudits;

    if (filteredAudits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No audits found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAudits.length,
      itemBuilder: (context, index) {
        final audit = filteredAudits[index];
        return _buildAuditCard(audit);
      },
    );
  }

  Widget _buildAuditCard(ComplianceAudit audit) {
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
                    audit.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(audit.status),
                _buildSeverityChip(audit.severity),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              audit.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${audit.auditType} - ${audit.category}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Auditor: ${audit.auditorId}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score: ${audit.complianceScore}/${audit.targetScore}'),
                      Text('Scheduled: ${_formatDate(audit.scheduledDate)}'),
                    ],
                  ),
                ),
                _buildComplianceIndicator(audit.compliancePercentage),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: audit.compliancePercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                audit.isCompliant ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem(ComplianceAudit audit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audit.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${audit.complianceScore}/${audit.targetScore} (${audit.compliancePercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildComplianceIndicator(audit.compliancePercentage),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'scheduled':
        color = Colors.blue;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      case 'remediation':
        color = Colors.purple;
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

  Widget _buildComplianceIndicator(double percentage) {
    Color color;
    if (percentage >= 95) {
      color = Colors.green;
    } else if (percentage >= 85) {
      color = Colors.blue;
    } else if (percentage >= 70) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAlertsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _complianceService.getComplianceAlerts(),
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
                Text('No compliance alerts', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
      future: _complianceService.getComplianceTrends(),
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
              _buildTrendsChart(trends),
              const SizedBox(height: 24),
              _buildTypeDistribution(trends['type_distribution']),
              const SizedBox(height: 24),
              _buildSeverityDistribution(trends['severity_distribution']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsChart(Map<String, dynamic> trends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compliance Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildTrendSpots(trends['monthly_audits']),
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildTrendSpots(Map<String, int> monthlyAudits) {
    final spots = <FlSpot>[];
    var index = 0;
    monthlyAudits.forEach((month, count) {
      spots.add(FlSpot(index.toDouble(), count.toDouble()));
      index++;
    });
    return spots;
  }

  Widget _buildTypeDistribution(Map<String, int> typeDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audits by Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...typeDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityDistribution(Map<String, int> severityDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audits by Severity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...severityDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int value) {
    final total = _audits.length;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateAuditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Compliance Audit'),
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
}