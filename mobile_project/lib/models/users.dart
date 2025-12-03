class User {
  final String userId;
  final String? firstname;
  final String? lastname;
  final String? username;
  final String? email;
  final String? profilePic;
  final DateTime? createdAt;
  final String? bio;
  final String? phoneNumber;
  final String? gender;

  User({
    required this.userId,
    this.firstname,
    this.lastname,
    this.username,
    this.email,
    this.profilePic,
    this.createdAt,
    this.bio,
    this.phoneNumber,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as String,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      profilePic: json['profile_pic'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      bio: json['bio'] as String?,
      phoneNumber: json['phone_number'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'firstname': firstname,
      'lastname': lastname,
      'username': username,
      'email': email,
      'profile_pic': profilePic,
      'created_at': createdAt?.toIso8601String(),
      'bio': bio,
      'phone_number': phoneNumber,
      'gender': gender,
    };
  }
}