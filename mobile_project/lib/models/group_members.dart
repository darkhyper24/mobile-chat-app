import 'users.dart';

/// Represents a member's role in a group
enum GroupRole {
  admin,
  member;

  static GroupRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return GroupRole.admin;
      default:
        return GroupRole.member;
    }
  }

  String toJson() => name;
}

class GroupMember {
  final String id;
  final DateTime? joinedAt;
  final String? userId;
  final String? groupId;
  final GroupRole role;
  final User? user; // Populated when fetching with user data

  GroupMember({
    required this.id,
    this.joinedAt,
    this.userId,
    this.groupId,
    this.role = GroupRole.member,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      userId: json['user_id'] as String?,
      groupId: json['group_id'] as String?,
      role: GroupRole.fromString(json['role'] as String?),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'joined_at': joinedAt?.toIso8601String(),
      'user_id': userId,
      'group_id': groupId,
      'role': role.toJson(),
    };
  }

  /// Check if this member is an admin
  bool get isAdmin => role == GroupRole.admin;

  /// Create a copy with updated fields
  GroupMember copyWith({
    String? id,
    DateTime? joinedAt,
    String? userId,
    String? groupId,
    GroupRole? role,
    User? user,
  }) {
    return GroupMember(
      id: id ?? this.id,
      joinedAt: joinedAt ?? this.joinedAt,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }
}
