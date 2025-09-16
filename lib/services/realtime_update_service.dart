import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'logging_service.dart';

/// Real-time update service for MedRefer AI
class RealtimeUpdateService extends ChangeNotifier {
  static final RealtimeUpdateService _instance = RealtimeUpdateService._internal();
  factory RealtimeUpdateService() => _instance;
  RealtimeUpdateService._internal();

  final LoggingService _loggingService = LoggingService();
  
  // WebSocket connection
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionUrl;
  String? _authToken;
  
  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  // Message handling
  final Map<String, StreamController<RealtimeMessage>> _subscriptions = {};
  final List<RealtimeMessage> _messageHistory = [];
  static const int _maxHistorySize = 1000;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectionUrl => _connectionUrl;
  int get reconnectAttempts => _reconnectAttempts;
  List<RealtimeMessage> get messageHistory => List.unmodifiable(_messageHistory);

  /// Initialize the real-time update service
  Future<void> initialize() async {
    try {
      _loggingService.info('Real-time update service initialized', context: 'Realtime');
    } catch (e) {
      _loggingService.error('Failed to initialize real-time update service', context: 'Realtime', error: e);
      rethrow;
    }
  }

  /// Connect to real-time server
  Future<void> connect(String url, {String? authToken}) async {
    if (_isConnected || _isConnecting) return;
    
    _isConnecting = true;
    _connectionUrl = url;
    _authToken = authToken;
    notifyListeners();
    
    try {
      _loggingService.info('Connecting to real-time server: $url', context: 'Realtime');
      
      // Create WebSocket connection
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);
      
      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
      // Send authentication if provided
      if (authToken != null) {
        await _sendAuthMessage(authToken);
      }
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      // Start heartbeat
      _startHeartbeat();
      
      _loggingService.info('Connected to real-time server', context: 'Realtime');
      notifyListeners();
      
    } catch (e) {
      _isConnecting = false;
      _loggingService.error('Failed to connect to real-time server', context: 'Realtime', error: e);
      await _scheduleReconnect();
    }
  }

  /// Disconnect from real-time server
  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    _loggingService.info('Disconnecting from real-time server', context: 'Realtime');
    
    _stopHeartbeat();
    _stopReconnectTimer();
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    
    _isConnected = false;
    _isConnecting = false;
    
    notifyListeners();
  }

  /// Subscribe to real-time updates for a specific channel
  Stream<RealtimeMessage> subscribe(String channel, {Map<String, dynamic>? filters}) {
    if (!_subscriptions.containsKey(channel)) {
      _subscriptions[channel] = StreamController<RealtimeMessage>.broadcast();
      
      // Send subscription message
      _sendSubscriptionMessage(channel, filters);
    }
    
    return _subscriptions[channel]!.stream;
  }

  /// Unsubscribe from a channel
  void unsubscribe(String channel) {
    if (_subscriptions.containsKey(channel)) {
      _subscriptions[channel]!.close();
      _subscriptions.remove(channel);
      
      // Send unsubscription message
      _sendUnsubscriptionMessage(channel);
    }
  }

  /// Send a message to the server
  Future<void> sendMessage(String type, Map<String, dynamic> data) async {
    if (!_isConnected) {
      throw RealtimeException('Not connected to real-time server');
    }
    
    final message = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    try {
      _channel!.sink.add(jsonEncode(message));
      _loggingService.debug('Sent real-time message: $type', context: 'Realtime', metadata: data);
    } catch (e) {
      _loggingService.error('Failed to send real-time message', context: 'Realtime', error: e);
      throw RealtimeException('Failed to send message: $e');
    }
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final realtimeMessage = RealtimeMessage.fromJson(data);
      
      // Add to history
      _addToHistory(realtimeMessage);
      
      // Route to appropriate subscribers
      _routeMessage(realtimeMessage);
      
      _loggingService.debug('Received real-time message: ${realtimeMessage.type}', 
        context: 'Realtime', metadata: realtimeMessage.data);
        
    } catch (e) {
      _loggingService.error('Failed to handle real-time message', context: 'Realtime', error: e);
    }
  }

  /// Handle connection errors
  void _handleError(dynamic error) {
    _loggingService.error('Real-time connection error', context: 'Realtime', error: error);
    
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    
    _scheduleReconnect();
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _loggingService.warning('Real-time connection closed', context: 'Realtime');
    
    _isConnected = false;
    _isConnecting = false;
    _stopHeartbeat();
    notifyListeners();
    
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  Future<void> _scheduleReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _loggingService.error('Max reconnection attempts reached', context: 'Realtime');
      return;
    }
    
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    _loggingService.info('Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s', 
      context: 'Realtime');
    
    _reconnectTimer = Timer(delay, () {
      if (_connectionUrl != null) {
        connect(_connectionUrl!, authToken: _authToken);
      }
    });
  }

  /// Stop reconnection timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendHeartbeat();
      }
    });
  }

  /// Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send heartbeat message
  void _sendHeartbeat() {
    try {
      _channel?.sink.add(jsonEncode({
        'type': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      _loggingService.error('Failed to send heartbeat', context: 'Realtime', error: e);
    }
  }

  /// Send authentication message
  Future<void> _sendAuthMessage(String token) async {
    await sendMessage('auth', {'token': token});
  }

  /// Send subscription message
  void _sendSubscriptionMessage(String channel, Map<String, dynamic>? filters) {
    sendMessage('subscribe', {
      'channel': channel,
      'filters': filters,
    });
  }

  /// Send unsubscription message
  void _sendUnsubscriptionMessage(String channel) {
    sendMessage('unsubscribe', {'channel': channel});
  }

  /// Add message to history
  void _addToHistory(RealtimeMessage message) {
    _messageHistory.add(message);
    
    // Keep history size manageable
    if (_messageHistory.length > _maxHistorySize) {
      _messageHistory.removeRange(0, _messageHistory.length - _maxHistorySize);
    }
  }

  /// Route message to appropriate subscribers
  void _routeMessage(RealtimeMessage message) {
    // Route to channel-specific subscribers
    if (message.channel != null && _subscriptions.containsKey(message.channel)) {
      _subscriptions[message.channel]!.add(message);
    }
    
    // Route to type-specific subscribers
    final typeKey = 'type:${message.type}';
    if (_subscriptions.containsKey(typeKey)) {
      _subscriptions[typeKey]!.add(message);
    }
  }

  /// Get connection status
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'connectionUrl': _connectionUrl,
      'reconnectAttempts': _reconnectAttempts,
      'subscriptionCount': _subscriptions.length,
      'messageHistorySize': _messageHistory.length,
    };
  }

  /// Clear message history
  void clearHistory() {
    _messageHistory.clear();
    _loggingService.info('Real-time message history cleared', context: 'Realtime');
  }

  @override
  void dispose() {
    disconnect();
    
    // Close all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.close();
    }
    _subscriptions.clear();
    
    super.dispose();
  }
}

/// Real-time message model
class RealtimeMessage {
  final String id;
  final String type;
  final String? channel;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? senderId;
  final Map<String, dynamic>? metadata;

  RealtimeMessage({
    required this.id,
    required this.type,
    this.channel,
    required this.data,
    required this.timestamp,
    this.senderId,
    this.metadata,
  });

  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'],
      channel: json['channel'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'channel': channel,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'metadata': metadata,
    };
  }
}

/// Real-time exception
class RealtimeException implements Exception {
  final String message;
  RealtimeException(this.message);
  
  @override
  String toString() => 'RealtimeException: $message';
}
