import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Login with email and password
  /// POST /auth/login/email
  Future<UserModel> loginWithEmail(String email, String password);

  /// Register with email
  /// POST /auth/register/email
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Login with LinkedIn token (obtained from Clerk OAuth)
  /// POST /auth/login/linkedin
  Future<UserModel> loginWithLinkedIn(String linkedinToken);

  /// Register with LinkedIn token (obtained from Clerk OAuth)
  /// POST /auth/register/linkedin
  Future<UserModel> registerWithLinkedIn(String linkedinToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.loginEmailUrl),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    return _handleAuthResponse(response, 'Login failed');
  }

  @override
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.registerEmailUrl),
      headers: _headers,
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return _handleAuthResponse(response, 'Registration failed');
  }

  @override
  Future<UserModel> loginWithLinkedIn(String linkedinToken) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.loginLinkedInUrl),
      headers: _headers,
      body: json.encode({
        'linkedin_token': linkedinToken,
      }),
    );

    return _handleAuthResponse(response, 'LinkedIn login failed');
  }

  @override
  Future<UserModel> registerWithLinkedIn(String linkedinToken) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.registerLinkedInUrl),
      headers: _headers,
      body: json.encode({
        'linkedin_token': linkedinToken,
      }),
    );

    return _handleAuthResponse(response, 'LinkedIn registration failed');
  }

  /// Handles auth response parsing consistently
  UserModel _handleAuthResponse(http.Response response, String defaultError) {
    print(
        'DEBUG: AuthRemoteDataSource - Response status: ${response.statusCode}');
    print('DEBUG: AuthRemoteDataSource - Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        return UserModel.fromJson(jsonResponse);
      } else {
        throw ServerException(jsonResponse['message'] ?? defaultError);
      }
    } else {
      // Try to extract error message from response body
      try {
        final jsonResponse = json.decode(response.body);
        // FastAPI uses 'detail', other backends use 'message'
        final errorMessage = jsonResponse['detail'] ??
            jsonResponse['message'] ??
            jsonResponse['error'] ??
            defaultError;
        throw ServerException('$errorMessage');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException('$defaultError (${response.statusCode})');
      }
    }
  }
}
