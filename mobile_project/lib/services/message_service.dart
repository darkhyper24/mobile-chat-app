import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db.dart';
import '../models/messages.dart';
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

  // Realtime subscription channels for broadcast messaging
  RealtimeChannel? _dmChannel;
  RealtimeChannel? _allMessagesChannel;

  // Stream controllers for real-time updates
  final _newMessageController = StreamController<Message>.broadcast();

  Stream<Message> get newMessageStream => _newMessageController.stream;

  /// Helper: build DM topic (pair-topic) with lexicographically smaller id first
  String _dmTopic(String a, String b) {
    return a.compareTo(b) < 0 ? 'dm:$a-$b' : 'dm:$b-$a';
  }

  /// Get all conversations for a user (derived from messages)
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      // Get all messages where user is sender or receiver (direct messages only)
      final messages = await _db.client
          .from('messages')
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

  /// Get messages between two users
  Future<List<Message>> getMessages({
    required String userId,
    required String partnerId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _db.client
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$userId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$userId)',
          )
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

  /// Send a text message (inserts to DB and broadcasts via channel)
  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      // Insert message to database first (canonical storage)
      final response = await _db.client
          .from('messages')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'message': text,
            'group_id': null, // Explicitly set to null for direct messages
          })
          .select()
          .single();

      final message = Message.fromJson(response);

      // Broadcast the message via the DM channel if subscribed
      if (_dmChannel != null) {
        _broadcastMessage(channel: _dmChannel!, message: message);
      }

      return message;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Broadcast a message via channel.send (WebSocket broadcast)
  void _broadcastMessage({
    required RealtimeChannel channel,
    required Message message,
  }) {
    channel.sendBroadcastMessage(
      event: 'message_created',
      payload: {
        'message_id': message.messageId,
        'message': message.message,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'group_id': message.groupId,
        'image': message.image,
        'created_at': message.createdAt?.toIso8601String(),
      },
    );
  }

  /// Subscribe to real-time messages for a specific DM conversation using broadcast
  RealtimeChannel subscribeToDmChannel({
    required String userId,
    required String partnerId,
    required Function(Message) onNewMessage,
  }) {
    // Unsubscribe from previous DM channel if exists
    _unsubscribeDmChannel();

    final topic = _dmTopic(userId, partnerId);
    final channel = _db.client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'message_created',
      callback: (payload) {
        try {
          final newMessage = Message.fromJson(payload);

          // Only process if this message is part of our conversation
          final isInConversation =
              (newMessage.senderId == userId &&
                  newMessage.receiverId == partnerId) ||
              (newMessage.senderId == partnerId &&
                  newMessage.receiverId == userId);

          if (isInConversation && newMessage.groupId == null) {
            onNewMessage(newMessage);
            _newMessageController.add(newMessage);
          }
        } catch (e) {
          print('Error processing realtime DM message: $e');
        }
      },
    );

    channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('Subscribed to DM channel: $topic');
      } else {
        print('DM channel status: $status ${error ?? ''}');
      }
    });

    _dmChannel = channel;
    return channel;
  }

  /// Subscribe to all new messages for a user (for home page updates) using broadcast
  RealtimeChannel subscribeToAllDmMessages({
    required String userId,
    required Function(Message) onNewMessage,
  }) {
    // Unsubscribe from previous channel if exists
    _unsubscribeAllMessagesChannel();

    final topic = 'user:$userId:dm_updates';
    final channel = _db.client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'message_created',
      callback: (payload) {
        try {
          final newMessage = Message.fromJson(payload);

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
    );

    channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('Subscribed to all DM updates: $topic');
      } else {
        print('All messages channel status: $status ${error ?? ''}');
      }
    });

    _allMessagesChannel = channel;
    return channel;
  }

  /// Unsubscribe from DM channel
  void _unsubscribeDmChannel() {
    if (_dmChannel != null) {
      _db.client.removeChannel(_dmChannel!);
      _dmChannel = null;
    }
  }

  /// Unsubscribe from all messages channel
  void _unsubscribeAllMessagesChannel() {
    if (_allMessagesChannel != null) {
      _db.client.removeChannel(_allMessagesChannel!);
      _allMessagesChannel = null;
    }
  }

  /// Unsubscribe from conversation channel (public API)
  void unsubscribeFromConversation() {
    _unsubscribeDmChannel();
  }

  /// Unsubscribe from all messages channel (public API)
  void unsubscribeFromAllMessages() {
    _unsubscribeAllMessagesChannel();
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

  /// Get the current DM channel (for sending messages after subscription)
  RealtimeChannel? get dmChannel => _dmChannel;
}
