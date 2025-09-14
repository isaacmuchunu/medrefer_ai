import '../database_helper.dart';
import '../models/models.dart';

class MessageDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'messages';

  // Create
  Future<String> createMessage(Message message) async {
    try {
      return await _dbHelper.insert(tableName, message.toMap());
    } catch (e) {
      throw Exception('Failed to create message: $e');
    }
  }

  // Read
  Future<List<Message>> getAllMessages() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'timestamp DESC');
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<Message?> getMessageById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? Message.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get message: $e');
    }
  }

  Future<List<Message>> getMessagesByConversationId(String conversationId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'timestamp ASC',
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get messages by conversation: $e');
    }
  }

  Future<List<Message>> getMessagesBySenderId(String senderId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'sender_id = ?',
        whereArgs: [senderId],
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get messages by sender: $e');
    }
  }

  Future<List<Message>> getMessagesByReferralId(String referralId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'referral_id = ?',
        whereArgs: [referralId],
        orderBy: 'timestamp ASC',
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get messages by referral: $e');
    }
  }

  Future<List<Message>> getMessagesByType(String messageType) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'message_type = ?',
        whereArgs: [messageType],
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get messages by type: $e');
    }
  }

  Future<List<Message>> searchMessages(String searchTerm) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'content LIKE ? OR sender_name LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  Future<List<Message>> getRecentMessages(int limit) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get recent messages: $e');
    }
  }

  Future<List<Message>> getUnreadMessages(String userId) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'status != ? AND sender_id != ?',
        whereArgs: ['read', userId],
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get unread messages: $e');
    }
  }

  // Update
  Future<bool> updateMessage(Message message) async {
    try {
      message.updateTimestamp();
      final rowsAffected = await _dbHelper.update(tableName, message.toMap(), message.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  Future<bool> updateMessageStatus(String id, String status) async {
    try {
      final rowsAffected = await _dbHelper.update(
        tableName,
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        id,
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  Future<bool> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.update(
        tableName,
        {
          'status': 'read',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'conversation_id = ? AND sender_id != ? AND status != ?',
        whereArgs: [conversationId, userId, 'read'],
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Delete
  Future<bool> deleteMessage(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.delete(
        tableName,
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Statistics
  Future<int> getTotalMessagesCount() async {
    try {
      return await _dbHelper.getTableCount(tableName);
    } catch (e) {
      throw Exception('Failed to get messages count: $e');
    }
  }

  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM $tableName 
        WHERE status != ? AND sender_id != ?
      ''', ['read', userId]);
      
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread messages count: $e');
    }
  }

  Future<Map<String, int>> getMessagesByTypeCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT message_type, COUNT(*) as count 
        FROM $tableName 
        GROUP BY message_type
      ''');
      
      Map<String, int> typeCounts = {};
      for (var row in result) {
        typeCounts[row['message_type'] as String] = row['count'] as int;
      }
      return typeCounts;
    } catch (e) {
      throw Exception('Failed to get message type statistics: $e');
    }
  }

  Future<List<String>> getUniqueConversationIds() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT conversation_id 
        FROM $tableName 
        ORDER BY MAX(timestamp) DESC
      ''');
      
      return result.map((row) => row['conversation_id'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get conversation IDs: $e');
    }
  }
}
