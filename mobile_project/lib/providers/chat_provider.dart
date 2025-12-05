import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/location_service.dart';
import '../models/massages.dart';
import '../models/users.dart' as models;

/// Result of attempting to send a location
enum LocationSendResultType {
  success,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  error,
}

class LocationSendResult {
  final LocationSendResultType type;
  final String? errorMessage;

  LocationSendResult._(this.type, [this.errorMessage]);

  factory LocationSendResult.success() => LocationSendResult._(LocationSendResultType.success);
  factory LocationSendResult.serviceDisabled() => LocationSendResult._(LocationSendResultType.serviceDisabled);
  factory LocationSendResult.permissionDenied() => LocationSendResult._(LocationSendResultType.permissionDenied);
  factory LocationSendResult.permissionPermanentlyDenied() => LocationSendResult._(LocationSendResultType.permissionPermanentlyDenied);
  factory LocationSendResult.error(String message) => LocationSendResult._(LocationSendResultType.error, message);

  bool get isSuccess => type == LocationSendResultType.success;
}

class ChatProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  final LocationService _locationService = LocationService();

  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];
  models.User? _currentChatPartner;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isGettingLocation = false;
  String? _errorMessage;
  String? _currentUserId;

  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  models.User? get currentChatPartner => _currentChatPartner;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isGettingLocation => _isGettingLocation;
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
  /// Following the Supabase Flutter tutorial pattern:
  /// 1. Load initial messages
  /// 2. Subscribe to real-time updates
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
      // 1. Load initial messages
      _currentMessages = await _messageService.getMessages(
        userId: userId,
        partnerId: partner.userId,
      );
      
      _isLoading = false;
      notifyListeners();

      // 2. Subscribe to real-time messages for this conversation
      _messageService.subscribeToConversation(
        userId: userId,
        partnerId: partner.userId,
        onNewMessage: (message) {
          _handleNewMessage(message);
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle incoming real-time message
  void _handleNewMessage(Message message) {
    print('Handling new message: ${message.messageId}');
    
    // Check if message already exists (to avoid duplicates)
    final exists = _currentMessages.any((m) => m.messageId == message.messageId);
    
    if (!exists) {
      // Create a new list with the new message appended
      _currentMessages = List<Message>.from(_currentMessages)..add(message);
      notifyListeners();
      print('Message added to list. Total messages: ${_currentMessages.length}');
    } else {
      print('Message already exists, skipping');
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
      // Send message and get the response
      final message = await _messageService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        text: text.trim(),
      );

      if (message != null) {
        // Add message to list immediately for responsive UI
        // Real-time subscription might also add it, so we check for duplicates
        final exists = _currentMessages.any((m) => m.messageId == message.messageId);
        if (!exists) {
          _currentMessages = List<Message>.from(_currentMessages)..add(message);
        }
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Send a location message
  /// Returns a result indicating success, failure reason, or if settings need to be opened
  Future<LocationSendResult> sendLocation({
    required String senderId,
    required String receiverId,
  }) async {
    _isGettingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current location (this handles permission requests internally)
      final locationResult = await _locationService.getCurrentLocation();

      _isGettingLocation = false;
      _isSending = true;
      notifyListeners();

      // Send the location message
      final message = await _messageService.sendLocationMessage(
        senderId: senderId,
        receiverId: receiverId,
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
      );

      if (message != null) {
        // Add message to list immediately for responsive UI
        final exists = _currentMessages.any((m) => m.messageId == message.messageId);
        if (!exists) {
          _currentMessages = List<Message>.from(_currentMessages)..add(message);
        }
      }

      _isSending = false;
      notifyListeners();
      return LocationSendResult.success();
    } on LocationServiceDisabledException {
      _isGettingLocation = false;
      _isSending = false;
      notifyListeners();
      return LocationSendResult.serviceDisabled();
    } on LocationPermissionDeniedException {
      _isGettingLocation = false;
      _isSending = false;
      notifyListeners();
      return LocationSendResult.permissionDenied();
    } on LocationPermissionPermanentlyDeniedException {
      _isGettingLocation = false;
      _isSending = false;
      notifyListeners();
      return LocationSendResult.permissionPermanentlyDenied();
    } catch (e) {
      _errorMessage = e.toString();
      _isGettingLocation = false;
      _isSending = false;
      notifyListeners();
      return LocationSendResult.error(e.toString());
    }
  }

  /// Open location in Google Maps
  Future<bool> openLocationInMaps(double latitude, double longitude) async {
    return await _locationService.openInGoogleMaps(latitude, longitude);
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await _locationService.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await _locationService.openAppSettings();
  }

  /// Load more messages (pagination) - for loading older messages
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
    // Unsubscribe from conversation real-time updates
    _messageService.unsubscribeFromConversation();
    
    _currentChatPartner = null;
    _currentMessages = [];
    
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
