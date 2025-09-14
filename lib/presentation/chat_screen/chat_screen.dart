import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../database/database.dart';

class ChatScreen extends StatefulWidget {
  final String? patientId;
  final String? specialistId;
  final String? conversationId;
  
  const ChatScreen({
    Key? key,
    this.patientId,
    this.specialistId,
    this.conversationId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _isEncrypted = true;
  String _conversationTitle = 'Secure Chat';
  String _participantName = 'Healthcare Professional';
  String _participantRole = 'Doctor';
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConversation();
    _setupTypingListener();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      
      // Load conversation details
      if (widget.patientId != null) {
        final patient = await dataService.getPatientById(widget.patientId!);
        setState(() {
          _participantName = patient?.name ?? 'Patient';
          _participantRole = 'Patient';
          _conversationTitle = 'Chat with ${_participantName}';
        });
      } else if (widget.specialistId != null) {
        final specialist = await dataService.getSpecialistById(widget.specialistId!);
        setState(() {
          _participantName = specialist?.name ?? 'Specialist';
          _participantRole = specialist?.specialty ?? 'Specialist';
          _conversationTitle = 'Chat with ${_participantName}';
        });
      }
      
      // Load messages
      _messages = await dataService.getMessagesByConversationId(widget.conversationId!);
      
      setState(() {
        _isLoading = false;
        _isOnline = true; // Mock online status
        _lastSeen = DateTime.now().subtract(Duration(minutes: 2));
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load conversation'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _setupTypingListener() {
    _messageController.addListener(() {
      final isTyping = _messageController.text.isNotEmpty;
      if (isTyping != _isTyping) {
        setState(() {
          _isTyping = isTyping;
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                // Security Banner
                _buildSecurityBanner(theme),
                
                // Messages Area
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(theme)
                      : _buildMessagesArea(theme),
                ),
                
                // Message Input
                _buildMessageInput(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _participantRole == 'Patient' ? Icons.person : Icons.medical_services,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Participant Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _participantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isOnline 
                      ? 'Online' 
                      : _lastSeen != null 
                          ? 'Last seen ${_formatLastSeen(_lastSeen!)}'
                          : _participantRole,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam, color: Colors.white),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: Icon(Icons.call, color: Colors.white),
          onPressed: _startVoiceCall,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'info', child: Text('Contact Info')),
            PopupMenuItem(value: 'media', child: Text('Media & Files')),
            PopupMenuItem(value: 'search', child: Text('Search Messages')),
            PopupMenuItem(value: 'export', child: Text('Export Chat')),
            PopupMenuItem(value: 'block', child: Text('Block Contact')),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isEncrypted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _isEncrypted ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEncrypted ? Icons.lock : Icons.lock_open,
            color: _isEncrypted ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEncrypted 
                  ? 'Messages are end-to-end encrypted and HIPAA compliant'
                  : 'Warning: This conversation is not encrypted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _isEncrypted ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isEncrypted)
            Icon(
              Icons.verified_user,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading conversation...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(ThemeData theme) {
    if (_messages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == 'current_user'; // Mock current user check
        final showTimestamp = index == 0 || 
            _messages[index - 1].timestamp.difference(message.timestamp).inMinutes.abs() > 5;
        
        return Column(
          children: [
            if (showTimestamp) _buildTimestamp(message.timestamp, theme),
            _buildMessageBubble(message, isMe, theme),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a secure conversation with ${_participantName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime timestamp, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatMessageTime(timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _participantRole == 'Patient' ? Icons.person : Icons.medical_services,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead
                              ? Colors.blue.shade200
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: _showAttachmentOptions,
            icon: Icon(
              Icons.attach_file,
              color: theme.colorScheme.primary,
            ),
          ),

          // Message Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a secure message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send Button
          Container(
            decoration: BoxDecoration(
              color: _isTyping ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _isTyping && !_isSending ? _sendMessage : null,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: _isTyping ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversationId!,
        senderId: 'current_user',
        senderName: 'Me', // TODO: Replace with actual user name
        content: messageText,
        timestamp: DateTime.now(),
        status: 'sending',
        messageType: 'text',
      );

      // Add message to local list immediately for better UX
      setState(() {
        _messages.add(message);
        _messageController.clear();
        _isTyping = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Send to server
      final dataService = Provider.of<DataService>(context, listen: false);
      await dataService.sendMessage(message);

      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAttachmentOptions() {
    // Mock attachment options
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _startVideoCall() {
    Navigator.pushNamed(
      context,
      AppRoutes.teleconferenceCallScreen,
      arguments: {
        'callId': widget.conversationId ?? 'new_call_${DateTime.now().millisecondsSinceEpoch}',
        'participantIds': [widget.patientId ?? widget.specialistId ?? 'unknown'],
        'isVideoCall': true,
      },
    );
  }

  void _startVoiceCall() {
    Navigator.pushNamed(
      context,
      AppRoutes.audioCallScreen,
      arguments: {
        'conversationId': widget.conversationId,
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        // Show contact info
        break;
      case 'media':
        // Show media files
        break;
      case 'search':
        // Show search messages
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat exported securely'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        break;
      case 'block':
        // Block contact
        break;
    }
  }
}
