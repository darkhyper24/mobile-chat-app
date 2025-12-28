import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/friends_provider.dart';
import '../models/users.dart';
import '../services/group_service.dart';
import 'group_chat.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isLoading = false;
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      context.read<FriendsProvider>().loadFriends(userId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final groupProvider = context.read<GroupProvider>();

      // Create the group first (without image)
      final group = await groupProvider.createGroup(
        name: _nameController.text.trim(),
        creatorId: userId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        initialMemberIds: _selectedMemberIds.toList(),
      );

      if (group != null) {
        // Upload image if selected
        if (_selectedImageFile != null) {
          await groupProvider.uploadGroupImageForGroup(
            groupId: group.groupId,
            imageFile: _selectedImageFile!,
          );
        }

        if (mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatPage(group: group),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Group',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      color: Color(0xFF6750A4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Image Preview
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE8DEF8),
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : null,
                    child: _isUploadingImage
                        ? const CircularProgressIndicator(
                            color: Color(0xFF6750A4),
                          )
                        : _selectedImageBytes == null
                        ? const Icon(
                            Icons.group,
                            size: 40,
                            color: Color(0xFF6750A4),
                          )
                        : null,
                  ),
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
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Group Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group Name *',
                hintText: 'Enter group name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6750A4),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'What is this group about?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6750A4),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add Members Section
            const Text(
              'Add Members',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Select friends to add to the group',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Selected Members Chips
            if (_selectedMemberIds.isNotEmpty)
              Consumer<FriendsProvider>(
                builder: (context, friendsProvider, _) {
                  final selectedFriends = friendsProvider.friends
                      .where((f) => _selectedMemberIds.contains(f.userId))
                      .toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedFriends.map((friend) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: const Color(0xFFE8DEF8),
                          backgroundImage: friend.profilePic != null
                              ? NetworkImage(friend.profilePic!)
                              : null,
                          child: friend.profilePic == null
                              ? Text(
                                  _getInitials(friend),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        label: Text(
                          '${friend.firstname ?? ''} ${friend.lastname ?? ''}'
                              .trim(),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedMemberIds.remove(friend.userId);
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Friends List
            Consumer<FriendsProvider>(
              builder: (context, friendsProvider, _) {
                if (friendsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (friendsProvider.friends.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No friends to add',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friendsProvider.friends.length,
                  itemBuilder: (context, index) {
                    final friend = friendsProvider.friends[index];
                    final isSelected = _selectedMemberIds.contains(
                      friend.userId,
                    );

                    return ListTile(
                      leading: CircleAvatar(
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
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        '${friend.firstname ?? ''} ${friend.lastname ?? ''}'
                            .trim(),
                      ),
                      subtitle: Text('@${friend.username ?? ''}'),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedMemberIds.add(friend.userId);
                            } else {
                              _selectedMemberIds.remove(friend.userId);
                            }
                          });
                        },
                        activeColor: const Color(0xFF6750A4),
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMemberIds.remove(friend.userId);
                          } else {
                            _selectedMemberIds.add(friend.userId);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final groupService = GroupService();
      final image = await groupService.pickImageFromGallery();
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }
}
