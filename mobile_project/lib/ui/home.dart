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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _isSearching
              ? IconButton(
                  key: const ValueKey('BackBtn'),
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                      backgroundColor: const Color(0xFFE8DEF8),
                      backgroundImage: user?.profilePic != null
                          ? NetworkImage(user!.profilePic!)
                          : null,
                      child: user?.profilePic == null
                          ? Text(
                              user?.firstname?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Color(0xFF6750A4),
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
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : const Align(
                  alignment: Alignment.centerLeft,
                  key: ValueKey('Title'),
                  child: Text(
                    'ChatApp',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        actions: [
          AnimatedCrossFade(
            firstChild: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/friends'),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xFF6750A4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
    return GestureDetector(
      onTap: () => _openChat(friend),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE8DEF8),
                  backgroundImage: friend.profilePic != null
                      ? NetworkImage(friend.profilePic!)
                      : null,
                  child: friend.profilePic == null
                      ? Text(
                          _getInitials(friend),
                          style: const TextStyle(
                            color: Color(0xFF6750A4),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              friend.firstname ?? 'User',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8DEF8),
            radius: 28,
            backgroundImage: participant.profilePic != null
                ? NetworkImage(participant.profilePic!)
                : null,
            child: participant.profilePic == null
                ? Text(
                    _getInitials(participant),
                    style: const TextStyle(
                      color: Color(0xFF6750A4),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        '${participant.firstname ?? ''} ${participant.lastname ?? ''}'.trim(),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Row(
        children: [
          if (isSentByMe)
            const Icon(Icons.done_all, size: 16, color: Color(0xFF6750A4)),
          if (isSentByMe) const SizedBox(width: 4),
          Expanded(
            child: Text(
              lastMessage.message ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(lastMessage.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF6750A4),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => _openChat(participant),
    );
  }

  Widget _buildChatTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _chatTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _chatTabIndex == 0
                      ? const Color(0xFF6750A4)
                      : Colors.grey.shade200,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: _chatTabIndex == 0 ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Direct',
                      style: TextStyle(
                        color: _chatTabIndex == 0 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _chatTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _chatTabIndex == 1
                      ? const Color(0xFF6750A4)
                      : Colors.grey.shade200,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 18,
                      color: _chatTabIndex == 1 ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Groups',
                      style: TextStyle(
                        color: _chatTabIndex == 1 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Group Chats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8DEF8),
        radius: 28,
        backgroundImage: group.image != null
            ? NetworkImage(group.image!)
            : null,
        child: group.image == null
            ? Text(
                _getGroupInitials(group.name),
                style: const TextStyle(
                  color: Color(0xFF6750A4),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      ),
      title: Text(
        group.name ?? 'Group',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.group, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            '${groupConv.memberCount} members',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          if (lastMessage != null) ...[
            Text(' • ', style: TextStyle(color: Colors.grey.shade500)),
            Expanded(
              child: Text(
                lastMessage.message ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
              _formatTime(lastMessage.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          if (groupConv.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF6750A4),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${groupConv.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => _openGroupChat(groupConv),
    );
  }
}
