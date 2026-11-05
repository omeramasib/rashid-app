import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_local_datasource.dart';
import 'package:rashed_app/features/cv/data/models/cv_analysis_result_model.dart';
import 'package:rashed_app/features/cv/data/models/cv_model.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_analysis_result.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';
import 'package:rashed_app/features/cv/domain/entities/selected_cv_file.dart';
import 'package:rashed_app/features/cv/domain/usecases/analyze_cv_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/delete_skill_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/update_skills_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/upload_cv_usecase.dart';
import 'package:rashed_app/features/cv/presentation/cubit/cv_cubit.dart';

class MockUpload extends Mock implements UploadCvUseCase {}

class MockAnalyze extends Mock implements AnalyzeCvUseCase {}

class MockUpdateSkills extends Mock implements UpdateSkillsUseCase {}

class MockDeleteSkill extends Mock implements DeleteSkillUseCase {}

class MockGetProfile extends Mock implements GetMyCvProfileUseCase {}

class MemoryStorage extends Fake implements SecureStorageService {
  final values = <String, String>{};
  bool failWrites = false;
  Future<void> Function()? beforeWrite;

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (beforeWrite != null) await beforeWrite!();
    if (failWrites) throw StateError('disk');
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

void ignoreProgress(int sent, int total) {}

void main() {
  setUpAll(() {
    registerFallbackValue(UploadCvParams(
      bytes: Uint8List(0),
      fileName: 'a.pdf',
      onProgress: ignoreProgress,
    ));
    registerFallbackValue(const AnalyzeCvParams(cvId: 'cv'));
    registerFallbackValue(const UpdateSkillsParams(skills: []));
    registerFallbackValue(const DeleteSkillParams(skill: 'x'));
    registerFallbackValue(NoParams());
  });

  late MemoryStorage storage;
  late CvLocalDataSource local;
  late MockUpload upload;
  late MockAnalyze analyze;
  late MockUpdateSkills updateSkills;
  late MockGetProfile profile;
  late CvCubit cubit;
  late List<String> calls;

  final pdf = SelectedCvFile(
    name: 'resume.pdf',
    sizeBytes: 12,
    bytes: Uint8List.fromList('%PDF-1.4\n'.codeUnits),
  );

  const analysis = CvAnalysisResultModel(
    fullName: 'Jane Smith',
    jobTitles: ['Engineer', 'Mentor'],
    skills: ['Python', 'FastAPI'],
  );

  setUp(() {
    storage = MemoryStorage()..values['user_id'] = 'user-a';
    local = CvLocalDataSource(storage: storage);
    upload = MockUpload();
    analyze = MockAnalyze();
    updateSkills = MockUpdateSkills();
    profile = MockGetProfile();
    calls = [];
    when(() => upload.cancel()).thenAnswer((_) {});
    when(() => analyze.cancel()).thenAnswer((_) {});
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    cubit = CvCubit(
      uploadCvUseCase: upload,
      analyzeCvUseCase: analyze,
      updateSkillsUseCase: updateSkills,
      deleteSkillUseCase: MockDeleteSkill(),
      getMyCvProfileUseCase: profile,
      localDataSource: local,
      secureStorage: storage,
    );
  });

  tearDown(() => cubit.close());

  void stubUpload(String cvId) {
    when(() => upload(any())).thenAnswer((invocation) async {
      calls.add('upload');
      final params = invocation.positionalArguments.first as UploadCvParams;
      params.onProgress(4, params.bytes.length);
      return Right(CvModel(
        cvId: cvId,
        fileUrl: 'https://signed.example/private',
      ));
    });
  }

  void stubAnalyze(Either<Failure, CvAnalysisResult> result) {
    when(() => analyze(any())).thenAnswer((_) async {
      calls.add('analyze');
      return result;
    });
  }

  Map<String, dynamic>? stored() {
    final raw = storage.values['cv_state_user-a'];
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  test('selecting a PDF sends no upload or analyze request', () async {
    await cubit.selectFile(pdf);
    expect(cubit.state, isA<CvFileSelected>());
    verifyNever(() => upload(any()));
    verifyNever(() => analyze(any()));
  });

  test('an invalid file is rejected without an API request', () async {
    await cubit.selectFile(SelectedCvFile(
      name: 'notes.txt',
      sizeBytes: 4,
      bytes: Uint8List.fromList('text'.codeUnits),
    ));
    expect(cubit.state, isA<CvFileRejected>());
    verifyNever(() => upload(any()));
  });

  test('one start sends upload, persists the id, then analyzes once', () async {
    stubUpload('cv-new');
    stubAnalyze(const Right(analysis));
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();

    expect(calls, ['upload', 'analyze']);
    final record = stored();
    expect(record?['uploadedCvId'], 'cv-new');
    expect(record?['analyzedCvId'], 'cv-new');
    expect(jsonEncode(record), isNot(contains('signed.example')));
    expect(jsonEncode(record), isNot(contains('%PDF')));
    final state = cubit.state as CvAnalyzed;
    expect(state.profileConfirmed, isFalse);
    expect(state.result.fullName, 'Jane Smith');
    expect(state.result.jobTitles, ['Engineer', 'Mentor']);
    expect(state.result.skills, ['Python', 'FastAPI']);
    verify(() => upload(any())).called(1);
    verify(() => analyze(any())).called(1);
  });

  test('an unfinished refresh does not confirm the analyzed CV', () async {
    stubUpload('cv-1');
    stubAnalyze(const Right(analysis));
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.inProgress,
      )),
    );
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();
    final state = cubit.state as CvAnalyzed;
    expect(state.profileConfirmed, isFalse);
    verify(() => analyze(any())).called(1);
  });

  test('a processed GET after analysis confirms the profile', () async {
    stubUpload('cv-1');
    stubAnalyze(const Right(analysis));
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        fullName: 'Jane Smith',
        jobTitles: ['Engineer', 'Mentor'],
        skills: ['Python', 'FastAPI'],
      )),
    );
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();
    final state = cubit.state as CvAnalyzed;
    expect(state.profileConfirmed, isTrue);
    expect(state.cvId, 'cv-1');
    verify(() => analyze(any())).called(1);
  });

  test('analyze does not start before the uploaded id is persisted', () async {
    stubUpload('cv-new');
    stubAnalyze(const Right(analysis));
    final gate = Completer<void>();
    storage.beforeWrite = () => gate.future;
    await cubit.selectFile(pdf);
    final pending = cubit.startAnalysis();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => analyze(any()));
    expect(stored(), isNull);
    gate.complete();
    await pending;
    verify(() => analyze(any())).called(1);
    expect(calls.first, 'upload');
    expect(calls.last, 'analyze');
  });

  test('upload failure does not analyze and keeps the previous record',
      () async {
    storage.values['cv_state_user-a'] = jsonEncode({
      'uploadedCvId': 'old',
      'analyzedCvId': 'old',
    });
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'old',
          status: CvAnalysisStatus.processed,
          fullName: 'Old Name',
          jobTitles: ['Engineer'],
          skills: ['Dart'],
        )));
    await cubit.load();
    expect(cubit.state, isA<CvAnalyzed>());
    when(() => upload(any())).thenAnswer((_) async {
      calls.add('upload');
      return const Left(ServerFailure('storage down'));
    });
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();
    expect(calls, ['upload']);
    verifyNever(() => analyze(any()));
    expect(stored()?['uploadedCvId'], 'old');
    expect(stored()?['analyzedCvId'], 'old');
    expect(cubit.state, isA<CvUploadFailed>());
  });

  test('analysis failure keeps uploadedCvId and retry analyzes only', () async {
    stubUpload('cv-new');
    stubAnalyze(const Left(ServerFailure('provider')));
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();
    expect(stored()?['uploadedCvId'], 'cv-new');
    expect(stored()?['analyzedCvId'], isNull);
    expect(cubit.state, isA<CvAnalysisFailed>());

    stubAnalyze(const Right(analysis));
    await cubit.retryAnalysis();
    expect(calls.where((call) => call == 'upload'), ['upload']);
    expect(calls.where((call) => call == 'analyze'), ['analyze', 'analyze']);
    expect(stored()?['analyzedCvId'], 'cv-new');
  });

  test('a second start while upload is in flight does not upload again',
      () async {
    final gate = Future<void>.delayed(const Duration(milliseconds: 40));
    when(() => upload(any())).thenAnswer((_) async {
      calls.add('upload');
      await gate;
      return const Right(
          CvModel(cvId: 'cv-new', fileUrl: 'https://signed.example'));
    });
    stubAnalyze(const Right(analysis));
    await cubit.selectFile(pdf);
    final first = cubit.startAnalysis();
    final second = cubit.startAnalysis();
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['upload']);
    await first;
    await second;
    expect(calls.where((call) => call == 'upload'), ['upload']);
    expect(calls.where((call) => call == 'analyze'), ['analyze']);
  });

  test(
      'storage failure blocks analysis and save retry does not upload or analyze',
      () async {
    stubUpload('cv-new');
    stubAnalyze(const Right(analysis));
    storage.failWrites = true;
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();
    expect(calls, ['upload']);
    verifyNever(() => analyze(any()));
    expect(cubit.state, isA<CvAwaitingPersistence>());
    expect(stored(), isNull);

    storage.failWrites = false;
    await cubit.retryPersistence();
    verifyNever(() => analyze(any()));
    expect(stored()?['uploadedCvId'], 'cv-new');
    expect(stored()?['analyzedCvId'], isNull);
    expect(cubit.state, isA<CvUploadSaved>());
  });

  test('a saved unanalyzed CV continues with analyze only', () async {
    storage.values['cv_state_user-a'] = jsonEncode({
      'uploadedCvId': 'cv-saved',
      'analyzedCvId': null,
    });
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-saved',
          status: CvAnalysisStatus.pending,
        )));
    stubAnalyze(const Right(analysis));
    await cubit.load();
    expect(cubit.state, isA<CvPendingAnalysis>());
    verifyNever(() => analyze(any()));
    await cubit.startAnalysis();
    verifyNever(() => upload(any()));
    verify(() => analyze(any())).called(1);
    expect((cubit.state as CvAnalyzed).result.skills, ['Python', 'FastAPI']);
  });

  test('reopening a completed analysis does not call analyze', () async {
    storage.values['cv_state_user-a'] = jsonEncode({
      'uploadedCvId': 'cv-done',
      'analyzedCvId': 'cv-done',
    });
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-done',
          status: CvAnalysisStatus.processed,
          fullName: 'Jane Smith',
          jobTitles: ['Engineer'],
          skills: ['Python'],
        )));
    await cubit.load();
    final state = cubit.state as CvAnalyzed;
    expect(state.cvId, 'cv-done');
    expect(state.result.fullName, 'Jane Smith');
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  test('switching accounts does not read another user CV id', () async {
    storage.values['cv_state_user-a'] = jsonEncode({
      'uploadedCvId': 'cv-a',
      'analyzedCvId': null,
    });
    storage.values['cv_state_user-b'] = jsonEncode({
      'uploadedCvId': 'cv-b',
      'analyzedCvId': 'cv-b',
    });
    when(() => profile(any())).thenAnswer((_) async {
      final user = storage.values['user_id'];
      if (user == 'user-b') {
        return const Right(CvProfile(
          cvId: 'cv-b',
          status: CvAnalysisStatus.processed,
          fullName: 'User B',
          skills: ['Dart'],
        ));
      }
      return const Right(CvProfile(
        cvId: 'cv-a',
        status: CvAnalysisStatus.pending,
      ));
    });
    await cubit.load();
    expect((cubit.state as CvPendingAnalysis).cvId, 'cv-a');
    storage.values['user_id'] = 'user-b';
    await cubit.load();
    final state = cubit.state as CvAnalyzed;
    expect(state.cvId, 'cv-b');
    expect(state.result.fullName, 'User B');
    verifyNever(() => analyze(any()));
  });

  CvCubit restartedCubit() {
    return CvCubit(
      uploadCvUseCase: upload,
      analyzeCvUseCase: analyze,
      updateSkillsUseCase: updateSkills,
      deleteSkillUseCase: MockDeleteSkill(),
      getMyCvProfileUseCase: profile,
      localDataSource: local,
      secureStorage: storage,
    );
  }

  test('processed profile is restored after a new cubit without storing text',
      () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          fullName: 'Secret Name',
          jobTitles: ['Flutter Developer'],
          skills: ['Flutter', 'Dart'],
        )));
    await cubit.load();
    final restarted = restartedCubit();
    await restarted.load();
    final state = restarted.state as CvAnalyzed;
    expect(state.result.fullName, 'Secret Name');
    expect(state.result.jobTitles, ['Flutter Developer']);
    expect(state.result.skills, ['Flutter', 'Dart']);
    final raw = jsonEncode(stored());
    expect(raw, isNot(contains('Secret Name')));
    expect(raw, isNot(contains('Flutter Developer')));
    expect(stored()?['uploadedCvId'], 'cv-1');
    expect(stored()?['analyzedCvId'], 'cv-1');
    verifyNever(() => analyze(any()));
    await restarted.close();
  });

  test('no CV stays on the upload state and does not analyze', () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    await cubit.load();
    expect(cubit.state, const CvReady());
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  test('pending analysis is manual and does not analyze on load', () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-pending',
          status: CvAnalysisStatus.pending,
        )));
    stubAnalyze(const Right(analysis));
    await cubit.load();
    expect((cubit.state as CvPendingAnalysis).cvId, 'cv-pending');
    verifyNever(() => analyze(any()));
    await cubit.startAnalysis();
    verify(() => analyze(any())).called(1);
  });

  test('in-progress analysis refreshes without another analyze request',
      () async {
    var reads = 0;
    when(() => profile(any())).thenAnswer((_) async {
      reads++;
      if (reads == 1) {
        return const Right(CvProfile(
          cvId: 'cv-run',
          status: CvAnalysisStatus.inProgress,
        ));
      }
      return const Right(CvProfile(
        cvId: 'cv-run',
        status: CvAnalysisStatus.processed,
        fullName: 'Jane Smith',
        jobTitles: ['Engineer'],
        skills: ['Python'],
      ));
    });
    await cubit.load();
    expect((cubit.state as CvAnalysisInProgress).cvId, 'cv-run');
    await cubit.startAnalysis();
    await cubit.retryAnalysis();
    verifyNever(() => analyze(any()));
    await cubit.refreshProfile();
    expect((cubit.state as CvAnalyzed).result.fullName, 'Jane Smith');
    verifyNever(() => analyze(any()));
  });

  test('failed analysis does not retry until the user asks', () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-bad',
          status: CvAnalysisStatus.failed,
        )));
    stubAnalyze(const Right(analysis));
    await cubit.load();
    expect(cubit.state, isA<CvAnalysisFailed>());
    verifyNever(() => analyze(any()));
    await cubit.retryAnalysis();
    verify(() => analyze(any())).called(1);
  });

  test('null name and empty lists are kept as an empty processed profile',
      () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-empty',
          status: CvAnalysisStatus.processed,
          fullName: null,
          jobTitles: [],
          skills: [],
        )));
    await cubit.load();
    final state = cubit.state as CvAnalyzed;
    expect(state.result.fullName, isEmpty);
    expect(state.result.jobTitles, isEmpty);
    expect(state.result.skills, isEmpty);
  });

  test('a newer uploaded id is kept when GET still returns the older CV',
      () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'old-cv',
          status: CvAnalysisStatus.processed,
          fullName: 'Old Person',
          jobTitles: ['Analyst'],
          skills: ['Excel'],
        )));
    await cubit.load();
    expect((cubit.state as CvAnalyzed).cvId, 'old-cv');
    stubUpload('new-cv');
    stubAnalyze(const Right(analysis));
    await cubit.selectFile(pdf);
    await cubit.startAnalysis();
    final state = cubit.state as CvAnalyzed;
    expect(state.cvId, 'new-cv');
    expect(state.result.fullName, 'Jane Smith');
    expect(stored()?['uploadedCvId'], 'new-cv');
    expect(stored()?['analyzedCvId'], 'new-cv');
    expect(jsonEncode(stored()), isNot(contains('Old Person')));
    verify(() => analyze(any())).called(1);
    verify(() => upload(any())).called(1);
  });

  test('an unanalyzed local upload is not replaced by an older processed CV',
      () async {
    storage.values['cv_state_user-a'] = jsonEncode({
      'uploadedCvId': 'new-cv',
      'analyzedCvId': null,
    });
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'old-cv',
          status: CvAnalysisStatus.processed,
          fullName: 'Old Person',
          skills: ['Excel'],
        )));
    await cubit.load();
    expect((cubit.state as CvPendingAnalysis).cvId, 'new-cv');
    expect(stored()?['uploadedCvId'], 'new-cv');
    expect(stored()?['analyzedCvId'], isNull);
    expect(jsonEncode(stored()), isNot(contains('Old Person')));
    verifyNever(() => analyze(any()));
  });

  test('a network failure is not treated as no CV', () async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Left(NetworkFailure('No internet connection')),
    );
    await cubit.load();
    final state = cubit.state as CvProfileLoadFailed;
    expect(state.failure, isA<NetworkFailure>());
    expect(cubit.state, isNot(isA<CvReady>()));
    verifyNever(() => analyze(any()));
  });

  test('a timeout while loading the profile is not a failed analysis',
      () async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Left(RequestTimeoutFailure('Connection timed out')),
    );
    await cubit.load();
    final state = cubit.state as CvProfileLoadFailed;
    expect(state.failure, isA<RequestTimeoutFailure>());
    expect(cubit.state, isNot(isA<CvAnalysisFailed>()));
    await cubit.retryAnalysis();
    verifyNever(() => analyze(any()));
  });

  test('401 on profile load expires the session', () async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Left(UnauthorizedFailure('unauthorized')),
    );
    await cubit.load();
    expect(cubit.state, isA<CvSessionExpired>());
  });

  test('saving skills refreshes the profile and does not analyze', () async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          fullName: 'Jane Smith',
          jobTitles: ['Engineer'],
          skills: ['Dart'],
        )));
    when(() => updateSkills(any())).thenAnswer((_) async => const Right(null));
    await cubit.load();
    await cubit.updateSkills(const ['Dart']);
    expect(cubit.state, isA<SkillsUpdated>());
    verifyNever(() => analyze(any()));
    verify(() => updateSkills(any())).called(1);
    verify(() => profile(any())).called(greaterThan(1));
  });

  CvProfile profileWith(List<String> skills) {
    return CvProfile(
      cvId: 'cv-1',
      status: CvAnalysisStatus.processed,
      fullName: 'Jane Smith',
      jobTitles: const ['Engineer'],
      skills: skills,
    );
  }

  test('adding a skill keeps existing skills and stores the profile copy',
      () async {
    var skills = const ['Dart'];
    when(() => profile(any())).thenAnswer(
      (_) async => Right(profileWith(skills)),
    );
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as UpdateSkillsParams;
      expect(params.skills, ['Dart', 'Flutter']);
      skills = const ['Dart', 'Flutter'];
      return const Right(null);
    });
    await cubit.load();
    final saved = await cubit.addSkill('  Flutter  ', existing: const ['Dart']);
    final state = cubit.state as CvAnalyzed;
    expect(saved, isTrue);
    expect(state.result.skills, ['Dart', 'Flutter']);
    verify(() => updateSkills(any())).called(1);
    verify(() => profile(any())).called(greaterThan(1));
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  test('omitting a skill updates the draft without an API request', () async {
    when(() => profile(any())).thenAnswer(
      (_) async => Right(profileWith(const ['Flutter', 'Dart'])),
    );
    await cubit.load();
    cubit.omitSkill('Flutter');
    final state = cubit.state as CvAnalyzed;
    expect(state.skills, ['Dart']);
    expect(state.result.skills, ['Flutter', 'Dart']);
    expect(state.skillAdded, isFalse);
    verifyNever(() => updateSkills(any()));
    verifyNever(() => analyze(any()));
  });

  test('empty and duplicate skills are not submitted', () async {
    expect(await cubit.addSkill('   ', existing: const ['Dart']), isFalse);
    expect(await cubit.addSkill('dart', existing: const ['Dart']), isFalse);
    expect(cubit.state, isNot(isA<SkillsUpdating>()));
    verifyNever(() => updateSkills(any()));
    verifyNever(() => analyze(any()));
  });

  test('a failed skill update keeps the previous profile skills', () async {
    when(() => profile(any())).thenAnswer(
      (_) async => Right(profileWith(const ['Dart'])),
    );
    when(() => updateSkills(any())).thenAnswer(
      (_) async => const Left(ServerFailure('boom')),
    );
    await cubit.load();
    final saved = await cubit.addSkill('Flutter', existing: const ['Dart']);
    final state = cubit.state as CvError;
    expect(saved, isFalse);
    expect(state.failure, isA<ServerFailure>());
    expect(cubit.state, isNot(isA<CvAnalyzed>()));
    verify(() => updateSkills(any())).called(1);
    verify(() => profile(any())).called(1);
    verifyNever(() => analyze(any()));
  });

  test('a second add while saving does not send another request', () async {
    final gate = Completer<Either<Failure, void>>();
    when(() => profile(any())).thenAnswer(
      (_) async => Right(profileWith(const ['Dart', 'Flutter'])),
    );
    when(() => updateSkills(any())).thenAnswer((_) => gate.future);
    await cubit.load();
    final first = cubit.addSkill('Flutter', existing: const ['Dart']);
    final second = cubit.addSkill('Firebase', existing: const ['Dart']);
    expect(await second, isFalse);
    gate.complete(const Right(null));
    expect(await first, isTrue);
    expect((cubit.state as CvAnalyzed).result.skills, ['Dart', 'Flutter']);
    verify(() => updateSkills(any())).called(1);
    verifyNever(() => analyze(any()));
  });

  test('an added skill is still present after the cubit is recreated',
      () async {
    var skills = const ['Dart'];
    when(() => profile(any())).thenAnswer(
      (_) async => Right(profileWith(skills)),
    );
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      skills = List<String>.from(
        (invocation.positionalArguments.first as UpdateSkillsParams).skills,
      );
      return const Right(null);
    });
    await cubit.load();
    await cubit.addSkill('Flutter', existing: const ['Dart']);
    final restarted = restartedCubit();
    await restarted.load();
    expect((restarted.state as CvAnalyzed).result.skills, ['Dart', 'Flutter']);
    verifyNever(() => analyze(any()));
    await restarted.close();
  });
}
