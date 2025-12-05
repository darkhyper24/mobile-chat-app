import '../database/db.dart';
import '../models/users.dart';
import '../models/friends.dart';
import '../models/friend_request.dart';

class FriendService {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  final _db = DatabaseService();

  // Get all friends for a user with their user data
  Future<List<User>> getFriends(String userId) async {
    // Get friend relationships where user is either user_id or friend_id
    final friendsAsUser = await _db.client
        .from('friends')
        .select('friend_id')
        .eq('user_id', userId);

    final friendsAsFriend = await _db.client
        .from('friends')
        .select('user_id')
        .eq('friend_id', userId);

    // Collect all friend IDs
    final friendIds = <String>{};
    for (final row in friendsAsUser) {
      friendIds.add(row['friend_id'] as String);
    }
    for (final row in friendsAsFriend) {
      friendIds.add(row['user_id'] as String);
    }

    if (friendIds.isEmpty) {
      return [];
    }

    // Get user data for all friends
    final usersResponse = await _db.client
        .from('users')
        .select()
        .inFilter('user_id', friendIds.toList());

    return (usersResponse as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  // Get pending friend requests received by user
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests(String userId) async {
    final requests = await _db.client
        .from('friend_request')
        .select('*, sender:users!friend_request_sender_id_fkey(*)')
        .eq('receiver_id', userId)
        .eq('status', 'pending');

    return List<Map<String, dynamic>>.from(requests);
  }

  // Get pending friend requests sent by user
  Future<List<Map<String, dynamic>>> getSentFriendRequests(String userId) async {
    final requests = await _db.client
        .from('friend_request')
        .select('*, receiver:users!friend_request_receiver_id_fkey(*)')
        .eq('sender_id', userId)
        .eq('status', 'pending');

    return List<Map<String, dynamic>>.from(requests);
  }

  // Send a friend request
  Future<FriendRequest?> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    // Check if already friends
    final existingFriend = await _db.client
        .from('friends')
        .select()
        .or('and(user_id.eq.$senderId,friend_id.eq.$receiverId),and(user_id.eq.$receiverId,friend_id.eq.$senderId)')
        .maybeSingle();

    if (existingFriend != null) {
      throw Exception('You are already friends with this user');
    }

    // Check if request already exists
    final existingRequest = await _db.client
        .from('friend_request')
        .select()
        .or('and(sender_id.eq.$senderId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
        .eq('status', 'pending')
        .maybeSingle();

    if (existingRequest != null) {
      throw Exception('A friend request already exists');
    }

    final response = await _db.client.from('friend_request').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': 'pending',
    }).select().single();

    return FriendRequest.fromJson(response);
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String requestId) async {
    // Get the request first
    final request = await _db.client
        .from('friend_request')
        .select()
        .eq('id', requestId)
        .single();

    // Update request status
    await _db.client
        .from('friend_request')
        .update({'status': 'accepted'})
        .eq('id', requestId);

    // Create friendship
    await _db.client.from('friends').insert({
      'user_id': request['sender_id'],
      'friend_id': request['receiver_id'],
    });
  }

  // Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    await _db.client
        .from('friend_request')
        .update({'status': 'declined'})
        .eq('id', requestId);
  }

  // Cancel a sent friend request
  Future<void> cancelFriendRequest(String requestId) async {
    await _db.client
        .from('friend_request')
        .delete()
        .eq('id', requestId);
  }

  // Remove a friend
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    await _db.client
        .from('friends')
        .delete()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');
  }

  // Search users by username or name
  Future<List<User>> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) {
      return [];
    }

    final response = await _db.client
        .from('users')
        .select()
        .neq('user_id', currentUserId)
        .or('username.ilike.%$query%,firstname.ilike.%$query%,lastname.ilike.%$query%')
        .limit(20);

    return (response as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  // Get a single user by ID
  Future<User?> getUserById(String userId) async {
    final response = await _db.client
        .from('users')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return User.fromJson(response);
  }
}



