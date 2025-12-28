import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../models/users.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isEditingFirstname = false;
  bool _isEditingLastname = false;
  bool _isEditingPhone = false;
  bool _isEditingBio = false;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _firstnameController.text = user.firstname ?? '';
      _lastnameController.text = user.lastname ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateField(String field, String value) async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? result;

      switch (field) {
        case 'firstname':
          result = await _userService.updateProfile(
            userId: userId,
            firstname: value,
          );
          break;
        case 'lastname':
          result = await _userService.updateProfile(
            userId: userId,
            lastname: value,
          );
          break;
        case 'phone':
          result = await _userService.updateProfile(
            userId: userId,
            phoneNumber: value,
          );
          break;
        case 'bio':
          result = await _userService.updateProfile(
            userId: userId,
            bio: value,
          );
          break;
      }

      if (result != null && mounted) {
        // Update the provider with new data
        await context.read<AuthProvider>().checkAuthStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Color(0xFF6750A4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditingFirstname = false;
          _isEditingLastname = false;
          _isEditingPhone = false;
          _isEditingBio = false;
        });
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    try {
      // Pick image from gallery
      final image = await _userService.pickImageFromGallery();
      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to Supabase
      final imageUrl = await _userService.uploadProfilePicture(
        userId: userId,
        imageFile: image,
      );

      if (imageUrl != null && mounted) {
        // Refresh user data
        await context.read<AuthProvider>().checkAuthStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Color(0xFF6750A4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6750A4)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header with gradient background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6750A4),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Profile Picture
                      GestureDetector(
                        onTap: _changeProfilePicture,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: user.profilePic != null
                                  ? NetworkImage(user.profilePic!)
                                  : null,
                              child: user.profilePic == null
                                  ? Text(
                                      _getInitials(user),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6750A4),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6750A4),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF6750A4),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Profile Information
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Name Field
                      _buildProfileField(
                        icon: Icons.person,
                        label: 'Name',
                        controller: _firstnameController,
                        isEditing: _isEditingFirstname,
                        onEditPressed: () {
                          setState(() => _isEditingFirstname = true);
                        },
                        onSavePressed: () {
                          _updateField('firstname', _firstnameController.text);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Name Field
                      _buildProfileField(
                        icon: Icons.person_outline,
                        label: 'Last Name',
                        controller: _lastnameController,
                        isEditing: _isEditingLastname,
                        onEditPressed: () {
                          setState(() => _isEditingLastname = true);
                        },
                        onSavePressed: () {
                          _updateField('lastname', _lastnameController.text);
                        },
                      ),
                      const SizedBox(height: 16),

                      // About/Bio Field
                      _buildProfileField(
                        icon: Icons.info_outline,
                        label: 'About',
                        controller: _bioController,
                        isEditing: _isEditingBio,
                        onEditPressed: () {
                          setState(() => _isEditingBio = true);
                        },
                        onSavePressed: () {
                          _updateField('bio', _bioController.text);
                        },
                        placeholder: "Hey there! I'm using ZC Chat App",
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      _buildProfileField(
                        icon: Icons.phone,
                        label: 'Phone',
                        controller: _phoneController,
                        isEditing: _isEditingPhone,
                        onEditPressed: () {
                          setState(() => _isEditingPhone = true);
                        },
                        onSavePressed: () {
                          _updateField('phone', _phoneController.text);
                        },
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6750A4)),
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

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      // Navigate to Messages/Home page
      Navigator.pop(context);
    } else if (index == 1) {
      // Navigate to Friends page
      Navigator.pop(context);
      Navigator.pushNamed(context, '/friends');
    } else if (index == 2) {
      // Navigate to Settings page
      Navigator.pop(context);
      Navigator.pushNamed(context, '/settings');
    }
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditPressed,
    required VoidCallback onSavePressed,
    TextInputType? keyboardType,
    String placeholder = 'Not set',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6750A4), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        controller.text.isEmpty ? placeholder : controller.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: controller.text.isEmpty
                              ? Colors.grey.shade400
                              : Colors.black,
                        ),
                      ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF6750A4),
              size: 20,
            ),
            onPressed: isEditing ? onSavePressed : onEditPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6750A4), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}
