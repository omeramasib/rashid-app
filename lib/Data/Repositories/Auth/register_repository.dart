import 'dart:developer';
import '../../../Presentation/utils/api_endpoints.dart';
import '../../../Presentation/utils/api_provider.dart';
import '../../../Presentation/utils/injection_container.dart';


class RegisterRepository {
  final apiEndpoints = locator<ApiEndpoints>();
  final apiProvider = locator<ApiProvider>();
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // final fcmToken = await FirebaseMessaging.instance.getToken();
      final body = {
        "name": name,
        "email": email,
        "password": password,
      };

      final result = await apiProvider.register(
        body: body,
        url: apiEndpoints.registerUrl,
      );

      if (result.containsKey('status') && result['status'] == "sucsses") {
        return {
          "status": result['status'],
          "message": result['message'],
          "token": result['token'],
        };
      } else {
        log('Unexpected result structure or register failed.');
        throw ApiException('Unexpected response structure or failed register');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}