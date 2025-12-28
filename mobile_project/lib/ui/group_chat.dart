import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../models/messages.dart';
import '../services/location_service.dart';
import 'group_settings.dart';

class GroupChatPage extends StatefulWidget {
  final Group group;

  const GroupChatPage({super.key, required this.group});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  late final GroupProvider _groupProvider;
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _groupProvider = context.read<GroupProvider>();
    _scrollController.addListener(_onScroll);
    _groupProvider.onNewMessageReceived = _onNewMessageReceived;

    // Schedule message loading after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  void _loadMessages() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      await _groupProvider.openGroupChat(userId: userId, group: widget.group);

      // Scroll to bottom after messages load
      _scrollToBottom(animate: false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 50) {
      _groupProvider.loadMoreMessages();
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _shouldAutoScroll = (maxScroll - currentScroll) < 100;
  }

  void _onNewMessageReceived(Message message) {
    if (_shouldAutoScroll) {
      _scrollToBottom(animate: true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _groupProvider.onNewMessageReceived = null;
    _groupProvider.closeGroupChat();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxExtent);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    _messageController.clear();
    _shouldAutoScroll = true;

    final success = await _groupProvider.sendMessage(
      senderId: userId,
      text: text,
    );

    if (success) {
      _scrollToBottom(animate: true);
    }
  }

  Future<void> _shareLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        final url = locationService.getGoogleMapsUrl(
          position.latitude,
          position.longitude,
        );

        final userId = context.read<AuthProvider>().currentUser?.userId;
        if (userId == null) return;

        _shouldAutoScroll = true;

        final success = await _groupProvider.sendMessage(
          senderId: userId,
          text: url,
        );

        if (success) {
          _scrollToBottom(animate: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.userId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF8F8F8);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final inputFillColor = isDark
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF5F5F5);
    final avatarBgColor = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFE8DEF8);
    final primaryColor = isDark
        ? const Color(0xFFD0BCFF)
        : const Color(0xFF6750A4);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Consumer<GroupProvider>(
          builder: (context, groupProvider, _) {
            final group = groupProvider.currentGroup ?? widget.group;
            final memberCount = groupProvider.currentGroupMembers.length;

            return GestureDetector(
              onTap: () => _openGroupSettings(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarBgColor,
                    backgroundImage: group.image != null
                        ? NetworkImage(group.image!)
                        : null,
                    child: group.image == null
                        ? Text(
                            _getGroupInitials(group.name ?? 'G'),
                            style: TextStyle(
                              color: primaryColor,
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
                          group.name ?? 'Group',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$memberCount members',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textColor),
            onPressed: () => _openGroupSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<GroupProvider>(
              builder: (context, groupProvider, _) {
                if (groupProvider.isLoading &&
                    groupProvider.currentGroupMessages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6750A4)),
                  );
                }

                if (groupProvider.currentGroupMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the group conversation!',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: groupProvider.currentGroupMessages.length,
                  itemBuilder: (context, index) {
                    final message = groupProvider.currentGroupMessages[index];
                    final isMe = message.senderId == currentUserId;
                    final showDate =
                        index == 0 ||
                        _shouldShowDate(
                          groupProvider
                              .currentGroupMessages[index - 1]
                              .createdAt,
                          message.createdAt,
                        );

                    // Get sender name for non-own messages
                    final senderName = isMe
                        ? null
                        : groupProvider.getSenderName(message);

                    // Get sender profile picture for non-own messages
                    final senderProfilePic = isMe
                        ? null
                        : groupProvider.getSenderProfilePic(message);

                    // Check if we should show sender name (different from previous sender)
                    final showSenderName =
                        !isMe &&
                        (index == 0 ||
                            groupProvider
                                    .currentGroupMessages[index - 1]
                                    .senderId !=
                                message.senderId);

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.createdAt),
                        _GroupMessageBubble(
                          message: message,
                          isMe: isMe,
                          time: _formatTime(message.createdAt),
                          senderName: showSenderName ? senderName : null,
                          senderProfilePic: showSenderName
                              ? senderProfilePic
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.location_on_outlined, color: primaryColor),
                  onPressed: _shareLocation,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputFillColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: subtitleColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<GroupProvider>(
                  builder: (context, groupProvider, _) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF6750A4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: groupProvider.isSending
                            ? null
                            : _sendMessage,
                        icon: groupProvider.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGroupSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupSettingsPage()),
    );
  }

  String _getGroupInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'G';
  }

  bool _shouldShowDate(DateTime? previous, DateTime? current) {
    if (previous == null || current == null) return true;
    return previous.day != current.day ||
        previous.month != current.month ||
        previous.year != current.year;
  }

  Widget _buildDateSeparator(DateTime? dateTime) {
    if (dateTime == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String time;
  final String? senderName;
  final String? senderProfilePic;

  const _GroupMessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
    this.senderName,
    this.senderProfilePic,
  });

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isLocation =
        message.message?.startsWith('https://www.google.com/maps/search/') ??
        false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: senderName != null ? 8 : 4,
          bottom: 4,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile picture for other users' messages
            if (!isMe && senderName != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8DEF8),
                backgroundImage: senderProfilePic != null
                    ? NetworkImage(senderProfilePic!)
                    : null,
                child: senderProfilePic == null
                    ? Text(
                        _getInitials(senderName ?? '?'),
                        style: const TextStyle(
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ] else if (!isMe && senderName == null) ...[
              const SizedBox(width: 40), // Placeholder for alignment
            ],
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        senderName!,
                        style: const TextStyle(
                          color: Color(0xFF6750A4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF6750A4) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (isLocation)
                          _buildLocationContent(context)
                        else
                          Text(
                            message.message ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(message.message!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: isMe ? Colors.white : Colors.red),
          const SizedBox(width: 8),
          Text(
            'Shared Location',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
