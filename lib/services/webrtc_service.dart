import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// WebRTC service for handling video/audio calls in the MedRefer AI app
class WebRTCService extends ChangeNotifier {
  static final WebRTCService _instance = _WebRTCService();
  factory WebRTCService() => _instance;
  _WebRTCService();

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // Stream controllers for UI updates
  final StreamController<MediaStream?> _localStreamController = StreamController<MediaStream?>.broadcast();
  final StreamController<MediaStream?> _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final StreamController<RTCIceConnectionState> _connectionStateController = StreamController<RTCIceConnectionState>.broadcast();
  
  // Call state
  bool _isInitialized = false;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  
  // Getters
  Stream<MediaStream?> get localStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStream => _remoteStreamController.stream;
  Stream<RTCIceConnectionState> get connectionState => _connectionStateController.stream;
  bool get isInitialized => _isInitialized;
  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;

  /// Initialize WebRTC service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('WebRTCService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WebRTCService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Request necessary permissions for audio/video
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
    ];
    
    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Permission ${permission.toString()} not granted');
      }
    }
  }

  /// Start a video call
  Future<void> startVideoCall({
    required String callId,
    required List<String> participantIds,
    bool enableVideo = true,
    bool enableAudio = true,
  }) async {
    if (!_isInitialized) {
      throw Exception('WebRTC service not initialized');
    }
    
    try {
      // Create peer connection
      await _createPeerConnection();
      
      // Get user media
      await _getUserMedia(enableVideo: enableVideo, enableAudio: enableAudio);
      
      _isInCall = true;
      _isVideoEnabled = enableVideo;
      
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('WebRTCService: Video call started - $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WebRTCService: Failed to start video call: $e');
      }
      rethrow;
    }
  }

  /// Start an audio-only call
  Future<void> startAudioCall({
    required String callId,
    required List<String> participantIds,
  }) async {
    await startVideoCall(
      callId: callId,
      participantIds: participantIds,
      enableVideo: false,
      enableAudio: true,
    );
  }

  /// Create peer connection
  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Add TURN servers for production
      ]
    };
    
    _peerConnection = await createPeerConnection(configuration);
    
    _peerConnection!.onIceConnectionState = (state) {
      _connectionStateController.add(state);
      if (kDebugMode) {
        debugPrint('WebRTC ICE Connection State: $state');
      }
    };
    
    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      _remoteStreamController.add(stream);
      if (kDebugMode) {
        debugPrint('WebRTC: Remote stream added');
      }
    };
    
    _peerConnection!.onRemoveStream = (stream) {
      _remoteStream = null;
      _remoteStreamController.add(null);
      if (kDebugMode) {
        debugPrint('WebRTC: Remote stream removed');
      }
    };
  }

  /// Get user media (camera/microphone)
  Future<void> _getUserMedia({
    required bool enableVideo,
    required bool enableAudio,
  }) async {
    final constraints = {
      'audio': enableAudio,
      'video': enableVideo ? {
        'width': 640,
        'height': 480,
        'frameRate': 30,
      } : false,
    };
    
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localStreamController.add(_localStream);
    
    if (_peerConnection != null && _localStream != null) {
      await _peerConnection!.addStream(_localStream!);
    }
    
    if (kDebugMode) {
      debugPrint('WebRTC: Local stream obtained');
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = _isMuted;
      }
      _isMuted = !_isMuted;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('WebRTC: Microphone ${_isMuted ? 'muted' : 'unmuted'}');
      }
    }
  }

  /// Toggle video
  Future<void> toggleVideo() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.enabled = _isVideoEnabled;
      }
      _isVideoEnabled = !_isVideoEnabled;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('WebRTC: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    // In production, implement actual speaker toggle
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('WebRTC: Speaker ${_isSpeakerOn ? 'on' : 'off'}');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        await Helper.switchCamera(track);
      }
      
      if (kDebugMode) {
        debugPrint('WebRTC: Camera switched');
      }
    }
  }

  /// End the call
  Future<void> endCall() async {
    try {
      // Stop local stream
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _localStream!.dispose();
        _localStream = null;
        _localStreamController.add(null);
      }
      
      // Close peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      
      // Reset remote stream
      _remoteStream = null;
      _remoteStreamController.add(null);
      
      // Reset state
      _isInCall = false;
      _isMuted = false;
      _isVideoEnabled = true;
      _isSpeakerOn = false;
      
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('WebRTC: Call ended');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WebRTC: Error ending call: $e');
      }
    }
  }

  /// Create offer for outgoing call
  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not initialized');
    }
    
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    if (kDebugMode) {
      debugPrint('WebRTC: Offer created');
    }
    
    return offer;
  }

  /// Create answer for incoming call
  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not initialized');
    }
    
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    
    if (kDebugMode) {
      debugPrint('WebRTC: Answer created');
    }
    
    return answer;
  }

  /// Set remote description
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not initialized');
    }
    
    await _peerConnection!.setRemoteDescription(description);
    
    if (kDebugMode) {
      debugPrint('WebRTC: Remote description set');
    }
  }

  /// Add ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not initialized');
    }
    
    await _peerConnection!.addCandidate(candidate);
    
    if (kDebugMode) {
      debugPrint('WebRTC: ICE candidate added');
    }
  }

  @override
  void dispose() {
    endCall();
    _localStreamController.close();
    _remoteStreamController.close();
    _connectionStateController.close();
    super.dispose();
  }
}
