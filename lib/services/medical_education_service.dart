import 'dart:async';
import '../database/dao/medical_education_dao.dart';
import '../database/models/medical_education.dart';

class MedicalEducationService {
  static final MedicalEducationService _instance = MedicalEducationService._internal();
  factory MedicalEducationService() => _instance;
  MedicalEducationService._internal();

  final MedicalEducationDao _dao = MedicalEducationDao();
  final StreamController<List<MedicalEducation>> _educationController = 
      StreamController<List<MedicalEducation>>.broadcast();

  Stream<List<MedicalEducation>> get educationStream => _educationController.stream;

  // Create a new medical education
  Future<MedicalEducation> createEducation(MedicalEducation education) async {
    try {
      final createdEducation = await _dao.insert(education);
      await _refreshEducation();
      return createdEducation;
    } catch (e) {
      throw Exception('Failed to create medical education: $e');
    }
  }

  // Get all education
  Future<List<MedicalEducation>> getAllEducation() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw Exception('Failed to get medical education: $e');
    }
  }

  // Get education by type
  Future<List<MedicalEducation>> getEducationByType(String type) async {
    try {
      return await _dao.getByType(type);
    } catch (e) {
      throw Exception('Failed to get education by type: $e');
    }
  }

  // Get education by category
  Future<List<MedicalEducation>> getEducationByCategory(String category) async {
    try {
      return await _dao.getByCategory(category);
    } catch (e) {
      throw Exception('Failed to get education by category: $e');
    }
  }

  // Get education by status
  Future<List<MedicalEducation>> getEducationByStatus(String status) async {
    try {
      return await _dao.getByStatus(status);
    } catch (e) {
      throw Exception('Failed to get education by status: $e');
    }
  }

  // Get upcoming education
  Future<List<MedicalEducation>> getUpcomingEducation() async {
    try {
      return await _dao.getUpcomingEducation();
    } catch (e) {
      throw Exception('Failed to get upcoming education: $e');
    }
  }

  // Get ongoing education
  Future<List<MedicalEducation>> getOngoingEducation() async {
    try {
      return await _dao.getOngoingEducation();
    } catch (e) {
      throw Exception('Failed to get ongoing education: $e');
    }
  }

  // Get completed education
  Future<List<MedicalEducation>> getCompletedEducation() async {
    try {
      return await _dao.getCompletedEducation();
    } catch (e) {
      throw Exception('Failed to get completed education: $e');
    }
  }

  // Get education by provider
  Future<List<MedicalEducation>> getEducationByProvider(String provider) async {
    try {
      return await _dao.getByProvider(provider);
    } catch (e) {
      throw Exception('Failed to get education by provider: $e');
    }
  }

  // Get education by instructor
  Future<List<MedicalEducation>> getEducationByInstructor(String instructor) async {
    try {
      return await _dao.getByInstructor(instructor);
    } catch (e) {
      throw Exception('Failed to get education by instructor: $e');
    }
  }

  // Get available education
  Future<List<MedicalEducation>> getAvailableEducation() async {
    try {
      return await _dao.getAvailableEducation();
    } catch (e) {
      throw Exception('Failed to get available education: $e');
    }
  }

  // Get education with CME credits
  Future<List<MedicalEducation>> getEducationWithCMECredits() async {
    try {
      return await _dao.getEducationWithCMECredits();
    } catch (e) {
      throw Exception('Failed to get education with CME credits: $e');
    }
  }

  // Update participant count
  Future<bool> updateParticipantCount(String id, int currentParticipants) async {
    try {
      final result = await _dao.updateParticipantCount(id, currentParticipants);
      await _refreshEducation();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update participant count: $e');
    }
  }

  // Update education status
  Future<bool> updateEducationStatus(String id, String status, {DateTime? endDate}) async {
    try {
      final result = await _dao.updateEducationStatus(id, status, endDate: endDate);
      await _refreshEducation();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update education status: $e');
    }
  }

  // Search education
  Future<List<MedicalEducation>> searchEducation(String query) async {
    try {
      return await _dao.searchEducation(query);
    } catch (e) {
      throw Exception('Failed to search education: $e');
    }
  }

  // Get education by keyword
  Future<List<MedicalEducation>> getEducationByKeyword(String keyword) async {
    try {
      return await _dao.getByKeyword(keyword);
    } catch (e) {
      throw Exception('Failed to get education by keyword: $e');
    }
  }

  // Get education dashboard
  Future<Map<String, dynamic>> getEducationDashboard() async {
    try {
      final summary = await _dao.getEducationSummary();
      final upcomingEducation = await getUpcomingEducation();
      final ongoingEducation = await getOngoingEducation();
      final completedEducation = await getCompletedEducation();
      
      return {
        'summary': summary,
        'upcoming_education': upcomingEducation,
        'ongoing_education': ongoingEducation,
        'completed_education': completedEducation,
        'total_education': summary['total_education'],
        'upcoming_count': summary['upcoming_education'],
        'ongoing_count': summary['ongoing_education'],
        'completed_count': summary['completed_education'],
        'completion_rate': summary['total_education'] > 0 ? 
          (summary['completed_education'] / summary['total_education']) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get education dashboard: $e');
    }
  }

  // Get education trends
  Future<Map<String, dynamic>> getEducationTrends({int days = 365}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final allEducation = await _dao.getAll();
      final recentEducation = allEducation.where((e) => 
        e.startDate.isAfter(startDate) && e.startDate.isBefore(endDate)
      ).toList();
      
      final monthlyEducation = <String, int>{};
      final typeDistribution = <String, int>{};
      final categoryDistribution = <String, int>{};
      final statusDistribution = <String, int>{};
      final enrollmentProgress = <String, double>{};
      final cmeCredits = <String, double>{};
      
      for (final education in recentEducation) {
        // Monthly education
        final monthKey = '${education.startDate.year}-${education.startDate.month.toString().padLeft(2, '0')}';
        monthlyEducation[monthKey] = (monthlyEducation[monthKey] ?? 0) + 1;
        
        // Type distribution
        typeDistribution[education.type] = (typeDistribution[education.type] ?? 0) + 1;
        
        // Category distribution
        categoryDistribution[education.category] = (categoryDistribution[education.category] ?? 0) + 1;
        
        // Status distribution
        statusDistribution[education.status] = (statusDistribution[education.status] ?? 0) + 1;
        
        // Enrollment progress
        enrollmentProgress[education.id] = education.enrollmentProgress;
        
        // CME credits
        cmeCredits[education.id] = education.cmeCredits;
      }
      
      return {
        'monthly_education': monthlyEducation,
        'type_distribution': typeDistribution,
        'category_distribution': categoryDistribution,
        'status_distribution': statusDistribution,
        'enrollment_progress': enrollmentProgress,
        'cme_credits': cmeCredits,
        'total_recent_education': recentEducation.length,
        'average_enrollment_progress': enrollmentProgress.values.isNotEmpty ? 
          enrollmentProgress.values.reduce((a, b) => a + b) / enrollmentProgress.values.length : 0,
        'total_cme_credits': cmeCredits.values.reduce((a, b) => a + b),
      };
    } catch (e) {
      throw Exception('Failed to get education trends: $e');
    }
  }

  // Get education insights
  Future<List<Map<String, dynamic>>> getEducationInsights() async {
    try {
      final insights = <Map<String, dynamic>>[];
      
      final upcomingEducation = await getUpcomingEducation();
      final availableEducation = await getAvailableEducation();
      final cmeEducation = await getEducationWithCMECredits();
      
      // Upcoming education insights
      if (upcomingEducation.isNotEmpty) {
        insights.add({
          'type': 'upcoming',
          'title': 'Upcoming Education',
          'message': '${upcomingEducation.length} education sessions are coming up',
          'priority': 'medium',
          'data': upcomingEducation,
        });
      }
      
      // Available education insights
      if (availableEducation.isNotEmpty) {
        insights.add({
          'type': 'available',
          'title': 'Available Education',
          'message': '${availableEducation.length} education sessions have available spots',
          'priority': 'low',
          'data': availableEducation,
        });
      }
      
      // CME credits insights
      if (cmeEducation.isNotEmpty) {
        final totalCredits = cmeEducation.fold(0.0, (sum, e) => sum + e.cmeCredits);
        insights.add({
          'type': 'cme_credits',
          'title': 'CME Credits Available',
          'message': '${totalCredits.toStringAsFixed(1)} CME credits available across ${cmeEducation.length} sessions',
          'priority': 'medium',
          'data': cmeEducation,
        });
      }
      
      return insights;
    } catch (e) {
      throw Exception('Failed to get education insights: $e');
    }
  }

  // Get CME tracking
  Future<Map<String, dynamic>> getCMETracking() async {
    try {
      final allEducation = await _dao.getAll();
      final completedEducation = allEducation.where((e) => e.status == 'completed').toList();
      final cmeEducation = allEducation.where((e) => e.cmeCredits > 0).toList();
      
      final totalCMECredits = cmeEducation.fold(0.0, (sum, e) => sum + e.cmeCredits);
      final earnedCMECredits = completedEducation.fold(0.0, (sum, e) => sum + e.cmeCredits);
      
      final categoryCredits = <String, double>{};
      final typeCredits = <String, double>{};
      final providerCredits = <String, double>{};
      
      for (final education in completedEducation) {
        if (education.cmeCredits > 0) {
          categoryCredits[education.category] = (categoryCredits[education.category] ?? 0) + education.cmeCredits;
          typeCredits[education.type] = (typeCredits[education.type] ?? 0) + education.cmeCredits;
          providerCredits[education.provider] = (providerCredits[education.provider] ?? 0) + education.cmeCredits;
        }
      }
      
      return {
        'total_cme_credits': totalCMECredits,
        'earned_cme_credits': earnedCMECredits,
        'remaining_cme_credits': totalCMECredits - earnedCMECredits,
        'completion_rate': totalCMECredits > 0 ? (earnedCMECredits / totalCMECredits) * 100 : 0,
        'category_credits': categoryCredits,
        'type_credits': typeCredits,
        'provider_credits': providerCredits,
        'completed_sessions': completedEducation.length,
        'total_sessions': allEducation.length,
      };
    } catch (e) {
      throw Exception('Failed to get CME tracking: $e');
    }
  }

  // Refresh education stream
  Future<void> _refreshEducation() async {
    try {
      final education = await _dao.getAll();
      _educationController.add(education);
    } catch (e) {
      _educationController.addError(e);
    }
  }

  // Dispose resources
  void dispose() {
    _educationController.close();
  }
}