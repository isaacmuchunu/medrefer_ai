import 'dart:convert';
import 'base_model.dart';

class Message extends BaseModel {
  String conversationId;
  String senderId;
  String senderName;
  String? senderAvatar;
  String content;
  String messageType;
  List<Map<String, dynamic>> attachments;
  String? referralId;
  DateTime timestamp;
  String status;

  Message({
    super.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.messageType = 'text',
    this.attachments = const [],
    this.referralId,
    DateTime? timestamp,
    this.status = 'sent',
    super.createdAt,
    super.updatedAt,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Message.fromMap(Map<String, dynamic> map) {
    var attachmentsList = <Map<String, dynamic>>[];
    if (map['attachments'] != null && map['attachments'].isNotEmpty) {
      try {
        final decoded = jsonDecode(map['attachments']);
        if (decoded is List) {
          attachmentsList = decoded.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        // Handle parsing error gracefully
        attachmentsList = [];
      }
    }

    return Message(
      id: map['id'],
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? '',
      senderAvatar: map['sender_avatar'],
      content: map['content'] ?? '',
      messageType: map['message_type'] ?? 'text',
      attachments: attachmentsList,
      referralId: map['referral_id'],
      timestamp: BaseModel.parseDateTime(map['timestamp']),
      status: map['status'] ?? 'sent',
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'message_type': messageType,
      'attachments': attachments.isNotEmpty ? jsonEncode(attachments) : null,
      'referral_id': referralId,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    });
    return map;
  }

  Message copyWith({
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? messageType,
    List<Map<String, dynamic>>? attachments,
    String? referralId,
    DateTime? timestamp,
    String? status,
  }) {
    return Message(
      id: id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachments: attachments ?? this.attachments,
      referralId: referralId ?? this.referralId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for message types
  bool get isTextMessage => messageType == 'text';
  bool get isVoiceMessage => messageType == 'voice';
  bool get isAttachmentMessage => messageType == 'attachment';
  bool get isReferralContext => messageType == 'referral_context';

  // Helper methods for status
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';
  bool get isSending => status == 'sending';

  @override
  String toString() {
    return 'Message{id: $id, senderId: $senderId, type: $messageType, status: $status}';
  }
}
