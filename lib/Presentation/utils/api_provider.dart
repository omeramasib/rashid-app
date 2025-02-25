import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:rashed_app/Presentation/utils/api_endpoints.dart';

import 'errorMessageKeysAndCodes.dart';
import 'injection_container.dart';

class ApiException implements Exception {
  String errorMessage;

  ApiException(this.errorMessage);

  @override
  String toString() {
    return errorMessage;
  }
}

class ApiProvider {
  final apiEndpoints = locator<ApiEndpoints>();
  final String baseUrl = ApiEndpoints.baseUrl;

  static Future<Map<String, dynamic>> headers() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final String token = await storage.read(key: "token") ?? "";
    if (kDebugMode) {
      log("token is: $token");
    }
    return {"Auth": "Bearer $token"};
  }

  static Future<Map<String, dynamic>> multipartHeaders() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final String token = await storage.read(key: "token") ?? "";
    if (kDebugMode) {
      log("token is: $token");
    }
    return {
      "Auth": "Bearer $token",
      "Content-Type": "multipart/form-data",
    };
  }

  Future<Map<String, dynamic>> login({
    required Map<String, dynamic> body,
    required String url,
    CancelToken? cancelToken,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      final formatedBody = json.encode(body);
      if (kDebugMode) {
        log("API Called POST: $url");
        log("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: formatedBody,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.acceptHeader: "application/json",
          },
        ),
      );

      if (kDebugMode) {
        log("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response!.statusMessage!.contains('Timeout')) {
        throw ApiException(ErrorMessageKeysAndCode.timeOut);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }

      if (e.response?.statusCode == 400) {
        throw ApiException(ErrorMessageKeysAndCode.invalidLogInCredentialsKey);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.invalidLogInCredentialsKey,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

    Future<Map<String, dynamic>> register({
    required Map<String, dynamic> body,
    required String url,
    CancelToken? cancelToken,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      final formatedBody = json.encode(body);
      if (kDebugMode) {
        log("API Called POST: $url");
        log("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: formatedBody,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.acceptHeader: "application/json",
          },
        ),
      );

      if (kDebugMode) {
        log("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response!.statusMessage!.contains('Timeout')) {
        throw ApiException(ErrorMessageKeysAndCode.timeOut);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }

      if (e.response?.statusCode == 400) {
        throw ApiException(ErrorMessageKeysAndCode.userAlreadyExist);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.userAlreadyExist,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required Map<String, dynamic> body,
    required String url,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      if (kDebugMode) {
        log("API Called POST: $url");
        log("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: body,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );

      if (kDebugMode) {
        log("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response!.statusMessage!.contains('Timeout')) {
        throw ApiException(ErrorMessageKeysAndCode.timeOut);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }

      if (e.response?.statusCode == 400) {
        throw ApiException(ErrorMessageKeysAndCode.invalidFileNo);
      }

      if (e.response?.statusCode == 422) {
        throw ApiException(ErrorMessageKeysAndCode.invalidFileNo);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.invalidFileNo,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required Map<String, dynamic> body,
    required String url,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      if (kDebugMode) {
        log("API Called POST: $url");
        log("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: body,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );

      if (kDebugMode) {
        log("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response!.statusMessage!.contains('Timeout')) {
        throw ApiException(ErrorMessageKeysAndCode.timeOut);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }

      if (e.response?.statusCode == 400) {
        throw ApiException(ErrorMessageKeysAndCode.invalidLogInCredentialsKey);
      }

      if (e.response?.statusCode == 422) {
        throw ApiException(ErrorMessageKeysAndCode.otpCodeInvalidOrExpired);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.otpCodeInvalidOrExpired,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required Map<String, dynamic> body,
    required String url,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      if (kDebugMode) {
        log("API Called POST: $url");
        log("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: body,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );

      if (kDebugMode) {
        log("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response!.statusMessage!.contains('Timeout')) {
        throw ApiException(ErrorMessageKeysAndCode.timeOut);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }

      if (e.response?.statusCode == 400) {
        throw ApiException(ErrorMessageKeysAndCode.invalidFileNo);
      }

      if (e.response?.statusCode == 422) {
        throw ApiException(ErrorMessageKeysAndCode.invalidFileNo);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.invalidFileNo,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  Future<Map<String, dynamic>> post({
    required Map<String, dynamic> body,
    required String url,
    required bool useAuthToken,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      if (kDebugMode) {
        log("API Called POST: $url");
        log("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: body,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        options: useAuthToken ? Options(headers: await headers()) : null,
      );

      if (kDebugMode) {
        log("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response!.statusMessage!.contains('Timeout')) {
        throw ApiException(ErrorMessageKeysAndCode.timeOut);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }

      if (e.response?.statusCode == 400) {
        throw ApiException(ErrorMessageKeysAndCode.invalidData);
      }

      if (e.response?.statusCode == 422) {
        throw ApiException(ErrorMessageKeysAndCode.validationError);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.invalidData,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  Future<Map<String, dynamic>> addLetterRequest({
    required String url,
    required Map<String, dynamic> formValues,
    required String fileFieldName,
  }) async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    // Prepare the erp_ticket_data
    List<Map<String, dynamic>> erpTicketData = [
      {
        'erp_ticket_data_type': 'text',
        'erp_ticket_data_name': formValues['erp_ticket_title'],
        'erp_ticket_data_value': formValues['erp_ticket_text'],
      },
      {
        'erp_ticket_data_type': 'text',
        'erp_ticket_data_name': 'notes',
        'erp_ticket_data_value': formValues['erp_ticket_notes'],
      },
      {
        'erp_ticket_data_type': 'text',
        'erp_ticket_data_name': 'Salary including',
        'erp_ticket_data_value': formValues['salary_included'],
      },
    ];

    // Prepare files to send
    List<File> fileList = formValues[fileFieldName] ?? [];
    List<http.MultipartFile> multipartFiles = [];
    for (var file in fileList) {
      multipartFiles.add(
        await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
          filename: file.path.split('/').last,
        ),
      );
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      final token = await secureStorage.read(key: 'token');
      if (token != null) {
        request.headers['Auth'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
      }

      request.fields['erp_ticket_title'] = formValues['erp_ticket_title'];
      request.fields['ui_widget_id'] = formValues['ui_widget_id'];
      request.fields['erp_ticket_text'] = formValues['erp_ticket_text'];

      // request.fields['erp_ticket_data'] = jsonEncode(erpTicketData);

      for (int i = 0; i < erpTicketData.length; i++) {
        request.fields['erp_ticket_data[$i][erp_ticket_daـta_type]'] =
            erpTicketData[i]['erp_ticket_data_type'];
        request.fields['erp_ticket_data[$i][erp_ticket_data_name]'] =
            erpTicketData[i]['erp_ticket_data_name'];
        request.fields['erp_ticket_data[$i][erp_ticket_data_value]'] =
            erpTicketData[i]['erp_ticket_data_value'];
      }

      // print the request before sending the request
      log(request.fields.toString());

      // Add files
      request.files.addAll(multipartFiles);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
            'Failed with status code ${response.statusCode}. Response: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  Future<Map<String, dynamic>> get({
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Dio dio = Dio();
      if (kDebugMode) {
        log("API Called GET: $url with $queryParameters");
      }

      final response = await dio.get(
        url,
        queryParameters: queryParameters,
        options: useAuthToken ? Options(headers: await headers()) : null,
      );

      if (kDebugMode) {
        log('Response: ${response.data}');
        log('Full response: $response');
      }

      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorKey);
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : e.message!,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
