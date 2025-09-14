import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_export.dart';
import '../../services/iot_medical_device_service.dart';
import '../../services/ai_service.dart';
import '../../services/blockchain_medical_records_service.dart';
import '../../services/realtime_update_service.dart';
import '../../services/notification_service.dart';
import '../../database/models/patient.dart';
import '../../database/models/vital_statistics.dart';
import '../../database/services/data_service.dart';
import 'dart:async';

class PatientMonitoringDashboard extends StatefulWidget {
  final String patientId;
  
  const PatientMonitoringDashboard({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientMonitoringDashboard> createState() => _PatientMonitoringDashboardState();
}

class _PatientMonitoringDashboardState extends State<PatientMonitoringDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _alertController;
  
  Patient? patient;
  List<VitalStatistics> vitals = [];
  Map<String, List<double>> vitalTrends = {};
  bool isLoading = true;
  bool hasAlerts = false;
  
  late StreamSubscription _realtimeSubscription;
  late StreamSubscription _deviceSubscription;
  
  final IoTMedicalDeviceService _deviceService = IoTMedicalDeviceService();
  final AIService _aiService = AIService();
  final BlockchainMedicalRecordsService _blockchainService = BlockchainMedicalRecordsService();
  final RealtimeUpdateService _realtimeService = RealtimeUpdateService();
  final NotificationService _notificationService = NotificationService();
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadPatientData();
    _subscribeToRealtimeUpdates();
    _subscribeToDeviceUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _alertController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    await _deviceService.initialize();
    await _aiService.initialize();
    await _blockchainService.initialize();
    await _realtimeService.initialize();
    await _notificationService.initialize();
  }

  Future<void> _loadPatientData() async {
    setState(() => isLoading = true);
    
    try {
      // Load patient information
      final patientResult = await _dataService.getPatientById(widget.patientId);
      if (patientResult.isSuccess) {
        patient = patientResult.data;
      }

      // Load recent vital statistics
      final vitalsResult = await _dataService.getVitalStatistics(
        patientId: widget.patientId,
        limit: 50,
      );
      if (vitalsResult.isSuccess) {
        vitals = vitalsResult.data ?? [];
        _processTrends();
      }

      // Connect to patient's medical devices
      await _connectToMedicalDevices();
      
      // Check for alerts using AI
      await _checkForAlerts();
      
    } catch (e) {
      print('Error loading patient data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _connectToMedicalDevices() async {
    if (patient != null) {
      // Connect to all available medical devices for this patient
      final devices = await _deviceService.getPatientDevices(widget.patientId);
      for (final device in devices) {
        await _deviceService.connectToDevice(device.id);
      }
    }
  }

  void _subscribeToRealtimeUpdates() {
    _realtimeSubscription = _realtimeService
        .subscribe('patient_vitals_${widget.patientId}')
        .listen((message) {
      if (message.type == 'vital_update') {
        _handleVitalUpdate(message.data);
      }
    });
  }

  void _subscribeToDeviceUpdates() {
    _deviceSubscription = _deviceService
        .getDeviceDataStream(widget.patientId)
        .listen((deviceData) {
      _handleDeviceData(deviceData);
    });
  }

  void _handleVitalUpdate(Map<String, dynamic> data) {
    final vital = VitalStatistics.fromMap(data);
    setState(() {
      vitals.insert(0, vital);
      if (vitals.length > 50) vitals.removeLast();
      _processTrends();
    });
    
    // Store in blockchain for immutable record
    _blockchainService.storeVitalSigns(widget.patientId, vital.toMap());
    
    // Check for alerts
    _checkVitalAlert(vital);
  }

  void _handleDeviceData(Map<String, dynamic> deviceData) {
    // Process real-time device data and create vital statistics
    final vital = VitalStatistics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patientId,
      heartRate: deviceData['heart_rate']?.toDouble(),
      bloodPressureSystolic: deviceData['bp_systolic']?.toDouble(),
      bloodPressureDiastolic: deviceData['bp_diastolic']?.toDouble(),
      oxygenSaturation: deviceData['oxygen_saturation']?.toDouble(),
      temperature: deviceData['temperature']?.toDouble(),
      respiratoryRate: deviceData['respiratory_rate']?.toDouble(),
      glucoseLevel: deviceData['glucose_level']?.toDouble(),
      timestamp: DateTime.now(),
      deviceId: deviceData['device_id'],
      notes: deviceData['notes'],
    );

    _handleVitalUpdate(vital.toMap());
  }

  void _processTrends() {
    vitalTrends.clear();
    
    if (vitals.isNotEmpty) {
      vitalTrends['heartRate'] = vitals.map((v) => v.heartRate ?? 0).toList();
      vitalTrends['bloodPressure'] = vitals.map((v) => v.bloodPressureSystolic ?? 0).toList();
      vitalTrends['oxygenSaturation'] = vitals.map((v) => v.oxygenSaturation ?? 0).toList();
      vitalTrends['temperature'] = vitals.map((v) => v.temperature ?? 0).toList();
      vitalTrends['respiratoryRate'] = vitals.map((v) => v.respiratoryRate ?? 0).toList();
      vitalTrends['glucoseLevel'] = vitals.map((v) => v.glucoseLevel ?? 0).toList();
    }
  }

  Future<void> _checkForAlerts() async {
    if (vitals.isEmpty) return;
    
    final latestVital = vitals.first;
    final riskAssessment = await _aiService.assessVitalRisk(
      patientId: widget.patientId,
      vitalStatistics: latestVital,
      historicalData: vitals.take(10).toList(),
    );
    
    if (riskAssessment.riskLevel > 0.7) {
      setState(() => hasAlerts = true);
      _alertController.forward();
      
      await _notificationService.sendCriticalAlert(
        title: 'Critical Patient Alert',
        message: 'Patient ${patient?.name} requires immediate attention',
        patientId: widget.patientId,
        riskLevel: riskAssessment.riskLevel,
      );
    }
  }

  void _checkVitalAlert(VitalStatistics vital) async {
    final alerts = <String>[];
    
    // Check heart rate
    if (vital.heartRate != null) {
      if (vital.heartRate! < 60 || vital.heartRate! > 100) {
        alerts.add('Abnormal heart rate: ${vital.heartRate} bpm');
      }
    }
    
    // Check blood pressure
    if (vital.bloodPressureSystolic != null && vital.bloodPressureDiastolic != null) {
      if (vital.bloodPressureSystolic! > 140 || vital.bloodPressureDiastolic! > 90) {
        alerts.add('High blood pressure: ${vital.bloodPressureSystolic}/${vital.bloodPressureDiastolic}');
      }
    }
    
    // Check oxygen saturation
    if (vital.oxygenSaturation != null && vital.oxygenSaturation! < 95) {
      alerts.add('Low oxygen saturation: ${vital.oxygenSaturation}%');
    }
    
    // Check temperature
    if (vital.temperature != null) {
      if (vital.temperature! < 36.1 || vital.temperature! > 37.2) {
        alerts.add('Abnormal temperature: ${vital.temperature}°C');
      }
    }
    
    if (alerts.isNotEmpty) {
      setState(() => hasAlerts = true);
      _alertController.forward();
      
      for (final alert in alerts) {
        await _notificationService.sendAlert(
          title: 'Vital Sign Alert',
          message: alert,
          patientId: widget.patientId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Monitoring - ${patient?.name ?? 'Loading...'}'),
        actions: [
          if (hasAlerts)
            AnimatedBuilder(
              animation: _alertController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_alertController.value * 0.2),
                  child: IconButton(
                    icon: Icon(
                      Icons.warning,
                      color: Colors.red[700],
                    ),
                    onPressed: () => _showAlertsDialog(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPatientData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfoCard(),
                    const SizedBox(height: 16),
                    _buildCurrentVitalsGrid(),
                    const SizedBox(height: 16),
                    _buildVitalTrendsCharts(),
                    const SizedBox(height: 16),
                    _buildConnectedDevices(),
                    const SizedBox(height: 16),
                    _buildAIInsights(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualVitalEntry(),
        icon: const Icon(Icons.add),
        label: const Text('Add Vital'),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    if (patient == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.primaryColor,
              child: Text(
                patient!.name.split(' ').map((n) => n[0]).take(2).join(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient!.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text('Age: ${patient!.age}'),
                  Text('MRN: ${patient!.medicalRecordNumber}'),
                  Text('Blood Type: ${patient!.bloodType ?? 'Unknown'}'),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasAlerts 
                        ? Colors.red.withOpacity(0.5 + (_pulseController.value * 0.5))
                        : Colors.green.withOpacity(0.5 + (_pulseController.value * 0.5)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentVitalsGrid() {
    if (vitals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No vital signs data available'),
        ),
      );
    }

    final latestVital = vitals.first;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Vitals',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildVitalCard(
                  'Heart Rate',
                  '${latestVital.heartRate?.toInt() ?? '--'} bpm',
                  Icons.favorite,
                  _getVitalColor(latestVital.heartRate, 60, 100),
                ),
                _buildVitalCard(
                  'Blood Pressure',
                  '${latestVital.bloodPressureSystolic?.toInt() ?? '--'}/${latestVital.bloodPressureDiastolic?.toInt() ?? '--'}',
                  Icons.bloodtype,
                  _getBPColor(latestVital.bloodPressureSystolic, latestVital.bloodPressureDiastolic),
                ),
                _buildVitalCard(
                  'Oxygen Sat',
                  '${latestVital.oxygenSaturation?.toInt() ?? '--'}%',
                  Icons.air,
                  _getVitalColor(latestVital.oxygenSaturation, 95, 100),
                ),
                _buildVitalCard(
                  'Temperature',
                  '${latestVital.temperature?.toStringAsFixed(1) ?? '--'}°C',
                  Icons.thermostat,
                  _getVitalColor(latestVital.temperature, 36.1, 37.2),
                ),
                _buildVitalCard(
                  'Respiratory',
                  '${latestVital.respiratoryRate?.toInt() ?? '--'} /min',
                  Icons.waves,
                  _getVitalColor(latestVital.respiratoryRate, 12, 20),
                ),
                _buildVitalCard(
                  'Glucose',
                  '${latestVital.glucoseLevel?.toInt() ?? '--'} mg/dL',
                  Icons.water_drop,
                  _getVitalColor(latestVital.glucoseLevel, 80, 120),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTrendsCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Trends (Last 24 Hours)',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: _buildChartLines(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildChartLines() {
    final lines = <LineChartBarData>[];
    
    if (vitalTrends['heartRate']?.isNotEmpty == true) {
      lines.add(LineChartBarData(
        spots: vitalTrends['heartRate']!
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        color: Colors.red,
        barWidth: 2,
        dotData: FlDotData(show: false),
      ));
    }
    
    return lines;
  }

  Widget _buildConnectedDevices() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected Devices',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _deviceService.getPatientDevices(widget.patientId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                final devices = snapshot.data!;
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: Icon(
                        _getDeviceIcon(device['type']),
                        color: device['connected'] ? Colors.green : Colors.grey,
                      ),
                      title: Text(device['name']),
                      subtitle: Text(device['type']),
                      trailing: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: device['connected'] ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Health Insights',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _generateAIInsights(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                final insights = snapshot.data!;
                
                return Column(
                  children: [
                    _buildInsightCard(
                      'Risk Assessment',
                      insights['riskLevel'].toString(),
                      _getRiskColor(insights['riskLevel']),
                    ),
                    const SizedBox(height: 8),
                    _buildInsightCard(
                      'Health Trend',
                      insights['trend'],
                      insights['trend'] == 'Improving' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildInsightCard(
                      'Recommendations',
                      insights['recommendations'].join(', '),
                      Colors.blue,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Color _getVitalColor(double? value, double min, double max) {
    if (value == null) return Colors.grey;
    if (value >= min && value <= max) return Colors.green;
    return Colors.red;
  }

  Color _getBPColor(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return Colors.grey;
    if (systolic <= 140 && diastolic <= 90) return Colors.green;
    return Colors.red;
  }

  Color _getRiskColor(double riskLevel) {
    if (riskLevel < 0.3) return Colors.green;
    if (riskLevel < 0.7) return Colors.orange;
    return Colors.red;
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'heart_monitor':
        return Icons.favorite;
      case 'blood_pressure':
        return Icons.bloodtype;
      case 'pulse_oximeter':
        return Icons.air;
      case 'thermometer':
        return Icons.thermostat;
      case 'glucometer':
        return Icons.water_drop;
      default:
        return Icons.medical_services;
    }
  }

  Future<Map<String, dynamic>> _generateAIInsights() async {
    if (vitals.isEmpty) {
      return {
        'riskLevel': 0.0,
        'trend': 'No data',
        'recommendations': ['Collect vital signs data'],
      };
    }

    final riskAssessment = await _aiService.assessVitalRisk(
      patientId: widget.patientId,
      vitalStatistics: vitals.first,
      historicalData: vitals.take(10).toList(),
    );

    return {
      'riskLevel': riskAssessment.riskLevel,
      'trend': riskAssessment.trend,
      'recommendations': riskAssessment.recommendations,
    };
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Critical alerts for this patient:'),
            // Add alert list here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monitoring Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Real-time Alerts'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Device Auto-connect'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showManualVitalEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Vital Entry'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Heart Rate (bpm)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Blood Pressure (systolic)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Blood Pressure (diastolic)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Oxygen Saturation (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save manual vital entry
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _alertController.dispose();
    _realtimeSubscription.cancel();
    _deviceSubscription.cancel();
    super.dispose();
  }
}