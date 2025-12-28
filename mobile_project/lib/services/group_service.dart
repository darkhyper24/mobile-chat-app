import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db.dart';
import '../models/group.dart';
import '../models/group_members.dart';
import '../models/massages.dart';
import '../models/users.dart' as models;

/// Represents a group conversation with its latest message and member count
class GroupConversation {
  final Group group;
  final Message? lastMessage;
  final int memberCount;
  final int unreadCount;

  GroupConversation({
    required this.group,
    this.lastMessage,
    this.memberCount = 0,
    this.unreadCount = 0,
  });
}

class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final _db = DatabaseService();

  // Realtime subscription channels
  RealtimeChannel? _groupMessagesChannel;
  RealtimeChannel? _groupMembersChannel;

  // Stream controllers for real-time updates
  final _newGroupMessageController = StreamController<Message>.broadcast();
  final _memberChangeController = StreamController<GroupMember>.broadcast();

  Stream<Message> get newGroupMessageStream =>
      _newGroupMessageController.stream;
  Stream<GroupMember> get memberChangeStream => _memberChangeController.stream;

  // ==================== GROUP CRUD OPERATIONS ====================

  /// Create a new group
  Future<Group?> createGroup({
    required String name,
    required String creatorId,
    String? description,
    String? image,
  }) async {
    try {
      // Create the group
      final groupResponse = await _db.client
          .from('group')
          .insert({'name': name, 'description': description, 'image': image})
          .select()
          .single();

      final group = Group.fromJson(groupResponse);

      // Add creator as admin member
      await _db.client.from('group_members').insert({
        'user_id': creatorId,
        'group_id': group.groupId,
        'role': 'admin',
      });

      return group;
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  /// Get a group by ID
  Future<Group?> getGroup(String groupId) async {
    try {
      final response = await _db.client
          .from('group')
          .select()
          .eq('group_id', groupId)
          .maybeSingle();

      if (response == null) return null;
      return Group.fromJson(response);
    } catch (e) {
      print('Error getting group: $e');
      rethrow;
    }
  }

  /// Update group details
  Future<Group?> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? image,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (image != null) updateData['image'] = image;

      if (updateData.isEmpty) return await getGroup(groupId);

      final response = await _db.client
          .from('group')
          .update(updateData)
          .eq('group_id', groupId)
          .select()
          .single();

      return Group.fromJson(response);
    } catch (e) {
      print('Error updating group: $e');
      rethrow;
    }
  }

  /// Delete a group (only admins can do this)
  Future<void> deleteGroup(String groupId) async {
    try {
      // First delete all members
      await _db.client.from('group_members').delete().eq('group_id', groupId);

      // Note: We don't delete messages due to Supabase replica identity limitations
      // Messages will be orphaned but won't be visible since the group is deleted
      // To properly delete messages, run this SQL in Supabase:
      // ALTER TABLE massages REPLICA IDENTITY FULL;

      // Delete the group
      await _db.client.from('group').delete().eq('group_id', groupId);
    } catch (e) {
      print('Error deleting group: $e');
      rethrow;
    }
  }

  /// Get all groups a user is a member of
  Future<List<GroupConversation>> getUserGroups(String userId) async {
    try {
      // Get group IDs where user is a member
      final membershipResponse = await _db.client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      if (membershipResponse.isEmpty) {
        return [];
      }

      final groupIds = (membershipResponse as List)
          .map((m) => m['group_id'] as String)
          .toList();

      // Get group details
      final groupsResponse = await _db.client
          .from('group')
          .select()
          .inFilter('group_id', groupIds);

      final groups = (groupsResponse as List)
          .map((g) => Group.fromJson(g))
          .toList();

      // Get latest message for each group
      final groupConversations = <GroupConversation>[];

      for (final group in groups) {
        // Get latest message
        final messagesResponse = await _db.client
            .from('massages')
            .select()
            .eq('group_id', group.groupId)
            .order('created_at', ascending: false)
            .limit(1);

        Message? lastMessage;
        if ((messagesResponse as List).isNotEmpty) {
          lastMessage = Message.fromJson(messagesResponse.first);
        }

        // Get member count
        final memberCountResponse = await _db.client
            .from('group_members')
            .select()
            .eq('group_id', group.groupId);

        groupConversations.add(
          GroupConversation(
            group: group,
            lastMessage: lastMessage,
            memberCount: (memberCountResponse as List).length,
          ),
        );
      }

      // Sort by last message time
      groupConversations.sort((a, b) {
        final aTime =
            a.lastMessage?.createdAt ?? a.group.createdAt ?? DateTime(1970);
        final bTime =
            b.lastMessage?.createdAt ?? b.group.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return groupConversations;
    } catch (e) {
      print('Error getting user groups: $e');
      rethrow;
    }
  }

  // ==================== MEMBER MANAGEMENT ====================

  /// Get all members of a group with their user data
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _db.client
          .from('group_members')
          .select('*, user:users(*)')
          .eq('group_id', groupId);

      return (response as List).map((json) {
        // Handle the nested user data
        final memberData = Map<String, dynamic>.from(json);
        final userData = memberData.remove('user');
        final member = GroupMember.fromJson(memberData);

        if (userData != null) {
          return member.copyWith(user: models.User.fromJson(userData));
        }
        return member;
      }).toList();
    } catch (e) {
      print('Error getting group members: $e');
      rethrow;
    }
  }

  /// Add a member to a group
  Future<GroupMember?> addMember({
    required String groupId,
    required String userId,
    GroupRole role = GroupRole.member,
  }) async {
    try {
      // Check if already a member
      final existing = await _db.client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('User is already a member of this group');
      }

      final response = await _db.client
          .from('group_members')
          .insert({
            'group_id': groupId,
            'user_id': userId,
            'role': role.toJson(),
          })
          .select()
          .single();

      return GroupMember.fromJson(response);
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    }
  }

  /// Remove a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _db.client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  /// Leave a group (for current user)
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Check if user is the only admin
      final admins = await _db.client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('role', 'admin');

      final isOnlyAdmin =
          (admins as List).length == 1 && admins.first['user_id'] == userId;

      if (isOnlyAdmin) {
        // Check if there are other members
        final members = await getGroupMembers(groupId);
        if (members.length > 1) {
          throw Exception(
            'You are the only admin. Please promote another member to admin before leaving.',
          );
        } else {
          // User is alone, delete the group
          await deleteGroup(groupId);
          return;
        }
      }

      await removeMember(groupId: groupId, userId: userId);
    } catch (e) {
      print('Error leaving group: $e');
      rethrow;
    }
  }

  /// Update a member's role
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole newRole,
  }) async {
    try {
      await _db.client
          .from('group_members')
          .update({'role': newRole.toJson()})
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating member role: $e');
      rethrow;
    }
  }

  /// Check if a user is an admin of a group
  Future<bool> isUserAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _db.client
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;
      return response['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if a user is a member of a group
  Future<bool> isUserMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _db.client
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking membership: $e');
      return false;
    }
  }

  // ==================== GROUP MESSAGES ====================

  /// Get messages for a group
  Future<List<Message>> getGroupMessages({
    required String groupId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _db.client.from('massages').select().eq('group_id', groupId);

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
          .toList();
    } catch (e) {
      print('Error getting group messages: $e');
      rethrow;
    }
  }

  /// Send a message to a group
  Future<Message?> sendGroupMessage({
    required String senderId,
    required String groupId,
    required String text,
    String? image,
  }) async {
    try {
      final response = await _db.client
          .from('massages')
          .insert({
            'sender_id': senderId,
            'group_id': groupId,
            'massage': text,
            'image': image,
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('Error sending group message: $e');
      rethrow;
    }
  }

  // ==================== REALTIME SUBSCRIPTIONS ====================

  /// Subscribe to real-time messages for a specific group
  void subscribeToGroupMessages({
    required String groupId,
    required Function(Message) onNewMessage,
  }) {
    // Unsubscribe from previous channel if exists
    _groupMessagesChannel?.unsubscribe();

    _groupMessagesChannel = _db.client
        .channel('group-messages:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'massages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            try {
              final newMessage = Message.fromJson(payload.newRecord);
              onNewMessage(newMessage);
              _newGroupMessageController.add(newMessage);
            } catch (e) {
              print('Error processing realtime group message: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('Group messages subscription status: $status');
          if (error != null) {
            print('Subscription error: $error');
          }
        });
  }

  /// Subscribe to member changes in a group
  void subscribeToGroupMembers({
    required String groupId,
    required Function(String event, GroupMember? member) onMemberChange,
  }) {
    _groupMembersChannel?.unsubscribe();

    _groupMembersChannel = _db.client
        .channel('group-members:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            try {
              GroupMember? member;
              if (payload.newRecord.isNotEmpty) {
                member = GroupMember.fromJson(payload.newRecord);
              }
              onMemberChange(payload.eventType.name, member);
            } catch (e) {
              print('Error processing member change: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('Group members subscription status: $status');
          if (error != null) {
            print('Subscription error: $error');
          }
        });
  }

  /// Unsubscribe from group messages channel
  void unsubscribeFromGroupMessages() {
    _groupMessagesChannel?.unsubscribe();
    _groupMessagesChannel = null;
  }

  /// Unsubscribe from group members channel
  void unsubscribeFromGroupMembers() {
    _groupMembersChannel?.unsubscribe();
    _groupMembersChannel = null;
  }

  /// Unsubscribe from all real-time updates
  void unsubscribe() {
    unsubscribeFromGroupMessages();
    unsubscribeFromGroupMembers();
  }

  /// Clean up resources
  void dispose() {
    unsubscribe();
    _newGroupMessageController.close();
    _memberChangeController.close();
  }
}
