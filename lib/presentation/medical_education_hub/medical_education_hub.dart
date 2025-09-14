import 'package:flutter/material.dart';
import '../../services/medical_education_service.dart';
import '../../database/models/medical_education.dart';
import '../../theme/app_theme.dart';

class MedicalEducationHub extends StatefulWidget {
  const MedicalEducationHub({Key? key}) : super(key: key);

  @override
  State<MedicalEducationHub> createState() => _MedicalEducationHubState();
}

class _MedicalEducationHubState extends State<MedicalEducationHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final MedicalEducationService _educationService = MedicalEducationService();
  List<MedicalEducation> _education = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEducation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEducation() async {
    setState(() => _isLoading = true);
    try {
      final education = await _educationService.getAllEducation();
      setState(() {
        _education = education;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load medical education: $e');
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

  List<MedicalEducation> get _filteredEducation {
    List<MedicalEducation> filtered = _education;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((edu) =>
          edu.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          edu.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          edu.topics.any((topic) => topic.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
    }

    switch (_selectedFilter) {
      case 'upcoming':
        filtered = filtered.where((e) => e.isUpcoming).toList();
        break;
      case 'ongoing':
        filtered = filtered.where((e) => e.isOngoing).toList();
        break;
      case 'completed':
        filtered = filtered.where((e) => e.status == 'completed').toList();
        break;
      case 'course':
        filtered = filtered.where((e) => e.type == 'course').toList();
        break;
      case 'webinar':
        filtered = filtered.where((e) => e.type == 'webinar').toList();
        break;
      case 'cme':
        filtered = filtered.where((e) => e.cmeCredits > 0).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Medical Education Hub'),
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
            Tab(text: 'Education'),
            Tab(text: 'CME Tracking'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEducation,
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
                _buildEducationList(),
                _buildCMETracking(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEducationDialog,
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
              hintText: 'Search education...',
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
                _buildFilterChip('upcoming', 'Upcoming'),
                _buildFilterChip('ongoing', 'Ongoing'),
                _buildFilterChip('completed', 'Completed'),
                _buildFilterChip('course', 'Course'),
                _buildFilterChip('webinar', 'Webinar'),
                _buildFilterChip('cme', 'CME Credits'),
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
      future: _educationService.getEducationDashboard(),
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
              _buildUpcomingEducation(dashboard['upcoming_education']),
              const SizedBox(height: 24),
              _buildOngoingEducation(dashboard['ongoing_education']),
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
            'Total Education',
            summary['total_education'].toString(),
            Icons.school,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Upcoming',
            summary['upcoming_education'].toString(),
            Icons.schedule,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Ongoing',
            summary['ongoing_education'].toString(),
            Icons.play_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Completed',
            summary['completed_education'].toString(),
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

  Widget _buildUpcomingEducation(List<MedicalEducation> education) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Education',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (education.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No upcoming education', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...education.take(5).map((edu) => _buildEducationItem(edu)),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingEducation(List<MedicalEducation> education) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ongoing Education',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (education.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No ongoing education', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...education.take(5).map((edu) => _buildEducationItem(edu)),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredEducation = _filteredEducation;

    if (filteredEducation.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No education found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEducation.length,
      itemBuilder: (context, index) {
        final education = filteredEducation[index];
        return _buildEducationCard(education);
      },
    );
  }

  Widget _buildEducationCard(MedicalEducation education) {
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
                    education.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(education.status),
                _buildTypeChip(education.type),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              education.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Instructor: ${education.instructor}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${education.currentParticipants}/${education.maxParticipants}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start: ${_formatDate(education.startDate)}'),
                      Text('Duration: ${education.duration} hours'),
                      if (education.cmeCredits > 0)
                        Text('CME Credits: ${education.cmeCredits}'),
                    ],
                  ),
                ),
                _buildEnrollmentProgress(education.enrollmentProgress),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: education.enrollmentProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                education.isFull ? Colors.red : 
                education.enrollmentProgress >= 80 ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Provider: ${education.provider}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => _showEducationDetails(education),
                  child: const Text('View Details'),
                ),
                if (education.isUpcoming && !education.isFull)
                  ElevatedButton(
                    onPressed: () => _enrollInEducation(education),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enroll'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(MedicalEducation education) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  education.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${education.currentParticipants}/${education.maxParticipants} participants',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildEnrollmentProgress(education.enrollmentProgress),
        ],
      ),
    );
  }

  Widget _buildCMETracking() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _educationService.getCMETracking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final cmeData = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCMEOverviewCards(cmeData),
              const SizedBox(height: 24),
              _buildCMEByCategory(cmeData['category_credits']),
              const SizedBox(height: 24),
              _buildCMEByType(cmeData['type_credits']),
              const SizedBox(height: 24),
              _buildCMEByProvider(cmeData['provider_credits']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCMEOverviewCards(Map<String, dynamic> cmeData) {
    return Row(
      children: [
        Expanded(
          child: _buildCMECard(
            'Total CME Credits',
            cmeData['total_cme_credits'].toString(),
            Icons.school,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCMECard(
            'Earned Credits',
            cmeData['earned_cme_credits'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCMECard(
            'Remaining',
            cmeData['remaining_cme_credits'].toString(),
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCMECard(
            'Completion',
            '${cmeData['completion_rate'].toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildCMECard(String title, String value, IconData icon, Color color) {
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

  Widget _buildCMEByCategory(Map<String, double> categoryCredits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CME Credits by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...categoryCredits.entries.map((entry) => 
              _buildCMEBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCMEByType(Map<String, double> typeCredits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CME Credits by Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...typeCredits.entries.map((entry) => 
              _buildCMEBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCMEByProvider(Map<String, double> providerCredits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CME Credits by Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...providerCredits.entries.map((entry) => 
              _buildCMEBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCMEBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${value.toStringAsFixed(1)} credits'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100, // Assuming max 100 credits for visualization
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _educationService.getEducationTrends(),
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
              _buildTrendsCard(trends),
              const SizedBox(height: 24),
              _buildTypeDistribution(trends['type_distribution']),
              const SizedBox(height: 24),
              _buildCategoryDistribution(trends['category_distribution']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsCard(Map<String, dynamic> trends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Education Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrendStat(
                    'Total Recent',
                    trends['total_recent_education'].toString(),
                    Icons.school,
                  ),
                ),
                Expanded(
                  child: _buildTrendStat(
                    'Avg Enrollment',
                    '${trends['average_enrollment_progress'].toStringAsFixed(1)}%',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildTrendStat(
                    'Total CME',
                    trends['total_cme_credits'].toStringAsFixed(1),
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTypeDistribution(Map<String, int> typeDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Education by Type',
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

  Widget _buildCategoryDistribution(Map<String, int> categoryDistribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Education by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...categoryDistribution.entries.map((entry) => 
              _buildDistributionBar(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int value) {
    final total = _education.length;
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'upcoming':
        color = Colors.blue;
        break;
      case 'ongoing':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.orange;
        break;
      case 'cancelled':
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
      case 'course':
        color = Colors.purple;
        break;
      case 'webinar':
        color = Colors.teal;
        break;
      case 'conference':
        color = Colors.indigo;
        break;
      case 'workshop':
        color = Colors.brown;
        break;
      case 'certification':
        color = Colors.amber;
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

  Widget _buildEnrollmentProgress(double progress) {
    Color color;
    if (progress >= 100) {
      color = Colors.red;
    } else if (progress >= 80) {
      color = Colors.orange;
    } else {
      color = Colors.green;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateEducationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Medical Education'),
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

  void _showEducationDetails(MedicalEducation education) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(education.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${education.description}'),
              const SizedBox(height: 8),
              Text('Type: ${education.type}'),
              const SizedBox(height: 8),
              Text('Category: ${education.category}'),
              const SizedBox(height: 8),
              Text('Instructor: ${education.instructor}'),
              const SizedBox(height: 8),
              Text('Provider: ${education.provider}'),
              const SizedBox(height: 8),
              Text('Duration: ${education.duration} hours'),
              const SizedBox(height: 8),
              Text('Participants: ${education.currentParticipants}/${education.maxParticipants}'),
              const SizedBox(height: 8),
              Text('CME Credits: ${education.cmeCredits}'),
              const SizedBox(height: 8),
              Text('Start Date: ${_formatDate(education.startDate)}'),
              if (education.endDate != null)
                Text('End Date: ${_formatDate(education.endDate!)}'),
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

  void _enrollInEducation(MedicalEducation education) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll in Education'),
        content: Text('Are you sure you want to enroll in "${education.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enrollment successful!')),
              );
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }
}