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
import 'package:rashed_app/features/cv/domain/entities/cv_analysis_result.dart';
import 'package:rashed_app/features/cv/domain/entities/selected_cv_file.dart';
import 'package:rashed_app/features/cv/domain/usecases/analyze_cv_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/delete_skill_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/update_skills_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/upload_cv_usecase.dart';
import 'package:rashed_app/features/cv/presentation/cubit/cv_cubit.dart';

class MockUpload extends Mock implements UploadCvUseCase {}

class MockAnalyze extends Mock implements AnalyzeCvUseCase {}

class MockUpdateSkills extends Mock implements UpdateSkillsUseCase {}

class MockDeleteSkill extends Mock implements DeleteSkillUseCase {}

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
  });

  late MemoryStorage storage;
  late CvLocalDataSource local;
  late MockUpload upload;
  late MockAnalyze analyze;
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
    calls = [];
    when(() => upload.cancel()).thenAnswer((_) {});
    when(() => analyze.cancel()).thenAnswer((_) {});
    cubit = CvCubit(
      uploadCvUseCase: upload,
      analyzeCvUseCase: analyze,
      updateSkillsUseCase: MockUpdateSkills(),
      deleteSkillUseCase: MockDeleteSkill(),
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
    expect(state.result.fullName, 'Jane Smith');
    expect(state.result.jobTitles, ['Engineer', 'Mentor']);
    expect(state.result.skills, ['Python', 'FastAPI']);
    verify(() => upload(any())).called(1);
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
    await cubit.load();
    expect(cubit.state, isA<CvAnalysisRecorded>());
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
    stubAnalyze(const Right(analysis));
    await cubit.load();
    expect(cubit.state, isA<CvUploadSaved>());
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
    await cubit.load();
    expect(cubit.state, isA<CvAnalysisRecorded>());
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
    await cubit.load();
    expect((cubit.state as CvUploadSaved).cvId, 'cv-a');
    storage.values['user_id'] = 'user-b';
    await cubit.load();
    expect(cubit.state, isA<CvAnalysisRecorded>());
    expect((cubit.state as CvAnalysisRecorded).cvId, 'cv-b');
  });
}
