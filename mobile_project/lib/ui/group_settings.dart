import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/friends_provider.dart';
import '../models/group_members.dart';
import '../models/users.dart';

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({super.key});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final group = context.read<GroupProvider>().currentGroup;
    _nameController.text = group?.name ?? '';
    _descriptionController.text = group?.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getUserInitials(User user) {
    final first = user.firstname?.isNotEmpty == true
        ? user.firstname![0].toUpperCase()
        : '';
    final last = user.lastname?.isNotEmpty == true
        ? user.lastname![0].toUpperCase()
        : '';
    return '$first$last'.isEmpty ? '?' : '$first$last';
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
        title: const Text(
          'Group Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF6750A4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, _) {
          final group = groupProvider.currentGroup;
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return ListView(
            children: [
              // Group Info Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE8DEF8),
                          backgroundImage: group.image != null
                              ? NetworkImage(group.image!)
                              : null,
                          child: _isUploadingImage
                              ? const CircularProgressIndicator(
                                  color: Color(0xFF6750A4),
                                )
                              : group.image == null
                              ? Text(
                                  _getInitials(group.name),
                                  style: const TextStyle(
                                    color: Color(0xFF6750A4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                )
                              : null,
                        ),
                        if (groupProvider.isCurrentUserAdmin &&
                            !_isUploadingImage)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF6750A4),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: _changeGroupImage,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            group.name ?? 'Group',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (groupProvider.isCurrentUserAdmin)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                setState(() => _isEditing = true);
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${groupProvider.currentGroupMembers.length} members',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        group.description!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Members Section
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Members',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (groupProvider.isCurrentUserAdmin)
                            TextButton.icon(
                              onPressed: () => _showAddMembersSheet(context),
                              icon: const Icon(
                                Icons.person_add,
                                color: Color(0xFF6750A4),
                              ),
                              label: const Text(
                                'Add',
                                style: TextStyle(color: Color(0xFF6750A4)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupProvider.currentGroupMembers.length,
                      itemBuilder: (context, index) {
                        final member = groupProvider.currentGroupMembers[index];
                        final user = member.user;
                        final isCurrentUser = member.userId == currentUserId;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE8DEF8),
                            backgroundImage: user?.profilePic != null
                                ? NetworkImage(user!.profilePic!)
                                : null,
                            child: user?.profilePic == null
                                ? Text(
                                    user != null ? _getUserInitials(user) : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF6750A4),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                user != null
                                    ? '${user.firstname ?? ''} ${user.lastname ?? ''}'
                                          .trim()
                                    : 'Unknown User',
                              ),
                              if (isCurrentUser)
                                const Text(
                                  ' (You)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                          subtitle: Text('@${user?.username ?? 'user'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (member.isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8DEF8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Color(0xFF6750A4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (groupProvider.isCurrentUserAdmin &&
                                  !isCurrentUser)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    _handleMemberAction(value, member);
                                  },
                                  itemBuilder: (context) => [
                                    if (!member.isAdmin)
                                      const PopupMenuItem(
                                        value: 'make_admin',
                                        child: Text('Make Admin'),
                                      ),
                                    if (member.isAdmin)
                                      const PopupMenuItem(
                                        value: 'remove_admin',
                                        child: Text('Remove Admin'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Text(
                                        'Remove from Group',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Actions Section
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.red),
                      title: const Text(
                        'Leave Group',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => _showLeaveGroupDialog(context),
                    ),
                    if (groupProvider.isCurrentUserAdmin) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          'Delete Group',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _showDeleteGroupDialog(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    final success = await context.read<GroupProvider>().updateGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated successfully')),
      );
    }
  }

  void _changeGroupImage() async {
    final groupProvider = context.read<GroupProvider>();

    setState(() => _isUploadingImage = true);

    try {
      // Pick image from gallery
      final imageFile = await groupProvider.pickGroupImage();
      if (imageFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      // Upload to Supabase
      final imageUrl = await groupProvider.uploadGroupImage(imageFile);

      if (imageUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group image updated successfully'),
            backgroundColor: Color(0xFF6750A4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update group image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showAddMembersSheet(BuildContext context) {
    // Load friends
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      context.read<FriendsProvider>().loadFriends(userId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(),
              Expanded(
                child: Consumer2<FriendsProvider, GroupProvider>(
                  builder: (context, friendsProvider, groupProvider, _) {
                    if (friendsProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter out users who are already members
                    final existingMemberIds = groupProvider.currentGroupMembers
                        .map((m) => m.userId)
                        .toSet();
                    final availableFriends = friendsProvider.friends
                        .where((f) => !existingMemberIds.contains(f.userId))
                        .toList();

                    if (availableFriends.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No friends to add',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: availableFriends.length,
                      itemBuilder: (context, index) {
                        final friend = availableFriends[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE8DEF8),
                            backgroundImage: friend.profilePic != null
                                ? NetworkImage(friend.profilePic!)
                                : null,
                            child: friend.profilePic == null
                                ? Text(
                                    _getUserInitials(friend),
                                    style: const TextStyle(
                                      color: Color(0xFF6750A4),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            '${friend.firstname ?? ''} ${friend.lastname ?? ''}'
                                .trim(),
                          ),
                          subtitle: Text('@${friend.username ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF6750A4),
                            ),
                            onPressed: () async {
                              final success = await groupProvider.addMember(
                                friend.userId,
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${friend.firstname} added to group',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMemberAction(String action, GroupMember member) async {
    final groupProvider = context.read<GroupProvider>();

    switch (action) {
      case 'make_admin':
        await groupProvider.updateMemberRole(
          userId: member.userId!,
          newRole: GroupRole.admin,
        );
        break;
      case 'remove_admin':
        await groupProvider.updateMemberRole(
          userId: member.userId!,
          newRole: GroupRole.member,
        );
        break;
      case 'remove':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${member.user?.firstname ?? 'this user'} from the group?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await groupProvider.removeMember(member.userId!);
        }
        break;
    }
  }

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<GroupProvider>().leaveGroup();
              if (success && mounted) {
                // Navigate to home and clear the navigation stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<GroupProvider>().errorMessage ??
                          'Failed to leave group',
                    ),
                  ),
                );
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<GroupProvider>().deleteGroup();
              if (success && mounted) {
                // Navigate to home and clear the navigation stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
