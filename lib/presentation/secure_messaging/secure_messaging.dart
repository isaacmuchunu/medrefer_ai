import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../core/app_export.dart';
import './widgets/conversation_header_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/quick_reply_widget.dart';
import './widgets/referral_context_card_widget.dart';

class SecureMessaging extends StatefulWidget {
  const SecureMessaging({Key? key}) : super(key: key);

  @override
  State<SecureMessaging> createState() => _SecureMessagingState();
}

class _SecureMessagingState extends State<SecureMessaging> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _showQuickReplies = false;
  Map<String, dynamic>? _selectedMessage;

  // Mock data for conversation
  final Map<String, dynamic> _participant = {
    'id': '2',
    'name': 'Dr. Sarah Chen',
    'specialty': 'Cardiology',
    'avatar':
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face',
    'status': 'online',
    'hospital': 'Metropolitan Heart Center',
  };

  final Map<String, dynamic>? _referralContext = {
    'id': 'REF-2024-001',
    'title': 'Cardiac Consultation - John Smith',
    'patientName': 'John Smith',
    'specialty': 'Cardiology',
    'status': 'pending',
    'urgency': 'high',
    'createdDate': '2024-08-29',
  };

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  /// Encrypt message content for secure storage
  String _encryptMessage(String content) {
    // In production, use proper encryption like AES
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return base64.encode(utf8.encode(content)); // Simplified for demo
  }

  /// Decrypt message content for display
  String _decryptMessage(String encryptedContent) {
    // In production, use proper decryption
    try {
      return utf8.decode(base64.decode(encryptedContent));
    } catch (e) {
      return encryptedContent; // Return as-is if not encrypted
    }
  }

  /// Log message activity for audit trail
  Future<void> _logMessageActivity(String action, String messageId, {Map<String, dynamic>? metadata}) async {
    final auditLog = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': 'current_user_id', // Get from auth service
      'action': action, // 'sent', 'received', 'read', 'deleted'
      'messageId': messageId,
      'conversationId': _participant['id'],
      'metadata': metadata ?? {},
    };

    // In production, save to secure audit log database
    if (kDebugMode) {
      debugPrint('Audit Log: $auditLog');
    }
  }

  Future<void> _loadMessages() async {
    // Assuming DataService has a method to fetch messages for this conversation
    // Replace 'conversationId' with actual conversation ID
    final messages = await DataService.instance.messageDAO.getMessagesForConversation('conversationId');
    setState(() {
      _messages.addAll(messages.map((msg) => msg.toMap()));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          ConversationHeaderWidget(
            participant: _participant,
            onProfileTap: () => _showParticipantProfile(),
          ),
          if (_referralContext != null)
            ReferralContextCardWidget(
              referralData: _referralContext,
              onTap: () => _viewReferralDetails(),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['senderId'] == '1';

                return Slidable(
                  key: ValueKey(message['id']),
                  startActionPane: !isCurrentUser
                      ? ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => _replyToMessage(message),
                              backgroundColor:
                                  AppTheme.lightTheme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              icon: Icons.reply,
                              label: 'Reply',
                            ),
                          ],
                        )
                      : null,
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _flagMessage(message),
                        backgroundColor: AppTheme.warningLight,
                        foregroundColor: Colors.white,
                        icon: Icons.flag,
                        label: 'Flag',
                      ),
                      if (isCurrentUser)
                        SlidableAction(
                          onPressed: (context) => _deleteMessage(message),
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.error,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                    ],
                  ),
                  child: GestureDetector(
                    onLongPress: () => _selectMessage(message),
                    child: MessageBubbleWidget(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showQuickReplies)
            QuickReplyWidget(
              onReplySelected: _sendQuickReply,
            ),
          MessageInputWidget(
            onSendMessage: _sendTextMessage,
            onSendAttachments: _sendAttachments,
            onSendVoiceNote: _sendVoiceNote,
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendTextMessage(String content) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final encryptedContent = _encryptMessage(content);

    final newMessage = {
      'id': messageId,
      'senderId': '1',
      'senderName': 'Dr. Michael Johnson',
      'senderAvatar':
          'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face',
      'content': encryptedContent,
      'originalContent': content, // For display purposes
      'timestamp': DateTime.now(),
      'status': 'sending',
      'type': 'text',
      'isEncrypted': true,
    };

    // Log message sending for audit trail
    await _logMessageActivity('sent', messageId, metadata: {
      'contentLength': content.length,
      'recipientId': _participant['id'],
      'messageType': 'text',
    });

    setState(() {
      _messages.add(newMessage);
      _showQuickReplies = false;
    });

    _scrollToBottom();

    // Simulate message delivery
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == newMessage['id']);
        if (index != -1) {
          _messages[index]['status'] = 'delivered';
        }
      });
    });

    // Show quick replies after sending
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _showQuickReplies = true;
      });
    });
  }

  void _sendQuickReply(String reply) {
    _sendTextMessage(reply);
  }

  void _sendAttachments(List<Map<String, dynamic>> attachments) {
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': '1',
      'senderName': 'Dr. Michael Johnson',
      'senderAvatar':
          'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face',
      'content': attachments.length == 1
          ? 'Sent ${attachments.first['name']}'
          : 'Sent ${attachments.length} files',
      'timestamp': DateTime.now(),
      'status': 'sending',
      'type': 'text',
      'attachments': attachments,
    };

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simulate message delivery
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == newMessage['id']);
        if (index != -1) {
          _messages[index]['status'] = 'delivered';
        }
      });
    });
  }

  void _sendVoiceNote(String audioPath) {
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': '1',
      'senderName': 'Dr. Michael Johnson',
      'senderAvatar':
          'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face',
      'content': 'Voice message',
      'timestamp': DateTime.now(),
      'status': 'sending',
      'type': 'voice',
      'audioPath': audioPath,
    };

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simulate message delivery
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == newMessage['id']);
        if (index != -1) {
          _messages[index]['status'] = 'delivered';
        }
      });
    });
  }

  void _replyToMessage(Map<String, dynamic> message) {
    setState(() {
      _showQuickReplies = true;
    });

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replying to: ${message['senderName']}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _flagMessage(Map<String, dynamic> message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message flagged for review'),
        backgroundColor: AppTheme.warningLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.removeWhere((m) => m['id'] == message['id']);
              });
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _selectMessage(Map<String, dynamic> message) {
    setState(() {
      _selectedMessage = message;
    });

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'reply',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'content_copy',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
                title: const Text('Copy Text'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message['content']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'forward',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Forward feature requires patient consent'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'flag',
                  color: AppTheme.warningLight,
                  size: 24,
                ),
                title: const Text('Flag Important'),
                onTap: () {
                  Navigator.pop(context);
                  _flagMessage(message);
                },
              ),
              if (message['senderId'] == '1')
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'delete',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 24,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showParticipantProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 8.h,
                      backgroundImage: NetworkImage(_participant['avatar']),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _participant['name'],
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _participant['specialty'],
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _participant['hospital'],
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildProfileAction('call', 'Call',
                            AppTheme.lightTheme.colorScheme.primary),
                        _buildProfileAction('videocam', 'Video',
                            AppTheme.lightTheme.colorScheme.secondary),
                        _buildProfileAction('person', 'Profile',
                            AppTheme.lightTheme.colorScheme.tertiary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAction(String iconName, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.w),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 28,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _viewReferralDetails() {
    Navigator.pushNamed(context, '/referral-tracking');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
