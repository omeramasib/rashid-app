import '../../domain/entities/linkedin_account.dart';

class LinkedInAccountModel extends LinkedInAccount {
  const LinkedInAccountModel({
    required super.linkedinProfileId,
    required super.name,
    required super.email,
  });

  factory LinkedInAccountModel.fromJson(Map<String, dynamic> json) {
    return LinkedInAccountModel(
      linkedinProfileId: json['linkedin_profile_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkedin_profile_id': linkedinProfileId,
      'name': name,
      'email': email,
    };
  }
}
