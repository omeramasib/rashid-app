import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/interview_start_response_model.dart';
import '../models/interview_report_model.dart';
import '../models/interview_simulation_history_model.dart';

abstract class InterviewRemoteDataSource {
  Future<InterviewStartResponseModel> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  });

  Future<InterviewStartResponseModel> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  });

  Future<void> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  });

  Future<void> finishInterview(String simulationId);

  Future<InterviewReportModel> getReport(String simulationId);

  Future<List<InterviewSimulationHistoryModel>> getSimulationsHistory();
}

class InterviewRemoteDataSourceImpl implements InterviewRemoteDataSource {
  final DioClient client;
  InterviewRemoteDataSourceImpl({required this.client});
  Dio get _dio => client.dio;

  @override
  Future<InterviewStartResponseModel> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.interviewStartByJob, data: {
        'job_field': jobField,
        'interview_type': interviewType,
        'difficulty': difficulty,
        'language': language,
        'simulation_type': simulationType,
        'num_questions': numQuestions,
      });
      return InterviewStartResponseModel.fromJson(
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
  Future<InterviewStartResponseModel> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  }) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.interviewStartByJobDesc, data: {
        'job_description': jobDescription,
        'interview_type': interviewType,
        'difficulty': difficulty,
        'language': language,
        'simulation_type': simulationType,
        'num_questions': numQuestions,
      });
      return InterviewStartResponseModel.fromJson(
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
  Future<void> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  }) async {
    try {
      await _dio.post(ApiEndpoints.interviewSubmitAnswer, data: {
        'question_id': questionId,
        'skipped': skipped,
        if (answerText != null) 'answer_text': answerText,
      });
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> finishInterview(String simulationId) async {
    try {
      await _dio.post(ApiEndpoints.interviewFinish,
          data: {'simulation_id': simulationId});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<InterviewReportModel> getReport(String simulationId) async {
    try {
      final response = await _dio.get(ApiEndpoints.interviewReport,
          queryParameters: {'simulation_id': simulationId});
      return InterviewReportModel.fromJson(
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
  Future<List<InterviewSimulationHistoryModel>> getSimulationsHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.interviewHistory);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => InterviewSimulationHistoryModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
