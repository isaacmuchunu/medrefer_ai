import 'package:flutter/material.dart';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/services/enterprise_analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';

class EnterpriseAnalyticsDashboard extends StatefulWidget {
  const EnterpriseAnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<EnterpriseAnalyticsDashboard> createState() => _EnterpriseAnalyticsDashboardState();
}

class _EnterpriseAnalyticsDashboardState extends State<EnterpriseAnalyticsDashboard>
    with TickerProviderStateMixin {
  late EnterpriseAnalyticsService _analyticsService;
  late TabController _tabController;
  
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  String _selectedTimeRange = '30d';

  @override
  void initState() {
    super.initState();
    _analyticsService = EnterpriseAnalyticsService();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      await _analyticsService.initialize();
      await _loadDashboardData();
      _analyticsService.addListener(_onAnalyticsUpdate);
    } catch (e) {
      debugPrint('Error initializing dashboard: $e');
    }
  }

  void _onAnalyticsUpdate() {
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _analyticsService.getDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.gray50,
      appBar: AppBar(
        title: Text(
          'Enterprise Analytics',
          style: AppStyle.txtInterBold24,
        ),
        backgroundColor: ColorConstant.whiteA700,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _onTimeRangeSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: '7d', child: Text('Last 7 Days')),
              PopupMenuItem(value: '30d', child: Text('Last 30 Days')),
              PopupMenuItem(value: '90d', child: Text('Last 90 Days')),
              PopupMenuItem(value: '1y', child: Text('Last Year')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Business', icon: Icon(Icons.business)),
            Tab(text: 'Reports', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildBusinessTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final metrics = _analyticsService.getRealTimeMetrics();
    final kpis = _dashboardData['kpis'] as List<Map<String, dynamic>>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPICards(kpis),
          SizedBox(height: 24.h),
          _buildRealTimeMetrics(metrics),
          SizedBox(height: 24.h),
          _buildTrendChart(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceMetrics(),
          SizedBox(height: 24.h),
          _buildResponseTimeChart(),
          SizedBox(height: 24.h),
          _buildErrorRateChart(),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBusinessMetrics(),
          SizedBox(height: 24.h),
          _buildRevenueChart(),
          SizedBox(height: 24.h),
          _buildSatisfactionChart(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportGenerator(),
          SizedBox(height: 24.h),
          _buildScheduledReports(),
          SizedBox(height: 24.h),
          _buildReportHistory(),
        ],
      ),
    );
  }

  Widget _buildKPICards(List<Map<String, dynamic>> kpis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Indicators',
          style: AppStyle.txtInterBold20,
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.5,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            final kpi = kpis[index];
            return _buildKPICard(kpi);
          },
        ),
      ],
    );
  }

  Widget _buildKPICard(Map<String, dynamic> kpi) {
    final value = kpi['value'] as int? ?? 0;
    final target = kpi['target'] as int? ?? 0;
    final trend = kpi['trend'] as String? ?? 'stable';
    final change = kpi['change'] as String? ?? '0%';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi['name'] as String? ?? '',
            style: AppStyle.txtInterMedium14.copyWith(
              color: ColorConstant.gray600,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                value.toString(),
                style: AppStyle.txtInterBold24.copyWith(
                  color: ColorConstant.blue600,
                ),
              ),
              Spacer(),
              Icon(
                trend == 'up' ? Icons.trending_up : Icons.trending_down,
                color: trend == 'up' ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Target: $target',
            style: AppStyle.txtInterRegular12.copyWith(
              color: ColorConstant.gray500,
            ),
          ),
          Text(
            change,
            style: AppStyle.txtInterMedium12.copyWith(
              color: trend == 'up' ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics(Map<String, double> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-time Metrics',
          style: AppStyle.txtInterBold20,
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.2,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final entry = metrics.entries.elementAt(index);
            return _buildMetricCard(entry.key, entry.value);
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(String name, double value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorConstant.gray200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 4.h),
          Text(
            _formatMetricName(name),
            style: AppStyle.txtInterRegular12,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final trends = _dashboardData['trends'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis',
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: trends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['value'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: ColorConstant.blue600,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 16.h),
          _buildMetricRow('Response Time', '245ms', Colors.green),
          _buildMetricRow('Error Rate', '0.2%', Colors.green),
          _buildMetricRow('Uptime', '99.9%', Colors.green),
          _buildMetricRow('Throughput', '1,250 req/min', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBusinessMetrics() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Metrics',
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 16.h),
          _buildMetricRow('Revenue Today', '\$12,450', Colors.green),
          _buildMetricRow('Patient Satisfaction', '4.8/5', Colors.blue),
          _buildMetricRow('Referral Success Rate', '87%', Colors.green),
          _buildMetricRow('New Patients Today', '23', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyle.txtInterMedium14),
          Text(
            value,
            style: AppStyle.txtInterBold14.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    return _buildChartContainer('Response Time Trend', _buildSampleLineChart());
  }

  Widget _buildErrorRateChart() {
    return _buildChartContainer('Error Rate Trend', _buildSampleLineChart());
  }

  Widget _buildRevenueChart() {
    return _buildChartContainer('Revenue Trend', _buildSampleBarChart());
  }

  Widget _buildSatisfactionChart() {
    return _buildChartContainer('Patient Satisfaction', _buildSampleLineChart());
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyle.txtInterBold18),
          SizedBox(height: 16.h),
          SizedBox(height: 200.h, child: chart),
        ],
      ),
    );
  }

  Widget _buildSampleLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(10, (index) => FlSpot(index.toDouble(), Random().nextDouble() * 100)),
            isCurved: true,
            color: ColorConstant.blue600,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) => 
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: Random().nextDouble() * 100,
                color: ColorConstant.blue600,
                width: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportGenerator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Report',
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _generateReport,
            icon: Icon(Icons.assessment),
            label: Text('Generate Analytics Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledReports() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled Reports',
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 16.h),
          _buildReportItem('Daily Summary', 'Every day at 8:00 AM', Icons.schedule),
          _buildReportItem('Weekly Analytics', 'Every Monday at 9:00 AM', Icons.schedule),
          _buildReportItem('Monthly Report', '1st of every month', Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildReportHistory() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.whiteA700,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report History',
            style: AppStyle.txtInterBold18,
          ),
          SizedBox(height: 16.h),
          _buildReportItem('Daily Summary - Dec 15', 'Generated 2 hours ago', Icons.description),
          _buildReportItem('Weekly Analytics - Week 50', 'Generated 1 day ago', Icons.description),
          _buildReportItem('Monthly Report - November', 'Generated 5 days ago', Icons.description),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: ColorConstant.blue600),
      title: Text(title, style: AppStyle.txtInterMedium14),
      subtitle: Text(subtitle, style: AppStyle.txtInterRegular12),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Handle report item tap
      },
    );
  }

  String _formatMetricName(String name) {
    return name.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  void _onTimeRangeSelected(String timeRange) {
    setState(() {
      _selectedTimeRange = timeRange;
    });
    _loadDashboardData();
  }

  void _generateReport() {
    // Implement report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report...')),
    );
  }

  @override
  void dispose() {
    _analyticsService.removeListener(_onAnalyticsUpdate);
    _tabController.dispose();
    super.dispose();
  }
}