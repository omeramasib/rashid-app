import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/auth/data/models/user_model.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';

void main() {
  const tUserModel = UserModel(
    id: 'test_id',
    name: 'Test User',
    email: 'test@test.com',
    token: 'test_token',
  );

  test('should be a subclass of User entity', () async {
    expect(tUserModel, isA<User>());
  });

  group('fromJson', () {
    test('should return a valid model from login response JSON', () async {
      // arrange - login response format
      final Map<String, dynamic> jsonMap = json.decode('''
        {
          "status": "success",
          "token": "test_token",
          "user": {
            "id": "test_id",
            "name": "Test User",
            "email": "test@test.com"
          }
        }
      ''');
      // act
      final result = UserModel.fromJson(jsonMap);
      // assert
      expect(result.id, 'test_id');
      expect(result.name, 'Test User');
      expect(result.email, 'test@test.com');
      expect(result.token, 'test_token');
    });

    test('should return a valid model from register response JSON', () async {
      // arrange - register response format (may not have token)
      final Map<String, dynamic> jsonMap = json.decode('''
        {
          "status": "success",
          "message": "Account created successfully",
          "user_id": "new_user_id"
        }
      ''');
      // act
      final result = UserModel.fromJson(jsonMap);
      // assert
      expect(result.id, 'new_user_id');
      expect(result.token, isNull);
    });

    test('should handle missing optional fields gracefully', () async {
      // arrange
      final Map<String, dynamic> jsonMap = json.decode('{"token": "only_token"}');
      // act
      final result = UserModel.fromJson(jsonMap);
      // assert
      expect(result.token, 'only_token');
      expect(result.id, isNull);
      expect(result.name, isNull);
      expect(result.email, isNull);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () async {
      // act
      final result = tUserModel.toJson();
      // assert
      expect(result['id'], 'test_id');
      expect(result['name'], 'Test User');
      expect(result['email'], 'test@test.com');
      expect(result['token'], 'test_token');
    });

    test('should not include null fields in JSON', () async {
      // arrange
      const partialModel = UserModel(token: 'only_token');
      // act
      final result = partialModel.toJson();
      // assert
      expect(result.containsKey('id'), false);
      expect(result.containsKey('name'), false);
      expect(result.containsKey('email'), false);
      expect(result['token'], 'only_token');
    });
  });

  group('copyWith', () {
    test('should create a copy with updated fields', () {
      // act
      final copy = tUserModel.copyWith(name: 'New Name');
      // assert
      expect(copy.name, 'New Name');
      expect(copy.id, tUserModel.id);
      expect(copy.email, tUserModel.email);
      expect(copy.token, tUserModel.token);
    });
  });

  group('hasToken', () {
    test('should return true when token is present', () {
      expect(tUserModel.hasToken, true);
    });

    test('should return false when token is null', () {
      const noTokenModel = UserModel(id: 'id');
      expect(noTokenModel.hasToken, false);
    });

    test('should return false when token is empty', () {
      const emptyTokenModel = UserModel(token: '');
      expect(emptyTokenModel.hasToken, false);
    });
  });
}
