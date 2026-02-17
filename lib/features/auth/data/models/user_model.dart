import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.id,
    super.name,
    super.email,
    super.token,
  });

  /// Parse auth response JSON.
  /// 
  /// Handles different response shapes:
  /// - Login response: { status, token, user: { id, name, email } }
  /// - Register response: { status, message, user_id }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user object (login responses)
    final userMap = json['user'] as Map<String, dynamic>?;
    
    return UserModel(
      id: userMap?['id'] ?? json['user_id'],
      name: userMap?['name'],
      email: userMap?['email'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (token != null) 'token': token,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
    );
  }
}
