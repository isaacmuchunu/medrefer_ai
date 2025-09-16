import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Advanced Real-time Collaboration Service
/// Provides WebSocket-based live updates, collaborative editing, and presence tracking
class CollaborationService extends ChangeNotifier {
  static final CollaborationService _instance = CollaborationService._internal();
  factory CollaborationService() => _instance;
  CollaborationService._internal();

  // WebSocket configuration
  static const String _wsUrl = 'wss://api.medrefer.ai/collaboration';
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 5;

  // Connection state
  WebSocketChannel? _channel;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // Collaboration state
  final Map<String, CollaborationSession> _activeSessions = {};
  final Map<String, List<UserPresence>> _presenceData = {};
  final Map<String, DocumentState> _documentStates = {};
  final List<CollaborationEvent> _eventHistory = [];
  
  // Stream controllers
  final _sessionUpdatesController = StreamController<CollaborationSession>.broadcast();
  final _presenceUpdatesController = StreamController<PresenceUpdate>.broadcast();
  final _documentUpdatesController = StreamController<DocumentUpdate>.broadcast();
  final _notificationController = StreamController<CollaborationNotification>.broadcast();
  
  // Public streams
  Stream<CollaborationSession> get sessionUpdates => _sessionUpdatesController.stream;
  Stream<PresenceUpdate> get presenceUpdates => _presenceUpdatesController.stream;
  Stream<DocumentUpdate> get documentUpdates => _documentUpdatesController.stream;
  Stream<CollaborationNotification> get notifications => _notificationController.stream;

  // Getters
  bool get isConnected => _isConnected;
  Map<String, CollaborationSession> get activeSessions => Map.unmodifiable(_activeSessions);
  Map<String, List<UserPresence>> get presenceData => Map.unmodifiable(_presenceData);

  /// Initialize the collaboration service
  Future<void> initialize(String userId, String authToken) async {
    try {
      await _connect(userId, authToken);
      _startHeartbeat();
      debugPrint('Collaboration Service initialized');
    } catch (e) {
      debugPrint('Error initializing Collaboration Service: $e');
      _scheduleReconnect();
    }
  }

  /// Connect to WebSocket server
  Future<void> _connect(String userId, String authToken) async {
    try {
      final uri = Uri.parse('$_wsUrl?userId=$userId&token=$authToken');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      
      // Send initial presence
      _sendPresence(userId, PresenceStatus.online);
      
      notifyListeners();
      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      throw CollaborationException('Failed to connect to collaboration server');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String;
      
      switch (type) {
        case 'session_update':
          _handleSessionUpdate(data['payload']);
          break;
        case 'presence_update':
          _handlePresenceUpdate(data['payload']);
          break;
        case 'document_update':
          _handleDocumentUpdate(data['payload']);
          break;
        case 'cursor_update':
          _handleCursorUpdate(data['payload']);
          break;
        case 'selection_update':
          _handleSelectionUpdate(data['payload']);
          break;
        case 'comment_added':
          _handleCommentAdded(data['payload']);
          break;
        case 'notification':
          _handleNotification(data['payload']);
          break;
        case 'conflict_detected':
          _handleConflict(data['payload']);
          break;
        case 'heartbeat_ack':
          // Heartbeat acknowledged
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
      
      // Store event in history
      _eventHistory.add(CollaborationEvent(
        type: type,
        payload: data['payload'],
        timestamp: DateTime.now(),
      ));
      
      // Limit history size
      if (_eventHistory.length > 1000) {
        _eventHistory.removeRange(0, 100);
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  /// Create a new collaboration session
  Future<CollaborationSession> createSession({
    required String documentId,
    required String documentType,
    required String creatorId,
    List<String>? invitedUserIds,
    SessionPermissions? permissions,
  }) async {
    try {
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      
      final session = CollaborationSession(
        id: sessionId,
        documentId: documentId,
        documentType: documentType,
        creatorId: creatorId,
        participants: [creatorId, ...?invitedUserIds],
        permissions: permissions ?? SessionPermissions.defaultPermissions(),
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      _activeSessions[sessionId] = session;
      
      // Send session creation message
      _sendMessage({
        'type': 'create_session',
        'payload': session.toJson(),
      });
      
      _sessionUpdatesController.add(session);
      
      return session;
    } catch (e) {
      debugPrint('Error creating collaboration session: $e');
      throw CollaborationException('Failed to create collaboration session');
    }
  }

  /// Join an existing collaboration session
  Future<void> joinSession(String sessionId, String userId) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        throw CollaborationException('Session not found');
      }
      
      final session = _activeSessions[sessionId]!;
      
      if (!session.participants.contains(userId)) {
        session.participants.add(userId);
      }
      
      // Send join message
      _sendMessage({
        'type': 'join_session',
        'payload': {
          'sessionId': sessionId,
          'userId': userId,
        },
      });
      
      // Update presence
      _updatePresence(sessionId, userId, PresenceStatus.active);
      
      _sessionUpdatesController.add(session);
    } catch (e) {
      debugPrint('Error joining session: $e');
      throw CollaborationException('Failed to join session');
    }
  }

  /// Leave a collaboration session
  Future<void> leaveSession(String sessionId, String userId) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return;
      }
      
      final session = _activeSessions[sessionId]!;
      session.participants.remove(userId);
      
      // Send leave message
      _sendMessage({
        'type': 'leave_session',
        'payload': {
          'sessionId': sessionId,
          'userId': userId,
        },
      });
      
      // Update presence
      _updatePresence(sessionId, userId, PresenceStatus.offline);
      
      // Remove session if no participants
      if (session.participants.isEmpty) {
        _activeSessions.remove(sessionId);
      }
      
      _sessionUpdatesController.add(session);
    } catch (e) {
      debugPrint('Error leaving session: $e');
    }
  }

  /// Send a document update
  Future<void> updateDocument({
    required String sessionId,
    required String documentId,
    required DocumentChange change,
    required String userId,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        throw CollaborationException('Session not found');
      }
      
      // Check permissions
      final session = _activeSessions[sessionId]!;
      if (!_hasEditPermission(session, userId)) {
        throw CollaborationException('User does not have edit permission');
      }
      
      // Apply operational transformation for conflict resolution
      final transformedChange = await _transformChange(documentId, change);
      
      // Update local document state
      if (!_documentStates.containsKey(documentId)) {
        _documentStates[documentId] = DocumentState(
          documentId: documentId,
          version: 0,
          content: '',
          lastModified: DateTime.now(),
        );
      }
      
      final documentState = _documentStates[documentId]!;
      documentState.applyChange(transformedChange);
      documentState.version++;
      
      // Send update message
      _sendMessage({
        'type': 'document_update',
        'payload': {
          'sessionId': sessionId,
          'documentId': documentId,
          'change': transformedChange.toJson(),
          'userId': userId,
          'version': documentState.version,
        },
      });
      
      // Broadcast update
      _documentUpdatesController.add(DocumentUpdate(
        sessionId: sessionId,
        documentId: documentId,
        change: transformedChange,
        userId: userId,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error updating document: $e');
      throw CollaborationException('Failed to update document');
    }
  }

  /// Send cursor position update
  Future<void> updateCursor({
    required String sessionId,
    required String documentId,
    required int position,
    required String userId,
  }) async {
    try {
      _sendMessage({
        'type': 'cursor_update',
        'payload': {
          'sessionId': sessionId,
          'documentId': documentId,
          'position': position,
          'userId': userId,
        },
      });
    } catch (e) {
      debugPrint('Error updating cursor: $e');
    }
  }

  /// Send selection update
  Future<void> updateSelection({
    required String sessionId,
    required String documentId,
    required int start,
    required int end,
    required String userId,
  }) async {
    try {
      _sendMessage({
        'type': 'selection_update',
        'payload': {
          'sessionId': sessionId,
          'documentId': documentId,
          'start': start,
          'end': end,
          'userId': userId,
        },
      });
    } catch (e) {
      debugPrint('Error updating selection: $e');
    }
  }

  /// Add a comment to a document
  Future<void> addComment({
    required String sessionId,
    required String documentId,
    required String comment,
    required int position,
    required String userId,
  }) async {
    try {
      final commentData = DocumentComment(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        documentId: documentId,
        userId: userId,
        comment: comment,
        position: position,
        timestamp: DateTime.now(),
      );
      
      _sendMessage({
        'type': 'add_comment',
        'payload': {
          'sessionId': sessionId,
          'comment': commentData.toJson(),
        },
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw CollaborationException('Failed to add comment');
    }
  }

  /// Resolve a comment
  Future<void> resolveComment(String sessionId, String commentId) async {
    try {
      _sendMessage({
        'type': 'resolve_comment',
        'payload': {
          'sessionId': sessionId,
          'commentId': commentId,
        },
      });
    } catch (e) {
      debugPrint('Error resolving comment: $e');
    }
  }

  /// Handle session update
  void _handleSessionUpdate(Map<String, dynamic> payload) {
    try {
      final session = CollaborationSession.fromJson(payload);
      _activeSessions[session.id] = session;
      _sessionUpdatesController.add(session);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling session update: $e');
    }
  }

  /// Handle presence update
  void _handlePresenceUpdate(Map<String, dynamic> payload) {
    try {
      final sessionId = payload['sessionId'] as String;
      final userId = payload['userId'] as String;
      final status = PresenceStatus.values.firstWhere(
        (s) => s.toString() == 'PresenceStatus.${payload['status']}',
        orElse: () => PresenceStatus.offline,
      );
      
      _updatePresence(sessionId, userId, status);
      
      _presenceUpdatesController.add(PresenceUpdate(
        sessionId: sessionId,
        userId: userId,
        status: status,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error handling presence update: $e');
    }
  }

  /// Handle document update
  void _handleDocumentUpdate(Map<String, dynamic> payload) {
    try {
      final sessionId = payload['sessionId'] as String;
      final documentId = payload['documentId'] as String;
      final change = DocumentChange.fromJson(payload['change']);
      final userId = payload['userId'] as String;
      final version = payload['version'] as int;
      
      // Update local document state
      if (_documentStates.containsKey(documentId)) {
        final documentState = _documentStates[documentId]!;
        
        // Check for version conflict
        if (version > documentState.version + 1) {
          // Request missing updates
          _requestMissingUpdates(documentId, documentState.version, version);
        } else if (version == documentState.version + 1) {
          documentState.applyChange(change);
          documentState.version = version;
        }
      }
      
      _documentUpdatesController.add(DocumentUpdate(
        sessionId: sessionId,
        documentId: documentId,
        change: change,
        userId: userId,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error handling document update: $e');
    }
  }

  /// Handle cursor update
  void _handleCursorUpdate(Map<String, dynamic> payload) {
    try {
      final sessionId = payload['sessionId'] as String;
      final userId = payload['userId'] as String;
      final position = payload['position'] as int;
      
      // Update cursor position in presence data
      final presence = _presenceData[sessionId]?.firstWhere(
        (p) => p.userId == userId,
        orElse: () => UserPresence(
          userId: userId,
          status: PresenceStatus.active,
          lastActivity: DateTime.now(),
        ),
      );
      
      if (presence != null) {
        presence.cursorPosition = position;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling cursor update: $e');
    }
  }

  /// Handle selection update
  void _handleSelectionUpdate(Map<String, dynamic> payload) {
    try {
      final sessionId = payload['sessionId'] as String;
      final userId = payload['userId'] as String;
      final start = payload['start'] as int;
      final end = payload['end'] as int;
      
      // Update selection in presence data
      final presence = _presenceData[sessionId]?.firstWhere(
        (p) => p.userId == userId,
        orElse: () => UserPresence(
          userId: userId,
          status: PresenceStatus.active,
          lastActivity: DateTime.now(),
        ),
      );
      
      if (presence != null) {
        presence.selectionStart = start;
        presence.selectionEnd = end;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling selection update: $e');
    }
  }

  /// Handle comment added
  void _handleCommentAdded(Map<String, dynamic> payload) {
    try {
      final comment = DocumentComment.fromJson(payload['comment']);
      
      _notificationController.add(CollaborationNotification(
        type: NotificationType.commentAdded,
        message: 'New comment added',
        data: comment,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error handling comment: $e');
    }
  }

  /// Handle notification
  void _handleNotification(Map<String, dynamic> payload) {
    try {
      final notification = CollaborationNotification.fromJson(payload);
      _notificationController.add(notification);
    } catch (e) {
      debugPrint('Error handling notification: $e');
    }
  }

  /// Handle conflict detection
  void _handleConflict(Map<String, dynamic> payload) {
    try {
      final documentId = payload['documentId'] as String;
      final conflicts = (payload['conflicts'] as List)
          .map((c) => ConflictInfo.fromJson(c))
          .toList();
      
      // Attempt automatic resolution
      _resolveConflicts(documentId, conflicts);
      
      // Notify if manual resolution needed
      if (conflicts.any((c) => !c.autoResolvable)) {
        _notificationController.add(CollaborationNotification(
          type: NotificationType.conflictDetected,
          message: 'Document conflict detected',
          data: conflicts,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error handling conflict: $e');
    }
  }

  /// Transform change using Operational Transformation
  Future<DocumentChange> _transformChange(
    String documentId,
    DocumentChange change,
  ) async {
    // Implement OT algorithm for concurrent editing
    // This is a simplified version - production would use full OT
    
    if (!_documentStates.containsKey(documentId)) {
      return change;
    }
    
    final documentState = _documentStates[documentId]!;
    
    // Transform based on pending operations
    final transformedChange = change;
    
    // Apply transformation rules
    if (change.type == ChangeType.insert) {
      // Adjust position based on concurrent inserts
      // ... transformation logic
    } else if (change.type == ChangeType.delete) {
      // Adjust range based on concurrent deletes
      // ... transformation logic
    }
    
    return transformedChange;
  }

  /// Resolve conflicts automatically where possible
  void _resolveConflicts(String documentId, List<ConflictInfo> conflicts) {
    for (final conflict in conflicts) {
      if (conflict.autoResolvable) {
        // Apply resolution strategy
        switch (conflict.strategy) {
          case ResolutionStrategy.lastWrite:
            // Accept the most recent change
            _applyResolution(documentId, conflict.changes.last);
            break;
          case ResolutionStrategy.merge:
            // Merge non-overlapping changes
            _mergeChanges(documentId, conflict.changes);
            break;
          case ResolutionStrategy.manual:
            // Requires manual resolution
            break;
        }
      }
    }
  }

  /// Apply conflict resolution
  void _applyResolution(String documentId, DocumentChange change) {
    if (_documentStates.containsKey(documentId)) {
      _documentStates[documentId]!.applyChange(change);
    }
  }

  /// Merge non-overlapping changes
  void _mergeChanges(String documentId, List<DocumentChange> changes) {
    if (!_documentStates.containsKey(documentId)) return;
    
    final documentState = _documentStates[documentId]!;
    
    // Sort changes by position
    changes.sort((a, b) => a.position.compareTo(b.position));
    
    // Apply non-overlapping changes
    for (final change in changes) {
      if (!_isOverlapping(change, changes)) {
        documentState.applyChange(change);
      }
    }
  }

  /// Check if change overlaps with others
  bool _isOverlapping(DocumentChange change, List<DocumentChange> others) {
    for (final other in others) {
      if (other == change) continue;
      
      if (change.type == ChangeType.delete && other.type == ChangeType.delete) {
        // Check if delete ranges overlap
        final changeEnd = change.position + (change.length ?? 0);
        final otherEnd = other.position + (other.length ?? 0);
        
        if (change.position < otherEnd && changeEnd > other.position) {
          return true;
        }
      }
    }
    return false;
  }

  /// Request missing document updates
  void _requestMissingUpdates(String documentId, int fromVersion, int toVersion) {
    _sendMessage({
      'type': 'request_updates',
      'payload': {
        'documentId': documentId,
        'fromVersion': fromVersion,
        'toVersion': toVersion,
      },
    });
  }

  /// Update user presence
  void _updatePresence(String sessionId, String userId, PresenceStatus status) {
    if (!_presenceData.containsKey(sessionId)) {
      _presenceData[sessionId] = [];
    }
    
    final presenceList = _presenceData[sessionId]!;
    final existingIndex = presenceList.indexWhere((p) => p.userId == userId);
    
    final presence = UserPresence(
      userId: userId,
      status: status,
      lastActivity: DateTime.now(),
    );
    
    if (existingIndex >= 0) {
      presenceList[existingIndex] = presence;
    } else {
      presenceList.add(presence);
    }
    
    // Remove offline users after delay
    if (status == PresenceStatus.offline) {
      Future.delayed(Duration(minutes: 5), () {
        presenceList.removeWhere((p) => p.userId == userId && p.status == PresenceStatus.offline);
      });
    }
  }

  /// Check if user has edit permission
  bool _hasEditPermission(CollaborationSession session, String userId) {
    if (session.creatorId == userId) return true;
    
    final permissions = session.permissions;
    if (permissions.allCanEdit) return true;
    
    return permissions.editUsers.contains(userId);
  }

  /// Send presence update
  void _sendPresence(String userId, PresenceStatus status) {
    _sendMessage({
      'type': 'presence_update',
      'payload': {
        'userId': userId,
        'status': status.toString().split('.').last,
      },
    });
  }

  /// Send message through WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket not connected');
      return;
    }
    
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        _sendMessage({'type': 'heartbeat'});
      }
    });
  }

  /// Handle WebSocket error
  void _handleError(error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('Attempting reconnection (${_reconnectAttempts}/$_maxReconnectAttempts)');
      // Reconnection logic would go here
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    
    _isConnected = false;
    _activeSessions.clear();
    _presenceData.clear();
    _documentStates.clear();
    
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _sessionUpdatesController.close();
    _presenceUpdatesController.close();
    _documentUpdatesController.close();
    _notificationController.close();
    super.dispose();
  }
}

// Data Models for Collaboration

class CollaborationSession {
  final String id;
  final String documentId;
  final String documentType;
  final String creatorId;
  final List<String> participants;
  final SessionPermissions permissions;
  final DateTime createdAt;
  bool isActive;

  CollaborationSession({
    required this.id,
    required this.documentId,
    required this.documentType,
    required this.creatorId,
    required this.participants,
    required this.permissions,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentId': documentId,
    'documentType': documentType,
    'creatorId': creatorId,
    'participants': participants,
    'permissions': permissions.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory CollaborationSession.fromJson(Map<String, dynamic> json) => CollaborationSession(
    id: json['id'],
    documentId: json['documentId'],
    documentType: json['documentType'],
    creatorId: json['creatorId'],
    participants: List<String>.from(json['participants']),
    permissions: SessionPermissions.fromJson(json['permissions']),
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'] ?? true,
  );
}

class SessionPermissions {
  final bool allCanEdit;
  final bool allCanComment;
  final List<String> editUsers;
  final List<String> viewUsers;

  SessionPermissions({
    required this.allCanEdit,
    required this.allCanComment,
    required this.editUsers,
    required this.viewUsers,
  });

  factory SessionPermissions.defaultPermissions() => SessionPermissions(
    allCanEdit: false,
    allCanComment: true,
    editUsers: [],
    viewUsers: [],
  );

  Map<String, dynamic> toJson() => {
    'allCanEdit': allCanEdit,
    'allCanComment': allCanComment,
    'editUsers': editUsers,
    'viewUsers': viewUsers,
  };

  factory SessionPermissions.fromJson(Map<String, dynamic> json) => SessionPermissions(
    allCanEdit: json['allCanEdit'],
    allCanComment: json['allCanComment'],
    editUsers: List<String>.from(json['editUsers']),
    viewUsers: List<String>.from(json['viewUsers']),
  );
}

class UserPresence {
  final String userId;
  PresenceStatus status;
  DateTime lastActivity;
  int? cursorPosition;
  int? selectionStart;
  int? selectionEnd;
  String? activeDocument;

  UserPresence({
    required this.userId,
    required this.status,
    required this.lastActivity,
    this.cursorPosition,
    this.selectionStart,
    this.selectionEnd,
    this.activeDocument,
  });
}

enum PresenceStatus {
  online,
  active,
  idle,
  away,
  offline,
}

class DocumentState {
  final String documentId;
  int version;
  String content;
  DateTime lastModified;
  final List<DocumentChange> pendingChanges = [];

  DocumentState({
    required this.documentId,
    required this.version,
    required this.content,
    required this.lastModified,
  });

  void applyChange(DocumentChange change) {
    switch (change.type) {
      case ChangeType.insert:
        if (change.text != null) {
          content = content.substring(0, change.position) +
              change.text! +
              content.substring(change.position);
        }
        break;
      case ChangeType.delete:
        if (change.length != null) {
          content = content.substring(0, change.position) +
              content.substring(change.position + change.length!);
        }
        break;
      case ChangeType.replace:
        if (change.text != null && change.length != null) {
          content = content.substring(0, change.position) +
              change.text! +
              content.substring(change.position + change.length!);
        }
        break;
      case ChangeType.format:
        // Handle formatting changes
        break;
    }
    lastModified = DateTime.now();
  }
}

class DocumentChange {
  final ChangeType type;
  final int position;
  final String? text;
  final int? length;
  final Map<String, dynamic>? attributes;

  DocumentChange({
    required this.type,
    required this.position,
    this.text,
    this.length,
    this.attributes,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'position': position,
    if (text != null) 'text': text,
    if (length != null) 'length': length,
    if (attributes != null) 'attributes': attributes,
  };

  factory DocumentChange.fromJson(Map<String, dynamic> json) => DocumentChange(
    type: ChangeType.values.firstWhere(
      (t) => t.toString() == 'ChangeType.${json['type']}',
    ),
    position: json['position'],
    text: json['text'],
    length: json['length'],
    attributes: json['attributes'],
  );
}

enum ChangeType {
  insert,
  delete,
  replace,
  format,
}

class DocumentUpdate {
  final String sessionId;
  final String documentId;
  final DocumentChange change;
  final String userId;
  final DateTime timestamp;

  DocumentUpdate({
    required this.sessionId,
    required this.documentId,
    required this.change,
    required this.userId,
    required this.timestamp,
  });
}

class PresenceUpdate {
  final String sessionId;
  final String userId;
  final PresenceStatus status;
  final DateTime timestamp;

  PresenceUpdate({
    required this.sessionId,
    required this.userId,
    required this.status,
    required this.timestamp,
  });
}

class DocumentComment {
  final String id;
  final String documentId;
  final String userId;
  final String comment;
  final int position;
  final DateTime timestamp;
  bool resolved;

  DocumentComment({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.comment,
    required this.position,
    required this.timestamp,
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentId': documentId,
    'userId': userId,
    'comment': comment,
    'position': position,
    'timestamp': timestamp.toIso8601String(),
    'resolved': resolved,
  };

  factory DocumentComment.fromJson(Map<String, dynamic> json) => DocumentComment(
    id: json['id'],
    documentId: json['documentId'],
    userId: json['userId'],
    comment: json['comment'],
    position: json['position'],
    timestamp: DateTime.parse(json['timestamp']),
    resolved: json['resolved'] ?? false,
  );
}

class CollaborationNotification {
  final NotificationType type;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  CollaborationNotification({
    required this.type,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory CollaborationNotification.fromJson(Map<String, dynamic> json) => CollaborationNotification(
    type: NotificationType.values.firstWhere(
      (t) => t.toString() == 'NotificationType.${json['type']}',
    ),
    message: json['message'],
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

enum NotificationType {
  userJoined,
  userLeft,
  documentUpdated,
  commentAdded,
  conflictDetected,
  sessionEnded,
}

class CollaborationEvent {
  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  CollaborationEvent({
    required this.type,
    required this.payload,
    required this.timestamp,
  });
}

class ConflictInfo {
  final String id;
  final List<DocumentChange> changes;
  final bool autoResolvable;
  final ResolutionStrategy strategy;

  ConflictInfo({
    required this.id,
    required this.changes,
    required this.autoResolvable,
    required this.strategy,
  });

  factory ConflictInfo.fromJson(Map<String, dynamic> json) => ConflictInfo(
    id: json['id'],
    changes: (json['changes'] as List)
        .map((c) => DocumentChange.fromJson(c))
        .toList(),
    autoResolvable: json['autoResolvable'],
    strategy: ResolutionStrategy.values.firstWhere(
      (s) => s.toString() == 'ResolutionStrategy.${json['strategy']}',
    ),
  );
}

enum ResolutionStrategy {
  lastWrite,
  merge,
  manual,
}

class CollaborationException implements Exception {
  final String message;
  CollaborationException(this.message);
  
  @override
  String toString() => 'CollaborationException: $message';
}