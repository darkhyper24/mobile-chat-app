import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db.dart';
import '../models/massages.dart';
import '../models/users.dart' as models;

/// Represents a conversation derived from messages
class Conversation {
  final models.User participant;
  final Message lastMessage;
  final int unreadCount;

  Conversation({
    required this.participant,
    required this.lastMessage,
    this.unreadCount = 0,
  });
}

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final _db = DatabaseService();
  
  // Realtime subscription channels
  RealtimeChannel? _conversationChannel;
  RealtimeChannel? _allMessagesChannel;
  
  // Stream controllers for real-time updates
  final _newMessageController = StreamController<Message>.broadcast();
  
  Stream<Message> get newMessageStream => _newMessageController.stream;

  /// Get all conversations for a user (derived from messages)
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      // Get all messages where user is sender or receiver (direct messages only)
      final messages = await _db.client
          .from('massages')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .isFilter('group_id', null)
          .order('created_at', ascending: false);

      if (messages.isEmpty) {
        return [];
      }

      // Group messages by conversation partner
      final Map<String, Message> latestMessages = {};
      final Set<String> participantIds = {};

      for (final msgJson in messages) {
        final message = Message.fromJson(msgJson);
        final partnerId = message.senderId == userId 
            ? message.receiverId 
            : message.senderId;
        
        if (partnerId != null && !latestMessages.containsKey(partnerId)) {
          latestMessages[partnerId] = message;
          participantIds.add(partnerId);
        }
      }

      if (participantIds.isEmpty) {
        return [];
      }

      // Get user data for all participants
      final usersResponse = await _db.client
          .from('users')
          .select()
          .inFilter('user_id', participantIds.toList());

      final usersMap = <String, models.User>{};
      for (final userJson in usersResponse) {
        final user = models.User.fromJson(userJson);
        usersMap[user.userId] = user;
      }

      // Build conversations list
      final conversations = <Conversation>[];
      for (final entry in latestMessages.entries) {
        final participant = usersMap[entry.key];
        if (participant != null) {
          conversations.add(Conversation(
            participant: participant,
            lastMessage: entry.value,
            unreadCount: 0,
          ));
        }
      }

      // Sort by last message time
      conversations.sort((a, b) => 
        (b.lastMessage.createdAt ?? DateTime.now())
          .compareTo(a.lastMessage.createdAt ?? DateTime.now()));

      return conversations;
    } catch (e) {
      print('Error getting conversations: $e');
      rethrow;
    }
  }

  /// Get messages between two users
  Future<List<Message>> getMessages({
    required String userId,
    required String partnerId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _db.client
          .from('massages')
          .select()
          .or('and(sender_id.eq.$userId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$userId)')
          .isFilter('group_id', null);
      
      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList()
          .reversed
          .toList(); // Reverse to get oldest first for display
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  /// Send a text message
  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final response = await _db.client.from('massages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': text,
      }).select().single();

      return Message.fromJson(response);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time messages for a specific conversation
  void subscribeToConversation({
    required String userId,
    required String partnerId,
    required Function(Message) onNewMessage,
  }) {
    // Unsubscribe from previous conversation channel if exists
    _conversationChannel?.unsubscribe();

    final channelName = 'chat:${_sortIds(userId, partnerId)}';
    
    _conversationChannel = _db.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'massages',
          callback: (payload) {
            try {
              final newMessage = Message.fromJson(payload.newRecord);
              
              // Only process if this message is part of our conversation
              final isInConversation = 
                  (newMessage.senderId == userId && newMessage.receiverId == partnerId) ||
                  (newMessage.senderId == partnerId && newMessage.receiverId == userId);
              
              if (isInConversation && newMessage.groupId == null) {
                onNewMessage(newMessage);
                _newMessageController.add(newMessage);
              }
            } catch (e) {
              print('Error processing realtime message: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('Conversation subscription status: $status');
          if (error != null) {
            print('Subscription error: $error');
          }
        });
  }

  /// Subscribe to all new messages for a user (for home page updates)
  void subscribeToAllMessages({
    required String userId,
    required Function(Message) onNewMessage,
  }) {
    // Unsubscribe from previous channel if exists
    _allMessagesChannel?.unsubscribe();

    _allMessagesChannel = _db.client
        .channel('all-messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'massages',
          callback: (payload) {
            try {
              final newMessage = Message.fromJson(payload.newRecord);
              
              // Only process if user is involved in this message
              final isUserInvolved = 
                  newMessage.senderId == userId || newMessage.receiverId == userId;
              
              if (isUserInvolved && newMessage.groupId == null) {
                onNewMessage(newMessage);
              }
            } catch (e) {
              print('Error processing realtime message: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('All messages subscription status: $status');
          if (error != null) {
            print('Subscription error: $error');
          }
        });
  }

  /// Helper to create consistent channel names
  String _sortIds(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return ids.join('-');
  }

  /// Unsubscribe from conversation channel
  void unsubscribeFromConversation() {
    _conversationChannel?.unsubscribe();
    _conversationChannel = null;
  }

  /// Unsubscribe from all messages channel
  void unsubscribeFromAllMessages() {
    _allMessagesChannel?.unsubscribe();
    _allMessagesChannel = null;
  }

  /// Unsubscribe from all real-time updates
  void unsubscribe() {
    unsubscribeFromConversation();
    unsubscribeFromAllMessages();
  }

  /// Clean up resources
  void dispose() {
    unsubscribe();
    _newMessageController.close();
  }
}
