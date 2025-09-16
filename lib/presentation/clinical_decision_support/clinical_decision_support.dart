import 'package:flutter/material.dart';
import '../../services/clinical_decision_service.dart';
import '../../database/models/clinical_decision.dart';
import '../../theme/app_theme.dart';

class ClinicalDecisionSupport extends StatefulWidget {
  const ClinicalDecisionSupport({super.key});

  @override
  State&lt;ClinicalDecisionSupport&gt; createState() =&gt; _ClinicalDecisionSupportState();
}

class _ClinicalDecisionSupportState extends State<ClinicalDecisionSupport>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ClinicalDecisionService _decisionService = ClinicalDecisionService();
  List<ClinicalDecision> _decisions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDecisions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDecisions() async {
    setState(() => _isLoading = true);
    try {
      final decisions = await _decisionService.getAllDecisions();
      setState(() {
        _decisions = decisions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load decisions: $e');
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

  List<ClinicalDecision> get _filteredDecisions {
    var filtered = _decisions;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((decision) =>
          decision.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          decision.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          decision.patientId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((d) => d.status == 'pending').toList();
        break;
      case 'approved':
        filtered = filtered.where((d) => d.status == 'approved').toList();
        break;
      case 'urgent':
        filtered = filtered.where((d) => d.priority == 'urgent').toList();
        break;
      case 'high_confidence':
        filtered = filtered.where((d) => d.confidence == 'high').toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Clinical Decision Support'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Decisions'),
            Tab(text: 'Pending'),
            Tab(text: 'Urgent'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDecisions,
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
                _buildDecisionsList(),
                _buildPendingDecisions(),
                _buildUrgentDecisions(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDecisionDialog,
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
              hintText: 'Search decisions...',
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
                _buildFilterChip('pending', 'Pending'),
                _buildFilterChip('approved', 'Approved'),
                _buildFilterChip('urgent', 'Urgent'),
                _buildFilterChip('high_confidence', 'High Confidence'),
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

  Widget _buildDecisionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredDecisions = _filteredDecisions;

    if (filteredDecisions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No decisions found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDecisions.length,
      itemBuilder: (context, index) {
        final decision = filteredDecisions[index];
        return _buildDecisionCard(decision);
      },
    );
  }

  Widget _buildPendingDecisions() {
    final pendingDecisions = _decisions.where((d) => d.status == 'pending').toList();
    
    if (pendingDecisions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending decisions', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingDecisions.length,
      itemBuilder: (context, index) {
        final decision = pendingDecisions[index];
        return _buildDecisionCard(decision);
      },
    );
  }

  Widget _buildUrgentDecisions() {
    final urgentDecisions = _decisions.where((d) => d.priority == 'urgent').toList();
    
    if (urgentDecisions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.priority_high, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('No urgent decisions', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: urgentDecisions.length,
      itemBuilder: (context, index) {
        final decision = urgentDecisions[index];
        return _buildDecisionCard(decision);
      },
    );
  }

  Widget _buildAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _decisionService.getDecisionStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard('Total Decisions', stats['total_decisions'].toString(), Icons.psychology),
              _buildStatsCard('Pending Decisions', stats['pending_decisions'].toString(), Icons.pending),
              _buildStatsCard('Approved Decisions', stats['approved_decisions'].toString(), Icons.check_circle),
              _buildStatsCard('Urgent Decisions', stats['urgent_decisions'].toString(), Icons.priority_high),
              _buildStatsCard('Approval Rate', '${stats['approval_rate'].toStringAsFixed(1)}%', Icons.trending_up),
              _buildStatsCard('Implementation Rate', '${stats['implementation_rate'].toStringAsFixed(1)}%', Icons.rocket_launch),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(ClinicalDecision decision) {
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
                    decision.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(decision.status),
                _buildPriorityChip(decision.priority),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              decision.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Patient: ${decision.patientId}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.psychology, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Confidence: ${decision.confidence}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Created: ${_formatDate(decision.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                if (decision.status == 'pending') ...[
                  TextButton(
                    onPressed: () => _approveDecision(decision),
                    child: const Text('Approve'),
                  ),
                  TextButton(
                    onPressed: () => _rejectDecision(decision),
                    child: const Text('Reject'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'implemented':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
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

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.yellow[700]!;
        break;
      case 'low':
        color = Colors.green;
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
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateDecisionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Clinical Decision'),
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

  Future<void> _approveDecision(ClinicalDecision decision) async {
    try {
      await _decisionService.approveDecision(decision.id, 'current_user');
      _loadDecisions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decision approved successfully')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to approve decision: $e');
    }
  }

  Future<void> _rejectDecision(ClinicalDecision decision) async {
    try {
      await _decisionService.rejectDecision(decision.id, 'current_user', 'Rejected by user');
      _loadDecisions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decision rejected successfully')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to reject decision: $e');
    }
  }
}