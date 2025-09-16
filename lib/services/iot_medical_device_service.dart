import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../database/services/data_service.dart';

/// IoT Medical Device Integration Service for real-time patient monitoring
class IoTMedicalDeviceService extends ChangeNotifier {
  factory IoTMedicalDeviceService() => _instance;
  _IoTMedicalDeviceService();
  static final IoTMedicalDeviceService _instance = _IoTMedicalDeviceService();

  bool _isInitialized = false;
  
  // Device management
  final Map<String, MedicalDevice> _connectedDevices = {};
  final Map<String, List<DeviceReading>> _deviceReadings = {};
  final Map<String, DeviceAlert> _activeAlerts = {};
  final Map<String, WebSocketChannel> _deviceConnections = {};
  
  // Real-time monitoring
  Timer? _monitoringTimer;
  Timer? _alertTimer;
  Timer? _dataProcessingTimer;
  
  // Device protocols and configurations
  final Map<DeviceType, DeviceProtocol> _deviceProtocols = {};
  
  // Data analytics and ML
  final Map<String, PatientVitalTrends> _vitalTrends = {};
  
  // Configuration
  static const Duration _readingInterval = Duration(seconds: 30);
  static const Duration _alertCheckInterval = Duration(minutes: 1);
  static const Duration _dataProcessingInterval = Duration(minutes: 5);
  static const int _maxReadingsPerDevice = 1000;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _initializeDeviceProtocols();
      await _discoverDevices();
      await _loadPatientDeviceAssociations();
      _startRealTimeMonitoring();
      _startAlertSystem();
      _startDataProcessing();
      _isInitialized = true;
      debugPrint('✅ IoT Medical Device Service initialized');
    } catch (e) {
      debugPrint('❌ IoT Medical Device Service initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize device protocols for different medical device types
  Future<void> _initializeDeviceProtocols() async {
    // Blood Pressure Monitor Protocol
    _deviceProtocols[DeviceType.bloodPressureMonitor] = DeviceProtocol(
      type: DeviceType.bloodPressureMonitor,
      communicationMethod: CommunicationMethod.bluetooth,
      dataFormat: DataFormat.json,
      readingFrequency: Duration(minutes: 15),
      parameters: ['systolic', 'diastolic', 'pulse', 'timestamp'],
      normalRanges: {
        'systolic': {'min': 90, 'max': 140},
        'diastolic': {'min': 60, 'max': 90},
        'pulse': {'min': 60, 'max': 100},
      },
      alertThresholds: {
        'systolic': {'critical_high': 180, 'critical_low': 70},
        'diastolic': {'critical_high': 110, 'critical_low': 40},
        'pulse': {'critical_high': 120, 'critical_low': 50},
      },
    );

    // Heart Rate Monitor Protocol
    _deviceProtocols[DeviceType.heartRateMonitor] = DeviceProtocol(
      type: DeviceType.heartRateMonitor,
      communicationMethod: CommunicationMethod.bluetooth,
      dataFormat: DataFormat.binary,
      readingFrequency: Duration(seconds: 30),
      parameters: ['heart_rate', 'rhythm', 'variability', 'timestamp'],
      normalRanges: {
        'heart_rate': {'min': 60, 'max': 100},
        'variability': {'min': 20, 'max': 50},
      },
      alertThresholds: {
        'heart_rate': {'critical_high': 150, 'critical_low': 40},
        'rhythm': {'irregular_threshold': 0.3},
      },
    );

    // Glucose Monitor Protocol
    _deviceProtocols[DeviceType.glucoseMonitor] = DeviceProtocol(
      type: DeviceType.glucoseMonitor,
      communicationMethod: CommunicationMethod.nfc,
      dataFormat: DataFormat.xml,
      readingFrequency: Duration(hours: 2),
      parameters: ['glucose_level', 'trend', 'timestamp'],
      normalRanges: {
        'glucose_level': {'min': 70, 'max': 140},
      },
      alertThresholds: {
        'glucose_level': {'critical_high': 250, 'critical_low': 50},
      },
    );

    // Pulse Oximeter Protocol
    _deviceProtocols[DeviceType.pulseOximeter] = DeviceProtocol(
      type: DeviceType.pulseOximeter,
      communicationMethod: CommunicationMethod.bluetooth,
      dataFormat: DataFormat.json,
      readingFrequency: Duration(minutes: 10),
      parameters: ['oxygen_saturation', 'pulse_rate', 'perfusion_index', 'timestamp'],
      normalRanges: {
        'oxygen_saturation': {'min': 95, 'max': 100},
        'pulse_rate': {'min': 60, 'max': 100},
      },
      alertThresholds: {
        'oxygen_saturation': {'critical_low': 90},
        'pulse_rate': {'critical_high': 120, 'critical_low': 50},
      },
    );

    // ECG Monitor Protocol
    _deviceProtocols[DeviceType.ecgMonitor] = DeviceProtocol(
      type: DeviceType.ecgMonitor,
      communicationMethod: CommunicationMethod.wifi,
      dataFormat: DataFormat.binary,
      readingFrequency: Duration(minutes: 5),
      parameters: ['ecg_waveform', 'heart_rate', 'rhythm_analysis', 'timestamp'],
      normalRanges: {
        'heart_rate': {'min': 60, 'max': 100},
      },
      alertThresholds: {
        'heart_rate': {'critical_high': 150, 'critical_low': 40},
        'rhythm_analysis': {'arrhythmia_threshold': 0.2},
      },
    );

    // Temperature Monitor Protocol
    _deviceProtocols[DeviceType.temperatureMonitor] = DeviceProtocol(
      type: DeviceType.temperatureMonitor,
      communicationMethod: CommunicationMethod.bluetooth,
      dataFormat: DataFormat.json,
      readingFrequency: Duration(minutes: 30),
      parameters: ['body_temperature', 'ambient_temperature', 'timestamp'],
      normalRanges: {
        'body_temperature': {'min': 36.1, 'max': 37.2},
      },
      alertThresholds: {
        'body_temperature': {'critical_high': 39.0, 'critical_low': 35.0},
      },
    );

    debugPrint('✅ Device protocols initialized for ${_deviceProtocols.length} device types');
  }

  /// Discover and connect to available medical devices
  Future<void> _discoverDevices() async {
    try {
      // Simulate device discovery (in production, use actual device discovery APIs)
      final discoveredDevices = await _simulateDeviceDiscovery();
      
      for (final device in discoveredDevices) {
        await _connectToDevice(device);
      }
      
      debugPrint('✅ Connected to ${_connectedDevices.length} medical devices');
    } catch (e) {
      debugPrint('❌ Device discovery failed: $e');
    }
  }

  /// Simulate device discovery for demonstration
  Future<List<MedicalDevice>> _simulateDeviceDiscovery() async {
    return [
      MedicalDevice(
        id: 'bp_monitor_001',
        name: 'Omron HEM-7156T',
        type: DeviceType.bloodPressureMonitor,
        manufacturer: 'Omron Healthcare',
        model: 'HEM-7156T',
        serialNumber: 'OM2024BP001',
        firmwareVersion: '2.1.0',
        batteryLevel: 85,
        lastCalibration: DateTime.now().subtract(Duration(days: 30)),
        isConnected: false,
        connectionMethod: CommunicationMethod.bluetooth,
        macAddress: '00:11:22:33:44:55',
      ),
      MedicalDevice(
        id: 'hr_monitor_001',
        name: 'Polar H10',
        type: DeviceType.heartRateMonitor,
        manufacturer: 'Polar Electro',
        model: 'H10',
        serialNumber: 'PO2024HR001',
        firmwareVersion: '3.2.1',
        batteryLevel: 92,
        lastCalibration: DateTime.now().subtract(Duration(days: 15)),
        isConnected: false,
        connectionMethod: CommunicationMethod.bluetooth,
        macAddress: '00:11:22:33:44:56',
      ),
      MedicalDevice(
        id: 'glucose_monitor_001',
        name: 'FreeStyle Libre 2',
        type: DeviceType.glucoseMonitor,
        manufacturer: 'Abbott',
        model: 'Libre 2',
        serialNumber: 'AB2024GL001',
        firmwareVersion: '1.8.5',
        batteryLevel: 78,
        lastCalibration: DateTime.now().subtract(Duration(days: 7)),
        isConnected: false,
        connectionMethod: CommunicationMethod.nfc,
        macAddress: '00:11:22:33:44:57',
      ),
      MedicalDevice(
        id: 'oximeter_001',
        name: 'Masimo MightySat Rx',
        type: DeviceType.pulseOximeter,
        manufacturer: 'Masimo',
        model: 'MightySat Rx',
        serialNumber: 'MS2024OX001',
        firmwareVersion: '4.1.2',
        batteryLevel: 88,
        lastCalibration: DateTime.now().subtract(Duration(days: 20)),
        isConnected: false,
        connectionMethod: CommunicationMethod.bluetooth,
        macAddress: '00:11:22:33:44:58',
      ),
    ];
  }

  /// Connect to a medical device
  Future<void> _connectToDevice(MedicalDevice device) async {
    try {
      // Simulate connection process
      await Future.delayed(Duration(milliseconds: 500));
      
      device.isConnected = true;
      device.lastConnected = DateTime.now();
      _connectedDevices[device.id] = device;
      
      // Initialize device readings list
      _deviceReadings[device.id] = [];
      
      // Start real-time data collection
      await _startDeviceDataCollection(device);
      
      debugPrint('✅ Connected to device: ${device.name}');
    } catch (e) {
      debugPrint('❌ Failed to connect to device ${device.name}: $e');
    }
  }

  /// Start real-time data collection from device
  Future<void> _startDeviceDataCollection(MedicalDevice device) async {
    final protocol = _deviceProtocols[device.type];
    if (protocol == null) return;
    
    // Create WebSocket connection for real-time data
    try {
      final wsUrl = 'ws://device-${device.id}.local:8080/data';
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _deviceConnections[device.id] = channel;
      
      // Listen for device data
      channel.stream.listen(
        (data) => _processDeviceData(device.id, data),
        onError: (error) => debugPrint('❌ WebSocket error for ${device.id}: $error'),
        onDone: () => _handleDeviceDisconnection(device.id),
      );
      
      // Send configuration to device
      await _configureDevice(device, channel);
      
    } catch (e) {
      debugPrint('❌ Failed to establish WebSocket connection for ${device.id}: $e');
      // Fallback to simulated data
      _startSimulatedDataCollection(device);
    }
  }

  /// Configure device parameters
  Future<void> _configureDevice(MedicalDevice device, WebSocketChannel channel) async {
    final protocol = _deviceProtocols[device.type]!;
    
    final config = {
      'device_id': device.id,
      'reading_frequency': protocol.readingFrequency.inMilliseconds,
      'parameters': protocol.parameters,
      'alert_thresholds': protocol.alertThresholds,
      'data_format': protocol.dataFormat.toString(),
    };
    
    channel.sink.add(jsonEncode(config));
    debugPrint('✅ Device ${device.id} configured');
  }

  /// Process incoming device data
  void _processDeviceData(String deviceId, dynamic rawData) {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) return;
      
      final protocol = _deviceProtocols[device.type];
      if (protocol == null) return;
      
      // Parse data based on protocol format
      Map<String, dynamic> data;
      switch (protocol.dataFormat) {
        case DataFormat.json:
          data = jsonDecode(rawData);
          break;
        case DataFormat.xml:
          data = _parseXmlData(rawData);
          break;
        case DataFormat.binary:
          data = _parseBinaryData(rawData);
          break;
      }
      
      // Create device reading
      final reading = DeviceReading(
        id: _generateReadingId(),
        deviceId: deviceId,
        patientId: device.assignedPatientId,
        timestamp: DateTime.now(),
        parameters: data,
        qualityScore: _calculateDataQuality(data, protocol),
        isValidated: false,
      );
      
      // Store reading
      _storeDeviceReading(reading);
      
      // Check for alerts
      _checkForAlerts(reading, protocol);
      
      // Update vital trends
      _updateVitalTrends(reading);
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error processing device data for $deviceId: $e');
    }
  }

  /// Store device reading
  void _storeDeviceReading(DeviceReading reading) {
    _deviceReadings[reading.deviceId] ??= [];
    _deviceReadings[reading.deviceId]!.add(reading);
    
    // Keep only recent readings
    if (_deviceReadings[reading.deviceId]!.length > _maxReadingsPerDevice) {
      _deviceReadings[reading.deviceId]!.removeAt(0);
    }
  }

  /// Check for alerts based on device reading
  void _checkForAlerts(DeviceReading reading, DeviceProtocol protocol) {
    final alerts = <DeviceAlert>[];
    
    for (final param in reading.parameters.keys) {
      final value = reading.parameters[param];
      if (value is! num) continue;
      
      final thresholds = protocol.alertThresholds[param];
      if (thresholds == null) continue;
      
      AlertSeverity? severity;
      String? message;
      
      // Check critical high threshold
      if (thresholds['critical_high'] != null && value > thresholds['critical_high']) {
        severity = AlertSeverity.critical;
        message = '$param critically high: $value';
      }
      // Check critical low threshold
      else if (thresholds['critical_low'] != null && value < thresholds['critical_low']) {
        severity = AlertSeverity.critical;
        message = '$param critically low: $value';
      }
      // Check warning thresholds
      else if (thresholds['warning_high'] != null && value > thresholds['warning_high']) {
        severity = AlertSeverity.warning;
        message = '$param elevated: $value';
      }
      else if (thresholds['warning_low'] != null && value < thresholds['warning_low']) {
        severity = AlertSeverity.warning;
        message = '$param below normal: $value';
      }
      
      if (severity != null && message != null) {
        final alert = DeviceAlert(
          id: _generateAlertId(),
          deviceId: reading.deviceId,
          patientId: reading.patientId,
          parameter: param,
          value: value,
          severity: severity,
          message: message,
          timestamp: reading.timestamp,
          isAcknowledged: false,
        );
        
        alerts.add(alert);
        _activeAlerts[alert.id] = alert;
      }
    }
    
    // Trigger alert notifications
    if (alerts.isNotEmpty) {
      _triggerAlertNotifications(alerts);
    }
  }

  /// Update vital trends analysis
  void _updateVitalTrends(DeviceReading reading) {
    if (reading.patientId == null) return;
    
    _vitalTrends[reading.patientId!] ??= PatientVitalTrends(
      patientId: reading.patientId!,
      trends: {},
      lastUpdated: DateTime.now(),
    );
    
    final trends = _vitalTrends[reading.patientId!]!;
    
    for (final param in reading.parameters.keys) {
      final value = reading.parameters[param];
      if (value is! num) continue;
      
      trends.trends[param] ??= VitalTrend(
        parameter: param,
        values: [],
        timestamps: [],
        trend: TrendDirection.stable,
        lastValue: value,
      );
      
      final trend = trends.trends[param]!;
      trend.values.add(value);
      trend.timestamps.add(reading.timestamp);
      trend.lastValue = value;
      
      // Keep only recent values (last 100 readings)
      if (trend.values.length > 100) {
        trend.values.removeAt(0);
        trend.timestamps.removeAt(0);
      }
      
      // Calculate trend direction
      trend.trend = _calculateTrendDirection(trend.values);
    }
    
    trends.lastUpdated = DateTime.now();
  }

  /// Get real-time patient vitals
  Future<Map<String, dynamic>> getPatientVitals(String patientId) async {
    final devices = _connectedDevices.values
        .where((d) => d.assignedPatientId == patientId)
        .toList();
    
    final vitals = <String, dynamic>{};
    
    for (final device in devices) {
      final readings = _deviceReadings[device.id];
      if (readings != null && readings.isNotEmpty) {
        final latestReading = readings.last;
        vitals[device.type.toString()] = {
          'device_name': device.name,
          'last_reading': latestReading.timestamp.toIso8601String(),
          'parameters': latestReading.parameters,
          'quality_score': latestReading.qualityScore,
        };
      }
    }
    
    return {
      'patient_id': patientId,
      'vitals': vitals,
      'trends': _vitalTrends[patientId]?.toJson(),
      'active_alerts': _getPatientAlerts(patientId),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Assign device to patient
  Future<void> assignDeviceToPatient(String deviceId, String patientId) async {
    final device = _connectedDevices[deviceId];
    if (device == null) throw Exception('Device not found');
    
    device.assignedPatientId = patientId;
    device.assignedAt = DateTime.now();
    
    debugPrint('✅ Device ${device.name} assigned to patient $patientId');
    notifyListeners();
  }

  /// Get device status and diagnostics
  Map<String, dynamic> getDeviceStatus(String deviceId) {
    final device = _connectedDevices[deviceId];
    if (device == null) throw Exception('Device not found');
    
    final readings = _deviceReadings[deviceId] ?? [];
    final recentReadings = readings.where(
      (r) => DateTime.now().difference(r.timestamp).inMinutes < 30,
    ).toList();
    
    return {
      'device': device.toJson(),
      'connection_status': device.isConnected ? 'connected' : 'disconnected',
      'last_reading': readings.isNotEmpty 
          ? readings.last.timestamp.toIso8601String() 
          : null,
      'recent_readings_count': recentReadings.length,
      'data_quality_average': recentReadings.isNotEmpty
          ? recentReadings.map((r) => r.qualityScore).reduce((a, b) => a + b) / recentReadings.length
          : 0.0,
      'battery_level': device.batteryLevel,
      'calibration_status': _getCalibrationStatus(device),
    };
  }

  /// Start real-time monitoring
  void _startRealTimeMonitoring() {
    _monitoringTimer = Timer.periodic(_readingInterval, (timer) async {
      await _collectRealTimeData();
    });
  }

  /// Start alert system
  void _startAlertSystem() {
    _alertTimer = Timer.periodic(_alertCheckInterval, (timer) async {
      await _processAlerts();
    });
  }

  /// Start data processing
  void _startDataProcessing() {
    _dataProcessingTimer = Timer.periodic(_dataProcessingInterval, (timer) async {
      await _processAndAnalyzeData();
    });
  }

  List<DeviceAlert> _getPatientAlerts(String patientId) {
    return _activeAlerts.values.where((alert) => alert.patientId == patientId).toList();
  }

  String _getCalibrationStatus(MedicalDevice device) {
    final calibration = _deviceCalibrations[device.id];
    if (calibration == null) return 'not_calibrated';
    if (calibration.nextCalibrationDue.isBefore(DateTime.now())) {
      return 'due_for_calibration';
    }
    return 'calibrated';
  }

  Future<void> _collectRealTimeData() async {
    for (final device in _connectedDevices.values) {
      if (device.isConnected) {
        // In a real scenario, you would request data from the device.
        // Here we simulate receiving data.
        _startSimulatedDataCollection(device);
      }
    }
  }

  Future<void> _processAlerts() async {
    // Process and escalate alerts as needed
  }

  Future<void> _processAndAnalyzeData() async {
    // Perform batch analysis on collected data
  }

  Map<String, dynamic> _parseXmlData(String xmlString) {
    // In a real implementation, use an XML parsing library
    return {'xml_data': xmlString};
  }

  Map<String, dynamic> _parseBinaryData(dynamic binaryData) {
    // In a real implementation, parse binary data according to the device protocol
    return {'binary_data': binaryData.toString()};
  }

  double _calculateDataQuality(Map<String, dynamic> data, DeviceProtocol protocol) {
    // Simple quality check
    return data.isNotEmpty ? 1.0 : 0.0;
  }

  String _generateReadingId() {
    return 'reading_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _triggerAlertNotifications(List<DeviceAlert> alerts) {
    // Integrate with notification service
  }

  TrendDirection _calculateTrendDirection(List<num> values) {
    if (values.length < 2) return TrendDirection.stable;
    final last = values.last;
    final previous = values[values.length - 2];
    if (last > previous) return TrendDirection.increasing;
    if (last < previous) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  void _startSimulatedDataCollection(MedicalDevice device) {
    // Simulate data for demonstration
  }

  Future<void> _loadPatientDeviceAssociations() async {
    // Load from database
  }

  void _handleDeviceDisconnection(String deviceId) {
    final device = _connectedDevices[deviceId];
    if (device != null) {
      device.isConnected = false;
      debugPrint('🔌 Device disconnected: ${device.name}');
      notifyListeners();
    }
  }

  // Helper methods and additional functionality...
  // Due to space constraints, showing key structure and main methods

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _alertTimer?.cancel();
    _dataProcessingTimer?.cancel();
    
    // Close WebSocket connections
    for (final connection in _deviceConnections.values) {
      connection.sink.close();
    }
    
    super.dispose();
  }
}

// Data models for IoT devices

class MedicalDevice {
  MedicalDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.batteryLevel,
    required this.lastCalibration,
    required this.isConnected,
    required this.connectionMethod,
    required this.macAddress,
    this.assignedPatientId,
    this.assignedAt,
    this.lastConnected,
  });
  String id;
  String name;
  DeviceType type;
  String manufacturer;
  String model;
  String serialNumber;
  String firmwareVersion;
  int batteryLevel;
  DateTime lastCalibration;
  bool isConnected;
  CommunicationMethod connectionMethod;
  String macAddress;
  String? assignedPatientId;
  DateTime? assignedAt;
  DateTime? lastConnected;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'manufacturer': manufacturer,
      'model': model,
      'serial_number': serialNumber,
      'firmware_version': firmwareVersion,
      'battery_level': batteryLevel,
      'last_calibration': lastCalibration.toIso8601String(),
      'is_connected': isConnected,
      'connection_method': connectionMethod.toString(),
      'mac_address': macAddress,
      'assigned_patient_id': assignedPatientId,
      'assigned_at': assignedAt?.toIso8601String(),
      'last_connected': lastConnected?.toIso8601String(),
    };
  }
}

class DeviceProtocol {
  DeviceProtocol({
    required this.type,
    required this.communicationMethod,
    required this.dataFormat,
    required this.readingFrequency,
    required this.parameters,
    required this.normalRanges,
    required this.alertThresholds,
  });
  DeviceType type;
  CommunicationMethod communicationMethod;
  DataFormat dataFormat;
  Duration readingFrequency;
  List<String> parameters;
  Map<String, Map<String, num>> normalRanges;
  Map<String, Map<String, num>> alertThresholds;
}

class DeviceReading {
  DeviceReading({
    required this.id,
    required this.deviceId,
    this.patientId,
    required this.timestamp,
    required this.parameters,
    required this.qualityScore,
    required this.isValidated,
  });
  String id;
  String deviceId;
  String? patientId;
  DateTime timestamp;
  Map<String, dynamic> parameters;
  double qualityScore;
  bool isValidated;
}

class DeviceAlert {
  DeviceAlert({
    required this.id,
    required this.deviceId,
    this.patientId,
    required this.parameter,
    required this.value,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.isAcknowledged,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });
  String id;
  String deviceId;
  String? patientId;
  String parameter;
  num value;
  AlertSeverity severity;
  String message;
  DateTime timestamp;
  bool isAcknowledged;
  DateTime? acknowledgedAt;
  String? acknowledgedBy;
}

class PatientVitalTrends {
  PatientVitalTrends({
    required this.patientId,
    required this.trends,
    required this.lastUpdated,
  });
  String patientId;
  Map<String, VitalTrend> trends;
  DateTime lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'trends': trends.map((k, v) => MapEntry(k, v.toJson())),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class VitalTrend {
  VitalTrend({
    required this.parameter,
    required this.values,
    required this.timestamps,
    required this.trend,
    required this.lastValue,
  });
  String parameter;
  List<num> values;
  List<DateTime> timestamps;
  TrendDirection trend;
  num lastValue;

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'values': values,
      'timestamps': timestamps.map((t) => t.toIso8601String()).toList(),
      'trend': trend.toString(),
      'last_value': lastValue,
    };
  }
}

class DeviceCalibration {
  DeviceCalibration({
    required this.deviceId,
    required this.calibratedAt,
    required this.calibratedBy,
    required this.calibrationData,
    required this.nextCalibrationDue,
  });
  String deviceId;
  DateTime calibratedAt;
  String calibratedBy;
  Map<String, dynamic> calibrationData;
  DateTime nextCalibrationDue;
}

class AnomalyDetection {
  AnomalyDetection({
    required this.id,
    required this.patientId,
    required this.parameter,
    required this.value,
    required this.expectedValue,
    required this.anomalyScore,
    required this.detectedAt,
    required this.description,
  });
  String id;
  String patientId;
  String parameter;
  num value;
  num expectedValue;
  double anomalyScore;
  DateTime detectedAt;
  String description;
}

enum DeviceType {
  bloodPressureMonitor,
  heartRateMonitor,
  glucoseMonitor,
  pulseOximeter,
  ecgMonitor,
  temperatureMonitor,
  weightScale,
  spirometer,
  peakFlowMeter,
  sleepMonitor,
}

enum CommunicationMethod { bluetooth, wifi, nfc, zigbee, lora, cellular }
enum DataFormat { json, xml, binary, csv }
enum AlertSeverity { info, warning, critical, emergency }
enum TrendDirection { increasing, decreasing, stable, volatile }