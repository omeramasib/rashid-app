import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/linkedin_connection_status_model.dart';
import '../models/linkedin_mark_deleted_result_model.dart';
import '../models/linkedin_oauth_start_model.dart';
import '../models/linkedin_publish_result_model.dart';
import '../models/linkedin_share_preview_model.dart';

abstract class LinkedInRemoteDataSource {
  Future<LinkedInConnectionStatusModel> getStatus();

  Future<LinkedInOAuthStartModel> startOAuth(String simulationId);

  Future<LinkedInSharePreviewModel> previewShare(String simulationId);

  Future<LinkedInPublishResultModel> publish({
    required String previewId,
    required String simulationId,
    required String contentSha256,
  });

  Future<LinkedInMarkDeletedResultModel> markDeleted({
    required String shareId,
  });

  Future<void> disconnect();
}

class LinkedInRemoteDataSourceImpl implements LinkedInRemoteDataSource {
  final DioClient client;

  LinkedInRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<LinkedInConnectionStatusModel> getStatus() async {
    return _guard(() async {
      final response = await _dio.get(ApiEndpoints.linkedInStatus);
      return LinkedInConnectionStatusModel.fromJson(_map(response.data));
    });
  }

  @override
  Future<LinkedInOAuthStartModel> startOAuth(String simulationId) async {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.linkedInOAuthStart,
        data: {'simulation_id': simulationId},
      );
      return LinkedInOAuthStartModel.fromJson(_map(response.data));
    });
  }

  @override
  Future<LinkedInSharePreviewModel> previewShare(String simulationId) async {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.linkedInSharePreview,
        data: {'simulation_id': simulationId},
      );
      return LinkedInSharePreviewModel.fromJson(_map(response.data));
    });
  }

  @override
  Future<LinkedInPublishResultModel> publish({
    required String previewId,
    required String simulationId,
    required String contentSha256,
  }) async {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.linkedInPublish,
        data: {
          'preview_id': previewId,
          'simulation_id': simulationId,
          'content_sha256': contentSha256,
          'confirmed': true,
        },
      );
      return LinkedInPublishResultModel.fromJson(response.data);
    });
  }

  @override
  Future<LinkedInMarkDeletedResultModel> markDeleted({
    required String shareId,
  }) async {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.linkedInMarkDeleted(shareId),
        data: {'confirm_deleted_on_linkedin': true},
      );
      return LinkedInMarkDeletedResultModel.fromJson(response.data);
    });
  }

  @override
  Future<void> disconnect() async {
    return _guard(() async {
      await _dio.post(ApiEndpoints.linkedInDisconnect);
    });
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('linkedin_body');
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw error.error is AppException
          ? error.error as AppException
          : ServerException(error.message ?? 'Unknown error');
    } on FormatException {
      throw ServerException('Unexpected LinkedIn response');
    } catch (error) {
      if (error is AppException) rethrow;
      throw ServerException('Unexpected LinkedIn response');
    }
  }
}
