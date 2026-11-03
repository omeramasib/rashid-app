import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/core/widgets/app_back_button.dart';
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
import 'package:rashed_app/features/profile/presentation/screens/complete_profile_screen.dart';

class MockUpload extends Mock implements UploadCvUseCase {}

class MockAnalyze extends Mock implements AnalyzeCvUseCase {}

class MockUpdateSkills extends Mock implements UpdateSkillsUseCase {}

class MockDeleteSkill extends Mock implements DeleteSkillUseCase {}

class MemoryStorage extends Fake implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  final Map<String, AppLocalizations> loaded;
  const LoadedLocalizationsDelegate(this.loaded);

  @override
  bool isSupported(Locale locale) => loaded.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(loaded[locale.languageCode]!);

  @override
  bool shouldReload(LoadedLocalizationsDelegate old) => false;
}

void ignoreProgress(int sent, int total) {}

void main() {
  final loaded = <String, AppLocalizations>{};

  setUpAll(() async {
    for (final code in ['en', 'ar']) {
      final strings = AppLocalizations(Locale(code));
      await strings.loadJsonLanguage();
      loaded[code] = strings;
    }
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
  late MockUpload upload;
  late MockAnalyze analyze;
  late CvCubit cubit;

  final pdf = SelectedCvFile(
    name: 'resume.pdf',
    sizeBytes: 12,
    bytes: Uint8List.fromList('%PDF-1.4\n'.codeUnits),
  );

  const analysis = CvAnalysisResultModel(
    fullName: 'Jane Smith',
    jobTitles: ['Engineer'],
    skills: ['Python'],
  );

  setUp(() {
    storage = MemoryStorage()..values['user_id'] = 'user-a';
    upload = MockUpload();
    analyze = MockAnalyze();
    when(() => upload.cancel()).thenAnswer((_) {});
    when(() => analyze.cancel()).thenAnswer((_) {});
    cubit = CvCubit(
      uploadCvUseCase: upload,
      analyzeCvUseCase: analyze,
      updateSkillsUseCase: MockUpdateSkills(),
      deleteSkillUseCase: MockDeleteSkill(),
      localDataSource: CvLocalDataSource(storage: storage),
      secureStorage: storage,
    );
  });

  tearDown(() => cubit.close());

  Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          LoadedLocalizationsDelegate(loaded),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider.value(
          value: cubit,
          child: const CompleteProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selecting a PDF does not call upload or analyze',
      (tester) async {
    await pumpScreen(tester, const Locale('en'));
    await cubit.selectFile(pdf);
    await tester.pump();
    expect(find.textContaining('resume.pdf'), findsOneWidget);
    verifyNever(() => upload(any()));
    verifyNever(() => analyze(any()));
  });

  testWidgets('successful analysis shows the backend fields and not before',
      (tester) async {
    final gate = Completer<Either<Failure, CvAnalysisResult>>();
    when(() => upload(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as UploadCvParams;
      params.onProgress(params.bytes.length, params.bytes.length);
      return const Right(
          CvModel(cvId: 'cv-1', fileUrl: 'https://signed.example'));
    });
    when(() => analyze(any())).thenAnswer((_) => gate.future);
    await pumpScreen(tester, const Locale('en'));
    await cubit.selectFile(pdf);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('cv_start_analysis')));
    await tester.tap(find.byKey(const Key('cv_start_analysis')));
    await tester.pump();
    expect(find.text('Jane Smith'), findsNothing);
    expect(find.text('Start Analysis'), findsNothing);
    gate.complete(const Right(analysis));
    await tester.pumpAndSettle();
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('https://signed.example'), findsNothing);
    verify(() => upload(any())).called(1);
    verify(() => analyze(any())).called(1);
  });

  testWidgets('Arabic back arrow is mirrored to point right', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpScreen(tester, const Locale('ar'));
      await _expectBackArrow(tester, mirrored: true);
      final back = tester.getCenter(find.byKey(const Key('app_back_button')));
      final title = tester.getCenter(find.text('الملف الشخصي'));
      expect(back.dx, greaterThan(title.dx));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('English back arrow points left', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpScreen(tester, const Locale('en'));
      await _expectBackArrow(tester, mirrored: false);
      final back = tester.getCenter(find.byKey(const Key('app_back_button')));
      final title = tester.getCenter(find.text('Profile'));
      expect(back.dx, lessThan(title.dx));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('back button pops the route', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          LoadedLocalizationsDelegate(loaded),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const CompleteProfileScreen(),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsOneWidget);
    await tester.tap(find.byKey(const Key('app_back_button')));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(CompleteProfileScreen), findsNothing);
  });
}

Future<void> _expectBackArrow(WidgetTester tester,
    {required bool mirrored}) async {
  final icon = find.descendant(
    of: find.byType(BackButtonIcon),
    matching: find.byType(Transform),
  );
  if (!mirrored) {
    expect(icon, findsNothing);
    return;
  }
  expect(icon, findsOneWidget);
  final transform = tester.widget<Transform>(icon);
  expect(transform.transform.storage[0], lessThan(0));
}
