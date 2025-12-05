import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/users.dart';
import '../models/massages.dart';
import '../services/location_service.dart';

class ChatPage extends StatefulWidget {
  final User partner;

  const ChatPage({super.key, required this.partner});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  late final ChatProvider _chatProvider;
  bool _shouldAutoScroll = true;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _scrollController.addListener(_onScroll);
    _loadMessages();
  }

  void _loadMessages() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      await _chatProvider.openChat(
        userId: userId,
        partner: widget.partner,
      );
      // Scroll to bottom after initial messages load
      _scrollToBottom(animate: false);
    }
  }

  void _onScroll() {
    // Load more messages when scrolling to top
    if (_scrollController.hasClients && _scrollController.position.pixels <= 50) {
      final userId = context.read<AuthProvider>().currentUser?.userId;
      if (userId != null) {
        _chatProvider.loadMoreMessages(
          userId: userId,
          partnerId: widget.partner.userId,
        );
      }
    }
    
    // Check if user is near bottom to determine auto-scroll behavior
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      _shouldAutoScroll = (maxScroll - currentScroll) < 100;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _chatProvider.closeChat();
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

    // Clear the text field immediately for better UX
    _messageController.clear();
    // Ensure we scroll to bottom when our message appears
    _shouldAutoScroll = true;
    
    // Send the message - the stream subscription will handle UI update
    await _chatProvider.sendMessage(
      senderId: userId,
      receiverId: widget.partner.userId,
      text: text,
    );
  }

  Future<void> _sendLocation() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    // Ensure we scroll to bottom when our message appears
    _shouldAutoScroll = true;

    final result = await _chatProvider.sendLocation(
      senderId: userId,
      receiverId: widget.partner.userId,
    );

    if (!mounted) return;

    switch (result.type) {
      case LocationSendResultType.success:
        // Location sent successfully - nothing to do, UI already updated
        break;
      case LocationSendResultType.serviceDisabled:
        _showLocationErrorDialog(
          title: 'Location Services Disabled',
          message: 'Please enable location services in your device settings to share your location.',
          showSettingsButton: true,
          onSettings: () => _chatProvider.openLocationSettings(),
        );
        break;
      case LocationSendResultType.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to share your location.'),
            duration: Duration(seconds: 3),
          ),
        );
        break;
      case LocationSendResultType.permissionPermanentlyDenied:
        _showLocationErrorDialog(
          title: 'Permission Required',
          message: 'Location permission is permanently denied. Please enable it in your app settings.',
          showSettingsButton: true,
          onSettings: () => _chatProvider.openAppSettings(),
        );
        break;
      case LocationSendResultType.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to get location'),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  void _showLocationErrorDialog({
    required String title,
    required String message,
    bool showSettingsButton = false,
    VoidCallback? onSettings,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (showSettingsButton)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onSettings?.call();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
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
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8DEF8),
              backgroundImage: widget.partner.profilePic != null
                  ? NetworkImage(widget.partner.profilePic!)
                  : null,
              child: widget.partner.profilePic == null
                  ? Text(
                      _getInitials(widget.partner),
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
                    '${widget.partner.firstname ?? ''} ${widget.partner.lastname ?? ''}'.trim(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${widget.partner.username ?? 'user'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('View Profile'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile view coming soon!')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: const Text('Block User', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Block feature coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.currentMessages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6750A4),
                    ),
                  );
                }

                if (chatProvider.currentMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
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
                          'Start the conversation!',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messageCount = chatProvider.currentMessages.length;
                
                // Auto-scroll when new messages arrive (if user is near bottom)
                if (messageCount > _previousMessageCount && _shouldAutoScroll) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom(animate: true);
                  });
                }
                _previousMessageCount = messageCount;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messageCount,
                  itemBuilder: (context, index) {
                    final message = chatProvider.currentMessages[index];
                    final isMe = message.senderId == currentUserId;
                    final showDate = index == 0 ||
                        _shouldShowDate(
                          chatProvider.currentMessages[index - 1].createdAt,
                          message.createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          _buildDateSeparator(message.createdAt),
                        _MessageBubble(
                          message: message,
                          isMe: isMe,
                          time: _formatTime(message.createdAt),
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
              color: Colors.white,
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
                // Location button
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    return IconButton(
                      onPressed: chatProvider.isGettingLocation || chatProvider.isSending
                          ? null
                          : _sendLocation,
                      icon: chatProvider.isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6750A4)),
                              ),
                            )
                          : const Icon(
                              Icons.location_on,
                              color: Color(0xFF6750A4),
                              size: 24,
                            ),
                      tooltip: 'Share location',
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
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
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF6750A4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: chatProvider.isSending ? null : _sendMessage,
                        icon: chatProvider.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white, size: 20),
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

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isLocationMessage = message.isLocation;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6750A4) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
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
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isLocationMessage) ...[
              // Location message UI
              _buildLocationContent(context),
            ] else ...[
              // Regular text message
              Text(
                message.message ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Location icon and text
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: isMe ? Colors.white : const Color(0xFF6750A4),
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Location shared',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Open in Maps button
        InkWell(
          onTap: () async {
            final chatProvider = context.read<ChatProvider>();
            final success = await chatProvider.openLocationInMaps(
              message.latitude!,
              message.longitude!,
            );
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open Google Maps'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe 
                  ? Colors.white.withOpacity(0.2) 
                  : const Color(0xFF6750A4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMe 
                    ? Colors.white.withOpacity(0.3) 
                    : const Color(0xFF6750A4).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  color: isMe ? Colors.white : const Color(0xFF6750A4),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Open in Google Maps',
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF6750A4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
