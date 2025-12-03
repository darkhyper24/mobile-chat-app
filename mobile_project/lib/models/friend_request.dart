class FriendRequest {
  final String id;
  final DateTime? createdAt;
  final String? senderId;
  final String? receiverId;
  final String? status;

  FriendRequest({
    required this.id,
    this.createdAt,
    this.senderId,
    this.receiverId,
    this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
    };
  }
}