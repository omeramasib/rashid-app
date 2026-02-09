import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.token});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(token: json['token']);
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}
