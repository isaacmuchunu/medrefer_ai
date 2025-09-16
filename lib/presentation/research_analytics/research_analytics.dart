import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/research_analytics_service.dart';
import '../../database/models/research_study.dart';
import '../../theme/app_theme.dart';

class ResearchAnalytics extends StatefulWidget {
  const ResearchAnalytics({super.key});

  @override
  State<ResearchAnalytics> createState() => _ResearchAnalyticsState();
}

class _ResearchAnalyticsState extends State<ResearchAnalytics>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ResearchAnalyticsService _researchService = ResearchAnalyticsService();
  List<ResearchStudy> _studies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStudies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudies() async {
    setState(() => _isLoading = true);
    try {
      final studies = await _researchService.getAllStudies();
      setState(() {
        _studies = studies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load research studies: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<ResearchStudy> get _filteredStudies {
    var filtered = _studies;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((study) =>
          study.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          study.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          study.keywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
    }

    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((s) => s.status == 'active').toList();
        break;
      case 'recruiting':
        filtered = filtered.where((s) => s.isRecruiting).toList();
        break;
      case 'completed':
        filtered = filtered.where((s) => s.isCompleted).toList();
        break;
      case 'observational':
        filtered = filtered.where((s) => s.studyType == 'observational').toList();
        break;
      case 'interventional':
        filtered = filtered.where((s) => s.studyType == 'interventional').toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Research & Analytics'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Studies'),
            Tab(text: 'Recruitment'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudies,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildStudiesList(),
                _buildRecruitmentView(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateStudyDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search studies...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                _buildFilterChip('active', 'Active'),
                _buildFilterChip('recruiting', 'Recruiting'),
                _buildFilterChip('completed', 'Completed'),
                _buildFilterChip('observational', 'Observational'),
                _buildFilterChip('interventional', 'Interventional'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        selectedColor: AppTheme.primary.withOpacity(0.2),
        checkmarkColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _researchService.getResearchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final dashboard = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(dashboard),
              const SizedBox(height: 24),
              _buildStudiesChart(),
              const SizedBox(height: 24),
              _buildRecruitingStudies(dashboard['recruiting_studies']),
              const SizedBox(height: 24),
              _buildActiveStudies(dashboard['active_studies']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> dashboard) {
    final summary = dashboard['summary'] as Map<String, dynamic>;
    
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Studies',
            summary['total_studies'].toString(),
            Icons.science,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Active',
            summary['active_studies'].toString(),
            Icons.play_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Recruiting',
            summary['recruiting_studies'].toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Completed',
            summary['completed_studies'].toString(),
            Icons.check_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudiesChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Studies Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildStudiesPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildStudiesPieChartSections() {
    final active = _studies.where((s) => s.status == 'active').length;
    final recruiting = _studies.where((s) => s.isRecruiting).length;
    final completed = _studies.where((s) => s.isCompleted).length;
    final other = _studies.length - active - recruiting - completed;

    return [
      PieChartSectionData(
        color: Colors.green,
        value: active.toDouble(),
        title: 'Active\n$active',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: recruiting.toDouble(),
        title: 'Recruiting\n$recruiting',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: completed.toDouble(),
        title: 'Completed\n$completed',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      if (other > 0)
        PieChartSectionData(
          color: Colors.grey,
          value: other.toDouble(),
          title: 'Other\n$other',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
    ];
  }

  Widget _buildRecruitingStudies(List<ResearchStudy> studies) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recruiting Studies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (studies.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recruiting studies', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...studies.take(5).map(_buildStudyItem),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStudies(List<ResearchStudy> studies) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Studies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (studies.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No active studies', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...studies.take(5).map(_buildStudyItem),
          ],
        ),
      ),
    );
  }

  Widget _buildStudiesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredStudies = _filteredStudies;

    if (filteredStudies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No studies found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudies.length,
      itemBuilder: (context, index) {
        final study = filteredStudies[index];
        return _buildStudyCard(study);
      },
    );
  }

  Widget _buildStudyCard(ResearchStudy study) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    study.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(study.status),
                _buildTypeChip(study.studyType),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              study.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('PI: ${study.principalInvestigator}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${study.currentParticipants}/${study.targetParticipants}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Start: ${_formatDate(study.startDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                _buildRecruitmentProgress(study.recruitmentProgress),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: study.recruitmentProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                study.recruitmentProgress >= 80 ? Colors.green : 
                study.recruitmentProgress >= 50 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyItem(ResearchStudy study) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  study.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${study.currentParticipants}/${study.targetParticipants} participants',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildRecruitmentProgress(study.recruitmentProgress),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'recruiting':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.orange;
        break;
      case 'suspended':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type) {
      case 'observational':
        color = Colors.purple;
        break;
      case 'interventional':
        color = Colors.teal;
        break;
      case 'retrospective':
        color = Colors.brown;
        break;
      case 'prospective':
        color = Colors.indigo;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecruitmentProgress(double progress) {
    Color color;
    if (progress >= 80) {
      color = Colors.green;
    } else if (progress >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '${progress.toStringAsFixed(1)}%',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecruitmentView() {
    return FutureBuilder<List<ResearchStudy>>(
      future: _researchService.getRecruitingStudies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final recruitingStudies = snapshot.data!;
        
        if (recruitingStudies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No recruiting studies', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recruitingStudies.length,
          itemBuilder: (context, index) {
            final study = recruitingStudies[index];
            return _buildRecruitmentCard(study);
          },
        );
      },
    );
  }

  Widget _buildRecruitmentCard(ResearchStudy study) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              study.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              study.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target: ${study.targetParticipants} participants'),
                      Text('Current: ${study.currentParticipants} participants'),
                      Text('Remaining: ${study.targetParticipants - study.currentParticipants} participants'),
                    ],
                  ),
                ),
                _buildRecruitmentProgress(study.recruitmentProgress),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: study.recruitmentProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                study.recruitmentProgress >= 80 ? Colors.green : 
                study.recruitmentProgress >= 50 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inclusion: ${study.inclusionCriteria}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _showStudyDetails(study),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _researchService.getResearchTrends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final trends = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrendsChart(trends),
              const SizedBox(height: 24),
              _buildTypeDistribution(trends['type_distribution']),
              const SizedBox(height: 24),
              _buildDepartmentDistribution(trends['department_distribution']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsChart(Map<String, dynamic> trends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Research Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildTrendSpots(trends['monthly_studies']),
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildTrendSpots(Map<String, int> monthlyStudies) {
    final spots = <FlSpot>[];
    var index = 0;
    monthlyStudies.forEach((month, count) {
      spots.add(FlSpot(index.toDouble(), count.toDouble()));
      index++;
    });
    return spots;
  }

  Widget _buildTypeDistribution(Map<String, int> typeDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Studies by Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...typeDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentDistribution(Map<String, int> departmentDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Studies by Department',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...departmentDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int value) {
    final total = _studies.length;
    final percentage = total > 0 ? (value / total) * 100 : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$value (${percentage.toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateStudyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Research Study'),
        content: const Text('This feature will be implemented in the next version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStudyDetails(ResearchStudy study) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(study.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${study.description}'),
              const SizedBox(height: 8),
              Text('Principal Investigator: ${study.principalInvestigator}'),
              const SizedBox(height: 8),
              Text('Department: ${study.department}'),
              const SizedBox(height: 8),
              Text('Study Type: ${study.studyType}'),
              const SizedBox(height: 8),
              Text('Participants: ${study.currentParticipants}/${study.targetParticipants}'),
              const SizedBox(height: 8),
              Text('Recruitment Progress: ${study.recruitmentProgress.toStringAsFixed(1)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}