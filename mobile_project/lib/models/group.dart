class Group {
  final String groupId;
  final DateTime? createdAt;
  final String? name;
  final String? image;
  final String? description;

  Group({
    required this.groupId,
    this.createdAt,
    this.name,
    this.image,
    this.description,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      name: json['name'] as String?,
      image: json['image'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'created_at': createdAt?.toIso8601String(),
      'name': name,
      'image': image,
      'description': description,
    };
  }
}