import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../models/massages.dart';
import '../models/users.dart' as models;

class ChatProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];
  models.User? _currentChatPartner;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  
  // Callback for new messages (for scroll handling in UI)
  Function(Message)? onNewMessageReceived;

  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  models.User? get currentChatPartner => _currentChatPartner;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  /// Load all conversations for the home page
  Future<void> loadConversations(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    
    // Use post-frame callback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _conversations = await _messageService.getConversations(userId);
      
      // Subscribe to real-time updates for home page
      _messageService.subscribeToAllMessages(
        userId: userId,
        onNewMessage: (message) {
          // Refresh conversations when new message arrives
          _refreshConversations(userId);
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh conversations without showing loading state
  Future<void> _refreshConversations(String userId) async {
    try {
      _conversations = await _messageService.getConversations(userId);
      notifyListeners();
    } catch (e) {
      print('Error refreshing conversations: $e');
    }
  }

  /// Open a chat with a specific user
  Future<void> openChat({
    required String userId,
    required models.User partner,
  }) async {
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    _currentChatPartner = partner;
    _currentMessages = [];
    notifyListeners();

    try {
      // Load initial messages
      _currentMessages = await _messageService.getMessages(
        userId: userId,
        partnerId: partner.userId,
      );
      
      _isLoading = false;
      notifyListeners();

      // Subscribe to real-time messages for this conversation
      _messageService.subscribeToConversation(
        userId: userId,
        partnerId: partner.userId,
        onNewMessage: (message) {
          _handleNewMessage(message, userId);
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle incoming real-time message
  void _handleNewMessage(Message message, String userId) {
    // Check if message already exists (might have been added when sent)
    final exists = _currentMessages.any((m) => m.messageId == message.messageId);
    
    if (!exists) {
      _currentMessages = [..._currentMessages, message];
      notifyListeners();
      
      // Notify UI about new message (for scroll handling)
      onNewMessageReceived?.call(message);
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _messageService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        text: text.trim(),
      );

      if (message != null) {
        // Add message to current list immediately for responsiveness
        // The realtime subscription will handle deduplication
        if (!_currentMessages.any((m) => m.messageId == message.messageId)) {
          _currentMessages = [..._currentMessages, message];
        }
        _isSending = false;
        notifyListeners();
        return true;
      }

      _isSending = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages({
    required String userId,
    required String partnerId,
  }) async {
    if (_currentMessages.isEmpty || _isLoading) return;

    try {
      final oldestMessage = _currentMessages.first;
      final moreMessages = await _messageService.getMessages(
        userId: userId,
        partnerId: partnerId,
        limit: 50,
        before: oldestMessage.createdAt,
      );

      if (moreMessages.isNotEmpty) {
        // Filter out duplicates and prepend older messages
        final existingIds = _currentMessages.map((m) => m.messageId).toSet();
        final newMessages = moreMessages
            .where((m) => !existingIds.contains(m.messageId))
            .toList();
        
        if (newMessages.isNotEmpty) {
          _currentMessages = [...newMessages, ..._currentMessages];
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Close the current chat
  void closeChat() {
    _currentChatPartner = null;
    _currentMessages = [];
    onNewMessageReceived = null;
    _messageService.unsubscribeFromConversation();
    
    // Only notify if we're not disposing
    if (_currentUserId != null) {
      // Re-subscribe to all messages for home page if we have a user ID
      _messageService.subscribeToAllMessages(
        userId: _currentUserId!,
        onNewMessage: (message) {
          _refreshConversations(_currentUserId!);
        },
      );
      
      // Use post-frame callback to safely notify listeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Filter conversations by search query
  List<Conversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;
    
    final lowerQuery = query.toLowerCase();
    return _conversations.where((conv) {
      final name = '${conv.participant.firstname ?? ''} ${conv.participant.lastname ?? ''}'.toLowerCase();
      final username = (conv.participant.username ?? '').toLowerCase();
      return name.contains(lowerQuery) || username.contains(lowerQuery);
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageService.unsubscribe();
    super.dispose();
  }
}
