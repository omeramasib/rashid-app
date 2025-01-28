// import 'dart:developer';


// import '../../../Presentation/utils/api_endpoints.dart';
// import '../../../Presentation/utils/api_provider.dart';
// import '../../../Presentation/utils/injection_container.dart';


// class LoginRepository {
//   final apiEndpoints = locator<ApiEndpoints>();
//   final apiProvider = locator<ApiProvider>();
//   Future<Map<String, dynamic>> login({
//     required String employeeFileNo,
//     required String password,
//   }) async {
//     try {
//       final fcmToken = await FirebaseMessaging.instance.getToken();
//       final body = {
//         "erp_emp_file_no": employeeFileNo,
//         "password": password,
//         "fcm_token": fcmToken ?? '',
//       };

//       final result = await apiProvider.login(
//         body: body,
//         url: apiEndpoints.loginUrl,
//       );

//       if (result.containsKey('status') && result['status'] == true) {
//         return {
//           "status": result['status'],
//           "token": result['data']['access_token'],
//           "message": result['message'],
//         };
//       } else {
//         log('Unexpected result structure or login failed.');
//         throw ApiException('Unexpected response structure or failed login');
//       }
//     } catch (e) {
//       throw ApiException(e.toString());
//     }
//   }
// }
