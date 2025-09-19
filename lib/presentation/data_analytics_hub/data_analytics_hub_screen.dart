import 'package:fl_chart/fl_chart.dart';
import '../../core/app_export.dart';
import '../../services/business_intelligence_service.dart';
import '../../services/advanced_ml_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';

class DataAnalyticsHubScreen extends StatefulWidget {
  const DataAnalyticsHubScreen({super.key});

  @override
  State<DataAnalyticsHubScreen> createState() => _DataAnalyticsHubScreenState();
}

class _DataAnalyticsHubScreenState extends State<DataAnalyticsHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Analytics data
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _mlAnalyticsData = {};
  List<Map<String, dynamic>> _dashboards = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      final biService = Provider.of<BusinessIntelligenceService>(context, listen: false);
      final mlService = Provider.of<AdvancedMLAnalyticsService>(context, listen: false);
      
      // Load sample analytics data
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      
      setState(() {
        _analyticsData = {
          'totalPatients': 15420,
          'totalAppointments': 8932,
          'totalReferrals': 3421,
          'revenue': 2847563.50,
          'growthRate': 12.5,
          'satisfactionScore': 4.7,
        };
        
        _mlAnalyticsData = {
          'predictionAccuracy': 94.2,
          'anomaliesDetected': 23,
          'riskPatients': 156,
          'automatedDecisions': 1247,
        };
        
        _dashboards = [
          {'name': 'Patient Overview', 'widgets': 8, 'views': 342},
          {'name': 'Financial Dashboard', 'widgets': 12, 'views': 189},
          {'name': 'Operational Metrics', 'widgets': 6, 'views': 234},
          {'name': 'Quality Indicators', 'widgets': 10, 'views': 167},
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Data Analytics Hub',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to analytics settings
            },
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildAnalyticsContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading analytics data...'),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return Column(
      children: [
        // Key Metrics Cards
        _buildKeyMetricsSection(),
        
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'ML Analytics'),
              Tab(text: 'Dashboards'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildMLAnalyticsTab(),
              _buildDashboardsTab(),
              _buildReportsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Performance Indicators',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMetricCard(
                  'Total Patients',
                  _analyticsData['totalPatients']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                  '+${_analyticsData['growthRate']}%',
                ),
                _buildMetricCard(
                  'Appointments',
                  _analyticsData['totalAppointments']?.toString() ?? '0',
                  Icons.calendar_today,
                  Colors.green,
                  'This month',
                ),
                _buildMetricCard(
                  'Referrals',
                  _analyticsData['totalReferrals']?.toString() ?? '0',
                  Icons.send,
                  Colors.orange,
                  'Active',
                ),
                _buildMetricCard(
                  'Revenue',
                  '\$${(_analyticsData['revenue'] ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                  'YTD',
                ),
                _buildMetricCard(
                  'Satisfaction',
                  '${_analyticsData['satisfactionScore']}/5.0',
                  Icons.star,
                  Colors.amber,
                  'Average',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Patient Growth Chart
          _buildChartCard(
            'Patient Growth Trend',
            _buildLineChart(),
          ),
          const SizedBox(height: 16),
          
          // Revenue vs Appointments
          Row(
            children: [
              Expanded(
                child: _buildChartCard(
                  'Monthly Revenue',
                  _buildBarChart(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Appointment Types',
                  _buildPieChart(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Recent Activity
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildMLAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ML Performance Metrics
          _buildMLMetricsCard(),
          const SizedBox(height: 16),
          
          // Prediction Results
          _buildPredictionResultsCard(),
          const SizedBox(height: 16),
          
          // Risk Analysis
          _buildRiskAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildDashboardsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dashboards.length,
      itemBuilder: (context, index) {
        final dashboard = _dashboards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.dashboard,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(dashboard['name']),
            subtitle: Text('${dashboard['widgets']} widgets • ${dashboard['views']} views'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Dashboard')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Dashboard')),
                const PopupMenuItem(value: 'share', child: Text('Share Dashboard')),
                const PopupMenuItem(value: 'export', child: Text('Export Dashboard')),
              ],
              onSelected: (value) {
                // Handle dashboard actions
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${value.toString().toUpperCase()} ${dashboard['name']}')),
                );
              },
            ),
            onTap: () {
              // Navigate to dashboard view
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${dashboard['name']}')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard('Patient Summary Report', 'Generated daily', Icons.people, Colors.blue),
        _buildReportCard('Financial Analysis', 'Generated weekly', Icons.attach_money, Colors.green),
        _buildReportCard('Quality Metrics', 'Generated monthly', Icons.star, Colors.orange),
        _buildReportCard('Operational Report', 'Generated weekly', Icons.business, Colors.purple),
        _buildReportCard('Compliance Audit', 'Generated quarterly', Icons.security, Colors.red),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
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
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 1),
              FlSpot(2, 4),
              FlSpot(3, 2),
              FlSpot(4, 5),
              FlSpot(5, 3),
              FlSpot(6, 4),
            ],
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.blue)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.blue)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.blue)]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.blue)]),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: 40, color: Colors.blue, title: '40%', radius: 60),
          PieChartSectionData(value: 30, color: Colors.green, title: '30%', radius: 60),
          PieChartSectionData(value: 20, color: Colors.orange, title: '20%', radius: 60),
          PieChartSectionData(value: 10, color: Colors.purple, title: '10%', radius: 60),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(Icons.analytics, color: Colors.grey[600]),
              ),
              title: Text('Analytics Report #${index + 1} Generated'),
              subtitle: Text('${DateTime.now().subtract(Duration(hours: index + 1))}'),
              trailing: const Icon(Icons.chevron_right),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMLMetricsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Machine Learning Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMLMetricItem(
                    'Prediction Accuracy',
                    '${_mlAnalyticsData['predictionAccuracy']}%',
                    Icons.adjust,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMLMetricItem(
                    'Anomalies Detected',
                    '${_mlAnalyticsData['anomaliesDetected']}',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMLMetricItem(
                    'High-Risk Patients',
                    '${_mlAnalyticsData['riskPatients']}',
                    Icons.person_outline,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildMLMetricItem(
                    'Automated Decisions',
                    '${_mlAnalyticsData['automatedDecisions']}',
                    Icons.smart_toy,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLMetricItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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

  Widget _buildPredictionResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Predictions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(Icons.psychology, color: Colors.blue),
              ),
              title: Text('Patient Risk Assessment #${index + 1}'),
              subtitle: Text('Confidence: ${92 - index * 3}%'),
              trailing: Chip(
                label: Text(index == 0 ? 'High Risk' : index == 1 ? 'Medium Risk' : 'Low Risk'),
                backgroundColor: index == 0 ? Colors.red.withOpacity(0.1) : 
                                index == 1 ? Colors.orange.withOpacity(0.1) : 
                                Colors.green.withOpacity(0.1),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysisCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Analysis Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            const SizedBox(height: 8),
            Text('High Risk Patients: 75%'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.45,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 8),
            Text('Medium Risk Patients: 45%'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.25,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text('Low Risk Patients: 25%'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'generate', child: Text('Generate Now')),
            const PopupMenuItem(value: 'schedule', child: Text('Schedule')),
            const PopupMenuItem(value: 'export', child: Text('Export')),
            const PopupMenuItem(value: 'share', child: Text('Share')),
          ],
          onSelected: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${value.toString().toUpperCase()} $title')),
            );
          },
        ),
      ),
    );
  }
}
