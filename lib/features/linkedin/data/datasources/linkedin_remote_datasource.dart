import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/linkedin_account_model.dart';

abstract class LinkedInRemoteDataSource {
  Future<LinkedInAccountModel> connectLinkedIn(String linkedinAccessToken);
  Future<void> disconnectLinkedIn();
}

class LinkedInRemoteDataSourceImpl implements LinkedInRemoteDataSource {
  final DioClient client;

  LinkedInRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<LinkedInAccountModel> connectLinkedIn(
      String linkedinAccessToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.linkedInConnect,
        data: {'linkedin_access_token': linkedinAccessToken},
      );
      return LinkedInAccountModel.fromJson(
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
  Future<void> disconnectLinkedIn() async {
    try {
      await _dio.post(ApiEndpoints.linkedInDisconnect);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
