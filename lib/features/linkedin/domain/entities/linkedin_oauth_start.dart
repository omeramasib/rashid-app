import 'package:equatable/equatable.dart';

class LinkedInOAuthStart extends Equatable {
  final String authorizationUrl;
  final DateTime? expiresAt;

  const LinkedInOAuthStart({
    required this.authorizationUrl,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [authorizationUrl, expiresAt];
}
