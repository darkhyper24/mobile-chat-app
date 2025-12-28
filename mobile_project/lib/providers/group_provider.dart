import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/group_service.dart';
import '../models/group.dart';
import '../models/group_members.dart';
import '../models/messages.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<GroupConversation> _groupConversations = [];
  List<GroupMember> _currentGroupMembers = [];
  List<Message> _currentGroupMessages = [];
  Group? _currentGroup;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  bool _isCurrentUserAdmin = false;

  // Current group channel for real-time messaging
  RealtimeChannel? _currentGroupChannel;

  // Callback for new messages (for scroll handling in UI)
  Function(Message)? onNewMessageReceived;

  // Getters
  List<GroupConversation> get groupConversations => _groupConversations;
  List<GroupMember> get currentGroupMembers => _currentGroupMembers;
  List<Message> get currentGroupMessages => _currentGroupMessages;
  Group? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get isCurrentUserAdmin => _isCurrentUserAdmin;

  /// Load all group conversations for a user
  Future<void> loadGroupConversations(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _groupConversations = await _groupService.getUserGroups(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh group conversations without loading state
  Future<void> refreshGroupConversations() async {
    if (_currentUserId == null) return;
    try {
      _groupConversations = await _groupService.getUserGroups(_currentUserId!);
      notifyListeners();
    } catch (e) {
      print('Error refreshing group conversations: $e');
    }
  }

  /// Create a new group
  Future<Group?> createGroup({
    required String name,
    required String creatorId,
    String? description,
    String? image,
    List<String>? initialMemberIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final group = await _groupService.createGroup(
        name: name,
        creatorId: creatorId,
        description: description,
        image: image,
      );

      if (group != null && initialMemberIds != null) {
        // Add initial members
        for (final memberId in initialMemberIds) {
          if (memberId != creatorId) {
            try {
              await _groupService.addMember(
                groupId: group.groupId,
                userId: memberId,
              );
            } catch (e) {
              print('Error adding initial member $memberId: $e');
            }
          }
        }
      }

      // Refresh conversations
      await refreshGroupConversations();

      _isLoading = false;
      notifyListeners();
      return group;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Open a group chat
  Future<void> openGroupChat({
    required String userId,
    required Group group,
  }) async {
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    _currentGroup = group;
    _currentGroupMessages = [];
    _currentGroupMembers = [];
    // Don't call notifyListeners() here - wait until after async operations

    try {
      // Load messages and members in parallel
      final results = await Future.wait([
        _groupService.getGroupMessages(groupId: group.groupId),
        _groupService.getGroupMembers(group.groupId),
        _groupService.isUserAdmin(groupId: group.groupId, userId: userId),
      ]);

      _currentGroupMessages = results[0] as List<Message>;
      _currentGroupMembers = results[1] as List<GroupMember>;
      _isCurrentUserAdmin = results[2] as bool;

      _isLoading = false;
      notifyListeners();

      // Subscribe to real-time updates using Postgres changes
      _currentGroupChannel = _groupService.subscribeToGroupMessages(
        groupId: group.groupId,
        onNewMessage: (message) {
          _handleNewMessage(message);
        },
      );

      _groupService.subscribeToGroupMembers(
        groupId: group.groupId,
        onMemberChange: (event, member) {
          _handleMemberChange(event, member);
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
    final exists = _currentGroupMessages.any(
      (m) => m.messageId == message.messageId,
    );

    if (!exists) {
      _currentGroupMessages = [..._currentGroupMessages, message];
      notifyListeners();
      onNewMessageReceived?.call(message);
    }
  }

  /// Handle member changes
  void _handleMemberChange(String event, GroupMember? member) async {
    // Refresh members list
    if (_currentGroup != null) {
      try {
        _currentGroupMembers = await _groupService.getGroupMembers(
          _currentGroup!.groupId,
        );
        notifyListeners();
      } catch (e) {
        print('Error refreshing members: $e');
      }
    }
  }

  /// Send a message to the current group
  Future<bool> sendMessage({
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty || _currentGroup == null) return false;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _groupService.sendGroupMessage(
        senderId: senderId,
        groupId: _currentGroup!.groupId,
        text: text.trim(),
      );

      if (message != null) {
        if (!_currentGroupMessages.any(
          (m) => m.messageId == message.messageId,
        )) {
          _currentGroupMessages = [..._currentGroupMessages, message];
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
  Future<void> loadMoreMessages() async {
    if (_currentGroupMessages.isEmpty || _isLoading || _currentGroup == null)
      return;

    try {
      final oldestMessage = _currentGroupMessages.first;
      final moreMessages = await _groupService.getGroupMessages(
        groupId: _currentGroup!.groupId,
        limit: 50,
        before: oldestMessage.createdAt,
      );

      if (moreMessages.isNotEmpty) {
        final existingIds = _currentGroupMessages
            .map((m) => m.messageId)
            .toSet();
        final newMessages = moreMessages
            .where((m) => !existingIds.contains(m.messageId))
            .toList();

        if (newMessages.isNotEmpty) {
          _currentGroupMessages = [...newMessages, ..._currentGroupMessages];
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Add a member to the current group
  Future<bool> addMember(String userId) async {
    if (_currentGroup == null) return false;

    try {
      await _groupService.addMember(
        groupId: _currentGroup!.groupId,
        userId: userId,
      );

      // Refresh members list
      _currentGroupMembers = await _groupService.getGroupMembers(
        _currentGroup!.groupId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove a member from the current group
  Future<bool> removeMember(String userId) async {
    if (_currentGroup == null) return false;

    try {
      await _groupService.removeMember(
        groupId: _currentGroup!.groupId,
        userId: userId,
      );

      // Refresh members list
      _currentGroupMembers = await _groupService.getGroupMembers(
        _currentGroup!.groupId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Leave the current group
  Future<bool> leaveGroup() async {
    if (_currentGroup == null || _currentUserId == null) return false;

    try {
      await _groupService.leaveGroup(
        groupId: _currentGroup!.groupId,
        userId: _currentUserId!,
      );

      await refreshGroupConversations();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update member role
  Future<bool> updateMemberRole({
    required String userId,
    required GroupRole newRole,
  }) async {
    if (_currentGroup == null) return false;

    try {
      await _groupService.updateMemberRole(
        groupId: _currentGroup!.groupId,
        userId: userId,
        newRole: newRole,
      );

      // Refresh members list
      _currentGroupMembers = await _groupService.getGroupMembers(
        _currentGroup!.groupId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update group details
  Future<bool> updateGroup({
    String? name,
    String? description,
    String? image,
  }) async {
    if (_currentGroup == null) return false;

    try {
      final updatedGroup = await _groupService.updateGroup(
        groupId: _currentGroup!.groupId,
        name: name,
        description: description,
        image: image,
      );

      if (updatedGroup != null) {
        _currentGroup = updatedGroup;
        await refreshGroupConversations();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Pick an image from gallery for group
  Future<XFile?> pickGroupImage() async {
    try {
      final image = await _groupService.pickImageFromGallery();
      return image;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Upload group image
  Future<String?> uploadGroupImage(XFile imageFile) async {
    if (_currentGroup == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _groupService.uploadGroupImage(
        groupId: _currentGroup!.groupId,
        imageFile: imageFile,
      );

      if (imageUrl != null) {
        // Refresh group data
        _currentGroup = await _groupService.getGroup(_currentGroup!.groupId);
        await refreshGroupConversations();
      }

      _isLoading = false;
      notifyListeners();
      return imageUrl;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload group image for a specific group (used during creation)
  Future<String?> uploadGroupImageForGroup({
    required String groupId,
    required XFile imageFile,
  }) async {
    try {
      final imageUrl = await _groupService.uploadGroupImage(
        groupId: groupId,
        imageFile: imageFile,
      );
      return imageUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete the current group
  Future<bool> deleteGroup() async {
    if (_currentGroup == null) return false;

    try {
      await _groupService.deleteGroup(_currentGroup!.groupId);
      _currentGroup = null;
      await refreshGroupConversations();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Close the current group chat
  void closeGroupChat() {
    _currentGroup = null;
    _currentGroupMessages = [];
    _currentGroupMembers = [];
    _isCurrentUserAdmin = false;
    onNewMessageReceived = null;
    _currentGroupChannel = null;
    _groupService.unsubscribe();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Get member by user ID from current group
  GroupMember? getMemberByUserId(String userId) {
    try {
      return _currentGroupMembers.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get user display name from a message
  String getSenderName(Message message) {
    final member = getMemberByUserId(message.senderId ?? '');
    if (member?.user != null) {
      final user = member!.user!;
      return '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim();
    }
    return 'Unknown';
  }

  /// Get user profile picture from a message
  String? getSenderProfilePic(Message message) {
    final member = getMemberByUserId(message.senderId ?? '');
    return member?.user?.profilePic;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _groupService.unsubscribe();
    super.dispose();
  }
}
