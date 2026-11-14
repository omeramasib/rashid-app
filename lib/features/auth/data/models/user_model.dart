import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.id,
    super.name,
    super.email,
    super.token,
    super.linkedinLinked,
  });

  /// Parse auth response JSON.
  ///
  /// Handles different response shapes:
  /// - Login response: { status, token, user: { id, name, email } }
  /// - Register response: { status, message, user_id }
  /// - Current user: { id, name, email, linkedin_linked }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;

    return UserModel(
      id: _string(userMap?['id'] ?? json['id'] ?? json['user_id']),
      name: _string(userMap?['name'] ?? json['name']),
      email: _string(userMap?['email'] ?? json['email']),
      token: _string(json['token']),
      linkedinLinked: userMap?['linkedin_linked'] == true ||
          json['linkedin_linked'] == true,
    );
  }

  static String? _string(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (token != null) 'token': token,
      'linkedin_linked': linkedinLinked,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    bool? linkedinLinked,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      linkedinLinked: linkedinLinked ?? this.linkedinLinked,
    );
  }
}
