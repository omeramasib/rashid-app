import 'package:equatable/equatable.dart';

class LinkedInAccount extends Equatable {
  final String linkedinProfileId;
  final String name;
  final String email;

  const LinkedInAccount({
    required this.linkedinProfileId,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [linkedinProfileId, name, email];
}
