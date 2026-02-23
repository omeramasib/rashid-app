import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/share_result_model.dart';

abstract class HomeRemoteDataSource {
  Future<ShareResultModel> shareLastInterviewResult(String? caption);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient client;

  HomeRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<ShareResultModel> shareLastInterviewResult(String? caption) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.shareInterviewResult,
        data: {
          if (caption != null) 'caption': caption,
        },
      );
      return ShareResultModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
