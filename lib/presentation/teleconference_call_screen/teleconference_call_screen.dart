import '../../core/app_export.dart';

class TeleconferenceCallScreen extends StatefulWidget {
  final String callId;
  final List<String> participantIds;
  final bool isVideoCall;

  const TeleconferenceCallScreen({
    super.key,
    required this.callId,
    required this.participantIds,
    this.isVideoCall = true,
  });

  @override
  _TeleconferenceCallScreenState createState() => _TeleconferenceCallScreenState();
}

class _TeleconferenceCallScreenState extends State<TeleconferenceCallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  bool _isScreenSharing = false;
  bool _showParticipants = false;
  bool _showChat = false;
  bool _isRecording = false;
  bool _isCallActive = true;

  Duration _callDuration = Duration.zero;
  late DateTime _callStartTime;

  List<CallParticipant> _participants = [];
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _initializeAnimations();
    _loadParticipants();
    _startCallTimer();

    // Set system UI for full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _loadParticipants() {
    // Mock participants data
    _participants = [
      CallParticipant(
        id: '1',
        name: 'Dr. Emily Chen',
        role: 'Cardiologist',
        isVideoEnabled: true,
        isMuted: false,
        isHost: true,
      ),
      CallParticipant(
        id: '2',
        name: 'Dr. Robert Wilson',
        role: 'Primary Care',
        isVideoEnabled: true,
        isMuted: false,
        isHost: false,
      ),
      CallParticipant(
        id: '3',
        name: 'Sarah Johnson',
        role: 'Patient',
        isVideoEnabled: false,
        isMuted: true,
        isHost: false,
      ),
    ];
  }

  void _startCallTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isCallActive && mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime);
        });
        _startCallTimer();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chatController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video grid
          _buildVideoGrid(),

          // Top bar with call info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(theme),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(theme),
          ),

          // Side panels
          if (_showParticipants)
            Positioned(
              right: 0,
              top: 80,
              bottom: 120,
              child: _buildParticipantsPanel(theme),
            ),

          if (_showChat)
            Positioned(
              right: 0,
              top: 80,
              bottom: 120,
              child: _buildChatPanel(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    if (_participants.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.only(top: 80, bottom: 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _participants.length > 4 ? 3 : 2,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        return _buildVideoTile(participant);
      },
    );
  }

  Widget _buildVideoTile(CallParticipant participant) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Video feed or avatar
          if (participant.isVideoEnabled)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.purple.shade800,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'Video Feed',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade800,
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    participant.name.split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Participant info
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          participant.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          participant.role,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (participant.isMuted)
                    Icon(
                      Icons.mic_off,
                      color: Colors.red,
                      size: 16,
                    ),
                  if (participant.isHost)
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      height: 80,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Call duration
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  _formatDuration(_callDuration),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // Recording indicator
          if (_isRecording)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: !_isMuted,
            onTap: () {
              setState(() {
                _isMuted = !_isMuted;
              });
              HapticFeedback.lightImpact();
            },
          ),

          // Video button
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            isActive: _isVideoEnabled,
            onTap: () {
              setState(() {
                _isVideoEnabled = !_isVideoEnabled;
              });
              HapticFeedback.lightImpact();
            },
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            isActive: false,
            isEndCall: true,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool isEndCall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isEndCall
              ? Colors.red
              : isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildParticipantsPanel(ThemeData theme) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Participants (${_participants.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showParticipants = false;
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      participant.name.split(' ').map((n) => n[0]).join(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    participant.name,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    participant.role,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(ThemeData theme) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showChat = false;
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Call'),
        content: Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('End Call'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Data models
class CallParticipant {
  final String id;
  final String name;
  final String role;
  final bool isVideoEnabled;
  final bool isMuted;
  final bool isHost;

  CallParticipant({
    required this.id,
    required this.name,
    required this.role,
    required this.isVideoEnabled,
    required this.isMuted,
    required this.isHost,
  });
}

class ChatMessage {
  final String senderName;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.senderName,
    required this.content,
    required this.timestamp,
  });
}
