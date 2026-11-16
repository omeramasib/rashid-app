import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/network/auth_interceptor.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/simulation/data/datasources/interview_remote_datasource.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';

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

  void respondBytes(
    Uint8List bytes, {
    String contentType = 'audio/wav',
    int status = 200,
  }) {
    dio.interceptors
      ..clear()
      ..add(ResponseInterceptor());
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      request = options;
      return Future.value(ResponseBody.fromBytes(
        bytes,
        status,
        headers: {
          Headers.contentTypeHeader: [contentType],
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
      'audio_delivery': 'direct',
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
    expect(request?.data['audio_delivery'], 'direct');
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
    dio.interceptors.insert(0, AuthInterceptor(RashedSession(storage)));
    await source.getSimulationHistoryCount();
    expect(request?.headers['Authorization'], 'Bearer access-token');
  });

  test('retry sends audio_delivery as a query parameter', () async {
    respond(body: startedBody());
    await source.retryGeneration('sim-1');
    expect(request?.path, ApiEndpoints.interviewRetry('sim-1'));
    expect(request?.queryParameters, {'audio_delivery': 'direct'});
    expect(request?.data, isNull);
  });

  test('reads question audio through the authenticated client', () async {
    final storage = _TokenStorage()..token = 'access-token';
    respondBytes(_wavBytes());
    dio.interceptors.insert(0, AuthInterceptor(RashedSession(storage)));

    final audio = await source.downloadQuestionAudio('q 1');

    expect(request?.uri.path, endsWith('/audio/direct'));
    expect(request?.uri.path, isNot(endsWith('/audio')));
    expect(request?.headers['Authorization'], 'Bearer access-token');
    expect(request?.headers['Accept'], 'audio/wav');
    expect(request?.responseType, ResponseType.bytes);
    expect(request?.receiveTimeout, const Duration(seconds: 60));
    expect(audio, _wavBytes());
  });

  test('rejects an invalid wav without calling the legacy audio endpoint',
      () async {
    respondBytes(Uint8List.fromList([0, 1, 2, 3]));
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<UpstreamException>()),
    );
    expect(request?.uri.path, endsWith('/audio/direct'));

    respondBytes(_wavBytes(), contentType: 'audio/mpeg');
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<UpstreamException>()),
    );
  });

  test('maps question audio http failures without rewriting them', () async {
    respond(
      status: 401,
      body: {'detail': 'Could not validate credentials'},
    );
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<UnauthorizedException>()),
    );

    respond(status: 404, body: {'detail': 'Question not found'});
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<NotFoundException>()),
    );

    respond(
      status: 429,
      body: {
        'detail': {
          'code': 'spending_limit',
          'message': 'AI spending limit reached',
        },
      },
      headers: {
        'retry-after': ['5'],
      },
    );
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<RateLimitException>()
          .having((error) => error.code, 'code', 'spending_limit')
          .having(
              (error) => error.message, 'message', 'AI spending limit reached')
          .having((error) => error.retryAfter, 'retryAfter',
              const Duration(seconds: 5))),
    );

    respond(status: 429, body: {'detail': 'Rate limit exceeded'});
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<RateLimitException>()
          .having((error) => error.code, 'code', isNull)
          .having((error) => error.message, 'message', 'Rate limit exceeded')),
    );

    respond(
      status: 503,
      body: {'detail': 'Question audio is temporarily unavailable'},
    );
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<ServiceUnavailableException>()),
    );

    respond(networkError: DioExceptionType.receiveTimeout);
    await expectLater(
      source.downloadQuestionAudio('q-1'),
      throwsA(isA<RequestTimeoutException>()),
    );
  });
}

Uint8List _wavBytes() {
  final fmt = ByteData(16)
    ..setUint16(0, 1, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint32(4, 16000, Endian.little)
    ..setUint32(8, 32000, Endian.little)
    ..setUint16(12, 2, Endian.little)
    ..setUint16(14, 16, Endian.little);
  final data = Uint8List(2);
  return _wavChunked([
    _chunk('fmt ', fmt.buffer.asUint8List()),
    _chunk('data', data),
  ]);
}

Uint8List _chunk(String id, Uint8List payload) {
  final size = ByteData(4)..setUint32(0, payload.length, Endian.little);
  final bytes = BytesBuilder()
    ..add(id.codeUnits)
    ..add(size.buffer.asUint8List())
    ..add(payload);
  if (payload.length.isOdd) bytes.addByte(0);
  return bytes.toBytes();
}

Uint8List _wavChunked(List<Uint8List> chunks) {
  final body = BytesBuilder();
  for (final chunk in chunks) {
    body.add(chunk);
  }
  final payload = body.toBytes();
  final size = ByteData(4)..setUint32(0, payload.length, Endian.little);
  return (BytesBuilder()
        ..add('RIFF'.codeUnits)
        ..add(size.buffer.asUint8List())
        ..add('WAVE'.codeUnits)
        ..add(payload))
      .toBytes();
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
