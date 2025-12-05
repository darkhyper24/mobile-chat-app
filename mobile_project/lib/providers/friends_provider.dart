import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../models/users.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendService _friendService = FriendService();

  List<User> _friends = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  List<User> get friends => _friends;
  List<Map<String, dynamic>> get receivedRequests => _receivedRequests;
  List<Map<String, dynamic>> get sentRequests => _sentRequests;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // Load all friends
  Future<void> loadFriends(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _friends = await _friendService.getFriends(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load received friend requests
  Future<void> loadReceivedRequests(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _receivedRequests = await _friendService.getReceivedFriendRequests(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load sent friend requests
  Future<void> loadSentRequests(String userId) async {
    try {
      _sentRequests = await _friendService.getSentFriendRequests(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load all data
  Future<void> loadAllData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadFriendsInternal(userId),
        _loadReceivedRequestsInternal(userId),
        _loadSentRequestsInternal(userId),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFriendsInternal(String userId) async {
    _friends = await _friendService.getFriends(userId);
  }

  Future<void> _loadReceivedRequestsInternal(String userId) async {
    _receivedRequests = await _friendService.getReceivedFriendRequests(userId);
  }

  Future<void> _loadSentRequestsInternal(String userId) async {
    _sentRequests = await _friendService.getSentFriendRequests(userId);
  }

  // Search users
  Future<void> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _friendService.searchUsers(query, currentUserId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // Send friend request
  Future<bool> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      await _friendService.sendFriendRequest(
        senderId: senderId,
        receiverId: receiverId,
      );
      await loadSentRequests(senderId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId, String userId) async {
    try {
      await _friendService.acceptFriendRequest(requestId);
      await loadAllData(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Decline friend request
  Future<bool> declineFriendRequest(String requestId, String userId) async {
    try {
      await _friendService.declineFriendRequest(requestId);
      await loadReceivedRequests(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel sent friend request
  Future<bool> cancelFriendRequest(String requestId, String userId) async {
    try {
      await _friendService.cancelFriendRequest(requestId);
      await loadSentRequests(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove friend
  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      await _friendService.removeFriend(userId: userId, friendId: friendId);
      await loadFriends(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if user is already a friend
  bool isFriend(String friendId) {
    return _friends.any((friend) => friend.userId == friendId);
  }

  // Check if request already sent
  bool hasRequestSent(String userId) {
    return _sentRequests.any((request) => 
      request['receiver']?['user_id'] == userId
    );
  }

  // Check if request already received
  bool hasRequestReceived(String userId) {
    return _receivedRequests.any((request) => 
      request['sender']?['user_id'] == userId
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}



