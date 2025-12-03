class GroupMember {
  final String id;
  final DateTime? joinedAt;
  final String? userId;
  final String? groupId;

  GroupMember({
    required this.id,
    this.joinedAt,
    this.userId,
    this.groupId,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      userId: json['user_id'] as String?,
      groupId: json['group_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'joined_at': joinedAt?.toIso8601String(),
      'user_id': userId,
      'group_id': groupId,
    };
  }
}