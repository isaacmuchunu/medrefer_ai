import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/models/models.dart';
import '../../database/services/data_service.dart';

class ConsentManagementScreen extends StatefulWidget {
  final String patientId;

  const ConsentManagementScreen({super.key, required this.patientId});

  @override
  State<ConsentManagementScreen> createState() => _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends State<ConsentManagementScreen> {
  late Future<List<Consent>> _futureConsents;

  @override
  void initState() {
    super.initState();
    _futureConsents = _loadConsents(force: true);
  }

  Future<List<Consent>> _loadConsents({bool force = false}) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    return await dataService.getConsentsForPatient(widget.patientId, {"forceRefresh": force}["forceRefresh"] as bool);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureConsents = _loadConsents(force: true);
    });
  }

  Future<void> _addConsent() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    ConsentType? selectedType = ConsentType.dataSharing;
    DateTime? expiresAt;
    final scopeController = TextEditingController();
    final grantedByController = TextEditingController();
    final notesController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Consent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ConsentType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Consent Type'),
                  items: ConsentType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (v) => selectedType = v,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: grantedByController,
                  decoration: const InputDecoration(labelText: 'Granted By (optional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: scopeController,
                  decoration: const InputDecoration(labelText: 'Scope (comma-separated)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now.add(const Duration(days: 365)),
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setState(() {
                              expiresAt = picked;
                            });
                          }
                        },
                        child: Text(expiresAt == null ? 'Set Expiry' : 'Expiry: ${expiresAt!.toIso8601String().split('T').first}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final consent = Consent(
                  patientId: widget.patientId,
                  consentType: selectedType ?? ConsentType.dataSharing,
                  grantedBy: grantedByController.text.isEmpty ? null : grantedByController.text,
                  expiresAt: expiresAt,
                  scope: BaseModel.parseStringList(scopeController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
                await dataService.createConsent(consent);
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _revokeConsent(Consent consent) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    consent.status = ConsentStatus.revoked;
    await dataService.updateConsent(consent);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent Management'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _addConsent, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<Consent>>(
        future: _futureConsents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final consents = snapshot.data ?? [];
          if (consents.isEmpty) {
            return const Center(child: Text('No consents found'));
          }
          return ListView.separated(
            itemCount: consents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = consents[index];
              return ListTile(
                title: Text('${c.consentType.name} (${c.status.name})'),
                subtitle: Text('Granted: ${c.grantedAt.toIso8601String().split('T').first} • Expires: ${c.expiresAt != null ? c.expiresAt!.toIso8601String().split('T').first : 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.status == ConsentStatus.active)
                      IconButton(
                        icon: const Icon(Icons.block),
                        tooltip: 'Revoke',
                        onPressed: () => _revokeConsent(c),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

