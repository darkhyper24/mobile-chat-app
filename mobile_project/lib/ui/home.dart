import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// TODO: Replace with actual chat model from backend
class DummyChat {
  final String name;
  final String lastMessage;
  final String time;
  final int? unreadCount;
  final String avatarInitials;

  DummyChat({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount,
    required this.avatarInitials,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // TODO: Replace with actual chat data from backend
  final List<DummyChat> _dummyChats = [
    DummyChat(
      name: 'Angel Curtis',
      lastMessage: 'Please help me find a good monitor for...',
      time: '02:11',
      unreadCount: 2,
      avatarInitials: 'AC',
    ),
    DummyChat(
      name: 'Zaire Dorwart',
      lastMessage: 'Oke pisah kang',
      time: '02:11',
      avatarInitials: 'ZD',
    ),
    DummyChat(
      name: 'Kelas Malam',
      lastMessage: 'Bima : No one can come today?',
      time: '02:11',
      unreadCount: 5,
      avatarInitials: 'KM',
    ),
    DummyChat(
      name: 'Jocelyn Gouse',
      lastMessage: "You're now an admin",
      time: '02:11',
      avatarInitials: 'JG',
    ),
    DummyChat(
      name: 'Jaylon Dias',
      lastMessage: 'So Jess: 10k gallons, top up credit, b...',
      time: '02:11',
      avatarInitials: 'JD',
    ),
    DummyChat(
      name: 'Chance Rhiel Madsen',
      lastMessage: 'Thank you mate!',
      time: '02:11',
      unreadCount: 2,
      avatarInitials: 'CM',
    ),
    DummyChat(
      name: 'Livia Dias',
      lastMessage: 'Great work everyone!',
      time: '02:11',
      avatarInitials: 'LD',
    ),
  ];

  List<DummyChat> get _filteredChats {
    if (_searchQuery.isEmpty) {
      return _dummyChats;
    }
    return _dummyChats
        .where(
          (chat) =>
              chat.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
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

    // TODO: Navigate to respective pages when they are created
    if (index == 1) {
      // Friends page - to be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friends page coming soon!')),
      );
    } else if (index == 2) {
      // Settings page - to be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings page coming soon!')),
      );
    } else if (index == 3) {
      // Profile page - to be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile page coming soon!')),
      );
    }
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
        // 1. Animate the Leading Icon (Avatar <-> Back Arrow)
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _isSearching
              ? IconButton(
                  key: const ValueKey('BackBtn'), // Keys are crucial for animation!
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _toggleSearch,
                )
              : Padding(
                  key: const ValueKey('Avatar'),
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFE8DEF8),
                    child: Text(
                      user?.firstname?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Color(0xFF6750A4),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
        ),
        // 2. Animate the Title (Text <-> Search Field)
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          // This creates a "Slide in from right" effect
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0), // Start from right
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _isSearching
              ? TextField(
                  key: const ValueKey('SearchField'), // Unique Key
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
                  key: ValueKey('Title'), // Unique Key
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
          // 3. Animate the Actions (Hide Search Icon smoothly)
          AnimatedCrossFade(
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                  onPressed: () {
                    // TODO: Implement new chat functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New chat coming soon!')),
                    );
                  },
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(), // Empty widget when searching
            crossFadeState: _isSearching
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _filteredChats.isEmpty
                ? const Center(
                    child: Text(
                      'No chats found',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredChats.length,
                    itemBuilder: (context, index) {
                      return _buildChatItem(_filteredChats[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6750A4),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        enableFeedback: false,
        backgroundColor: Colors.white,
        elevation: 8,
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildChatItem(DummyChat chat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8DEF8),
        radius: 28,
        child: Text(
          chat.avatarInitials,
          style: const TextStyle(
            color: Color(0xFF6750A4),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        chat.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.time,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (chat.unreadCount != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF6750A4),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat.unreadCount}',
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
      onTap: () {
        // TODO: Navigate to chat detail page when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening chat with ${chat.name}')),
        );
      },
    );
  }
}
