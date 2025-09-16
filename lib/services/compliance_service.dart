import 'dart:async';
import '../database/dao/compliance_audit_dao.dart';
import '../database/models/compliance_audit.dart';

class ComplianceService {
  ComplianceService._internal();

  static final ComplianceService _instance = ComplianceService._internal();
  factory ComplianceService() => _instance;

  final ComplianceAuditDao _dao = ComplianceAuditDao();
  final StreamController<List<ComplianceAudit>> _auditsController = 
      StreamController<List<ComplianceAudit>>.broadcast();

  Stream<List<ComplianceAudit>> get auditsStream => _auditsController.stream;

  // Create a new compliance audit
  Future<ComplianceAudit> createAudit(ComplianceAudit audit) async {
    try {
      final createdAudit = await _dao.insert(audit);
      await _refreshAudits();
      return createdAudit;
    } catch (e) {
      throw ComplianceServiceException('Failed to create compliance audit: $e');
    }
  }

  // Get all audits
  Future<List<ComplianceAudit>> getAllAudits() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw ComplianceServiceException('Failed to get compliance audits: $e');
    }
  }

  // Get audits by type
  Future<List<ComplianceAudit>> getAuditsByType(String auditType) async {
    try {
      return await _dao.getByType(auditType);
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits by type: $e');
    }
  }

  // Get audits by status
  Future<List<ComplianceAudit>> getAuditsByStatus(String status) async {
    try {
      return await _dao.getByStatus(status);
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits by status: $e');
    }
  }

  // Get audits by severity
  Future<List<ComplianceAudit>> getAuditsBySeverity(String severity) async {
    try {
      return await _dao.getBySeverity(severity);
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits by severity: $e');
    }
  }

  // Get audits by category
  Future<List<ComplianceAudit>> getAuditsByCategory(String category) async {
    try {
      return await _dao.getByCategory(category);
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits by category: $e');
    }
  }

  // Get audits by auditor
  Future<List<ComplianceAudit>> getAuditsByAuditor(String auditorId) async {
    try {
      return await _dao.getByAuditor(auditorId);
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits by auditor: $e');
    }
  }

  // Get audits by department
  Future<List<ComplianceAudit>> getAuditsByDepartment(String departmentId) async {
    try {
      return await _dao.getByDepartment(departmentId);
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits by department: $e');
    }
  }

  // Get overdue audits
  Future<List<ComplianceAudit>> getOverdueAudits() async {
    try {
      return await _dao.getOverdueAudits();
    } catch (e) {
      throw ComplianceServiceException('Failed to get overdue audits: $e');
    }
  }

  // Get scheduled audits
  Future<List<ComplianceAudit>> getScheduledAudits() async {
    try {
      return await _dao.getScheduledAudits();
    } catch (e) {
      throw ComplianceServiceException('Failed to get scheduled audits: $e');
    }
  }

  // Get audits requiring remediation
  Future<List<ComplianceAudit>> getAuditsRequiringRemediation() async {
    try {
      return await _dao.getAuditsRequiringRemediation();
    } catch (e) {
      throw ComplianceServiceException('Failed to get audits requiring remediation: $e');
    }
  }

  // Get non-compliant audits
  Future<List<ComplianceAudit>> getNonCompliantAudits() async {
    try {
      return await _dao.getNonCompliantAudits();
    } catch (e) {
      throw ComplianceServiceException('Failed to get non-compliant audits: $e');
    }
  }

  // Update audit status
  Future<bool> updateAuditStatus(String id, String status, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final result = await _dao.updateAuditStatus(id, status, startDate: startDate, endDate: endDate);
      await _refreshAudits();
      return result > 0;
    } catch (e) {
      throw ComplianceServiceException('Failed to update audit status: $e');
    }
  }

  // Update compliance score
  Future<bool> updateComplianceScore(String id, double complianceScore, {String? report}) async {
    try {
      final result = await _dao.updateComplianceScore(id, complianceScore, report: report);
      await _refreshAudits();
      return result > 0;
    } catch (e) {
      throw ComplianceServiceException('Failed to update compliance score: $e');
    }
  }

  // Get compliance dashboard
  Future<Map<String, dynamic>> getComplianceDashboard() async {
    try {
      final summary = await _dao.getComplianceSummary();
      final overdueAudits = await getOverdueAudits();
      final nonCompliantAudits = await getNonCompliantAudits();
      final scheduledAudits = await getScheduledAudits();
      
      final totalAudits = summary['total_audits'] as int? ?? 0;
      final completedAudits = summary['completed_audits'] as int? ?? 0;

      return {
        'summary': summary,
        'overdue_audits': overdueAudits,
        'non_compliant_audits': nonCompliantAudits,
        'scheduled_audits': scheduledAudits,
        'total_audits': totalAudits,
        'completed_audits': completedAudits,
        'non_compliant_count': summary['non_compliant_audits'],
        'overdue_count': summary['overdue_audits'],
        'compliance_rate': totalAudits > 0 ? 
          (completedAudits / totalAudits) * 100 : 0,
      };
    } catch (e) {
      throw ComplianceServiceException('Failed to get compliance dashboard: $e');
    }
  }

  // Get compliance trends
  Future<Map<String, dynamic>> getComplianceTrends({int days = 90}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final allAudits = await _dao.getAll();
      final recentAudits = allAudits.where((a) => 
        a.scheduledDate.isAfter(startDate) && a.scheduledDate.isBefore(endDate)
      ).toList();
      
      final monthlyAudits = <String, int>{};
      final typeDistribution = <String, int>{};
      final statusDistribution = <String, int>{};
      final severityDistribution = <String, int>{};
      final categoryDistribution = <String, int>{};
      final complianceScores = <String, double>{};
      
      for (final audit in recentAudits) {
        // Monthly audits
        final monthKey = '${audit.scheduledDate.year}-${audit.scheduledDate.month.toString().padLeft(2, '0')}';
        monthlyAudits[monthKey] = (monthlyAudits[monthKey] ?? 0) + 1;
        
        // Type distribution
        typeDistribution[audit.auditType] = (typeDistribution[audit.auditType] ?? 0) + 1;
        
        // Status distribution
        statusDistribution[audit.status] = (statusDistribution[audit.status] ?? 0) + 1;
        
        // Severity distribution
        severityDistribution[audit.severity] = (severityDistribution[audit.severity] ?? 0) + 1;
        
        // Category distribution
        categoryDistribution[audit.category] = (categoryDistribution[audit.category] ?? 0) + 1;
        
        // Compliance scores
        complianceScores[audit.id] = audit.compliancePercentage;
      }
      
      return {
        'monthly_audits': monthlyAudits,
        'type_distribution': typeDistribution,
        'status_distribution': statusDistribution,
        'severity_distribution': severityDistribution,
        'category_distribution': categoryDistribution,
        'compliance_scores': complianceScores,
        'total_recent_audits': recentAudits.length,
        'average_compliance_score': complianceScores.values.isNotEmpty ? 
          complianceScores.values.reduce((a, b) => a + b) / complianceScores.values.length : 0,
      };
    } catch (e) {
      throw ComplianceServiceException('Failed to get compliance trends: $e');
    }
  }

  // Get compliance alerts
  Future<List<Map<String, dynamic>>> getComplianceAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];
      
      final overdueAudits = await getOverdueAudits();
      final nonCompliantAudits = await getNonCompliantAudits();
      final scheduledAudits = await getScheduledAudits();
      
      // Add overdue alerts
      for (final audit in overdueAudits) {
        alerts.add({
          'type': 'overdue',
          'severity': 'high',
          'title': 'Overdue Audit',
          'message': '${audit.title} is overdue by ${DateTime.now().difference(audit.dueDate!).inDays} days',
          'audit': audit,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add non-compliant alerts
      for (final audit in nonCompliantAudits) {
        alerts.add({
          'type': 'non_compliant',
          'severity': audit.severity == 'critical' ? 'high' : 'medium',
          'title': 'Non-Compliant Audit',
          'message': '${audit.title} scored ${audit.compliancePercentage.toStringAsFixed(1)}% (target: ${audit.targetScore}%)',
          'audit': audit,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add upcoming audits
      final upcomingAudits = scheduledAudits.where((a) => 
        a.scheduledDate.difference(DateTime.now()).inDays <= 7
      ).toList();
      
      for (final audit in upcomingAudits) {
        alerts.add({
          'type': 'upcoming',
          'severity': 'low',
          'title': 'Upcoming Audit',
          'message': '${audit.title} is scheduled in ${audit.scheduledDate.difference(DateTime.now()).inDays} days',
          'audit': audit,
          'timestamp': DateTime.now(),
        });
      }
      
      return alerts;
    } catch (e) {
      throw ComplianceServiceException('Failed to get compliance alerts: $e');
    }
  }

  // Get compliance risk assessment
  Future<Map<String, dynamic>> getComplianceRiskAssessment() async {
    try {
      final allAudits = await _dao.getAll();
      
      final totalAudits = allAudits.length;
      final completedAudits = allAudits.where((a) => a.status == 'completed').length;
      final nonCompliantAudits = allAudits.where((a) => !a.isCompliant).length;
      final overdueAudits = allAudits.where((a) => a.isOverdue).length;
      final criticalAudits = allAudits.where((a) => a.severity == 'critical').length;
      
      final averageComplianceScore = allAudits.isNotEmpty ? 
        allAudits.map((a) => a.compliancePercentage).reduce((a, b) => a + b) / allAudits.length : 0.0;
      
      // Risk calculation
      double riskScore = 0;
      if (totalAudits > 0) {
        if (nonCompliantAudits > 0) riskScore += (nonCompliantAudits / totalAudits) * 40;
        if (overdueAudits > 0) riskScore += (overdueAudits / totalAudits) * 30;
        if (criticalAudits > 0) riskScore += (criticalAudits / totalAudits) * 20;
      }
      if (averageComplianceScore < 80) riskScore += (80 - averageComplianceScore) / 80 * 10;
      
      var riskLevel = 'low';
      if (riskScore > 70) {
        riskLevel = 'high';
      } else if (riskScore > 40) riskLevel = 'medium';
      
      return {
        'total_audits': totalAudits,
        'completed_audits': completedAudits,
        'non_compliant_audits': nonCompliantAudits,
        'overdue_audits': overdueAudits,
        'critical_audits': criticalAudits,
        'average_compliance_score': averageComplianceScore,
        'risk_score': riskScore,
        'risk_level': riskLevel,
        'compliance_rate': totalAudits > 0 ? (completedAudits / totalAudits) * 100 : 0,
        'recommendations': _getRiskRecommendations(riskLevel, nonCompliantAudits, overdueAudits, criticalAudits),
      };
    } catch (e) {
      throw ComplianceServiceException('Failed to get compliance risk assessment: $e');
    }
  }

  List<String> _getRiskRecommendations(String riskLevel, int nonCompliant, int overdue, int critical) {
    final recommendations = <String>[];
    
    if (riskLevel == 'high') {
      recommendations.add('Immediate action required to address compliance issues');
    }
    
    if (nonCompliant > 0) {
      recommendations.add('Address $nonCompliant non-compliant audits');
    }
    
    if (overdue > 0) {
      recommendations.add('Complete $overdue overdue audits');
    }
    
    if (critical > 0) {
      recommendations.add('Prioritize $critical critical audits');
    }
    
    if (riskLevel == 'low') {
      recommendations.add('Maintain current compliance standards');
    }
    
    return recommendations;
  }

  // Refresh audits stream
  Future<void> _refreshAudits() async {
    try {
      final audits = await _dao.getAll();
      _auditsController.add(audits);
    } catch (e) {
      _auditsController.addError(ComplianceServiceException('Failed to refresh audits: $e'));
    }
  }

  // Dispose resources
  void dispose() {
    _auditsController.close();
  }
}

class ComplianceServiceException implements Exception {
  final String message;

  ComplianceServiceException(this.message);

  @override
  String toString() => 'ComplianceServiceException: $message';
}