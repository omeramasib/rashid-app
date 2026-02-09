import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/auth/data/models/user_model.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';

void main() {
  const tUserModel = UserModel(token: 'test_token');

  test('should be a subclass of User entity', () async {
    expect(tUserModel, isA<User>());
  });

  group('fromJson', () {
    test('should return a valid model when the JSON is valid', () async {
      // arrange
      final Map<String, dynamic> jsonMap =
          json.decode('{"token": "test_token"}');
      // act
      final result = UserModel.fromJson(jsonMap);
      // assert
      expect(result, tUserModel);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () async {
      // act
      final result = tUserModel.toJson();
      // assert
      final expectedMap = {
        "token": "test_token",
      };
      expect(result, expectedMap);
    });
  });
}
