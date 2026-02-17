import 'package:equatable/equatable.dart';

/// User entity representing authenticated user data.
/// 
/// Different auth endpoints return different fields:
/// - Login (email/LinkedIn): returns token + user info
/// - Register (email): may return only user_id and message
/// - Register (LinkedIn): may return token + user info
class User extends Equatable {
  final String? id;
  final String? name;
  final String? email;
  final String? token;

  const User({
    this.id,
    this.name,
    this.email,
    this.token,
  });

  /// Check if user has a valid token for authenticated requests
  bool get hasToken => token != null && token!.isNotEmpty;

  @override
  List<Object?> get props => [id, name, email, token];
}
