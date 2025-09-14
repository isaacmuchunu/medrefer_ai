import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _alerts = [
        {
          'id': 'alert_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Emergency Referral',
          'message': 'Critical cardiac case requires immediate attention',
          'timestamp': DateTime.now(),
          'priority': 'critical',
          'type': 'referral',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          const Text('No emergency alerts'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        return Card(
                          color: theme.colorScheme.error.withOpacity(0.05),
                          child: ListTile(
                            leading: Icon(Icons.warning, color: theme.colorScheme.error),
                            title: Text(alert['title'] as String),
                            subtitle: Text(alert['message'] as String),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to details
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

