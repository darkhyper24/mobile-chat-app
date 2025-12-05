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
          conversations.add(
            Conversation(
              participant: participant,
              lastMessage: entry.value,
              unreadCount: 0,
            ),
          );
        }
      }

      // Sort by last message time
      conversations.sort(
        (a, b) => (b.lastMessage.createdAt ?? DateTime.now()).compareTo(
          a.lastMessage.createdAt ?? DateTime.now(),
        ),
      );

      return conversations;
    } catch (e) {
      print('Error getting conversations: $e');
      rethrow;
    }
  }

  /// Get messages between two users (one-time fetch)
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
          .or(
            'and(sender_id.eq.$userId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$userId)',
          )
          .isFilter('group_id', null);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  /// Send a text message and return the created message
  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final response = await _db.client
          .from('massages')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'massage': text,
            'group_id': null,
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Send a location message and return the created message
  Future<Message?> sendLocationMessage({
    required String senderId,
    required String receiverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _db.client
          .from('massages')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'massage': '📍 Location shared',
            'latitude': latitude,
            'longitude': longitude,
            'group_id': null,
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('Error sending location message: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time messages for a specific conversation
  /// Following the Supabase Flutter tutorial pattern
  void subscribeToConversation({
    required String userId,
    required String partnerId,
    required Function(Message) onNewMessage,
  }) {
    // Create a unique channel name for this conversation
    final ids = [userId, partnerId]..sort();
    final channelName = 'chat-${ids.join('-')}-${DateTime.now().millisecondsSinceEpoch}';

    print('Subscribing to conversation channel: $channelName');

    // Unsubscribe from previous conversation channel if exists
    if (_conversationChannel != null) {
      print('Removing previous conversation channel');
      _db.client.removeChannel(_conversationChannel!);
      _conversationChannel = null;
    }

    _conversationChannel = _db.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'massages',
          callback: (payload) {
            print('=== REALTIME EVENT RECEIVED ===');
            print('Payload: ${payload.newRecord}');
            try {
              final newMessage = Message.fromJson(payload.newRecord);
              print('Parsed message - senderId: ${newMessage.senderId}, receiverId: ${newMessage.receiverId}');

              // Only process if this message is part of our conversation
              final isInConversation =
                  (newMessage.senderId == userId &&
                      newMessage.receiverId == partnerId) ||
                  (newMessage.senderId == partnerId &&
                      newMessage.receiverId == userId);

              print('Is in conversation: $isInConversation, groupId: ${newMessage.groupId}');

              if (isInConversation && newMessage.groupId == null) {
                print('Calling onNewMessage callback');
                onNewMessage(newMessage);
              }
            } catch (e) {
              print('Error processing realtime message: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('Conversation subscription status: $status');
          if (error != null) {
            print('Conversation subscription error: $error');
          }
        });
  }

  /// Subscribe to all new messages for a user (for home page updates)
  void subscribeToAllMessages({
    required String userId,
    required Function(Message) onNewMessage,
  }) {
    final channelName = 'all-messages-$userId-${DateTime.now().millisecondsSinceEpoch}';
    
    // Remove previous channel if exists
    if (_allMessagesChannel != null) {
      print('Removing previous all-messages channel');
      _db.client.removeChannel(_allMessagesChannel!);
      _allMessagesChannel = null;
    }

    _allMessagesChannel = _db.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'massages',
          callback: (payload) {
            print('=== ALL MESSAGES EVENT RECEIVED ===');
            try {
              final newMessage = Message.fromJson(payload.newRecord);

              // Only process if user is involved in this message
              final isUserInvolved =
                  newMessage.senderId == userId ||
                  newMessage.receiverId == userId;

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

  /// Unsubscribe from conversation channel
  void unsubscribeFromConversation() {
    if (_conversationChannel != null) {
      print('Unsubscribing from conversation channel');
      _db.client.removeChannel(_conversationChannel!);
      _conversationChannel = null;
    }
  }

  /// Unsubscribe from all messages channel
  void unsubscribeFromAllMessages() {
    if (_allMessagesChannel != null) {
      print('Unsubscribing from all messages channel');
      _db.client.removeChannel(_allMessagesChannel!);
      _allMessagesChannel = null;
    }
  }

  /// Unsubscribe from all real-time updates
  void unsubscribe() {
    unsubscribeFromConversation();
    unsubscribeFromAllMessages();
  }

  /// Clean up resources
  void dispose() {
    unsubscribe();
  }
}
