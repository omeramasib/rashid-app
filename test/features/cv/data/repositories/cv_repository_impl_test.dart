import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_remote_datasource.dart';
import 'package:rashed_app/features/cv/data/repositories/cv_repository_impl.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';

class MockRemote extends Mock implements CvRemoteDataSource {}

void main() {
  late MockRemote remote;
  late CvRepositoryImpl repository;

  const profile = CvProfile(
    cvId: 'cv-1',
    status: CvAnalysisStatus.processed,
    fullName: 'Example Name',
    jobTitles: ['Flutter Developer'],
    skills: ['Flutter'],
  );

  setUp(() {
    remote = MockRemote();
    repository = CvRepositoryImpl(remoteDataSource: remote);
  });

  test('returns a processed profile', () async {
    when(() => remote.getMyCvProfile()).thenAnswer((_) async => profile);
    expect(await repository.getMyCvProfile(), const Right(profile));
  });

  test('returns null when no CV exists', () async {
    when(() => remote.getMyCvProfile()).thenAnswer((_) async => null);
    expect(await repository.getMyCvProfile(),
        const Right<Failure, CvProfile?>(null));
  });

  test('maps network and server exceptions to failures', () async {
    when(() => remote.getMyCvProfile())
        .thenThrow(NetworkException('No internet connection'));
    expect(
      await repository.getMyCvProfile(),
      const Left<Failure, CvProfile?>(NetworkFailure('No internet connection')),
    );

    when(() => remote.getMyCvProfile())
        .thenThrow(ServerException('Unexpected CV profile response'));
    expect(
      await repository.getMyCvProfile(),
      const Left<Failure, CvProfile?>(
        ServerFailure('Unexpected CV profile response'),
      ),
    );
  });
}
