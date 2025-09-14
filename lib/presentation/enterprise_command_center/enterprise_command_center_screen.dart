import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_export.dart';
import '../../services/advanced_ml_analytics_service.dart';
import '../../services/blockchain_medical_records_service.dart';
import '../../services/iot_medical_device_service.dart';
import '../../services/advanced_telemedicine_service.dart';
import '../../services/ai_workflow_automation_service.dart';
import '../../services/enterprise_integration_service.dart';
import '../../services/enterprise_erp_service.dart';
import '../../services/business_intelligence_service.dart';
import '../../services/multi_tenant_service.dart';
import '../../services/workflow_management_service.dart';
import '../../services/api_gateway_service.dart';
import '../../services/digital_asset_management_service.dart';
import '../../services/advanced_reporting_service.dart';
import '../../services/robotic_process_automation_service.dart';
import '../../services/comprehensive_error_handling_service.dart';

/// Enterprise Command Center - Comprehensive dashboard for all advanced features
class EnterpriseCommandCenterScreen extends StatefulWidget {
  const EnterpriseCommandCenterScreen({Key? key}) : super(key: key);

  @override
  State<EnterpriseCommandCenterScreen> createState() => _EnterpriseCommandCenterScreenState();
}

class _EnterpriseCommandCenterScreenState extends State<EnterpriseCommandCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Dashboard data
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _blockchainData = {};
  Map<String, dynamic> _iotData = {};
  Map<String, dynamic> _telemedicineData = {};
  Map<String, dynamic> _workflowData = {};
  Map<String, dynamic> _integrationData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final mlService = Provider.of<AdvancedMLAnalyticsService>(context, listen: false);
      final blockchainService = Provider.of<BlockchainMedicalRecordsService>(context, listen: false);
      final iotService = Provider.of<IoTMedicalDeviceService>(context, listen: false);
      final telemedicineService = Provider.of<AdvancedTelemedicineService>(context, listen: false);
      final workflowService = Provider.of<AIWorkflowAutomationService>(context, listen: false);
      final integrationService = Provider.of<EnterpriseIntegrationService>(context, listen: false);

      final futures = await Future.wait([
        mlService.getAnalyticsDashboard(),
        blockchainService.getBlockchainStats(),
        _getIoTDashboardData(iotService),
        _getTelemedicineDashboardData(telemedicineService),
        workflowService.getWorkflowMetrics(),
        integrationService.getSystemHealth(),
      ]);

      setState(() {
        _analyticsData = futures[0];
        _blockchainData = futures[1];
        _iotData = futures[2];
        _telemedicineData = futures[3];
        _workflowData = futures[4];
        _integrationData = futures[5];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getIoTDashboardData(IoTMedicalDeviceService service) async {
    // Simulate IoT dashboard data
    return {
      'connected_devices': 24,
      'active_patients': 18,
      'alerts_today': 7,
      'data_points_collected': 15420,
      'average_response_time': 0.8,
      'system_uptime': 99.7,
    };
  }

  Future<Map<String, dynamic>> _getTelemedicineDashboardData(AdvancedTelemedicineService service) async {
    // Simulate telemedicine dashboard data
    return {
      'active_sessions': 12,
      'completed_sessions_today': 45,
      'ar_sessions': 8,
      'vr_sessions': 3,
      'average_session_quality': 4.6,
      'total_participants': 89,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Enterprise Command Center',
          style: TextStyle(
            fontSize: 24.fSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'ML Analytics'),
            Tab(text: 'Blockchain'),
            Tab(text: 'IoT Devices'),
            Tab(text: 'Telemedicine'),
            Tab(text: 'AI Workflows'),
            Tab(text: 'Integrations'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMLAnalyticsTab(),
                _buildBlockchainTab(),
                _buildIoTTab(),
                _buildTelemedicineTab(),
                _buildWorkflowsTab(),
                _buildIntegrationsTab(),
              ],
            ),
    );
  }

  Widget _buildMLAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('AI/ML Analytics Dashboard', Icons.analytics),
          SizedBox(height: 16.v),
          
          // Key Metrics Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('Prediction Accuracy', '94.2%', Icons.target, Colors.green)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Models Active', '12', Icons.psychology, Colors.blue)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Predictions Today', '2,847', Icons.trending_up, Colors.orange)),
            ],
          ),
          
          SizedBox(height: 20.v),
          
          // Real-time Analytics Chart
          _buildChartCard(
            'Real-time Analytics Performance',
            _buildAnalyticsChart(),
            height: 300.v,
          ),
          
          SizedBox(height: 20.v),
          
          // AI Insights
          _buildInsightsCard('AI-Generated Insights', [
            'High-risk patient identification improved by 23%',
            'Resource optimization saved \$45,000 this month',
            'Diagnostic accuracy increased to 94.2%',
            'Anomaly detection prevented 8 critical incidents',
          ]),
        ],
      ),
    );
  }

  Widget _buildBlockchainTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Blockchain Medical Records', Icons.security),
          SizedBox(height: 16.v),
          
          // Blockchain Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Blocks', _blockchainData['total_blocks']?.toString() ?? '0', Icons.link, Colors.purple)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Transactions', _blockchainData['total_transactions']?.toString() ?? '0', Icons.swap_horiz, Colors.teal)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Records Secured', _blockchainData['total_records']?.toString() ?? '0', Icons.verified_user, Colors.green)),
            ],
          ),
          
          SizedBox(height: 20.v),
          
          // Blockchain Network Status
          _buildNetworkStatusCard(),
          
          SizedBox(height: 20.v),
          
          // Recent Transactions
          _buildTransactionsCard(),
        ],
      ),
    );
  }

  Widget _buildIoTTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('IoT Medical Devices', Icons.devices),
          SizedBox(height: 16.v),
          
          // IoT Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Connected Devices', _iotData['connected_devices']?.toString() ?? '0', Icons.device_hub, Colors.blue)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Active Patients', _iotData['active_patients']?.toString() ?? '0', Icons.person, Colors.green)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Alerts Today', _iotData['alerts_today']?.toString() ?? '0', Icons.warning, Colors.orange)),
            ],
          ),
          
          SizedBox(height: 20.v),
          
          // Device Status Grid
          _buildDeviceStatusGrid(),
          
          SizedBox(height: 20.v),
          
          // Vital Signs Monitoring
          _buildVitalSignsCard(),
        ],
      ),
    );
  }

  Widget _buildTelemedicineTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Advanced Telemedicine', Icons.video_call),
          SizedBox(height: 16.v),
          
          // Telemedicine Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Active Sessions', _telemedicineData['active_sessions']?.toString() ?? '0', Icons.videocam, Colors.red)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('AR Sessions', _telemedicineData['ar_sessions']?.toString() ?? '0', Icons.view_in_ar, Colors.purple)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('VR Sessions', _telemedicineData['vr_sessions']?.toString() ?? '0', Icons.threed_rotation, Colors.indigo)),
            ],
          ),
          
          SizedBox(height: 20.v),
          
          // Session Quality Chart
          _buildChartCard(
            'Session Quality Metrics',
            _buildQualityChart(),
            height: 250.v,
          ),
          
          SizedBox(height: 20.v),
          
          // AR/VR Features
          _buildARVRFeaturesCard(),
        ],
      ),
    );
  }

  Widget _buildWorkflowsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('AI Workflow Automation', Icons.auto_awesome),
          SizedBox(height: 16.v),
          
          // Workflow Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Active Workflows', _workflowData['active_workflows']?.toString() ?? '0', Icons.play_arrow, Colors.green)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('AI Agents', _workflowData['ai_agents']?.toString() ?? '0', Icons.smart_toy, Colors.blue)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Cost Savings', '\$${_formatNumber(_workflowData['cost_savings'])}', Icons.savings, Colors.orange)),
            ],
          ),
          
          SizedBox(height: 20.v),
          
          // Workflow Performance Chart
          _buildChartCard(
            'Workflow Performance',
            _buildWorkflowChart(),
            height: 280.v,
          ),
          
          SizedBox(height: 20.v),
          
          // AI Agents Status
          _buildAIAgentsCard(),
        ],
      ),
    );
  }

  Widget _buildIntegrationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Enterprise Integrations', Icons.integration_instructions),
          SizedBox(height: 16.v),
          
          // Integration Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Connected Systems', _integrationData['total_connections']?.toString() ?? '0', Icons.link, Colors.teal)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Active Connections', _integrationData['active_connections']?.toString() ?? '0', Icons.check_circle, Colors.green)),
              SizedBox(width: 12.h),
              Expanded(child: _buildMetricCard('Messages Processed', _formatNumber(_integrationData['total_messages_processed']), Icons.message, Colors.blue)),
            ],
          ),
          
          SizedBox(height: 20.v),
          
          // System Health Overview
          _buildSystemHealthCard(),
          
          SizedBox(height: 20.v),
          
          // Integration Standards
          _buildIntegrationStandardsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: Colors.indigo[100],
            borderRadius: BorderRadius.circular(12.h),
          ),
          child: Icon(icon, color: Colors.indigo[800], size: 24.adaptSize),
        ),
        SizedBox(width: 12.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 20.fSize,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24.adaptSize),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: color,
                    fontSize: 10.fSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.v),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart, {double? height}) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          SizedBox(
            height: height ?? 200.v,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 85),
              FlSpot(1, 88),
              FlSpot(2, 92),
              FlSpot(3, 89),
              FlSpot(4, 94),
              FlSpot(5, 96),
              FlSpot(6, 94),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 4.2, color: Colors.green, width: 20)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 4.6, color: Colors.blue, width: 20)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 4.1, color: Colors.orange, width: 20)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4.8, color: Colors.purple, width: 20)]),
        ],
      ),
    );
  }

  Widget _buildWorkflowChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: 35, color: Colors.blue, title: 'Completed', radius: 50),
          PieChartSectionData(value: 25, color: Colors.green, title: 'Running', radius: 50),
          PieChartSectionData(value: 30, color: Colors.orange, title: 'Pending', radius: 50),
          PieChartSectionData(value: 10, color: Colors.red, title: 'Failed', radius: 50),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(String title, List<String> insights) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20.adaptSize),
              SizedBox(width: 8.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.v),
          ...insights.map((insight) => Padding(
            padding: EdgeInsets.only(bottom: 8.v),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16.adaptSize),
                SizedBox(width: 8.h),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blockchain Network Status',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem('Network Nodes', '5', Colors.green),
              ),
              Expanded(
                child: _buildStatusItem('Consensus', '100%', Colors.blue),
              ),
              Expanded(
                child: _buildStatusItem('Security', 'High', Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8.v),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.fSize,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          ...List.generate(3, (index) => _buildTransactionItem(index)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(int index) {
    final types = ['Patient Record', 'Referral', 'Lab Result'];
    final hashes = ['0x1a2b3c...', '0x4d5e6f...', '0x7g8h9i...'];
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.v),
      child: Row(
        children: [
          Container(
            width: 40.h,
            height: 40.v,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Icon(Icons.receipt, color: Colors.indigo),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  types[index],
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  hashes[index],
                  style: TextStyle(
                    fontSize: 12.fSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Text(
              'Verified',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10.fSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusGrid() {
    final devices = [
      {'name': 'BP Monitor', 'status': 'Online', 'patients': 8, 'color': Colors.green},
      {'name': 'Heart Rate', 'status': 'Online', 'patients': 12, 'color': Colors.green},
      {'name': 'Glucose', 'status': 'Warning', 'patients': 6, 'color': Colors.orange},
      {'name': 'Oximeter', 'status': 'Online', 'patients': 10, 'color': Colors.green},
    ];

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Status Overview',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.h,
              mainAxisSpacing: 12.v,
              childAspectRatio: 1.5,
            ),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: (device['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.h),
                  border: Border.all(color: device['color'] as Color, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          device['name'] as String,
                          style: TextStyle(
                            fontSize: 14.fSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          width: 8.h,
                          height: 8.v,
                          decoration: BoxDecoration(
                            color: device['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.v),
                    Text(
                      '${device['patients']} patients',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      device['status'] as String,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: device['color'] as Color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-time Vital Signs Monitoring',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          Row(
            children: [
              Expanded(child: _buildVitalSign('Heart Rate', '72 BPM', Colors.red)),
              SizedBox(width: 12.h),
              Expanded(child: _buildVitalSign('Blood Pressure', '120/80', Colors.blue)),
              SizedBox(width: 12.h),
              Expanded(child: _buildVitalSign('Oxygen Sat', '98%', Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSign(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARVRFeaturesCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AR/VR Telemedicine Features',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(
                  'AR Annotations',
                  'Real-time medical annotations',
                  Icons.view_in_ar,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: _buildFeatureItem(
                  'VR Environments',
                  'Immersive consultation rooms',
                  Icons.threed_rotation,
                  Colors.indigo,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.v),
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(
                  'Virtual Tools',
                  'AI-powered diagnostic tools',
                  Icons.medical_services,
                  Colors.teal,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: _buildFeatureItem(
                  'Multi-party',
                  'Collaborative sessions',
                  Icons.group,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.adaptSize),
          SizedBox(height: 8.v),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAgentsCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Agents Performance',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          ...List.generate(4, (index) => _buildAgentItem(index)),
        ],
      ),
    );
  }

  Widget _buildAgentItem(int index) {
    final agents = [
      {'name': 'Patient Triage AI', 'accuracy': 94, 'status': 'Active'},
      {'name': 'Scheduling Optimizer', 'accuracy': 91, 'status': 'Active'},
      {'name': 'Document Processor', 'accuracy': 96, 'status': 'Active'},
      {'name': 'Quality Assurance', 'accuracy': 93, 'status': 'Active'},
    ];

    final agent = agents[index];
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.v),
      child: Row(
        children: [
          Container(
            width: 40.h,
            height: 40.v,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Icon(Icons.smart_toy, color: Colors.blue),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent['name'] as String,
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Accuracy: ${agent['accuracy']}%',
                  style: TextStyle(
                    fontSize: 12.fSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Text(
              agent['status'] as String,
              style: TextStyle(
                color: Colors.green,
                fontSize: 10.fSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health Overview',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          ...List.generate(4, (index) => _buildSystemHealthItem(index)),
        ],
      ),
    );
  }

  Widget _buildSystemHealthItem(int index) {
    final systems = [
      {'name': 'Epic EHR', 'status': 'Healthy', 'response': '120ms', 'color': Colors.green},
      {'name': 'PACS System', 'status': 'Healthy', 'response': '85ms', 'color': Colors.green},
      {'name': 'Laboratory LIS', 'status': 'Warning', 'response': '250ms', 'color': Colors.orange},
      {'name': 'Pharmacy System', 'status': 'Healthy', 'response': '95ms', 'color': Colors.green},
    ];

    final system = systems[index];
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.v),
      child: Row(
        children: [
          Container(
            width: 8.h,
            height: 8.v,
            decoration: BoxDecoration(
              color: system['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  system['name'] as String,
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Response: ${system['response']}',
                  style: TextStyle(
                    fontSize: 12.fSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
            decoration: BoxDecoration(
              color: (system['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Text(
              system['status'] as String,
              style: TextStyle(
                color: system['color'] as Color,
                fontSize: 10.fSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationStandardsCard() {
    final standards = [
      {'name': 'HL7 FHIR R4', 'status': 'Active', 'connections': 8},
      {'name': 'DICOM 2023e', 'status': 'Active', 'connections': 3},
      {'name': 'HL7 v2.8', 'status': 'Active', 'connections': 12},
      {'name': 'IHE XDS.b', 'status': 'Active', 'connections': 5},
    ];

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Healthcare Integration Standards',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.v),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.h,
              mainAxisSpacing: 12.v,
              childAspectRatio: 2,
            ),
            itemCount: standards.length,
            itemBuilder: (context, index) {
              final standard = standards[index];
              return Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.h),
                  border: Border.all(color: Colors.teal, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      standard['name'] as String,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      '${standard['connections']} connections',
                      style: TextStyle(
                        fontSize: 10.fSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is num) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      }
      return value.toString();
    }
    return value.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}