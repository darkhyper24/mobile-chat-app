class Friend {
  final String id;
  final DateTime? createdAt;
  final String? userId;
  final String? friendId;

  Friend({
    required this.id,
    this.createdAt,
    this.userId,
    this.friendId,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userId: json['user_id'] as String?,
      friendId: json['friend_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'user_id': userId,
      'friend_id': friendId,
    };
  }
}