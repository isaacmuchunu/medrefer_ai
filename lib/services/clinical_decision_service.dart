import 'dart:async';
import '../database/dao/clinical_decision_dao.dart';
import '../database/models/clinical_decision.dart';

class ClinicalDecisionService {
  static final ClinicalDecisionService _instance = ClinicalDecisionService._internal();
  factory ClinicalDecisionService() => _instance;
  ClinicalDecisionService._internal();

  final ClinicalDecisionDao _dao = ClinicalDecisionDao();
  final StreamController<List<ClinicalDecision>> _decisionsController = 
      StreamController<List<ClinicalDecision>>.broadcast();

  Stream<List<ClinicalDecision>> get decisionsStream => _decisionsController.stream;

  // Create a new clinical decision
  Future<ClinicalDecision> createDecision(ClinicalDecision decision) async {
    try {
      final createdDecision = await _dao.insert(decision);
      await _refreshDecisions();
      return createdDecision;
    } catch (e) {
      throw Exception('Failed to create clinical decision: $e');
    }
  }

  // Get all decisions
  Future<List<ClinicalDecision>> getAllDecisions() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw Exception('Failed to get clinical decisions: $e');
    }
  }

  // Get decisions by patient
  Future<List<ClinicalDecision>> getDecisionsByPatient(String patientId) async {
    try {
      return await _dao.getByPatient(patientId);
    } catch (e) {
      throw Exception('Failed to get patient decisions: $e');
    }
  }

  // Get decisions by specialist
  Future<List<ClinicalDecision>> getDecisionsBySpecialist(String specialistId) async {
    try {
      return await _dao.getBySpecialist(specialistId);
    } catch (e) {
      throw Exception('Failed to get specialist decisions: $e');
    }
  }

  // Get pending decisions
  Future<List<ClinicalDecision>> getPendingDecisions() async {
    try {
      return await _dao.getPendingDecisions();
    } catch (e) {
      throw Exception('Failed to get pending decisions: $e');
    }
  }

  // Get decisions by priority
  Future<List<ClinicalDecision>> getDecisionsByPriority(String priority) async {
    try {
      return await _dao.getByPriority(priority);
    } catch (e) {
      throw Exception('Failed to get decisions by priority: $e');
    }
  }

  // Get critical decisions
  Future<List<ClinicalDecision>> getCriticalDecisions() async {
    try {
      return await _dao.getByPriority('urgent');
    } catch (e) {
      throw Exception('Failed to get critical decisions: $e');
    }
  }

  // Update decision status
  Future<bool> updateDecisionStatus(String id, String status, {String? reviewedBy, String? reviewNotes}) async {
    try {
      final result = await _dao.updateStatus(id, status, reviewedBy: reviewedBy, reviewNotes: reviewNotes);
      await _refreshDecisions();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update decision status: $e');
    }
  }

  // Approve decision
  Future<bool> approveDecision(String id, String reviewedBy, {String? reviewNotes}) async {
    try {
      final result = await _dao.updateStatus(id, 'approved', reviewedBy: reviewedBy, reviewNotes: reviewNotes);
      await _refreshDecisions();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to approve decision: $e');
    }
  }

  // Reject decision
  Future<bool> rejectDecision(String id, String reviewedBy, String reviewNotes) async {
    try {
      final result = await _dao.updateStatus(id, 'rejected', reviewedBy: reviewedBy, reviewNotes: reviewNotes);
      await _refreshDecisions();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to reject decision: $e');
    }
  }

  // Implement decision
  Future<bool> implementDecision(String id, String reviewedBy) async {
    try {
      final result = await _dao.updateStatus(id, 'implemented', reviewedBy: reviewedBy);
      await _refreshDecisions();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to implement decision: $e');
    }
  }

  // Get expired decisions
  Future<List<ClinicalDecision>> getExpiredDecisions() async {
    try {
      return await _dao.getExpiredDecisions();
    } catch (e) {
      throw Exception('Failed to get expired decisions: $e');
    }
  }

  // Search decisions
  Future<List<ClinicalDecision>> searchDecisions(String query) async {
    try {
      return await _dao.searchDecisions(query);
    } catch (e) {
      throw Exception('Failed to search decisions: $e');
    }
  }

  // Get decision statistics
  Future<Map<String, dynamic>> getDecisionStatistics() async {
    try {
      final allDecisions = await _dao.getAll();
      
      final totalDecisions = allDecisions.length;
      final pendingDecisions = allDecisions.where((d) => d.status == 'pending').length;
      final approvedDecisions = allDecisions.where((d) => d.status == 'approved').length;
      final rejectedDecisions = allDecisions.where((d) => d.status == 'rejected').length;
      final implementedDecisions = allDecisions.where((d) => d.status == 'implemented').length;
      final urgentDecisions = allDecisions.where((d) => d.priority == 'urgent').length;
      final highConfidenceDecisions = allDecisions.where((d) => d.confidence == 'high').length;
      
      return {
        'total_decisions': totalDecisions,
        'pending_decisions': pendingDecisions,
        'approved_decisions': approvedDecisions,
        'rejected_decisions': rejectedDecisions,
        'implemented_decisions': implementedDecisions,
        'urgent_decisions': urgentDecisions,
        'high_confidence_decisions': highConfidenceDecisions,
        'approval_rate': totalDecisions > 0 ? (approvedDecisions / totalDecisions) * 100 : 0,
        'implementation_rate': totalDecisions > 0 ? (implementedDecisions / totalDecisions) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get decision statistics: $e');
    }
  }

  // Get decisions by decision type
  Future<List<ClinicalDecision>> getDecisionsByType(String decisionType) async {
    try {
      return await _dao.getByDecisionType(decisionType);
    } catch (e) {
      throw Exception('Failed to get decisions by type: $e');
    }
  }

  // Get decision trends
  Future<Map<String, dynamic>> getDecisionTrends({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final allDecisions = await _dao.getAll();
      final recentDecisions = allDecisions.where((d) => 
        d.createdAt.isAfter(startDate) && d.createdAt.isBefore(endDate)
      ).toList();
      
      final dailyDecisions = <String, int>{};
      final typeDistribution = <String, int>{};
      final priorityDistribution = <String, int>{};
      final confidenceDistribution = <String, int>{};
      
      for (final decision in recentDecisions) {
        final dateKey = '${decision.createdAt.year}-${decision.createdAt.month.toString().padLeft(2, '0')}-${decision.createdAt.day.toString().padLeft(2, '0')}';
        dailyDecisions[dateKey] = (dailyDecisions[dateKey] ?? 0) + 1;
        
        typeDistribution[decision.decisionType] = (typeDistribution[decision.decisionType] ?? 0) + 1;
        priorityDistribution[decision.priority] = (priorityDistribution[decision.priority] ?? 0) + 1;
        confidenceDistribution[decision.confidence] = (confidenceDistribution[decision.confidence] ?? 0) + 1;
      }
      
      return {
        'daily_decisions': dailyDecisions,
        'type_distribution': typeDistribution,
        'priority_distribution': priorityDistribution,
        'confidence_distribution': confidenceDistribution,
        'total_recent_decisions': recentDecisions.length,
      };
    } catch (e) {
      throw Exception('Failed to get decision trends: $e');
    }
  }

  // Refresh decisions stream
  Future<void> _refreshDecisions() async {
    try {
      final decisions = await _dao.getAll();
      _decisionsController.add(decisions);
    } catch (e) {
      _decisionsController.addError(e);
    }
  }

  // Dispose resources
  void dispose() {
    _decisionsController.close();
  }
}