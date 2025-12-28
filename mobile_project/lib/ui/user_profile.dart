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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(color: Color(0xFF6750A4)),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile Picture
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
                    icon: Icons.person,
                    label: 'First Name',
                    value: user.firstname ?? 'Not set',
                  ),
                  const SizedBox(height: 16),

                  // Last Name Field
                  _buildReadOnlyField(
                    icon: Icons.person_outline,
                    label: 'Last Name',
                    value: user.lastname ?? 'Not set',
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  _buildReadOnlyField(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: user.username ?? 'Not set',
                  ),
                  const SizedBox(height: 16),

                  // About/Bio Field
                  _buildReadOnlyField(
                    icon: Icons.info_outline,
                    label: 'About',
                    value: (user.bio != null && user.bio!.isNotEmpty)
                        ? user.bio!
                        : "Hey there! I'm using ZC Chat App",
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  _buildReadOnlyField(
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
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isNotSet = value == 'Not set';
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isNotSet ? Colors.grey.shade400 : Colors.black,
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
