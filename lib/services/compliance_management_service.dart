import 'dart:async';
import 'dart:math';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/database/models/compliance_models.dart';

/// Compliance Management Service for enterprise compliance tracking
class ComplianceManagementService extends ChangeNotifier {
  static final ComplianceManagementService _instance = ComplianceManagementService._internal();
  factory ComplianceManagementService() => _instance;
  ComplianceManagementService._internal();

  late LoggingService _loggingService;
  final List<AuditLog> _auditLogs = [];
  final List<CompliancePolicy> _policies = [];
  final List<ComplianceAssessment> _assessments = [];
  final List<ComplianceViolation> _violations = [];
  final List<ComplianceReport> _reports = [];

  // Statistics tracking
  int _totalAuditEvents = 0;
  int _totalViolations = 0;
  int _criticalViolations = 0;
  double _complianceScore = 0.0;

  /// Initialize the compliance service
  Future<void> initialize() async {
    try {
      _loggingService = LoggingService();
      
      // Initialize with sample data
      await _initializeSampleData();
      
      _loggingService.info('Compliance Management Service initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize Compliance Management Service', error: e);
      rethrow;
    }
  }

  /// Initialize with sample data
  Future<void> _initializeSampleData() async {
    // Sample compliance policies
    _policies.addAll([
      CompliancePolicy(
        id: 'policy_1',
        name: 'HIPAA Privacy Policy',
        description: 'Health Insurance Portability and Accountability Act privacy requirements',
        category: 'hipaa',
        version: '2.1',
        status: 'active',
        requirements: [
          'Administrative safeguards',
          'Physical safeguards',
          'Technical safeguards',
          'Audit controls',
        ],
        controls: {
          'access_control': 'Role-based access control implemented',
          'encryption': 'Data encrypted at rest and in transit',
          'audit_logging': 'All access logged and monitored',
        },
        applicableRoles: ['Doctor', 'Nurse', 'Admin'],
        effectiveDate: DateTime.now().subtract(Duration(days: 365)),
        policyOwner: 'Compliance Officer',
        approvalAuthority: 'Chief Medical Officer',
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        updatedAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      CompliancePolicy(
        id: 'policy_2',
        name: 'Data Protection Policy',
        description: 'General data protection and privacy requirements',
        category: 'gdpr',
        version: '1.5',
        status: 'active',
        requirements: [
          'Data minimization',
          'Purpose limitation',
          'Storage limitation',
          'Consent management',
        ],
        controls: {
          'data_inventory': 'Comprehensive data inventory maintained',
          'consent_tracking': 'User consent tracked and managed',
          'data_retention': 'Automated data retention policies',
        },
        applicableRoles: ['All'],
        effectiveDate: DateTime.now().subtract(Duration(days: 200)),
        policyOwner: 'Data Protection Officer',
        approvalAuthority: 'Chief Information Officer',
        createdAt: DateTime.now().subtract(Duration(days: 200)),
        updatedAt: DateTime.now().subtract(Duration(days: 15)),
      ),
    ]);

    // Sample compliance assessments
    _assessments.addAll([
      ComplianceAssessment(
        id: 'assessment_1',
        policyId: 'policy_1',
        name: 'HIPAA Annual Assessment 2024',
        description: 'Annual HIPAA compliance assessment',
        assessmentType: 'internal',
        status: 'completed',
        assessorId: 'assessor_1',
        assessorName: 'Dr. Jane Smith',
        assessorCompany: 'Internal Audit Team',
        controls: [
          AssessmentControl(
            id: 'control_1',
            controlId: 'AC-1',
            name: 'Access Control Policy',
            description: 'Access control policies are documented and implemented',
            controlType: 'administrative',
            status: 'implemented',
            evidence: 'Access control policy document v2.1',
            notes: 'Policy is comprehensive and well-documented',
            riskLevel: 'low',
            assessedAt: DateTime.now().subtract(Duration(days: 10)),
            assessedBy: 'assessor_1',
          ),
          AssessmentControl(
            id: 'control_2',
            controlId: 'SC-1',
            name: 'Data Encryption',
            description: 'All PHI is encrypted at rest and in transit',
            controlType: 'technical',
            status: 'implemented',
            evidence: 'Encryption configuration audit report',
            notes: 'AES-256 encryption implemented across all systems',
            riskLevel: 'low',
            assessedAt: DateTime.now().subtract(Duration(days: 10)),
            assessedBy: 'assessor_1',
          ),
        ],
        findings: {
          'strengths': [
            'Strong access control implementation',
            'Comprehensive audit logging',
            'Regular staff training',
          ],
          'weaknesses': [
            'Need to update incident response procedures',
            'Mobile device policy needs revision',
          ],
        },
        overallScore: '85%',
        riskLevel: 'medium',
        recommendations: [
          'Update incident response procedures',
          'Revise mobile device security policy',
          'Implement additional monitoring for high-risk areas',
        ],
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now().subtract(Duration(days: 5)),
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
      ),
    ]);

    // Sample compliance violations
    _violations.addAll([
      ComplianceViolation(
        id: 'violation_1',
        policyId: 'policy_1',
        violationType: 'breach',
        severity: 'high',
        status: 'resolved',
        reportedBy: 'user_1',
        assignedTo: 'security_team',
        description: 'Unauthorized access to patient records by terminated employee',
        rootCause: 'Access credentials not revoked upon termination',
        impact: 'Potential exposure of 150 patient records',
        remediation: 'Implemented automated access revocation process',
        affectedUsers: ['150 patients'],
        affectedData: ['Patient demographics', 'Medical history'],
        discoveredAt: DateTime.now().subtract(Duration(days: 45)),
        resolvedAt: DateTime.now().subtract(Duration(days: 30)),
        createdAt: DateTime.now().subtract(Duration(days: 45)),
        updatedAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      ComplianceViolation(
        id: 'violation_2',
        policyId: 'policy_2',
        violationType: 'violation',
        severity: 'medium',
        status: 'investigating',
        reportedBy: 'user_2',
        assignedTo: 'compliance_officer',
        description: 'Data retention policy not followed for inactive accounts',
        rootCause: 'Automated data retention process failed',
        impact: 'Personal data retained longer than required',
        affectedData: ['User account data'],
        discoveredAt: DateTime.now().subtract(Duration(days: 10)),
        dueDate: DateTime.now().add(Duration(days: 5)),
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
    ]);

    // Sample audit logs
    _generateSampleAuditLogs();

    _updateStatistics();
  }

  /// Generate sample audit logs
  void _generateSampleAuditLogs() {
    final events = [
      {'action': 'login', 'resource': 'system', 'eventType': 'login'},
      {'action': 'view', 'resource': 'patient', 'eventType': 'read'},
      {'action': 'update', 'resource': 'patient', 'eventType': 'update'},
      {'action': 'create', 'resource': 'referral', 'eventType': 'create'},
      {'action': 'delete', 'resource': 'document', 'eventType': 'delete'},
      {'action': 'access', 'resource': 'reports', 'eventType': 'access'},
    ];

    for (var i = 0; i < 100; i++) {
      final event = events[Random().nextInt(events.length)];
      final severity = ['low', 'medium', 'high', 'critical'][Random().nextInt(4)];
      
      _auditLogs.add(AuditLog(
        id: 'audit_$i',
        userId: 'user_${Random().nextInt(10)}',
        action: event['action']!,
        resource: event['resource']!,
        resourceId: '${event['resource']}_${Random().nextInt(1000)}',
        eventType: event['eventType']!,
        severity: severity,
        ipAddress: '192.168.1.${Random().nextInt(255)}',
        userAgent: 'MedRefer AI Mobile App',
        location: 'New York, NY',
        deviceId: 'device_${Random().nextInt(50)}',
        details: {
          'session_id': 'session_${Random().nextInt(1000)}',
          'duration': Random().nextInt(300),
        },
        result: Random().nextBool() ? 'success' : 'failure',
        timestamp: DateTime.now().subtract(Duration(hours: Random().nextInt(720))),
        createdAt: DateTime.now().subtract(Duration(hours: Random().nextInt(720))),
      ));
    }
  }

  /// Update statistics
  void _updateStatistics() {
    _totalAuditEvents = _auditLogs.length;
    _totalViolations = _violations.length;
    _criticalViolations = _violations.where((v) => v.severity == 'critical').length;
    
    // Calculate compliance score based on assessments
    if (_assessments.isNotEmpty) {
      final totalScore = _assessments.fold(0.0, (sum, assessment) {
        final score = double.tryParse(assessment.overallScore?.replaceAll('%', '') ?? '0') ?? 0;
        return sum + score;
      });
      _complianceScore = totalScore / _assessments.length;
    }
  }

  /// Log audit event
  Future<void> logAuditEvent({
    required String userId,
    required String action,
    required String resource,
    required String resourceId,
    required String eventType,
    String severity = 'low',
    String? organizationId,
    String? ipAddress,
    String? userAgent,
    String? location,
    String? deviceId,
    Map<String, dynamic>? details,
    Map<String, dynamic>? metadata,
    String? result,
    String? errorMessage,
  }) async {
    try {
      final auditLog = AuditLog(
        id: _generateId(),
        userId: userId,
        organizationId: organizationId,
        action: action,
        resource: resource,
        resourceId: resourceId,
        eventType: eventType,
        severity: severity,
        ipAddress: ipAddress,
        userAgent: userAgent,
        location: location,
        deviceId: deviceId,
        details: details ?? {},
        metadata: metadata ?? {},
        result: result,
        errorMessage: errorMessage,
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      );

      _auditLogs.add(auditLog);
      _totalAuditEvents++;
      
      _loggingService.debug('Audit event logged', context: 'Compliance', metadata: {
        'user_id': userId,
        'action': action,
        'resource': resource,
        'severity': severity,
      });

      // Check for suspicious activities
      _checkSuspiciousActivity(auditLog);
    } catch (e) {
      _loggingService.error('Failed to log audit event', error: e);
      rethrow;
    }
  }

  /// Check for suspicious activities
  void _checkSuspiciousActivity(AuditLog auditLog) {
    // Check for multiple failed login attempts
    if (auditLog.eventType == 'login' && auditLog.result == 'failure') {
      final recentFailedLogins = _auditLogs.where((log) =>
          log.userId == auditLog.userId &&
          log.eventType == 'login' &&
          log.result == 'failure' &&
          log.timestamp.isAfter(DateTime.now().subtract(Duration(minutes: 15)))).length;

      if (recentFailedLogins >= 5) {
        _createComplianceViolation(
          policyId: 'policy_1',
          violationType: 'breach',
          severity: 'high',
          description: 'Multiple failed login attempts detected',
          reportedBy: 'system',
        );
      }
    }

    // Check for unusual access patterns
    if (auditLog.eventType == 'read' && auditLog.resource == 'patient') {
      final recentAccess = _auditLogs.where((log) =>
          log.userId == auditLog.userId &&
          log.eventType == 'read' &&
          log.resource == 'patient' &&
          log.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 1)))).length;

      if (recentAccess >= 50) {
        _createComplianceViolation(
          policyId: 'policy_1',
          violationType: 'violation',
          severity: 'medium',
          description: 'Unusual patient data access pattern detected',
          reportedBy: 'system',
        );
      }
    }
  }

  /// Get audit logs
  List<AuditLog> getAuditLogs({
    String? userId,
    String? organizationId,
    String? eventType,
    String? severity,
    String? resource,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    return _auditLogs.where((log) {
      if (userId != null && log.userId != userId) return false;
      if (organizationId != null && log.organizationId != organizationId) return false;
      if (eventType != null && log.eventType != eventType) return false;
      if (severity != null && log.severity != severity) return false;
      if (resource != null && log.resource != resource) return false;
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate)) return false;
      return true;
    }).take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get compliance policies
  List<CompliancePolicy> getPolicies({
    String? category,
    String? status,
    String? organizationId,
  }) {
    return _policies.where((policy) {
      if (category != null && policy.category != category) return false;
      if (status != null && policy.status != status) return false;
      if (organizationId != null && policy.organizationId != organizationId) return false;
      return true;
    }).toList();
  }

  /// Get compliance assessments
  List<ComplianceAssessment> getAssessments({
    String? policyId,
    String? status,
    String? assessmentType,
    String? organizationId,
  }) {
    return _assessments.where((assessment) {
      if (policyId != null && assessment.policyId != policyId) return false;
      if (status != null && assessment.status != status) return false;
      if (assessmentType != null && assessment.assessmentType != assessmentType) return false;
      if (organizationId != null && assessment.organizationId != organizationId) return false;
      return true;
    }).toList();
  }

  /// Get compliance violations
  List<ComplianceViolation> getViolations({
    String? policyId,
    String? severity,
    String? status,
    String? violationType,
    String? organizationId,
  }) {
    return _violations.where((violation) {
      if (policyId != null && violation.policyId != policyId) return false;
      if (severity != null && violation.severity != severity) return false;
      if (status != null && violation.status != status) return false;
      if (violationType != null && violation.violationType != violationType) return false;
      if (organizationId != null && violation.organizationId != organizationId) return false;
      return true;
    }).toList();
  }

  /// Create compliance violation
  Future<String> createViolation({
    required String policyId,
    required String violationType,
    required String severity,
    required String description,
    String? organizationId,
    String? departmentId,
    required String reportedBy,
    String? assignedTo,
    String? rootCause,
    String? impact,
    List<String>? affectedUsers,
    List<String>? affectedData,
    DateTime? dueDate,
  }) async {
    try {
      final violation = ComplianceViolation(
        id: _generateId(),
        policyId: policyId,
        violationType: violationType,
        severity: severity,
        status: 'open',
        organizationId: organizationId,
        departmentId: departmentId,
        reportedBy: reportedBy,
        assignedTo: assignedTo,
        description: description,
        rootCause: rootCause,
        impact: impact,
        affectedUsers: affectedUsers ?? [],
        affectedData: affectedData ?? [],
        discoveredAt: DateTime.now(),
        dueDate: dueDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _violations.add(violation);
      _totalViolations++;
      if (severity == 'critical') _criticalViolations++;
      
      notifyListeners();

      _loggingService.info('Compliance violation created', context: 'Compliance', metadata: {
        'violation_id': violation.id,
        'policy_id': policyId,
        'severity': severity,
        'type': violationType,
      });

      return violation.id;
    } catch (e) {
      _loggingService.error('Failed to create compliance violation', error: e);
      rethrow;
    }
  }

  /// Update violation status
  Future<void> updateViolationStatus(String violationId, String status, {
    String? remediation,
    String? assignedTo,
  }) async {
    try {
      final index = _violations.indexWhere((v) => v.id == violationId);
      if (index != -1) {
        final violation = _violations[index];
        _violations[index] = ComplianceViolation(
          id: violation.id,
          policyId: violation.policyId,
          violationType: violation.violationType,
          severity: violation.severity,
          status: status,
          organizationId: violation.organizationId,
          departmentId: violation.departmentId,
          reportedBy: violation.reportedBy,
          assignedTo: assignedTo ?? violation.assignedTo,
          description: violation.description,
          rootCause: violation.rootCause,
          impact: violation.impact,
          remediation: remediation ?? violation.remediation,
          affectedUsers: violation.affectedUsers,
          affectedData: violation.affectedData,
          discoveredAt: violation.discoveredAt,
          resolvedAt: status == 'resolved' ? DateTime.now() : violation.resolvedAt,
          dueDate: violation.dueDate,
          metadata: violation.metadata,
          createdAt: violation.createdAt,
          updatedAt: DateTime.now(),
        );
        
        notifyListeners();
        
        _loggingService.info('Violation status updated', context: 'Compliance', metadata: {
          'violation_id': violationId,
          'status': status,
        });
      }
    } catch (e) {
      _loggingService.error('Failed to update violation status', error: e);
      rethrow;
    }
  }

  /// Generate compliance report
  Future<String> generateReport({
    required String name,
    required String description,
    required String reportType,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? organizationId,
    String? policyId,
    String? assessmentId,
  }) async {
    try {
      final report = ComplianceReport(
        id: _generateId(),
        name: name,
        description: description,
        reportType: reportType,
        organizationId: organizationId,
        policyId: policyId,
        assessmentId: assessmentId,
        period: period,
        startDate: startDate,
        endDate: endDate,
        status: 'generated',
        generatedBy: 'system',
        generatedAt: DateTime.now(),
        data: await _generateReportData(reportType, startDate, endDate),
        fileFormat: 'pdf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _reports.add(report);
      notifyListeners();

      _loggingService.info('Compliance report generated', context: 'Compliance', metadata: {
        'report_id': report.id,
        'report_type': reportType,
        'period': period,
      });

      return report.id;
    } catch (e) {
      _loggingService.error('Failed to generate compliance report', error: e);
      rethrow;
    }
  }

  /// Generate report data
  Future<Map<String, dynamic>> _generateReportData(String reportType, DateTime startDate, DateTime endDate) async {
    switch (reportType) {
      case 'audit':
        return _generateAuditReportData(startDate, endDate);
      case 'assessment':
        return _generateAssessmentReportData(startDate, endDate);
      case 'violation':
        return _generateViolationReportData(startDate, endDate);
      case 'summary':
        return _generateSummaryReportData(startDate, endDate);
      default:
        return {};
    }
  }

  /// Generate audit report data
  Map<String, dynamic> _generateAuditReportData(DateTime startDate, DateTime endDate) {
    final auditLogs = getAuditLogs(startDate: startDate, endDate: endDate);
    
    final eventTypeCounts = <String, int>{};
    final severityCounts = <String, int>{};
    final resourceCounts = <String, int>{};
    
    for (final log in auditLogs) {
      eventTypeCounts[log.eventType] = (eventTypeCounts[log.eventType] ?? 0) + 1;
      severityCounts[log.severity] = (severityCounts[log.severity] ?? 0) + 1;
      resourceCounts[log.resource] = (resourceCounts[log.resource] ?? 0) + 1;
    }

    return {
      'total_events': auditLogs.length,
      'event_type_distribution': eventTypeCounts,
      'severity_distribution': severityCounts,
      'resource_distribution': resourceCounts,
      'top_users': _getTopUsers(auditLogs),
      'suspicious_activities': _getSuspiciousActivities(auditLogs),
    };
  }

  /// Generate assessment report data
  Map<String, dynamic> _generateAssessmentReportData(DateTime startDate, DateTime endDate) {
    final assessments = getAssessments().where((a) => 
        a.startDate.isAfter(startDate) && a.startDate.isBefore(endDate)).toList();

    return {
      'total_assessments': assessments.length,
      'completed_assessments': assessments.where((a) => a.status == 'completed').length,
      'average_score': assessments.isNotEmpty 
          ? assessments.fold(0.0, (sum, a) => sum + (double.tryParse(a.overallScore?.replaceAll('%', '') ?? '0') ?? 0)) / assessments.length
          : 0.0,
      'risk_distribution': _getRiskDistribution(assessments),
      'common_gaps': _getCommonGaps(assessments),
    };
  }

  /// Generate violation report data
  Map<String, dynamic> _generateViolationReportData(DateTime startDate, DateTime endDate) {
    final violations = getViolations().where((v) => 
        v.discoveredAt.isAfter(startDate) && v.discoveredAt.isBefore(endDate)).toList();

    final severityCounts = <String, int>{};
    final statusCounts = <String, int>{};
    final typeCounts = <String, int>{};
    
    for (final violation in violations) {
      severityCounts[violation.severity] = (severityCounts[violation.severity] ?? 0) + 1;
      statusCounts[violation.status] = (statusCounts[violation.status] ?? 0) + 1;
      typeCounts[violation.violationType] = (typeCounts[violation.violationType] ?? 0) + 1;
    }

    return {
      'total_violations': violations.length,
      'severity_distribution': severityCounts,
      'status_distribution': statusCounts,
      'type_distribution': typeCounts,
      'resolution_time': _getAverageResolutionTime(violations),
      'common_causes': _getCommonCauses(violations),
    };
  }

  /// Generate summary report data
  Map<String, dynamic> _generateSummaryReportData(DateTime startDate, DateTime endDate) {
    return {
      'compliance_score': _complianceScore,
      'total_policies': _policies.length,
      'active_policies': _policies.where((p) => p.status == 'active').length,
      'total_assessments': _assessments.length,
      'total_violations': _totalViolations,
      'critical_violations': _criticalViolations,
      'total_audit_events': _totalAuditEvents,
      'risk_level': _getOverallRiskLevel(),
    };
  }

  /// Helper methods for report generation
  List<Map<String, dynamic>> _getTopUsers(List<AuditLog> logs) {
    final userCounts = <String, int>{};
    for (final log in logs) {
      userCounts[log.userId] = (userCounts[log.userId] ?? 0) + 1;
    }
    
    return userCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10)
        .map((e) => {'user_id': e.key, 'count': e.value})
        .toList();
  }

  List<Map<String, dynamic>> _getSuspiciousActivities(List<AuditLog> logs) {
    return logs
        .where((log) => log.severity == 'high' || log.severity == 'critical')
        .take(10)
        .map((log) => {
          'timestamp': log.timestamp.toIso8601String(),
          'user_id': log.userId,
          'action': log.action,
          'resource': log.resource,
          'severity': log.severity,
        })
        .toList();
  }

  Map<String, int> _getRiskDistribution(List<ComplianceAssessment> assessments) {
    final riskCounts = <String, int>{};
    for (final assessment in assessments) {
      riskCounts[assessment.riskLevel ?? 'unknown'] = (riskCounts[assessment.riskLevel ?? 'unknown'] ?? 0) + 1;
    }
    return riskCounts;
  }

  List<String> _getCommonGaps(List<ComplianceAssessment> assessments) {
    final gapCounts = <String, int>{};
    for (final assessment in assessments) {
      for (final control in assessment.controls) {
        if (control.status != 'implemented') {
          gapCounts[control.name] = (gapCounts[control.name] ?? 0) + 1;
        }
      }
    }
    
    return gapCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5)
        .map((e) => e.key)
        .toList();
  }

  double _getAverageResolutionTime(List<ComplianceViolation> violations) {
    final resolvedViolations = violations.where((v) => v.resolvedAt != null).toList();
    if (resolvedViolations.isEmpty) return 0.0;
    
    final totalDays = resolvedViolations.fold(0.0, (sum, v) => 
        sum + v.resolvedAt!.difference(v.discoveredAt).inDays);
    
    return totalDays / resolvedViolations.length;
  }

  List<String> _getCommonCauses(List<ComplianceViolation> violations) {
    final causeCounts = <String, int>{};
    for (final violation in violations) {
      if (violation.rootCause != null) {
        causeCounts[violation.rootCause!] = (causeCounts[violation.rootCause!] ?? 0) + 1;
      }
    }
    
    return causeCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5)
        .map((e) => e.key)
        .toList();
  }

  String _getOverallRiskLevel() {
    if (_criticalViolations > 0) return 'critical';
    if (_violations.any((v) => v.severity == 'high')) return 'high';
    if (_violations.any((v) => v.severity == 'medium')) return 'medium';
    return 'low';
  }

  /// Get compliance dashboard data
  Map<String, dynamic> getComplianceDashboard() {
    return {
      'compliance_score': _complianceScore,
      'total_policies': _policies.length,
      'active_policies': _policies.where((p) => p.status == 'active').length,
      'total_assessments': _assessments.length,
      'completed_assessments': _assessments.where((a) => a.status == 'completed').length,
      'total_violations': _totalViolations,
      'open_violations': _violations.where((v) => v.status != 'resolved').length,
      'critical_violations': _criticalViolations,
      'total_audit_events': _totalAuditEvents,
      'recent_activities': _auditLogs.take(10).map((log) => {
        'timestamp': log.timestamp.toIso8601String(),
        'user_id': log.userId,
        'action': log.action,
        'resource': log.resource,
        'severity': log.severity,
      }).toList(),
      'violations_by_severity': {
        'critical': _violations.where((v) => v.severity == 'critical').length,
        'high': _violations.where((v) => v.severity == 'high').length,
        'medium': _violations.where((v) => v.severity == 'medium').length,
        'low': _violations.where((v) => v.severity == 'low').length,
      },
    };
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}