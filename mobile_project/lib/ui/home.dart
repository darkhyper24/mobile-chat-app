import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../services/message_service.dart';
import '../services/group_service.dart';
import '../models/users.dart';
import 'chat.dart';
import 'profile.dart';
import 'group_chat.dart';
import 'create_group.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _chatTabIndex = 0; // 0 = Direct, 1 = Groups
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Schedule data loading after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      context.read<ChatProvider>().loadConversations(userId);
      context.read<FriendsProvider>().loadFriends(userId);
      context.read<GroupProvider>().loadGroupConversations(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushNamed(context, '/friends');
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) {
        _loadData();
      });
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _openChat(User partner) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(partner: partner)),
    ).then((_) {
      // Refresh conversations when returning from chat
      _loadData();
    });
  }

  void _openGroupChat(GroupConversation groupConv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatPage(group: groupConv.group),
      ),
    ).then((_) {
      _loadData();
    });
  }

  void _createNewGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupPage()),
    ).then((_) {
      _loadData();
    });
  }

  String _getInitials(User user) {
    final first = user.firstname?.isNotEmpty == true
        ? user.firstname![0].toUpperCase()
        : '';
    final last = user.lastname?.isNotEmpty == true
        ? user.lastname![0].toUpperCase()
        : '';
    return '$first$last'.isEmpty ? '?' : '$first$last';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _getGroupInitials(String? name) {
    if (name == null || name.isEmpty) return 'G';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _isSearching
              ? IconButton(
                  key: const ValueKey('BackBtn'),
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: _toggleSearch,
                )
              : GestureDetector(
                  key: const ValueKey('Avatar'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    ).then((_) {
                      _loadData();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: isDark
                          ? const Color(0xFF3D3D3D)
                          : const Color(0xFFE8DEF8),
                      backgroundImage: user?.profilePic != null
                          ? NetworkImage(user!.profilePic!)
                          : null,
                      child: user?.profilePic == null
                          ? Text(
                              user?.firstname?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFD0BCFF)
                                    : const Color(0xFF6750A4),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _isSearching
              ? TextField(
                  key: const ValueKey('SearchField'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: subtitleColor),
                  ),
                  style: TextStyle(color: textColor, fontSize: 18),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  key: const ValueKey('Title'),
                  child: Text(
                    'ZC Chat App',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        actions: [
          AnimatedCrossFade(
            firstChild: IconButton(
              icon: Icon(Icons.search, color: textColor),
              onPressed: _toggleSearch,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isSearching
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6750A4),
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Friends Section (horizontal scroll)
              _buildFriendsSection(),

              const Divider(height: 1),

              // Chat Type Tabs
              _buildChatTabs(),

              // Conversations Section based on selected tab
              if (_chatTabIndex == 0)
                _buildConversationsSection()
              else
                _buildGroupsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: _chatTabIndex == 1
          ? FloatingActionButton(
              onPressed: _createNewGroup,
              backgroundColor: const Color(0xFF6750A4),
              child: const Icon(Icons.group_add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isDark
            ? const Color(0xFFD0BCFF)
            : const Color(0xFF6750A4),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        enableFeedback: false,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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

  Widget _buildFriendsSection() {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, _) {
        final friends = friendsProvider.friends;

        if (friends.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter friends based on search
        final filteredFriends = _searchQuery.isEmpty
            ? friends
            : friends.where((friend) {
                final name =
                    '${friend.firstname ?? ''} ${friend.lastname ?? ''}'
                        .toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredFriends.isEmpty && _searchQuery.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  final textColor = isDark ? Colors.white : Colors.black87;
                  final accentColor = isDark
                      ? const Color(0xFFD0BCFF)
                      : const Color(0xFF6750A4);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Friends',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/friends'),
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredFriends.length,
                itemBuilder: (context, index) {
                  final friend = filteredFriends[index];
                  return _buildFriendAvatar(friend);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFriendAvatar(User friend) {
    return _AnimatedFriendAvatar(
      friend: friend,
      onTap: () => _openChat(friend),
      getInitials: _getInitials,
    );
  }

  Widget _buildConversationsSection() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF6750A4)),
            ),
          );
        }

        final conversations = _searchQuery.isEmpty
            ? chatProvider.conversations
            : chatProvider.searchConversations(_searchQuery);

        if (conversations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No conversations yet'
                        : 'No conversations found',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Start chatting with your friends!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final textColor = isDark ? Colors.white : Colors.black87;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationItem(conversations[index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final participant = conversation.participant;
    final lastMessage = conversation.lastMessage;
    final currentUserId = context.read<AuthProvider>().currentUser?.userId;
    final isSentByMe = lastMessage.senderId == currentUserId;

    return _AnimatedConversationItem(
      conversation: conversation,
      isSentByMe: isSentByMe,
      onTap: () => _openChat(participant),
      getInitials: _getInitials,
      formatTime: _formatTime,
    );
  }

  Widget _buildChatTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedTabButton(
              isSelected: _chatTabIndex == 0,
              icon: Icons.chat_bubble_outline,
              label: 'Direct',
              onTap: () => setState(() => _chatTabIndex = 0),
              isLeft: true,
            ),
          ),
          Expanded(
            child: _AnimatedTabButton(
              isSelected: _chatTabIndex == 1,
              icon: Icons.group_outlined,
              label: 'Groups',
              onTap: () => setState(() => _chatTabIndex = 1),
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsSection() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        if (groupProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF6750A4)),
            ),
          );
        }

        final groups = groupProvider.groupConversations;

        // Filter based on search query
        final filteredGroups = _searchQuery.isEmpty
            ? groups
            : groups.where((g) {
                final name = g.group.name?.toLowerCase() ?? '';
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredGroups.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No groups yet' : 'No groups found',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Create a group to start chatting!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createNewGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final textColor = isDark ? Colors.white : Colors.black87;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Group Chats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                return _buildGroupItem(filteredGroups[index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupItem(GroupConversation groupConv) {
    final group = groupConv.group;
    final lastMessage = groupConv.lastMessage;

    return _AnimatedGroupItem(
      groupConv: groupConv,
      onTap: () => _openGroupChat(groupConv),
      getGroupInitials: _getGroupInitials,
      formatTime: _formatTime,
    );
  }
}

/// Animated tab button with smooth color transitions
class _AnimatedTabButton extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLeft;

  const _AnimatedTabButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isLeft,
  });

  @override
  State<_AnimatedTabButton> createState() => _AnimatedTabButtonState();
}

class _AnimatedTabButtonState extends State<_AnimatedTabButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF6750A4)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.horizontal(
              left: widget.isLeft ? const Radius.circular(25) : Radius.zero,
              right: !widget.isLeft ? const Radius.circular(25) : Radius.zero,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.isSelected),
                  size: 18,
                  color: widget.isSelected ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated friend avatar with tap feedback
class _AnimatedFriendAvatar extends StatefulWidget {
  final User friend;
  final VoidCallback onTap;
  final String Function(User) getInitials;

  const _AnimatedFriendAvatar({
    required this.friend,
    required this.onTap,
    required this.getInitials,
  });

  @override
  State<_AnimatedFriendAvatar> createState() => _AnimatedFriendAvatarState();
}

class _AnimatedFriendAvatarState extends State<_AnimatedFriendAvatar> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarBgColor = isDark
        ? const Color(0xFF3E3253)
        : const Color(0xFFE8DEF8);
    final avatarTextColor = isDark
        ? const Color(0xFFD0BCFF)
        : const Color(0xFF6750A4);
    final textColor = isDark ? Colors.white : Colors.black;

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
          width: 72,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: avatarBgColor,
                    backgroundImage: widget.friend.profilePic != null
                        ? NetworkImage(widget.friend.profilePic!)
                        : null,
                    child: widget.friend.profilePic == null
                        ? Text(
                            widget.getInitials(widget.friend),
                            style: TextStyle(
                              color: avatarTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.friend.firstname ?? 'User',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated conversation item with swipe and tap feedback
class _AnimatedConversationItem extends StatefulWidget {
  final Conversation conversation;
  final bool isSentByMe;
  final VoidCallback onTap;
  final String Function(User) getInitials;
  final String Function(DateTime?) formatTime;

  const _AnimatedConversationItem({
    required this.conversation,
    required this.isSentByMe,
    required this.onTap,
    required this.getInitials,
    required this.formatTime,
  });

  @override
  State<_AnimatedConversationItem> createState() =>
      _AnimatedConversationItemState();
}

class _AnimatedConversationItemState extends State<_AnimatedConversationItem> {
  double _scale = 1.0;
  double _offsetX = 0.0;
  Color _backgroundColor = Colors.transparent;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.98;
      _backgroundColor = Colors.grey.withOpacity(0.05);
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
      _backgroundColor = Colors.transparent;
    });
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
      _backgroundColor = Colors.transparent;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX = (_offsetX + details.delta.dx).clamp(-50.0, 50.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _offsetX = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.conversation.participant;
    final lastMessage = widget.conversation.lastMessage;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarBgColor = isDark
        ? const Color(0xFF3E3253)
        : const Color(0xFFE8DEF8);
    final avatarTextColor = isDark
        ? const Color(0xFFD0BCFF)
        : const Color(0xFF6750A4);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: _onPanEnd,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(_offsetX, 0, 0),
          decoration: BoxDecoration(color: _backgroundColor),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: Hero(
              tag: 'avatar_${participant.userId}',
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: avatarBgColor,
                    radius: 28,
                    backgroundImage: participant.profilePic != null
                        ? NetworkImage(participant.profilePic!)
                        : null,
                    child: participant.profilePic == null
                        ? Text(
                            widget.getInitials(participant),
                            style: TextStyle(
                              color: avatarTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            title: Text(
              '${participant.firstname ?? ''} ${participant.lastname ?? ''}'
                  .trim(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    lastMessage.message ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.formatTime(lastMessage.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (widget.conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6750A4),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated group item with tap feedback
class _AnimatedGroupItem extends StatefulWidget {
  final GroupConversation groupConv;
  final VoidCallback onTap;
  final String Function(String?) getGroupInitials;
  final String Function(DateTime?) formatTime;

  const _AnimatedGroupItem({
    required this.groupConv,
    required this.onTap,
    required this.getGroupInitials,
    required this.formatTime,
  });

  @override
  State<_AnimatedGroupItem> createState() => _AnimatedGroupItemState();
}

class _AnimatedGroupItemState extends State<_AnimatedGroupItem> {
  double _scale = 1.0;
  Color _backgroundColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final group = widget.groupConv.group;
    final lastMessage = widget.groupConv.lastMessage;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarBgColor = isDark
        ? const Color(0xFF3E3253)
        : const Color(0xFFE8DEF8);
    final avatarTextColor = isDark
        ? const Color(0xFFD0BCFF)
        : const Color(0xFF6750A4);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return GestureDetector(
      onTapDown: (_) => setState(() {
        _scale = 0.98;
        _backgroundColor = Colors.grey.withOpacity(0.05);
      }),
      onTapUp: (_) {
        setState(() {
          _scale = 1.0;
          _backgroundColor = Colors.transparent;
        });
        widget.onTap();
      },
      onTapCancel: () => setState(() {
        _scale = 1.0;
        _backgroundColor = Colors.transparent;
      }),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(color: _backgroundColor),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: Hero(
              tag: 'group_${group.groupId}',
              child: CircleAvatar(
                backgroundColor: avatarBgColor,
                radius: 28,
                backgroundImage: group.image != null
                    ? NetworkImage(group.image!)
                    : null,
                child: group.image == null
                    ? Text(
                        widget.getGroupInitials(group.name),
                        style: TextStyle(
                          color: avatarTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            title: Text(
              group.name ?? 'Group',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.group, size: 14, color: subtitleColor),
                const SizedBox(width: 4),
                Text(
                  '${widget.groupConv.memberCount} members',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                if (lastMessage != null) ...[
                  Text(' • ', style: TextStyle(color: subtitleColor)),
                  Expanded(
                    child: Text(
                      lastMessage.message ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessage != null)
                  Text(
                    widget.formatTime(lastMessage.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                if (widget.groupConv.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6750A4),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.groupConv.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
