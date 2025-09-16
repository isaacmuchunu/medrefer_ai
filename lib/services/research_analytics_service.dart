import 'dart:async';
import '../database/dao/research_study_dao.dart';
import '../database/models/research_study.dart';

class ResearchAnalyticsService {
  _ResearchAnalyticsService();

  static final ResearchAnalyticsService _instance = _ResearchAnalyticsService();
  factory ResearchAnalyticsService() => _instance;

  final ResearchStudyDao _dao = ResearchStudyDao();
  final StreamController<List<ResearchStudy>> _studiesController = 
      StreamController<List<ResearchStudy>>.broadcast();

  Stream<List<ResearchStudy>> get studiesStream => _studiesController.stream;

  // Create a new research study
  Future<ResearchStudy> createStudy(ResearchStudy study) async {
    try {
      final createdStudy = await _dao.insert(study);
      await _refreshStudies();
      return createdStudy;
    } catch (e) {
      throw Exception('Failed to create research study: $e');
    }
  }

  // Get all studies
  Future<List<ResearchStudy>> getAllStudies() async {
    try {
      return await _dao.getAll();
    } catch (e) {
      throw Exception('Failed to get research studies: $e');
    }
  }

  // Get studies by status
  Future<List<ResearchStudy>> getStudiesByStatus(String status) async {
    try {
      return await _dao.getByStatus(status);
    } catch (e) {
      throw Exception('Failed to get studies by status: $e');
    }
  }

  // Get studies by type
  Future<List<ResearchStudy>> getStudiesByType(String studyType) async {
    try {
      return await _dao.getByType(studyType);
    } catch (e) {
      throw Exception('Failed to get studies by type: $e');
    }
  }

  // Get recruiting studies
  Future<List<ResearchStudy>> getRecruitingStudies() async {
    try {
      return await _dao.getRecruitingStudies();
    } catch (e) {
      throw Exception('Failed to get recruiting studies: $e');
    }
  }

  // Get active studies
  Future<List<ResearchStudy>> getActiveStudies() async {
    try {
      return await _dao.getActiveStudies();
    } catch (e) {
      throw Exception('Failed to get active studies: $e');
    }
  }

  // Get completed studies
  Future<List<ResearchStudy>> getCompletedStudies() async {
    try {
      return await _dao.getCompletedStudies();
    } catch (e) {
      throw Exception('Failed to get completed studies: $e');
    }
  }

  // Get studies by principal investigator
  Future<List<ResearchStudy>> getStudiesByInvestigator(String investigatorId) async {
    try {
      return await _dao.getByPrincipalInvestigator(investigatorId);
    } catch (e) {
      throw Exception('Failed to get studies by investigator: $e');
    }
  }

  // Get studies by department
  Future<List<ResearchStudy>> getStudiesByDepartment(String department) async {
    try {
      return await _dao.getByDepartment(department);
    } catch (e) {
      throw Exception('Failed to get studies by department: $e');
    }
  }

  // Update participant count
  Future<bool> updateParticipantCount(String id, int currentParticipants) async {
    try {
      final result = await _dao.updateParticipantCount(id, currentParticipants);
      await _refreshStudies();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update participant count: $e');
    }
  }

  // Update study status
  Future<bool> updateStudyStatus(String id, String status, {DateTime? endDate}) async {
    try {
      final result = await _dao.updateStudyStatus(id, status, endDate: endDate);
      await _refreshStudies();
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update study status: $e');
    }
  }

  // Search studies
  Future<List<ResearchStudy>> searchStudies(String query) async {
    try {
      return await _dao.searchStudies(query);
    } catch (e) {
      throw Exception('Failed to search studies: $e');
    }
  }

  // Get studies by keyword
  Future<List<ResearchStudy>> getStudiesByKeyword(String keyword) async {
    try {
      return await _dao.getByKeyword(keyword);
    } catch (e) {
      throw Exception('Failed to get studies by keyword: $e');
    }
  }

  // Get research analytics dashboard
  Future<Map<String, dynamic>> getResearchDashboard() async {
    try {
      final summary = await _dao.getStudiesSummary();
      final recruitingStudies = await getRecruitingStudies();
      final activeStudies = await getActiveStudies();
      final completedStudies = await getCompletedStudies();
      
      return {
        'summary': summary,
        'recruiting_studies': recruitingStudies,
        'active_studies': activeStudies,
        'completed_studies': completedStudies,
        'total_studies': summary['total_studies'],
        'active_count': summary['active_studies'],
        'recruiting_count': summary['recruiting_studies'],
        'completed_count': summary['completed_studies'],
        'completion_rate': summary['total_studies'] > 0 ? 
          (summary['completed_studies'] / summary['total_studies']) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get research dashboard: $e');
    }
  }

  // Get research trends
  Future<Map<String, dynamic>> getResearchTrends({int days = 365}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final allStudies = await _dao.getAll();
      final recentStudies = allStudies.where((s) => 
        s.startDate.isAfter(startDate) && s.startDate.isBefore(endDate)
      ).toList();
      
      final monthlyStudies = <String, int>{};
      final typeDistribution = <String, int>{};
      final statusDistribution = <String, int>{};
      final departmentDistribution = <String, int>{};
      final recruitmentProgress = <String, double>{};
      
      for (final study in recentStudies) {
        // Monthly studies
        final monthKey = '${study.startDate.year}-${study.startDate.month.toString().padLeft(2, '0')}';
        monthlyStudies[monthKey] = (monthlyStudies[monthKey] ?? 0) + 1;
        
        // Type distribution
        typeDistribution[study.studyType] = (typeDistribution[study.studyType] ?? 0) + 1;
        
        // Status distribution
        statusDistribution[study.status] = (statusDistribution[study.status] ?? 0) + 1;
        
        // Department distribution
        departmentDistribution[study.department] = (departmentDistribution[study.department] ?? 0) + 1;
        
        // Recruitment progress
        recruitmentProgress[study.id] = study.recruitmentProgress;
      }
      
      return {
        'monthly_studies': monthlyStudies,
        'type_distribution': typeDistribution,
        'status_distribution': statusDistribution,
        'department_distribution': departmentDistribution,
        'recruitment_progress': recruitmentProgress,
        'total_recent_studies': recentStudies.length,
        'average_recruitment_progress': recruitmentProgress.values.isNotEmpty ? 
          recruitmentProgress.values.reduce((a, b) => a + b) / recruitmentProgress.values.length : 0,
      };
    } catch (e) {
      throw Exception('Failed to get research trends: $e');
    }
  }

  // Get research performance metrics
  Future<Map<String, dynamic>> getResearchPerformance() async {
    try {
      final allStudies = await _dao.getAll();
      
      final totalStudies = allStudies.length;
      final completedStudies = allStudies.where((s) => s.isCompleted).length;
      final activeStudies = allStudies.where((s) => s.status == 'active').length;
      final recruitingStudies = allStudies.where((s) => s.isRecruiting).length;
      
      final totalParticipants = allStudies.fold(0, (sum, s) => sum + s.currentParticipants);
      final targetParticipants = allStudies.fold(0, (sum, s) => sum + s.targetParticipants);
      
      final averageRecruitmentRate = allStudies.isNotEmpty ? 
        allStudies.map((s) => s.recruitmentProgress).reduce((a, b) => a + b) / allStudies.length : 0;
      
      final completionRate = totalStudies > 0 ? (completedStudies / totalStudies) * 100 : 0;
      final overallRecruitmentRate = targetParticipants > 0 ? (totalParticipants / targetParticipants) * 100 : 0;
      
      return {
        'total_studies': totalStudies,
        'completed_studies': completedStudies,
        'active_studies': activeStudies,
        'recruiting_studies': recruitingStudies,
        'total_participants': totalParticipants,
        'target_participants': targetParticipants,
        'completion_rate': completionRate,
        'overall_recruitment_rate': overallRecruitmentRate,
        'average_recruitment_rate': averageRecruitmentRate,
        'studies_on_track': allStudies.where((s) => s.recruitmentProgress >= 80).length,
        'studies_behind': allStudies.where((s) => s.recruitmentProgress < 50).length,
      };
    } catch (e) {
      throw Exception('Failed to get research performance: $e');
    }
  }

  // Get research insights
  Future<List<Map<String, dynamic>>> getResearchInsights() async {
    try {
      final insights = <Map<String, dynamic>>[];
      
      final recruitingStudies = await getRecruitingStudies();
      final activeStudies = await getActiveStudies();
      final performance = await getResearchPerformance();
      
      // Recruitment insights
      if (recruitingStudies.isNotEmpty) {
        insights.add({
          'type': 'recruitment',
          'title': 'Recruitment Opportunities',
          'message': '${recruitingStudies.length} studies are currently recruiting participants',
          'priority': 'medium',
          'data': recruitingStudies,
        });
      }
      
      // Performance insights
      if (performance['studies_behind'] > 0) {
        insights.add({
          'type': 'performance',
          'title': 'Studies Behind Schedule',
          'message': '${performance['studies_behind']} studies are behind recruitment targets',
          'priority': 'high',
          'data': performance,
        });
      }
      
      // Completion insights
      if (performance['completion_rate'] < 70) {
        insights.add({
          'type': 'completion',
          'title': 'Low Completion Rate',
          'message': 'Study completion rate is ${performance['completion_rate'].toStringAsFixed(1)}%',
          'priority': 'medium',
          'data': performance,
        });
      }
      
      return insights;
    } catch (e) {
      throw Exception('Failed to get research insights: $e');
    }
  }

  // Refresh studies stream
  Future<void> _refreshStudies() async {
    try {
      final studies = await _dao.getAll();
      _studiesController.add(studies);
    } catch (e) {
      _studiesController.addError(e);
    }
  }

  // Dispose resources
  void dispose() {
    _studiesController.close();
  }
}