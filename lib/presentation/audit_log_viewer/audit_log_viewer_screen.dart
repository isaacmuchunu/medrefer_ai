import 'package:flutter/material.dart';
import '../../services/security_audit_service.dart';

class AuditLogViewerScreen extends StatefulWidget {
  const AuditLogViewerScreen({super.key});

  @override
  State<AuditLogViewerScreen> createState() => _AuditLogViewerScreenState();
}

class _AuditLogViewerScreenState extends State<AuditLogViewerScreen> {
  final _service = SecurityAuditService();
  SecurityEventType? _eventType;
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final logs = _service.getAuditLogs(
      eventType: _eventType,
      startDate: _range?.start,
      endDate: _range?.end,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _pickFilters,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: Icon(_iconFor(log.eventType), color: _colorFor(log.riskLevel)),
            title: Text('${log.eventType.name} • ${log.action}'),
            subtitle: Text('${log.timestamp.toIso8601String()} • user: ${log.userId} • ip: ${log.ipAddress}'),
            onTap: () => _showDetails(log),
          );
        },
      ),
    );
  }

  void _showDetails(SecurityAuditLog log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${log.eventType.name} • ${log.action}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('User: ${log.userId}'),
              Text('IP: ${log.ipAddress}'),
              Text('Risk: ${log.riskLevel.name}'),
              Text('Session: ${log.sessionId}'),
              const SizedBox(height: 8),
              Text('Metadata: ${log.metadata}'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFilters() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SecurityEventType>(
              initialValue: _eventType,
              decoration: const InputDecoration(labelText: 'Event Type'),
              items: [null, ...SecurityEventType.values]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e?.name ?? 'Any'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _eventType = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: now.subtract(const Duration(days: 365 * 5)),
                        lastDate: now,
                        initialDateRange: _range,
                      );
                      if (picked != null) setState(() => _range = picked);
                    },
                    child: Text(_range == null
                        ? 'Pick Date Range'
                        : '${_range!.start.toIso8601String().split('T').first} → ${_range!.end.toIso8601String().split('T').first}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply'),
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _iconFor(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.authentication:
        return Icons.login;
      case SecurityEventType.dataAccess:
        return Icons.folder_open;
      case SecurityEventType.system:
        return Icons.settings;
      case SecurityEventType.security:
        return Icons.security;
      case SecurityEventType.compliance:
        return Icons.fact_check;
    }
  }

  Color _colorFor(SecurityRiskLevel level) {
    switch (level) {
      case SecurityRiskLevel.low:
        return Colors.green;
      case SecurityRiskLevel.medium:
        return Colors.orange;
      case SecurityRiskLevel.high:
        return Colors.red;
      case SecurityRiskLevel.critical:
        return Colors.purple;
    }
  }
}

