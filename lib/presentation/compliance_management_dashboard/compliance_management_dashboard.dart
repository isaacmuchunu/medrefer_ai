import 'package:flutter/material.dart';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/services/compliance_management_service.dart';
import 'package:medrefer_ai/database/models/compliance_models.dart';

class ComplianceManagementDashboard extends StatefulWidget {
  const ComplianceManagementDashboard({Key? key}) : super(key: key);

  @override
  State<ComplianceManagementDashboard> createState() => _ComplianceManagementDashboardState();
}

class _ComplianceManagementDashboardState extends State<ComplianceManagementDashboard>
    with TickerProviderStateMixin {
  late ComplianceManagementService _complianceService;
  late TabController _tabController;
  
  Map<String, dynamic> _dashboardData = {};
  List<AuditLog> _recentAuditLogs = [];
  List<CompliancePolicy> _policies = [];
  List<ComplianceAssessment> _assessments = [];
  List<ComplianceViolation> _violations = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _complianceService = ComplianceManagementService();
    _tabController = TabController(length: 5, vsync: this);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _complianceService.initialize();
      await _loadDashboardData();
      _complianceService.addListener(_onComplianceUpdate);
    } catch (e) {
      debugPrint('Error initializing compliance dashboard: $e');
    }
  }

  void _onComplianceUpdate() {
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadDashboardMetrics(),
        _loadRecentAuditLogs(),
        _loadPolicies(),
        _loadAssessments(),
        _loadViolations(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardMetrics() async {
    final dashboardData = _complianceService.getComplianceDashboard();
    setState(() => _dashboardData = dashboardData);
  }

  Future<void> _loadRecentAuditLogs() async {
    final auditLogs = _complianceService.getAuditLogs(limit: 20);
    setState(() => _recentAuditLogs = auditLogs);
  }

  Future<void> _loadPolicies() async {
    final policies = _complianceService.getPolicies();
    setState(() => _policies = policies);
  }

  Future<void> _loadAssessments() async {
    final assessments = _complianceService.getAssessments();
    setState(() => _assessments = assessments);
  }

  Future<void> _loadViolations() async {
    final violations = _complianceService.getViolations();
    setState(() => _violations = violations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.gray50,
      appBar: AppBar(
        title: Text(
          'Compliance Management',
          style: AppStyle.txtInterBold24,
        ),
        backgroundColor: ColorConstant.whiteA700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Icon(Icons.assessment),
            onPressed: _showGenerateReportDialog,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text('Export Data')),
              PopupMenuItem(value: 'settings', child: Text('Compliance Settings')),
              PopupMenuItem(value: 'help', child: Text('Help & Support')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Audit Logs', icon: Icon(Icons.list_alt)),
            Tab(text: 'Policies', icon: Icon(Icons.policy)),
            Tab(text: 'Assessments', icon: Icon(Icons.assessment)),
            Tab(text: 'Violations', icon: Icon(Icons.warning)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildAuditLogsTab(),
                _buildPoliciesTab(),
                _buildAssessmentsTab(),
                _buildViolationsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateViolationDialog,
        child: Icon(Icons.add_alert),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceScoreCard(),
          SizedBox(height: 16.h),
          _buildMetricsGrid(),
          SizedBox(height: 16.h),
          _buildViolationsBySeverityChart(),
          SizedBox(height: 16.h),
          _buildRecentActivitiesCard(),
        ],
      ),
    );
  }

  Widget _buildComplianceScoreCard() {
    final score = _dashboardData['compliance_score'] as double? ?? 0.0;
    final riskLevel = _dashboardData['risk_level'] as String? ?? 'low';
    
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Compliance Score',
                        style: AppStyle.txtInterMedium14.copyWith(
                          color: ColorConstant.gray600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: AppStyle.txtInterBold36.copyWith(
                          color: scoreColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            _getRiskLevelIcon(riskLevel),
                            color: _getRiskLevelColor(riskLevel),
                            size: 16,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Risk Level: ${riskLevel.toUpperCase()}',
                            style: AppStyle.txtInterMedium12.copyWith(
                              color: _getRiskLevelColor(riskLevel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: ColorConstant.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Policies',
          _dashboardData['total_policies']?.toString() ?? '0',
          Icons.policy,
          Colors.blue,
          'Active: ${_dashboardData['active_policies'] ?? 0}',
        ),
        _buildMetricCard(
          'Assessments',
          _dashboardData['total_assessments']?.toString() ?? '0',
          Icons.assessment,
          Colors.green,
          'Completed: ${_dashboardData['completed_assessments'] ?? 0}',
        ),
        _buildMetricCard(
          'Violations',
          _dashboardData['total_violations']?.toString() ?? '0',
          Icons.warning,
          Colors.orange,
          'Open: ${_dashboardData['open_violations'] ?? 0}',
        ),
        _buildMetricCard(
          'Audit Events',
          _dashboardData['total_audit_events']?.toString() ?? '0',
          Icons.list_alt,
          Colors.purple,
          'Last 30 days',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                Spacer(),
                Text(
                  value,
                  style: AppStyle.txtInterBold24.copyWith(color: color),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppStyle.txtInterMedium14.copyWith(
                color: ColorConstant.gray600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppStyle.txtInterRegular12.copyWith(
                color: ColorConstant.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsBySeverityChart() {
    final violationsBySeverity = _dashboardData['violations_by_severity'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Violations by Severity',
              style: AppStyle.txtInterBold18,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildSeverityBar('Critical', violationsBySeverity['critical'] ?? 0, Colors.red),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildSeverityBar('High', violationsBySeverity['high'] ?? 0, Colors.orange),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildSeverityBar('Medium', violationsBySeverity['medium'] ?? 0, Colors.yellow),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildSeverityBar('Low', violationsBySeverity['low'] ?? 0, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBar(String label, int count, Color color) {
    final maxCount = _violations.length;
    final height = maxCount > 0 ? (count / maxCount * 100) : 0.0;
    
    return Column(
      children: [
        Container(
          height: 100.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: ColorConstant.gray100,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          count.toString(),
          style: AppStyle.txtInterBold16.copyWith(color: color),
        ),
        Text(
          label,
          style: AppStyle.txtInterRegular12.copyWith(
            color: ColorConstant.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesCard() {
    final recentActivities = _dashboardData['recent_activities'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: AppStyle.txtInterBold18,
            ),
            SizedBox(height: 16.h),
            if (recentActivities.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Text(
                    'No recent activities',
                    style: AppStyle.txtInterRegular14.copyWith(
                      color: ColorConstant.gray500,
                    ),
                  ),
                ),
              )
            else
              ...recentActivities.take(10).map((activity) => 
                _buildActivityItem(activity)
              ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: _getSeverityColor(activity['severity'] as String? ?? 'low'),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity['action']} ${activity['resource']}',
                  style: AppStyle.txtInterMedium14,
                ),
                Text(
                  'User: ${activity['user_id']} • ${_formatTimestamp(activity['timestamp'])}',
                  style: AppStyle.txtInterRegular12.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        _buildAuditLogFilters(),
        Expanded(
          child: _recentAuditLogs.isEmpty
              ? _buildEmptyState('No audit logs found')
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _recentAuditLogs.length,
                  itemBuilder: (context, index) {
                    final log = _recentAuditLogs[index];
                    return _buildAuditLogCard(log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAuditLogFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: ColorConstant.whiteA700,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'login', child: Text('Login')),
                DropdownMenuItem(value: 'read', child: Text('Read')),
                DropdownMenuItem(value: 'update', child: Text('Update')),
                DropdownMenuItem(value: 'create', child: Text('Create')),
                DropdownMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onChanged: (value) {
                // Implement filtering
              },
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Severities')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {
                // Implement filtering
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(AuditLog log) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(log.severity),
          child: Icon(
            _getEventTypeIcon(log.eventType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${log.action} ${log.resource}',
          style: AppStyle.txtInterMedium14,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${log.userId} • ${_formatTimestamp(log.timestamp.toIso8601String())}',
              style: AppStyle.txtInterRegular12,
            ),
            if (log.ipAddress != null)
              Text(
                'IP: ${log.ipAddress} • ${log.location ?? 'Unknown'}',
                style: AppStyle.txtInterRegular10.copyWith(
                  color: ColorConstant.gray500,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSeverityChip(log.severity),
            SizedBox(height: 4.h),
            Text(
              log.result ?? 'unknown',
              style: AppStyle.txtInterRegular10.copyWith(
                color: log.result == 'success' ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        onTap: () => _showAuditLogDetails(log),
      ),
    );
  }

  Widget _buildPoliciesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _policies.length,
      itemBuilder: (context, index) {
        final policy = _policies[index];
        return _buildPolicyCard(policy);
      },
    );
  }

  Widget _buildPolicyCard(CompliancePolicy policy) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(policy.category),
          child: Text(
            policy.category.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          policy.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              policy.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _buildStatusChip(policy.status),
                SizedBox(width: 8.w),
                Text(
                  'v${policy.version}',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
                Spacer(),
                Text(
                  'Effective: ${_formatDate(policy.effectiveDate)}',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onPolicyAction(value, policy),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('View Details')),
            PopupMenuItem(value: 'assess', child: Text('Create Assessment')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
          ],
        ),
        onTap: () => _showPolicyDetails(policy),
      ),
    );
  }

  Widget _buildAssessmentsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return _buildAssessmentCard(assessment);
      },
    );
  }

  Widget _buildAssessmentCard(ComplianceAssessment assessment) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAssessmentTypeColor(assessment.assessmentType),
          child: Icon(
            Icons.assessment,
            color: Colors.white,
          ),
        ),
        title: Text(
          assessment.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assessment.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _buildStatusChip(assessment.status),
                SizedBox(width: 8.w),
                if (assessment.overallScore != null)
                  Text(
                    'Score: ${assessment.overallScore}',
                    style: AppStyle.txtInterBold12.copyWith(
                      color: _getScoreColor(assessment.overallScore!),
                    ),
                  ),
                Spacer(),
                Text(
                  'Due: ${_formatDate(assessment.dueDate ?? assessment.endDate)}',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onAssessmentAction(value, assessment),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('View Details')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'report', child: Text('Generate Report')),
          ],
        ),
        onTap: () => _showAssessmentDetails(assessment),
      ),
    );
  }

  Widget _buildViolationsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _violations.length,
      itemBuilder: (context, index) {
        final violation = _violations[index];
        return _buildViolationCard(violation);
      },
    );
  }

  Widget _buildViolationCard(ComplianceViolation violation) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(violation.severity),
          child: Icon(
            _getViolationTypeIcon(violation.violationType),
            color: Colors.white,
          ),
        ),
        title: Text(
          violation.description,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSeverityChip(violation.severity),
                SizedBox(width: 8.w),
                _buildStatusChip(violation.status),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Reported by: ${violation.reportedBy} • ${_formatDate(violation.discoveredAt)}',
              style: AppStyle.txtInterRegular10.copyWith(
                color: ColorConstant.gray500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onViolationAction(value, violation),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('View Details')),
            PopupMenuItem(value: 'assign', child: Text('Assign')),
            PopupMenuItem(value: 'resolve', child: Text('Mark Resolved')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
          ],
        ),
        onTap: () => _showViolationDetails(violation),
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _getSeverityColor(severity).withOpacity(0.3)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: AppStyle.txtInterBold10.copyWith(
          color: _getSeverityColor(severity),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppStyle.txtInterBold10.copyWith(
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: ColorConstant.gray400),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppStyle.txtInterBold18.copyWith(color: ColorConstant.gray400),
          ),
        ],
      ),
    );
  }

  // Helper methods for colors and icons
  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskLevelIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'resolved':
      case 'active':
        return Colors.green;
      case 'in_progress':
      case 'investigating':
        return Colors.orange;
      case 'open':
      case 'draft':
        return Colors.blue;
      case 'failed':
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hipaa':
        return Colors.blue;
      case 'gdpr':
        return Colors.purple;
      case 'sox':
        return Colors.orange;
      case 'pci':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getAssessmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'internal':
        return Colors.blue;
      case 'external':
        return Colors.orange;
      case 'self':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(String score) {
    final scoreValue = double.tryParse(score.replaceAll('%', '')) ?? 0;
    if (scoreValue >= 80) return Colors.green;
    if (scoreValue >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'read':
        return Icons.visibility;
      case 'update':
        return Icons.edit;
      case 'create':
        return Icons.add;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  IconData _getViolationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breach':
        return Icons.security;
      case 'violation':
        return Icons.warning;
      case 'incident':
        return Icons.error;
      case 'non_compliance':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action handlers
  void _onMenuSelected(String value) {
    switch (value) {
      case 'export':
        // Implement export functionality
        break;
      case 'settings':
        // Implement settings navigation
        break;
      case 'help':
        // Implement help navigation
        break;
    }
  }

  void _onPolicyAction(String action, CompliancePolicy policy) {
    switch (action) {
      case 'view':
        _showPolicyDetails(policy);
        break;
      case 'assess':
        _showCreateAssessmentDialog(policy);
        break;
      case 'edit':
        // Implement edit functionality
        break;
      case 'archive':
        // Implement archive functionality
        break;
    }
  }

  void _onAssessmentAction(String action, ComplianceAssessment assessment) {
    switch (action) {
      case 'view':
        _showAssessmentDetails(assessment);
        break;
      case 'edit':
        // Implement edit functionality
        break;
      case 'report':
        _showGenerateReportDialog();
        break;
    }
  }

  void _onViolationAction(String action, ComplianceViolation violation) {
    switch (action) {
      case 'view':
        _showViolationDetails(violation);
        break;
      case 'assign':
        _showAssignViolationDialog(violation);
        break;
      case 'resolve':
        _resolveViolation(violation);
        break;
      case 'edit':
        // Implement edit functionality
        break;
    }
  }

  // Dialog methods
  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Compliance Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Report Type'),
              items: [
                DropdownMenuItem(value: 'audit', child: Text('Audit Report')),
                DropdownMenuItem(value: 'assessment', child: Text('Assessment Report')),
                DropdownMenuItem(value: 'violation', child: Text('Violation Report')),
                DropdownMenuItem(value: 'summary', child: Text('Summary Report')),
              ],
              onChanged: (value) {},
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Period'),
              items: [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement report generation
              Navigator.pop(context);
            },
            child: Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showCreateViolationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Compliance Violation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Violation Type'),
              items: [
                DropdownMenuItem(value: 'breach', child: Text('Data Breach')),
                DropdownMenuItem(value: 'violation', child: Text('Policy Violation')),
                DropdownMenuItem(value: 'incident', child: Text('Security Incident')),
                DropdownMenuItem(value: 'non_compliance', child: Text('Non-compliance')),
              ],
              onChanged: (value) {},
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Severity'),
              items: [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {},
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement violation creation
              Navigator.pop(context);
            },
            child: Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showCreateAssessmentDialog(CompliancePolicy policy) {
    // Implement create assessment dialog
  }

  void _showAssignViolationDialog(ComplianceViolation violation) {
    // Implement assign violation dialog
  }

  void _resolveViolation(ComplianceViolation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve Violation'),
        content: TextField(
          decoration: InputDecoration(labelText: 'Remediation Notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _complianceService.updateViolationStatus(violation.id, 'resolved');
              Navigator.pop(context);
            },
            child: Text('Resolve'),
          ),
        ],
      ),
    );
  }

  // Detail view methods
  void _showAuditLogDetails(AuditLog log) {
    // Implement audit log details view
  }

  void _showPolicyDetails(CompliancePolicy policy) {
    // Implement policy details view
  }

  void _showAssessmentDetails(ComplianceAssessment assessment) {
    // Implement assessment details view
  }

  void _showViolationDetails(ComplianceViolation violation) {
    // Implement violation details view
  }

  @override
  void dispose() {
    _complianceService.removeListener(_onComplianceUpdate);
    _tabController.dispose();
    super.dispose();
  }
}