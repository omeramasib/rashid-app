import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/answer_evaluation_model.dart';
import '../models/interview_finish_result_model.dart';
import '../models/interview_report_model.dart';
import '../models/interview_simulation_history_model.dart';
import '../models/interview_start_response_model.dart';

abstract class InterviewRemoteDataSource {
  Future<InterviewStartResponseModel> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  });

  Future<InterviewStartResponseModel> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  });

  Future<InterviewStartResponseModel> retryGeneration(String simulationId);

  Future<AnswerEvaluationModel> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  });

  Future<InterviewFinishResultModel> finishInterview(String simulationId);

  Future<InterviewReportModel> getReport(String simulationId);

  Future<List<InterviewSimulationHistoryModel>> getSimulationsHistory();
}

class InterviewRemoteDataSourceImpl implements InterviewRemoteDataSource {
  final DioClient client;

  /// Question generation waits on the provider, which may retry once.
  static const Duration aiReceiveTimeout = Duration(seconds: 150);

  InterviewRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  Options get _aiOptions => Options(receiveTimeout: aiReceiveTimeout);

  @override
  Future<InterviewStartResponseModel> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  }) {
    return _start(ApiEndpoints.interviewStartByJob, {
      'job_field': jobField,
      'interview_type': interviewType,
      'difficulty': difficulty,
      'language': language,
      'simulation_type': simulationType,
      'num_questions': numQuestions,
      if (cvId != null) 'cv_id': cvId,
    });
  }

  @override
  Future<InterviewStartResponseModel> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  }) {
    return _start(ApiEndpoints.interviewStartByJobDesc, {
      'job_description': jobDescription,
      'interview_type': interviewType,
      'difficulty': difficulty,
      'language': language,
      'simulation_type': simulationType,
      'num_questions': numQuestions,
      if (cvId != null) 'cv_id': cvId,
    });
  }

  @override
  Future<InterviewStartResponseModel> retryGeneration(
    String simulationId,
  ) {
    return _start(ApiEndpoints.interviewRetry(simulationId), const {});
  }

  Future<InterviewStartResponseModel> _start(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(
        path,
        data: body.isEmpty ? null : body,
        options: _aiOptions,
      );
      return InterviewStartResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _startException(error);
    } catch (error) {
      throw InterviewStartException(ServerException(error.toString()));
    }
  }

  @override
  Future<AnswerEvaluationModel> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.interviewSubmitAnswer,
        data: {
          'question_id': questionId,
          'skipped': skipped,
          if (!skipped && answerText != null) 'answer_text': answerText,
        },
        options: _aiOptions,
      );
      return AnswerEvaluationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _exception(error);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<InterviewFinishResultModel> finishInterview(
    String simulationId,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.interviewFinish,
        data: {'simulation_id': simulationId},
        options: _aiOptions,
      );
      return InterviewFinishResultModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _exception(error);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<InterviewReportModel> getReport(String simulationId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.interviewReport,
        queryParameters: {'simulation_id': simulationId},
        options: _aiOptions,
      );
      return InterviewReportModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _exception(error);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<InterviewSimulationHistoryModel>> getSimulationsHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.interviewHistory);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((item) => InterviewSimulationHistoryModel.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList();
    } on DioException catch (error) {
      throw _exception(error);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  InterviewStartException _startException(DioException error) {
    final header = error.response?.headers.value('x-simulation-id')?.trim();
    return InterviewStartException(
      _exception(error),
      simulationId: header == null || header.isEmpty ? null : header,
    );
  }

  AppException _exception(DioException error) {
    final mapped = error.error;
    if (mapped is AppException) return mapped;
    return ServerException(error.message ?? 'Unknown error');
  }
}
