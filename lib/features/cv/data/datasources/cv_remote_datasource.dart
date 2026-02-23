import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/cv_model.dart';
import '../models/cv_analysis_result_model.dart';

abstract class CvRemoteDataSource {
  Future<CvModel> uploadCv(String filePath, String fileName);
  Future<CvAnalysisResultModel> analyzeCv(String cvId);
  Future<void> updateSkills(List<String> skills);
  Future<void> deleteSkill(String skill);
}

class CvRemoteDataSourceImpl implements CvRemoteDataSource {
  final DioClient client;

  CvRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<CvModel> uploadCv(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post(ApiEndpoints.cvUpload, data: formData);
      return CvModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CvAnalysisResultModel> analyzeCv(String cvId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.cvAnalyze,
        data: {'cv_id': cvId},
      );
      return CvAnalysisResultModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
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
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteSkill(String skill) async {
    try {
      await _dio.delete(
        ApiEndpoints.cvDeleteSkill,
        // The implementation plan implies data payload: {'skill': skill}
        data: {'skill': skill},
      );
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
