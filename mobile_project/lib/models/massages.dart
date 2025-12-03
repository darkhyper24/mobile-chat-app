class Message {
  final String messageId;
  final DateTime? createdAt;
  final String? senderId;
  final String? receiverId;
  final String? message;
  final String? image;
  final String? groupId;

  Message({
    required this.messageId,
    this.createdAt,
    this.senderId,
    this.receiverId,
    this.message,
    this.image,
    this.groupId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      message: json['message'] as String?,
      image: json['image'] as String?,
      groupId: json['group_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'created_at': createdAt?.toIso8601String(),
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'image': image,
      'group_id': groupId,
    };
  }
}