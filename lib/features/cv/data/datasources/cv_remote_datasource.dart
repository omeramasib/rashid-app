import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/cv_profile.dart';
import '../models/cv_analysis_result_model.dart';
import '../models/cv_model.dart';
import '../models/cv_profile_model.dart';

abstract class CvRemoteDataSource {
  Future<CvModel> uploadCv({
    required Uint8List bytes,
    required String fileName,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  });

  Future<CvAnalysisResultModel> analyzeCv(
    String cvId, {
    required CancelToken cancelToken,
  });

  Future<void> updateSkills(List<String> skills);

  Future<void> deleteSkill(String skill);

  /// Null means the account has no CV. Failures throw; they are not "no CV".
  Future<CvProfile?> getMyCvProfile();
}

class CvRemoteDataSourceImpl implements CvRemoteDataSource {
  final DioClient client;

  CvRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<CvModel> uploadCv({
    required Uint8List bytes,
    required String fileName,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });
      final response = await _dio.post(
        ApiEndpoints.cvUpload,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerException('Unexpected upload response');
      }
      return CvModel.fromJson(data);
    } on DioException catch (e) {
      throw _exception(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CvAnalysisResultModel> analyzeCv(
    String cvId, {
    required CancelToken cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.cvAnalyze,
        data: {'cv_id': cvId},
        cancelToken: cancelToken,
        options: Options(
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 150),
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerException('Unexpected analysis response');
      }
      return CvAnalysisResultModel.fromJson(data);
    } on DioException catch (e) {
      throw _exception(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateSkills(List<String> skills) async {
    try {
      await _dio.put(
        ApiEndpoints.cvUpdateSkills,
        data: {'skills': skills},
      );
    } on DioException catch (e) {
      throw _exception(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CvProfile?> getMyCvProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.cvMe);
      return CvProfileModel.parse(response.data);
    } on DioException catch (e) {
      throw _exception(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteSkill(String skill) async {
    try {
      await _dio.delete(
        ApiEndpoints.cvDeleteSkill,
        data: {'skill': skill},
      );
    } on DioException catch (e) {
      throw _exception(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  AppException _exception(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return RequestCancelledException('Request cancelled');
    }
    final mapped = error.error;
    if (mapped is AppException) return mapped;
    return ServerException(error.message ?? 'Unknown error');
  }
}
