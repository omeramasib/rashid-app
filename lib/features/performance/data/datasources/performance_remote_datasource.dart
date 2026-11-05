import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/performance_summary_model.dart';

abstract class PerformanceRemoteDataSource {
  Future<PerformanceSummaryModel> getSummary();
}

class PerformanceRemoteDataSourceImpl implements PerformanceRemoteDataSource {
  final DioClient client;

  PerformanceRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<PerformanceSummaryModel> getSummary() async {
    try {
      final response = await _dio.get(ApiEndpoints.interviewPerformanceSummary);
      final data = response.data;
      if (data is! Map) {
        throw ServerException('Unexpected performance summary response');
      }
      return PerformanceSummaryModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw error.error is AppException
          ? error.error as AppException
          : ServerException(error.message ?? 'Unknown error');
    } catch (error) {
      if (error is AppException) rethrow;
      throw ServerException(error.toString());
    }
  }
}
