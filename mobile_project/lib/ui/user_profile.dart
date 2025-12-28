import 'package:flutter/material.dart';
import '../models/users.dart';

class UserProfilePage extends StatelessWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final primaryColor = const Color(0xFF6750A4);
    final avatarBgColor = isDark ? const Color(0xFF3E3253) : Colors.white;
    final avatarTextColor = isDark ? const Color(0xFFD0BCFF) : primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: avatarBgColor,
                    backgroundImage: user.profilePic != null
                        ? NetworkImage(user.profilePic!)
                        : null,
                    child: user.profilePic == null
                        ? Text(
                            _getInitials(user),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: avatarTextColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  Text(
                    '${user.firstname ?? ''} ${user.lastname ?? ''}'
                            .trim()
                            .isEmpty
                        ? 'Unknown User'
                        : '${user.firstname ?? ''} ${user.lastname ?? ''}'
                              .trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Username
                  Text(
                    '@${user.username ?? 'user'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                  _buildReadOnlyField(
                    context: context,
                    icon: Icons.person,
                    label: 'First Name',
                    value: user.firstname ?? 'Not set',
                  ),
                  const SizedBox(height: 16),

                  // Last Name Field
                  _buildReadOnlyField(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Last Name',
                    value: user.lastname ?? 'Not set',
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  _buildReadOnlyField(
                    context: context,
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: user.username ?? 'Not set',
                  ),
                  const SizedBox(height: 16),

                  // About/Bio Field
                  _buildReadOnlyField(
                    context: context,
                    icon: Icons.info_outline,
                    label: 'About',
                    value: (user.bio != null && user.bio!.isNotEmpty)
                        ? user.bio!
                        : "Hey there! I'm using ZC Chat App",
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  _buildReadOnlyField(
                    context: context,
                    icon: Icons.phone,
                    label: 'Phone',
                    value: user.phoneNumber ?? 'Not set',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : Colors.black;
    final primaryColor = isDark
        ? const Color(0xFFD0BCFF)
        : const Color(0xFF6750A4);

    final isNotSet = value == 'Not set';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isNotSet ? Colors.grey.shade400 : textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
