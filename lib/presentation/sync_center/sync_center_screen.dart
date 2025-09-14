import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/offline_sync_service.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<OfflineSyncService>(context);
    final status = syncService.getStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await syncService.performSync();
              setState(() {});
            },
            tooltip: 'Sync Now',
          ),
        ],
      ),
      body: FutureBuilder<SyncStatistics>(
        future: status,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatCard(label: 'Pending', value: stats.pendingCount.toString(), icon: Icons.pending_actions),
                    _StatCard(label: 'Completed', value: stats.completedCount.toString(), icon: Icons.check_circle),
                    _StatCard(label: 'Failed', value: stats.failedCount.toString(), icon: Icons.error),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Last Sync: ${stats.lastSyncTime?.toIso8601String() ?? 'Never'}'),
                Text('Conflicts Resolved: ${stats.conflictsResolved}'),
                Text('Avg Sync Time: ${stats.averageSyncTime.inMilliseconds} ms'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

