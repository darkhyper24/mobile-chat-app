enum MessageType {
  text,
  location,
}

class Message {
  final String messageId;
  final DateTime? createdAt;
  final String? senderId;
  final String? receiverId;
  final String? message;
  final String? image;
  final String? groupId;
  final double? latitude;
  final double? longitude;
  final MessageType messageType;

  Message({
    required this.messageId,
    this.createdAt,
    this.senderId,
    this.receiverId,
    this.message,
    this.image,
    this.groupId,
    this.latitude,
    this.longitude,
    this.messageType = MessageType.text,
  });

  /// Check if this message is a location message
  bool get isLocation => messageType == MessageType.location && latitude != null && longitude != null;

  /// Get Google Maps URL for this location
  String? get googleMapsUrl {
    if (!isLocation) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Determine message type based on presence of coordinates
    final lat = json['latitude'] as num?;
    final lng = json['longitude'] as num?;
    final hasLocation = lat != null && lng != null;
    
    return Message(
      messageId: (json['message_id'] ?? json['id'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      message: json['massage'] as String?,
      image: json['image'] as String?,
      groupId: json['group_id'] as String?,
      latitude: lat?.toDouble(),
      longitude: lng?.toDouble(),
      messageType: hasLocation ? MessageType.location : MessageType.text,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'created_at': createdAt?.toIso8601String(),
      'sender_id': senderId,
      'receiver_id': receiverId,
      'massage': message,
      'image': image,
      'group_id': groupId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
