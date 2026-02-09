import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.loginUrl),
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'sucsses') {
        return UserModel.fromJson(jsonResponse);
      } else {
        throw ServerException(jsonResponse['message'] ?? 'Login failed');
      }
    } else {
      throw ServerException('Server Error');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.registerUrl),
      body: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'sucsses') {
        return UserModel.fromJson(jsonResponse);
      } else {
        throw ServerException(jsonResponse['message'] ?? 'Registration failed');
      }
    } else {
      throw ServerException('Server Error');
    }
  }
}
