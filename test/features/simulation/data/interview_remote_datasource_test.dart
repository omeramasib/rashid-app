import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/auth_interceptor.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/simulation/data/datasources/interview_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late Dio dio;
  late InterviewRemoteDataSourceImpl source;
  RequestOptions? request;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final client = MockDioClient();
    when(() => client.dio).thenReturn(dio);
    source = InterviewRemoteDataSourceImpl(client: client);
    request = null;
  });

  void respond({
    int status = 200,
    Object? body,
    DioExceptionType? networkError,
    Map<String, List<String>>? headers,
  }) {
    dio.interceptors
      ..clear()
      ..add(ResponseInterceptor());
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      request = options;
      if (networkError != null) {
        return Future<ResponseBody>.error(DioException(
          requestOptions: options,
          type: networkError,
        ));
      }
      return Future.value(ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          ...?headers,
        },
      ));
    });
  }

  Map<String, dynamic> startedBody() {
    return {
      'status': 'success',
      'message': 'Interview started',
      'data': {
        'simulation_id': 'sim-1',
        'interview_setting_id': 'setting-1',
        'status': 'ready',
        'report_status': 'pending',
        'questions': [
          {
            'id': 'q-1',
            'question_text': 'Describe a project.',
            'audio_url': null,
            'category': 'technical',
            'position': 1,
          },
        ],
      },
    };
  }

  test('start by job sends cv_id only when it is present', () async {
    respond(body: startedBody());
    await source.startByJob(
      jobField: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 5,
      cvId: 'cv-1',
    );

    expect(request?.path, ApiEndpoints.interviewStartByJob);
    expect(request?.data, {
      'job_field': 'Nurse',
      'interview_type': 'technical',
      'difficulty': 'medium',
      'language': 'English',
      'simulation_type': 'text',
      'num_questions': 5,
      'cv_id': 'cv-1',
    });

    respond(body: startedBody());
    await source.startByJob(
      jobField: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 5,
    );
    expect((request?.data as Map).containsKey('cv_id'), isFalse);
  });

  test('start by job description omits cv_id when absent', () async {
    respond(body: startedBody());
    final response = await source.startByJobDescription(
      jobDescription: 'A role that needs careful clinical judgment.',
      interviewType: 'behavioral',
      difficulty: 'hard',
      language: 'Arabic',
      simulationType: 'text',
      numQuestions: 3,
    );

    expect(request?.path, ApiEndpoints.interviewStartByJobDesc);
    expect(request?.data['job_description'], contains('clinical'));
    expect((request?.data as Map).containsKey('cv_id'), isFalse);
    expect(response.questions.single.id, 'q-1');
  });

  test('keeps the simulation id from a failed start', () async {
    respond(
      status: 502,
      body: {
        'detail': 'Interview AI provider returned an invalid result',
      },
      headers: {
        'x-simulation-id': ['sim-failed'],
      },
    );

    expect(
      source.startByJob(
        jobField: 'Nurse',
        interviewType: 'technical',
        difficulty: 'medium',
        language: 'English',
        simulationType: 'text',
        numQuestions: 5,
      ),
      throwsA(isA<InterviewStartException>()
          .having((error) => error.simulationId, 'simulationId', 'sim-failed')
          .having(
            (error) => error.cause,
            'cause',
            isA<UpstreamException>(),
          )),
    );
  });

  test('maps a start with no network and a provider timeout', () async {
    respond(networkError: DioExceptionType.connectionError);
    expect(
      source.startByJobDescription(
        jobDescription: 'A role that needs careful clinical judgment.',
        interviewType: 'technical',
        difficulty: 'medium',
        language: 'English',
        simulationType: 'text',
        numQuestions: 5,
      ),
      throwsA(isA<InterviewStartException>()
          .having((error) => error.simulationId, 'simulationId', isNull)
          .having((error) => error.cause, 'cause', isA<NetworkException>())),
    );

    respond(networkError: DioExceptionType.receiveTimeout);
    expect(
      source.retryGeneration('sim-failed'),
      throwsA(isA<InterviewStartException>().having(
        (error) => error.cause,
        'cause',
        isA<RequestTimeoutException>(),
      )),
    );
  });

  test('submit sends the answer and skip sends no answer text', () async {
    respond(body: {
      'status': 'success',
      'message': 'Answer evaluated',
      'data': {
        'question_id': 'q-1',
        'score': 70,
        'strengths': ['Clear'],
        'weaknesses': null,
        'suggested_answer': 'Add an example.',
        'skipped': false,
      },
    });
    final evaluation = await source.submitAnswer(
      questionId: 'q-1',
      skipped: false,
      answerText: 'My answer',
    );
    expect(request?.path, ApiEndpoints.interviewSubmitAnswer);
    expect(request?.data, {
      'question_id': 'q-1',
      'skipped': false,
      'answer_text': 'My answer',
    });
    expect(evaluation.score, 70);
    expect(evaluation.weaknesses, isNull);

    respond(body: {
      'status': 'success',
      'message': 'Question skipped',
      'data': {
        'question_id': 'q-1',
        'score': null,
        'strengths': null,
        'weaknesses': null,
        'suggested_answer': null,
        'skipped': true,
      },
    });
    final skipped = await source.submitAnswer(
      questionId: 'q-1',
      skipped: true,
      answerText: 'ignored',
    );
    expect((request?.data as Map).containsKey('answer_text'), isFalse);
    expect(request?.data['skipped'], isTrue);
    expect(skipped.skipped, isTrue);
  });

  test('finish sends the simulation id and parses the score', () async {
    respond(body: {
      'status': 'success',
      'message': 'Interview finished',
      'data': {
        'simulation_id': 'sim-1',
        'score': 40,
        'performance_status': 'poor',
        'total_questions': 1,
        'answered_questions': 1,
        'skipped_questions': 0,
        'unanswered_questions': 0,
        'status': 'completed',
        'report_status': 'completed',
        'report_summary': 'Needs work',
      },
    });
    final result = await source.finishInterview('sim-1');
    expect(request?.path, ApiEndpoints.interviewFinish);
    expect(request?.data, {'simulation_id': 'sim-1'});
    expect(result.score, 40);
    expect(result.reportSummary, 'Needs work');
  });

  test('history count reads total_simulations from the unwrapped payload',
      () async {
    respond(body: {
      'status': 'success',
      'message': 'Simulation history count retrieved successfully',
      'data': {'total_simulations': 12},
    });
    final count = await source.getSimulationHistoryCount();
    expect(request?.method, 'GET');
    expect(request?.path, ApiEndpoints.interviewHistoryCount);
    expect(count.totalSimulations, 12);
  });

  test('history count preserves a real zero', () async {
    respond(body: {
      'status': 'success',
      'data': {'total_simulations': 0},
    });
    final count = await source.getSimulationHistoryCount();
    expect(count.totalSimulations, 0);
  });

  test('history count failure is not treated as zero', () async {
    respond(status: 503, body: const {'detail': 'unavailable'});
    await expectLater(
      source.getSimulationHistoryCount(),
      throwsA(isA<ServiceUnavailableException>()),
    );
  });

  test('malformed history count is rejected', () async {
    respond(body: {
      'status': 'success',
      'data': {'total_simulations': '12'},
    });
    await expectLater(
      source.getSimulationHistoryCount(),
      throwsA(isA<ServerException>()),
    );

    dio.interceptors.clear();
    respond(body: {
      'status': 'success',
      'data': {'count': 12},
    });
    await expectLater(
      source.getSimulationHistoryCount(),
      throwsA(isA<ServerException>()),
    );
  });

  test('history count attaches the bearer token from the auth interceptor',
      () async {
    final storage = _TokenStorage()..token = 'access-token';
    respond(body: {
      'status': 'success',
      'data': {'total_simulations': 12},
    });
    dio.interceptors.insert(0, AuthInterceptor(storage));
    await source.getSimulationHistoryCount();
    expect(request?.headers['Authorization'], 'Bearer access-token');
  });
}

class _TokenStorage extends Fake implements SecureStorageService {
  String? token;

  @override
  Future<String?> read({required String key}) async {
    if (key == 'token') return token;
    return null;
  }
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._fetch);

  final Future<ResponseBody> Function(RequestOptions options) _fetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _fetch(options);
  }
}
