import 'dart:async';
import '../core/exceptions/emergency_service_exception.dart';
import '../database/dao/emergency_protocol_dao.dart';
import '../database/models/emergency_protocol.dart';

class EmergencyService {
  EmergencyService._internal();
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;

  final EmergencyProtocolDao _dao = EmergencyProtocolDao();
  final StreamController<List<EmergencyProtocol>> _protocolsController = 
      StreamController<List<EmergencyProtocol>>.broadcast();

  Stream<List<EmergencyProtocol>> get protocolsStream => _protocolsController.stream;

  // Create a new emergency protocol
  Future<EmergencyProtocol> createProtocol(EmergencyProtocol protocol) async {
    try {
      final createdProtocol = await _dao.insert(protocol);
      await _refreshProtocols();
      return createdProtocol;
    } catch (e) {
      throw EmergencyServiceException('Failed to create emergency protocol: $e');
    }
  }

  // Get all protocols
  Future<List<EmergencyProtocol>> getAllProtocols() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw EmergencyServiceException('Failed to get emergency protocols: $e');
    }
  }

  // Get protocols by emergency type
  Future<List<EmergencyProtocol>> getProtocolsByType(String emergencyType) async {
    try {
      return await _dao.getByEmergencyType(emergencyType);
    } catch (e) {
      throw EmergencyServiceException('Failed to get protocols by type: $e');
    }
  }

  // Get protocols by severity
  Future<List<EmergencyProtocol>> getProtocolsBySeverity(String severity) async {
    try {
      return await _dao.getBySeverity(severity);
    } catch (e) {
      throw EmergencyServiceException('Failed to get protocols by severity: $e');
    }
  }

  // Get protocols by category
  Future<List<EmergencyProtocol>> getProtocolsByCategory(String category) async {
    try {
      return await _dao.getByCategory(category);
    } catch (e) {
      throw EmergencyServiceException('Failed to get protocols by category: $e');
    }
  }

  // Get active protocols
  Future<List<EmergencyProtocol>> getActiveProtocols() async {
    try {
      return await _dao.getActiveProtocols();
    } catch (e) {
      throw EmergencyServiceException('Failed to get active protocols: $e');
    }
  }

  // Get critical protocols
  Future<List<EmergencyProtocol>> getCriticalProtocols() async {
    try {
      return await _dao.getCriticalProtocols();
    } catch (e) {
      throw EmergencyServiceException('Failed to get critical protocols: $e');
    }
  }

  // Get protocols by department
  Future<List<EmergencyProtocol>> getProtocolsByDepartment(String departmentId) async {
    try {
      return await _dao.getByDepartment(departmentId);
    } catch (e) {
      throw EmergencyServiceException('Failed to get protocols by department: $e');
    }
  }

  // Get protocols needing review
  Future<List<EmergencyProtocol>> getProtocolsNeedingReview() async {
    try {
      return await _dao.getProtocolsNeedingReview();
    } catch (e) {
      throw EmergencyServiceException('Failed to get protocols needing review: $e');
    }
  }

  // Get approved protocols
  Future<List<EmergencyProtocol>> getApprovedProtocols() async {
    try {
      return await _dao.getApprovedProtocols();
    } catch (e) {
      throw EmergencyServiceException('Failed to get approved protocols: $e');
    }
  }

  // Get public protocols
  Future<List<EmergencyProtocol>> getPublicProtocols() async {
    try {
      return await _dao.getPublicProtocols();
    } catch (e) {
      throw EmergencyServiceException('Failed to get public protocols: $e');
    }
  }

  // Update protocol status
  Future<bool> updateProtocolStatus(String id, String status) async {
    try {
      final result = await _dao.updateProtocolStatus(id, status);
      await _refreshProtocols();
      return result > 0;
    } catch (e) {
      throw EmergencyServiceException('Failed to update protocol status: $e');
    }
  }

  // Approve protocol
  Future<bool> approveProtocol(String id, String approvedBy) async {
    try {
      final result = await _dao.approveProtocol(id, approvedBy);
      await _refreshProtocols();
      return result > 0;
    } catch (e) {
      throw EmergencyServiceException('Failed to approve protocol: $e');
    }
  }

  // Update review date
  Future<bool> updateReviewDate(String id, DateTime nextReview) async {
    try {
      final result = await _dao.updateReviewDate(id, nextReview);
      await _refreshProtocols();
      return result > 0;
    } catch (e) {
      throw EmergencyServiceException('Failed to update review date: $e');
    }
  }

  // Search protocols
  Future<List<EmergencyProtocol>> searchProtocols(String query) async {
    try {
      return await _dao.searchProtocols(query);
    } catch (e) {
      throw EmergencyServiceException('Failed to search protocols: $e');
    }
  }

  // Get emergency dashboard
  Future<Map<String, dynamic>> getEmergencyDashboard() async {
    try {
      final summary = await _dao.getProtocolsSummary();
      final criticalProtocols = await getCriticalProtocols();
      final protocolsNeedingReview = await getProtocolsNeedingReview();
      final activeProtocols = await getActiveProtocols();
      final totalProtocols = summary['total_protocols'] ?? 0;
      final activeProtocolCount = summary['active_protocols'] ?? 0;

      return {
        'summary': summary,
        'critical_protocols': criticalProtocols,
        'protocols_needing_review': protocolsNeedingReview,
        'active_protocols': activeProtocols,
        'total_protocols': totalProtocols,
        'active_count': activeProtocolCount,
        'critical_count': summary['critical_protocols'],
        'needs_review_count': summary['needs_review'],
        'approval_rate': totalProtocols > 0
            ? (activeProtocolCount / totalProtocols) * 100
            : 0.0,
      };
    } catch (e) {
      throw EmergencyServiceException('Failed to get emergency dashboard: $e');
    }
  }

  // Get emergency alerts
  Future<List<Map<String, dynamic>>> getEmergencyAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];
      
      final protocolsNeedingReview = await getProtocolsNeedingReview();
      final criticalProtocols = await getCriticalProtocols();
      
      // Add review alerts
      for (final protocol in protocolsNeedingReview) {
        alerts.add({
          'type': 'review_needed',
          'severity': 'medium',
          'title': 'Protocol Review Required',
          'message': '${protocol.title} needs review',
          'protocol': protocol,
          'timestamp': DateTime.now(),
        });
      }
      
      // Add critical protocol alerts
      for (final protocol in criticalProtocols) {
        alerts.add({
          'type': 'critical_protocol',
          'severity': 'high',
          'title': 'Critical Protocol',
          'message': '${protocol.title} is a critical emergency protocol',
          'protocol': protocol,
          'timestamp': DateTime.now(),
        });
      }
      
      return alerts;
    } catch (e) {
      throw EmergencyServiceException('Failed to get emergency alerts: $e');
    }
  }

  // Get emergency response plan
  Future<Map<String, dynamic>> getEmergencyResponsePlan(String emergencyType) async {
    try {
      final protocols = await getProtocolsByType(emergencyType);
      final criticalProtocols = protocols.where((p) => p.isCritical).toList();
      final activeProtocols = protocols.where((p) => p.status == 'active').toList();
      
      return {
        'emergency_type': emergencyType,
        'total_protocols': protocols.length,
        'critical_protocols': criticalProtocols,
        'active_protocols': activeProtocols,
        'response_steps': _generateResponseSteps(protocols),
        'required_equipment': _getRequiredEquipment(protocols),
        'required_personnel': _getRequiredPersonnel(protocols),
        'contacts': _getEmergencyContacts(protocols),
      };
    } catch (e) {
      throw EmergencyServiceException('Failed to get emergency response plan: $e');
    }
  }

  List<String> _generateResponseSteps(List<EmergencyProtocol> protocols) {
    final steps = <String>[];
    for (final protocol in protocols) {
      steps.addAll(protocol.steps);
    }
    return steps.toSet().toList(); // Remove duplicates
  }

  List<String> _getRequiredEquipment(List<EmergencyProtocol> protocols) {
    final equipment = <String>[];
    for (final protocol in protocols) {
      equipment.addAll(protocol.requiredEquipment);
    }
    return equipment.toSet().toList(); // Remove duplicates
  }

  List<String> _getRequiredPersonnel(List<EmergencyProtocol> protocols) {
    final personnel = <String>[];
    for (final protocol in protocols) {
      personnel.addAll(protocol.requiredPersonnel);
    }
    return personnel.toSet().toList(); // Remove duplicates
  }

  List<String> _getEmergencyContacts(List<EmergencyProtocol> protocols) {
    final contacts = <String>[];
    for (final protocol in protocols) {
      contacts.addAll(protocol.contacts);
    }
    return contacts.toSet().toList(); // Remove duplicates
  }

  // Refresh protocols stream
  Future<void> _refreshProtocols() async {
    try {
      final protocols = await _dao.getAll();
      _protocolsController.add(protocols);
    } catch (e) {
      _protocolsController.addError(e);
    }
  }

  // Dispose resources
  void dispose() {
    _protocolsController.close();
  }
}