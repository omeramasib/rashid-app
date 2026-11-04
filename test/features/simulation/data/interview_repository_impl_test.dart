import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/simulation/data/datasources/interview_remote_datasource.dart';
import 'package:rashed_app/features/simulation/data/repositories/interview_repository_impl.dart';
import 'package:rashed_app/features/simulation/domain/failures/interview_start_failure.dart';

class MockSource extends Mock implements InterviewRemoteDataSource {}

void main() {
  late MockSource source;
  late InterviewRepositoryImpl repository;

  setUp(() {
    source = MockSource();
    repository = InterviewRepositoryImpl(remoteDataSource: source);
  });

  test('preserves the failed simulation id and the original failure', () async {
    when(() => source.startByJob(
          jobField: any(named: 'jobField'),
          interviewType: any(named: 'interviewType'),
          difficulty: any(named: 'difficulty'),
          language: any(named: 'language'),
          simulationType: any(named: 'simulationType'),
          numQuestions: any(named: 'numQuestions'),
          cvId: any(named: 'cvId'),
        )).thenThrow(InterviewStartException(
      NotFoundException('CV not found'),
      simulationId: 'sim-9',
    ));

    final result = await repository.startByJob(
      jobField: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 5,
      cvId: 'missing',
    );

    final failure = result.fold((failure) => failure, (_) => null);
    expect(failure, isA<InterviewStartFailure>());
    final start = failure as InterviewStartFailure;
    expect(start.simulationId, 'sim-9');
    expect(start.cause, isA<NotFoundFailure>());
    expect(start.message, 'CV not found');
  });

  test('maps timeout and network errors without hiding their type', () async {
    when(() => source.submitAnswer(
          questionId: any(named: 'questionId'),
          skipped: any(named: 'skipped'),
          answerText: any(named: 'answerText'),
        )).thenThrow(RequestTimeoutException('Connection timed out'));

    final timeout = await repository.submitAnswer(
      questionId: 'q-1',
      skipped: false,
      answerText: 'Answer',
    );
    expect(
      timeout.fold((failure) => failure, (_) => null),
      isA<RequestTimeoutFailure>(),
    );

    when(() => source.submitAnswer(
          questionId: any(named: 'questionId'),
          skipped: any(named: 'skipped'),
          answerText: any(named: 'answerText'),
        )).thenThrow(NetworkException('No internet connection'));
    final offline = await repository.submitAnswer(
      questionId: 'q-1',
      skipped: false,
      answerText: 'Answer',
    );
    expect(
        offline.fold((failure) => failure, (_) => null), isA<NetworkFailure>());
    expect(
      offline.fold((failure) => failure, (_) => null),
      isNot(isA<RequestTimeoutFailure>()),
    );
  });

  test('maps an already finished simulation to a conflict', () async {
    when(() => source.finishInterview(any())).thenThrow(
      ConflictException('Interview cannot be finished'),
    );
    final result = await repository.finishInterview('sim-1');
    expect(
      result,
      const Left(ConflictFailure('Interview cannot be finished')),
    );
  });
}
