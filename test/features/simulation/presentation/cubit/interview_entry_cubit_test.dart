import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/simulation/domain/interview_cv_gate.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_entry_cubit.dart';

class MockProfile extends Mock implements GetMyCvProfileUseCase {}

void main() {
  const processed = CvProfile(
    cvId: 'cv-1',
    status: CvAnalysisStatus.processed,
    fullName: 'Example User',
    jobTitles: ['Flutter Developer', 'Mobile Engineer'],
    skills: ['Flutter', 'Dart'],
  );

  late MockProfile profile;

  setUpAll(() => registerFallbackValue(NoParams()));

  setUp(() {
    profile = MockProfile();
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
  });

  InterviewEntryCubit build() {
    return InterviewEntryCubit(getMyCvProfileUseCase: profile);
  }

  test('null and unfinished profiles go to completion', () {
    expect(
      interviewCvGateDestination(null),
      InterviewCvGateDestination.completeProfile,
    );
    for (final status in [
      CvAnalysisStatus.pending,
      CvAnalysisStatus.inProgress,
      CvAnalysisStatus.failed,
    ]) {
      expect(
        interviewCvGateDestination(CvProfile(cvId: 'cv-1', status: status)),
        InterviewCvGateDestination.completeProfile,
      );
    }
    expect(
      interviewCvGateDestination(processed),
      InterviewCvGateDestination.setup,
    );
  });

  blocTest<InterviewEntryCubit, InterviewEntryState>(
    'a missing CV needs the profile flow',
    build: build,
    act: (cubit) => cubit.check(),
    expect: () => [const InterviewEntryState.needsProfile()],
    verify: (_) => verify(() => profile(any())).called(1),
  );

  blocTest<InterviewEntryCubit, InterviewEntryState>(
    'a processed CV is ready for setup',
    build: build,
    setUp: () {
      when(() => profile(any()))
          .thenAnswer((_) async => const Right(processed));
    },
    act: (cubit) => cubit.check(),
    expect: () => [const InterviewEntryState.ready(processed)],
  );

  test('each unfinished status is sent to completion', () async {
    for (final status in [
      CvAnalysisStatus.pending,
      CvAnalysisStatus.inProgress,
      CvAnalysisStatus.failed,
    ]) {
      when(() => profile(any())).thenAnswer(
        (_) async => Right(CvProfile(
          cvId: 'cv-1',
          status: status,
          jobTitles: const ['Flutter Developer'],
        )),
      );
      final cubit = build();
      await cubit.check();
      expect(cubit.state.phase, InterviewEntryPhase.needsProfile);
      expect(cubit.state.profile, isNull);
      await cubit.close();
    }
  });

  blocTest<InterviewEntryCubit, InterviewEntryState>(
    'a network failure stays on the gate',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );
    },
    act: (cubit) => cubit.check(),
    expect: () => [
      const InterviewEntryState.failed(
        NetworkFailure('No internet connection'),
      ),
    ],
  );

  blocTest<InterviewEntryCubit, InterviewEntryState>(
    '401 is unauthorized and is not a missing CV',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Left(UnauthorizedFailure('unauthorized')),
      );
    },
    act: (cubit) => cubit.check(),
    expect: () => [
      const InterviewEntryState.unauthorized(
        UnauthorizedFailure('unauthorized'),
      ),
    ],
  );

  test('one check is shared by repeated calls', () async {
    final gate = Completer<Either<Failure, CvProfile?>>();
    when(() => profile(any())).thenAnswer((_) => gate.future);
    final cubit = build();
    final first = cubit.check();
    final second = cubit.check();
    final ignored = cubit.retry();
    verify(() => profile(any())).called(1);
    gate.complete(const Right(null));
    await Future.wait([first, second, ignored]);
    expect(cubit.state.phase, InterviewEntryPhase.needsProfile);
    verifyNoMoreInteractions(profile);
    await cubit.close();
  });

  test('retry after a failure checks once more', () async {
    var calls = 0;
    when(() => profile(any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Left(ServerFailure('down'));
      }
      return const Right(processed);
    });
    final cubit = build();
    await cubit.check();
    expect(cubit.state.phase, InterviewEntryPhase.failed);
    await cubit.retry();
    await cubit.retry();
    expect(cubit.state.phase, InterviewEntryPhase.ready);
    expect(calls, 2);
    await cubit.close();
  });
}
