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
          result = await _userService.updateProfile(userId: userId, bio: value);
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : Colors.white,
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
                      // Profile Picture with animation
                      GestureDetector(
                        onTap: _changeProfilePicture,
                        child: _AnimatedProfilePicture(
                          profilePic: user.profilePic,
                          initials: _getInitials(user),
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
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFD0BCFF)
            : const Color(0xFF6750A4),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        enableFeedback: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
    return _AnimatedProfileField(
      icon: icon,
      label: label,
      controller: controller,
      isEditing: isEditing,
      onEditPressed: onEditPressed,
      onSavePressed: onSavePressed,
      keyboardType: keyboardType,
      placeholder: placeholder,
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

/// Animated profile field with smooth transitions
class _AnimatedProfileField extends StatefulWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final TextInputType? keyboardType;
  final String placeholder;

  const _AnimatedProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.onEditPressed,
    required this.onSavePressed,
    this.keyboardType,
    this.placeholder = 'Not set',
  });

  @override
  State<_AnimatedProfileField> createState() => _AnimatedProfileFieldState();
}

class _AnimatedProfileFieldState extends State<_AnimatedProfileField> {
  double _buttonScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isEditing ? const Color(0xFF6750A4) : borderColor,
          width: widget.isEditing ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.icon,
              color: isDark ? const Color(0xFFD0BCFF) : const Color(0xFF6750A4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: widget.isEditing
                      ? TextField(
                          key: const ValueKey('editing'),
                          controller: widget.controller,
                          autofocus: true,
                          keyboardType: widget.keyboardType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          widget.controller.text.isEmpty
                              ? widget.placeholder
                              : widget.controller.text,
                          key: const ValueKey('display'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: widget.controller.text.isEmpty
                                ? subtitleColor
                                : textColor,
                          ),
                        ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTapDown: (_) => setState(() => _buttonScale = 0.85),
            onTapUp: (_) {
              setState(() => _buttonScale = 1.0);
              widget.isEditing
                  ? widget.onSavePressed()
                  : widget.onEditPressed();
            },
            onTapCancel: () => setState(() => _buttonScale = 1.0),
            child: AnimatedScale(
              scale: _buttonScale,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(widget.isEditing),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    widget.isEditing ? Icons.check : Icons.edit,
                    color: isDark
                        ? const Color(0xFFD0BCFF)
                        : const Color(0xFF6750A4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated profile picture with tap feedback
class _AnimatedProfilePicture extends StatefulWidget {
  final String? profilePic;
  final String initials;

  const _AnimatedProfilePicture({
    required this.profilePic,
    required this.initials,
  });

  @override
  State<_AnimatedProfilePicture> createState() =>
      _AnimatedProfilePictureState();
}

class _AnimatedProfilePictureState extends State<_AnimatedProfilePicture> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: widget.profilePic != null
                  ? NetworkImage(widget.profilePic!)
                  : null,
              child: widget.profilePic == null
                  ? Text(
                      widget.initials,
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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
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
            ),
          ],
        ),
      ),
    );
  }
}
