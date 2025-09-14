import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _totalPatients = 0;
  int _totalSpecialists = 0;
  int _totalReferrals = 0;
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    _totalPatients = await dataService.getPatientCount();
    _totalSpecialists = await dataService.getSpecialistCount();
    _totalReferrals = await dataService.getReferralCount();
    _recentActivity = await dataService.getRecentActivity(); // Assume this method exists or implement it
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'refresh', size: 24),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Patients', _totalPatients, Icons.people),
                  _buildStatCard('Specialists', _totalSpecialists, Icons.medical_services),
                  _buildStatCard('Referrals', _totalReferrals, Icons.assignment),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Referral Trends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: 7,
                    minY: 0,
                    maxY: 10,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 3),
                          FlSpot(1, 1),
                          FlSpot(2, 4),
                          FlSpot(3, 2),
                          FlSpot(4, 5),
                          FlSpot(5, 3),
                          FlSpot(6, 4),
                        ],
                        isCurved: true,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Enterprise Features', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildEnterpriseFeatureGrid(),
              const SizedBox(height: 24),
              const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivity.length,
                itemBuilder: (context, index) {
                  final activity = _recentActivity[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(activity['description']),
                    subtitle: Text(activity['timestamp'].toString()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.lightTheme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(title),
            Text(count.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterpriseFeatureGrid() {
    final features = [
      {
        'title': 'Data Analytics Hub',
        'subtitle': 'Advanced BI & ML Analytics',
        'icon': Icons.analytics,
        'color': Colors.blue,
        'route': AppRoutes.dataAnalyticsHubScreen,
      },
      {
        'title': 'System Administration',
        'subtitle': 'System Health & Configuration',
        'icon': Icons.admin_panel_settings,
        'color': Colors.purple,
        'route': AppRoutes.systemAdministrationScreen,
      },
      {
        'title': 'Enterprise Command Center',
        'subtitle': 'Comprehensive System Overview',
        'icon': Icons.dashboard,
        'color': Colors.green,
        'route': AppRoutes.enterpriseCommandCenter,
      },
      {
        'title': 'Compliance Dashboard',
        'subtitle': 'Regulatory Compliance Monitoring',
        'icon': Icons.security,
        'color': Colors.orange,
        'route': AppRoutes.complianceDashboard,
      },
      {
        'title': 'Quality Assurance',
        'subtitle': 'Quality Metrics & Auditing',
        'icon': Icons.verified,
        'color': Colors.teal,
        'route': AppRoutes.qualityAssuranceDashboard,
      },
      {
        'title': 'Research Analytics',
        'subtitle': 'Clinical Research & Trials',
        'icon': Icons.science,
        'color': Colors.indigo,
        'route': AppRoutes.researchAnalytics,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, feature['route'] as String);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 28,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (feature['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: feature['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}