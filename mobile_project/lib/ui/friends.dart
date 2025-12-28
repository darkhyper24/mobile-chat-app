import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../models/users.dart';
import 'profile.dart';
import 'chat.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addFriendController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final friendsProvider = context.read<FriendsProvider>();
    final userId = authProvider.currentUser?.userId;

    if (userId != null) {
      friendsProvider.loadAllData(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _addFriendController.dispose();
    super.dispose();
  }

  List<User> _getFilteredFriends(List<User> friends) {
    if (_searchQuery.isEmpty) return friends;
    return friends.where((friend) {
      final fullName = '${friend.firstname ?? ''} ${friend.lastname ?? ''}'
          .toLowerCase();
      final username = (friend.username ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || username.contains(query);
    }).toList();
  }

  void _showAddFriendDialog() {
    _addFriendController.clear();
    final friendsProvider = context.read<FriendsProvider>();
    friendsProvider.clearSearch();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _AddFriendBottomSheet(
        controller: _addFriendController,
        onSearch: (query) {
          final userId = context.read<AuthProvider>().currentUser?.userId;
          if (userId != null) {
            context.read<FriendsProvider>().searchUsers(query, userId);
          }
        },
        onSendRequest: (receiverId) async {
          final userId = context.read<AuthProvider>().currentUser?.userId;
          if (userId != null) {
            final success = await context
                .read<FriendsProvider>()
                .sendFriendRequest(senderId: userId, receiverId: receiverId);
            if (modalContext.mounted) {
              Navigator.pop(modalContext);
              ScaffoldMessenger.of(modalContext).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Friend request sent!' : 'Failed to send request',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Navigate to Messages/Home page
      Navigator.pop(context);
    } else if (index == 1) {
      // Already on Friends page
    } else if (index == 2) {
      // Navigate to Settings page
      Navigator.pushNamed(context, '/settings');
    } else if (index == 3) {
      // Navigate to Profile page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF6750A4)),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  child: Consumer<FriendsProvider>(
                    builder: (context, provider, _) {
                      return Text('Friends (${provider.friends.length})');
                    },
                  ),
                ),
                Tab(
                  child: Consumer<FriendsProvider>(
                    builder: (context, provider, _) {
                      final count = provider.receivedRequests.length;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Requests'),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6750A4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFriendsTab(), _buildRequestsTab()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Friends tab is selected
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6750A4),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        enableFeedback: false,
        backgroundColor: Colors.white,
        elevation: 8,
        iconSize: 26,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<FriendsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6750A4)),
          );
        }

        final filteredFriends = _getFilteredFriends(provider.friends);

        if (filteredFriends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No friends yet' : 'No friends found',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showAddFriendDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add friends'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6750A4),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF6750A4),
          onRefresh: () async {
            _loadData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredFriends.length,
            itemBuilder: (context, index) {
              return _FriendListItem(
                friend: filteredFriends[index],
                onMessage: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(partner: filteredFriends[index]),
                    ),
                  );
                },
                onRemove: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Friend'),
                      content: Text(
                        'Are you sure you want to remove ${filteredFriends[index].firstname} from your friends?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final userId = context
                        .read<AuthProvider>()
                        .currentUser
                        ?.userId;
                    if (userId != null) {
                      await context.read<FriendsProvider>().removeFriend(
                        userId: userId,
                        friendId: filteredFriends[index].userId,
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<FriendsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6750A4)),
          );
        }

        if (provider.receivedRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF6750A4),
          onRefresh: () async {
            _loadData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.receivedRequests.length,
            itemBuilder: (context, index) {
              final request = provider.receivedRequests[index];
              final sender = request['sender'] as Map<String, dynamic>?;

              return _FriendRequestItem(
                requestId: request['id'] as String,
                senderName:
                    '${sender?['firstname'] ?? ''} ${sender?['lastname'] ?? ''}'
                        .trim(),
                senderUsername: sender?['username'] ?? '',
                senderProfilePic: sender?['profile_pic'],
                onAccept: () async {
                  final userId = context
                      .read<AuthProvider>()
                      .currentUser
                      ?.userId;
                  if (userId != null) {
                    final success = await provider.acceptFriendRequest(
                      request['id'],
                      userId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Friend request accepted!'
                                : 'Failed to accept request',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                onDecline: () async {
                  final userId = context
                      .read<AuthProvider>()
                      .currentUser
                      ?.userId;
                  if (userId != null) {
                    await provider.declineFriendRequest(request['id'], userId);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

// Friend List Item Widget with animation
class _FriendListItem extends StatefulWidget {
  final User friend;
  final VoidCallback onMessage;
  final VoidCallback onRemove;

  const _FriendListItem({
    required this.friend,
    required this.onMessage,
    required this.onRemove,
  });

  @override
  State<_FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends State<_FriendListItem> {
  double _scale = 1.0;
  double _offsetX = 0.0;

  String _getInitials() {
    final first = widget.friend.firstname?.isNotEmpty == true
        ? widget.friend.firstname![0].toUpperCase()
        : '';
    final last = widget.friend.lastname?.isNotEmpty == true
        ? widget.friend.lastname![0].toUpperCase()
        : '';
    return '$first$last'.isEmpty ? '?' : '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _offsetX = (_offsetX + details.delta.dx).clamp(-60.0, 60.0);
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() => _offsetX = 0.0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_offsetX, 0, 0),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8DEF8),
                backgroundImage: widget.friend.profilePic != null
                    ? NetworkImage(widget.friend.profilePic!)
                    : null,
                child: widget.friend.profilePic == null
                    ? Text(
                        _getInitials(),
                        style: const TextStyle(
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          title: Text(
            '${widget.friend.firstname ?? ''} ${widget.friend.lastname ?? ''}'
                .trim(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            '@${widget.friend.username ?? 'user'}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedOutlinedButton(text: 'Message', onTap: widget.onMessage),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'remove') {
                    widget.onRemove();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Remove friend',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated outlined button with tap feedback
class _AnimatedOutlinedButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _AnimatedOutlinedButton({required this.text, required this.onTap});

  @override
  State<_AnimatedOutlinedButton> createState() =>
      _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<_AnimatedOutlinedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6750A4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Color(0xFF6750A4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Friend Request Item Widget with animation
class _FriendRequestItem extends StatefulWidget {
  final String requestId;
  final String senderName;
  final String senderUsername;
  final String? senderProfilePic;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _FriendRequestItem({
    required this.requestId,
    required this.senderName,
    required this.senderUsername,
    this.senderProfilePic,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_FriendRequestItem> createState() => _FriendRequestItemState();
}

class _FriendRequestItemState extends State<_FriendRequestItem> {
  double _acceptScale = 1.0;
  double _declineScale = 1.0;
  bool _isVisible = true;

  String _getInitials() {
    final parts = widget.senderName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (widget.senderName.isNotEmpty) {
      return widget.senderName[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(1, 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8DEF8),
                backgroundImage: widget.senderProfilePic != null
                    ? NetworkImage(widget.senderProfilePic!)
                    : null,
                child: widget.senderProfilePic == null
                    ? Text(
                        _getInitials(),
                        style: const TextStyle(
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.senderName.isEmpty
                          ? 'Unknown User'
                          : widget.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.senderUsername.isNotEmpty)
                      Text(
                        '@${widget.senderUsername}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decline button
                  GestureDetector(
                    onTapDown: (_) => setState(() => _declineScale = 0.85),
                    onTapUp: (_) {
                      setState(() => _declineScale = 1.0);
                      widget.onDecline();
                    },
                    onTapCancel: () => setState(() => _declineScale = 1.0),
                    child: AnimatedScale(
                      scale: _declineScale,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept button
                  GestureDetector(
                    onTapDown: (_) => setState(() => _acceptScale = 0.85),
                    onTapUp: (_) {
                      setState(() => _acceptScale = 1.0);
                      widget.onAccept();
                    },
                    onTapCancel: () => setState(() => _acceptScale = 1.0),
                    child: AnimatedScale(
                      scale: _acceptScale,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add Friend Bottom Sheet
class _AddFriendBottomSheet extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String) onSendRequest;

  const _AddFriendBottomSheet({
    required this.controller,
    required this.onSearch,
    required this.onSendRequest,
  });

  @override
  State<_AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<_AddFriendBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add Friend',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Search by username or name...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                widget.onSearch(value);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Search Results
          Expanded(
            child: Consumer<FriendsProvider>(
              builder: (context, provider, _) {
                if (provider.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6750A4)),
                  );
                }

                if (widget.controller.text.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Search for users to add as friends',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = provider.searchResults[index];
                    final isFriend = provider.isFriend(user.userId);
                    final hasSentRequest = provider.hasRequestSent(user.userId);
                    final hasReceivedRequest = provider.hasRequestReceived(
                      user.userId,
                    );

                    return _SearchResultItem(
                      user: user,
                      isFriend: isFriend,
                      hasSentRequest: hasSentRequest,
                      hasReceivedRequest: hasReceivedRequest,
                      onAdd: () => widget.onSendRequest(user.userId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Search Result Item
class _SearchResultItem extends StatelessWidget {
  final User user;
  final bool isFriend;
  final bool hasSentRequest;
  final bool hasReceivedRequest;
  final VoidCallback onAdd;

  const _SearchResultItem({
    required this.user,
    required this.isFriend,
    required this.hasSentRequest,
    required this.hasReceivedRequest,
    required this.onAdd,
  });

  String _getInitials() {
    final first = user.firstname?.isNotEmpty == true
        ? user.firstname![0].toUpperCase()
        : '';
    final last = user.lastname?.isNotEmpty == true
        ? user.lastname![0].toUpperCase()
        : '';
    return '$first$last'.isEmpty ? '?' : '$first$last';
  }

  String _getButtonText() {
    if (isFriend) return 'Friends';
    if (hasSentRequest) return 'Pending';
    if (hasReceivedRequest) return 'Respond';
    return 'Add';
  }

  bool _isButtonEnabled() {
    return !isFriend && !hasSentRequest && !hasReceivedRequest;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8DEF8),
            backgroundImage: user.profilePic != null
                ? NetworkImage(user.profilePic!)
                : null,
            child: user.profilePic == null
                ? Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Color(0xFF6750A4),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '@${user.username ?? 'user'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isButtonEnabled() ? onAdd : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled()
                  ? const Color(0xFF6750A4)
                  : Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: Text(_getButtonText()),
          ),
        ],
      ),
    );
  }
}
