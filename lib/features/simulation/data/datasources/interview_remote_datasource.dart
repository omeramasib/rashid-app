import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/answer_evaluation_model.dart';
import '../models/interview_finish_result_model.dart';
import '../models/interview_report_model.dart';
import '../models/interview_simulation_history_model.dart';
import '../models/simulation_history_count_model.dart';
import '../models/interview_start_response_model.dart';
import '../models/question_audio_model.dart';

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

  Future<Uint8List> downloadQuestionAudio(
    String questionId, {
    CancelToken? cancelToken,
  });

  void cancelQuestionAudio();

  Future<List<InterviewSimulationHistoryModel>> getSimulationsHistory();

  Future<SimulationHistoryCountModel> getSimulationHistoryCount();
}

class InterviewRemoteDataSourceImpl implements InterviewRemoteDataSource {
  final DioClient client;

  /// Question generation waits on the provider, which may retry once.
  static const Duration aiReceiveTimeout = Duration(seconds: 150);

  /// Direct TTS can take longer than a metadata poll. It is not retried.
  static const Duration audioReceiveTimeout = Duration(seconds: 60);

  final Set<CancelToken> _questionAudioTokens = {};

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
      'audio_delivery': 'direct',
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
      'audio_delivery': 'direct',
      if (cvId != null) 'cv_id': cvId,
    });
  }

  @override
  Future<InterviewStartResponseModel> retryGeneration(
    String simulationId,
  ) {
    return _start(
      ApiEndpoints.interviewRetry(simulationId),
      const {},
      queryParameters: const {'audio_delivery': 'direct'},
    );
  }

  Future<InterviewStartResponseModel> _start(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body.isEmpty ? null : body,
        queryParameters: queryParameters,
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
  Future<Uint8List> downloadQuestionAudio(
    String questionId, {
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    _questionAudioTokens.add(token);
    var tooLarge = false;
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.interviewQuestionAudioDirect(questionId),
        cancelToken: token,
        onReceiveProgress: (received, total) {
          final overCap = received > maxQuestionAudioBytes ||
              (total > 0 && total > maxQuestionAudioBytes);
          if (!overCap || token.isCancelled) return;
          tooLarge = true;
          token.cancel('question audio too large');
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: audioReceiveTimeout,
          headers: const {'Accept': 'audio/wav'},
        ),
      );
      if (response.statusCode != 200) {
        throw UpstreamException('Invalid question audio');
      }
      final bytes = _asBytes(response.data);
      final contentType = response.headers.value(Headers.contentTypeHeader);
      if (!isPlayableWav(bytes, contentType: contentType)) {
        throw UpstreamException('Invalid question audio');
      }
      return bytes;
    } on DioException catch (error) {
      if (tooLarge) throw UpstreamException('Invalid question audio');
      throw _exception(error);
    } on AppException {
      rethrow;
    } catch (error) {
      throw ServerException(error.toString());
    } finally {
      _questionAudioTokens.remove(token);
    }
  }

  @override
  void cancelQuestionAudio() {
    for (final token in _questionAudioTokens.toList()) {
      if (!token.isCancelled) token.cancel('question audio cancelled');
    }
    _questionAudioTokens.clear();
  }

  Uint8List _asBytes(Object? data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Uint8List(0);
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
  Future<SimulationHistoryCountModel> getSimulationHistoryCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.interviewHistoryCount);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerException('Malformed simulation history count');
      }
      return SimulationHistoryCountModel.fromJson(data);
    } on DioException catch (error) {
      throw _exception(error);
    } on FormatException {
      throw ServerException('Malformed simulation history count');
    } catch (error) {
      if (error is AppException) rethrow;
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
