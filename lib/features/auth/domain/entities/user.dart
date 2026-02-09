import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String token;
  // Add other user properties here as needed, based on the API response.
  // For now, based on the current login response, we primarily get a token.
  // We can expand this model as we inspect the full API response.

  const User({required this.token});

  @override
  List<Object?> get props => [token];
}
