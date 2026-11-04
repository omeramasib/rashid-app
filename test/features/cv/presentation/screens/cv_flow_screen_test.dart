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
import 'package:rashed_app/features/profile/presentation/screens/complete_profile_screen.dart';

class MockUpload extends Mock implements UploadCvUseCase {}

class MockAnalyze extends Mock implements AnalyzeCvUseCase {}

class MockUpdateSkills extends Mock implements UpdateSkillsUseCase {}

class MockDeleteSkill extends Mock implements DeleteSkillUseCase {}

class MockGetProfile extends Mock implements GetMyCvProfileUseCase {}

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
    registerFallbackValue(NoParams());
  });

  late MemoryStorage storage;
  late MockUpload upload;
  late MockAnalyze analyze;
  late MockUpdateSkills updateSkills;
  late MockGetProfile profile;
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

  CvCubit buildCubit() {
    return CvCubit(
      uploadCvUseCase: upload,
      analyzeCvUseCase: analyze,
      updateSkillsUseCase: updateSkills,
      deleteSkillUseCase: MockDeleteSkill(),
      getMyCvProfileUseCase: profile,
      localDataSource: CvLocalDataSource(storage: storage),
      secureStorage: storage,
    );
  }

  setUp(() {
    storage = MemoryStorage()..values['user_id'] = 'user-a';
    upload = MockUpload();
    analyze = MockAnalyze();
    updateSkills = MockUpdateSkills();
    profile = MockGetProfile();
    when(() => upload.cancel()).thenAnswer((_) {});
    when(() => analyze.cancel()).thenAnswer((_) {});
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    cubit = buildCubit();
  });

  tearDown(() => cubit.close());

  Future<void> pumpScreen(
    WidgetTester tester,
    Locale locale, {
    Size size = const Size(800, 1600),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
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
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.text('https://signed.example'), findsNothing);
    verify(() => upload(any())).called(1);
    verify(() => analyze(any())).called(1);
  });

  testWidgets('a long skill wraps inside the skills box', (tester) async {
    const longSkill =
        'Cross-functional stakeholder communication and technical writing';
    const unbroken =
        'SupercalifragilisticexpialidociousSkillNameWithoutAnySpacesAtAll';
    when(() => upload(any())).thenAnswer((_) async {
      return const Right(
          CvModel(cvId: 'cv-1', fileUrl: 'https://signed.example'));
    });
    when(() => analyze(any())).thenAnswer((_) async {
      return const Right(CvAnalysisResultModel(
        fullName: 'Jane Smith',
        jobTitles: ['Engineer'],
        skills: [longSkill, unbroken, 'Python'],
      ));
    });
    await pumpScreen(tester, const Locale('en'), size: const Size(360, 900));
    await cubit.selectFile(pdf);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('cv_start_analysis')));
    await tester.tap(find.byKey(const Key('cv_start_analysis')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.byKey(const Key('cv_skills_box')));
    for (final skill in [longSkill, unbroken]) {
      final chip = tester.getSize(find.byKey(Key('cv_skill_$skill')));
      expect(chip.width, lessThanOrEqualTo(box.width));
    }
    expect(
      tester.getSize(find.byKey(Key('cv_skill_$longSkill'))).height,
      greaterThan(
          tester.getSize(find.byKey(const Key('cv_skill_Python'))).height),
    );
    await tester.tap(find.byKey(Key('cv_remove_skill_$unbroken')));
    await tester.pump();
    expect(find.byKey(Key('cv_skill_$unbroken')), findsNothing);
    expect(tester.takeException(), isNull);
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

  const processed = CvProfile(
    cvId: 'cv-1',
    status: CvAnalysisStatus.processed,
    fullName: 'Jane Smith',
    jobTitles: ['Engineer'],
    skills: ['Python'],
  );

  testWidgets('a processed profile shows the server fields', (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(processed));
    await pumpScreen(tester, const Locale('en'));
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.text('Example Name'), findsNothing);
    expect(find.text('Flutter Developer'), findsNothing);
    verifyNever(() => upload(any()));
    verifyNever(() => analyze(any()));
  });

  testWidgets('null name and empty lists render the empty labels',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-empty',
          status: CvAnalysisStatus.processed,
        )));
    await pumpScreen(tester, const Locale('en'));
    expect(find.byKey(const Key('cv_full_name')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('cv_full_name')),
        matching: find.text('None'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cv_job_titles')), findsOneWidget);
    expect(find.byKey(const Key('cv_skills_box')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_Python')), findsNothing);
    verifyNever(() => analyze(any()));
  });

  testWidgets('loading does not show the upload form or analyze',
      (tester) async {
    final gate = Completer<Either<Failure, CvProfile?>>();
    when(() => profile(any())).thenAnswer((_) => gate.future);
    await pumpScreen(tester, const Locale('en'), settle: false);
    expect(find.byKey(const Key('cv_profile_loading')), findsOneWidget);
    expect(find.byKey(const Key('cv_pick_file')), findsNothing);
    verifyNever(() => analyze(any()));
    gate.complete(const Right(null));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_pick_file')), findsOneWidget);
  });

  testWidgets('a network failure offers retry and stays off the upload form',
      (tester) async {
    var reads = 0;
    when(() => profile(any())).thenAnswer((_) async {
      reads++;
      if (reads == 1) {
        return const Left(NetworkFailure('No internet connection'));
      }
      return const Right(processed);
    });
    await pumpScreen(tester, const Locale('en'));
    expect(
      find.text('No internet connection. Your CV profile could not be loaded.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cv_pick_file')), findsNothing);
    await tester.tap(find.byKey(const Key('cv_profile_retry')));
    await tester.pumpAndSettle();
    expect(find.text('Jane Smith'), findsOneWidget);
    verifyNever(() => analyze(any()));
  });

  testWidgets('pending analysis waits for a manual start', (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-pending',
          status: CvAnalysisStatus.pending,
        )));
    when(() => analyze(any())).thenAnswer((_) async => const Right(analysis));
    await pumpScreen(tester, const Locale('en'));
    expect(
      find.text('Your CV is uploaded and waiting for analysis.'),
      findsOneWidget,
    );
    verifyNever(() => analyze(any()));
    await tester.ensureVisible(find.byKey(const Key('cv_start_analysis')));
    await tester.tap(find.byKey(const Key('cv_start_analysis')));
    await tester.pumpAndSettle();
    verify(() => analyze(any())).called(1);
  });

  testWidgets('in-progress analysis can be refreshed without analyzing',
      (tester) async {
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
    await pumpScreen(tester, const Locale('en'), settle: false);
    await tester.pump();
    expect(find.textContaining('Analysis is still running'), findsOneWidget);
    expect(find.byKey(const Key('cv_start_analysis')), findsNothing);
    verifyNever(() => analyze(any()));
    await tester.tap(find.byKey(const Key('cv_refresh_status')));
    await tester.pumpAndSettle();
    expect(find.text('Jane Smith'), findsOneWidget);
    verifyNever(() => analyze(any()));
  });

  testWidgets('failed analysis retries only after the user asks',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(CvProfile(
          cvId: 'cv-bad',
          status: CvAnalysisStatus.failed,
        )));
    when(() => analyze(any())).thenAnswer((_) async => const Right(analysis));
    await pumpScreen(tester, const Locale('en'));
    expect(find.text('Analysis did not complete. You can try again.'),
        findsOneWidget);
    verifyNever(() => analyze(any()));
    await tester.ensureVisible(find.byKey(const Key('cv_retry_analysis')));
    await tester.tap(find.byKey(const Key('cv_retry_analysis')));
    await tester.pumpAndSettle();
    verify(() => analyze(any())).called(1);
  });

  testWidgets('returning to the CV screen shows the saved profile again',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(processed));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> mount() {
      return tester.pumpWidget(
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
    }

    await mount();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Jane Smith'), findsOneWidget);
    await tester.tap(find.byKey(const Key('app_back_button')));
    await tester.pumpAndSettle();
    await cubit.close();
    cubit = buildCubit();
    await mount();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Jane Smith'), findsOneWidget);
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  testWidgets('deleted skills are replaced by the refreshed profile',
      (tester) async {
    var saved = false;
    when(() => profile(any())).thenAnswer((_) async {
      return Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        fullName: 'Jane Smith',
        jobTitles: const ['Engineer'],
        skills: saved ? const ['Dart'] : const ['Flutter', 'Dart'],
      ));
    });
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as UpdateSkillsParams;
      expect(params.skills, ['Dart']);
      saved = true;
      return const Right(null);
    });
    await pumpScreen(tester, const Locale('en'));
    expect(find.byKey(const Key('cv_skill_Flutter')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cv_remove_skill_Flutter')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('cv_save_skills')));
    await tester.tap(find.byKey(const Key('cv_save_skills')));
    await tester.pumpAndSettle();
    expect(find.text('Your profile is ready.'), findsOneWidget);
    verifyNever(() => analyze(any()));
  });

  CvProfile skillsProfile(List<String> skills) {
    return CvProfile(
      cvId: 'cv-1',
      status: CvAnalysisStatus.processed,
      fullName: 'Jane Smith',
      jobTitles: const ['Engineer'],
      skills: skills,
    );
  }

  testWidgets('adding a skill updates the chips from the refreshed profile',
      (tester) async {
    var skills = const ['Python'];
    when(() => profile(any())).thenAnswer(
      (_) async => Right(skillsProfile(skills)),
    );
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as UpdateSkillsParams;
      expect(params.skills, ['Python', 'Flutter']);
      skills = const ['Python', 'Flutter'];
      return const Right(null);
    });
    await pumpScreen(tester, const Locale('en'));
    await tester.enterText(
        find.byKey(const Key('cv_new_skill')), '  Flutter  ');
    await tester.ensureVisible(find.byKey(const Key('cv_add_skill_button')));
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_Flutter')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_added_message')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('cv_new_skill')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Your profile is ready.'), findsNothing);
    verify(() => updateSkills(any())).called(1);
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  testWidgets('empty and duplicate skills are rejected before a request',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => Right(skillsProfile(const ['Python'])),
    );
    await pumpScreen(tester, const Locale('en'));
    await tester.enterText(find.byKey(const Key('cv_new_skill')), '   ');
    await tester.ensureVisible(find.byKey(const Key('cv_add_skill_button')));
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_added_message')), findsNothing);

    await tester.enterText(find.byKey(const Key('cv_new_skill')), 'python');
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_python')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('cv_new_skill')))
          .controller!
          .text,
      'python',
    );
    verifyNever(() => updateSkills(any()));
    verifyNever(() => analyze(any()));
  });

  testWidgets('a failed add keeps the saved skills and can be retried',
      (tester) async {
    var skills = const ['Python'];
    var attempts = 0;
    when(() => profile(any())).thenAnswer(
      (_) async => Right(skillsProfile(skills)),
    );
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      attempts++;
      final params = invocation.positionalArguments.first as UpdateSkillsParams;
      expect(params.skills, ['Python', 'Flutter']);
      if (attempts == 1) return const Left(ServerFailure('boom'));
      skills = const ['Python', 'Flutter'];
      return const Right(null);
    });
    await pumpScreen(tester, const Locale('en'));
    await tester.enterText(find.byKey(const Key('cv_new_skill')), 'Flutter');
    await tester.ensureVisible(find.byKey(const Key('cv_add_skill_button')));
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Flutter')), findsNothing);
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(
      find.text('The skill could not be saved. You can try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('cv_new_skill')))
          .controller!
          .text,
      'Flutter',
    );

    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Flutter')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.byKey(const Key('cv_status_message')), findsNothing);
    expect(attempts, 2);
    verifyNever(() => analyze(any()));
  });

  testWidgets('tapping add twice does not send a second request',
      (tester) async {
    final gate = Completer<Either<Failure, void>>();
    var skills = const ['Python'];
    when(() => profile(any())).thenAnswer(
      (_) async => Right(skillsProfile(skills)),
    );
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as UpdateSkillsParams;
      expect(params.skills, ['Python', 'Flutter']);
      skills = const ['Python', 'Flutter'];
      return gate.future;
    });
    await pumpScreen(tester, const Locale('en'));
    await tester.enterText(find.byKey(const Key('cv_new_skill')), 'Flutter');
    await tester.ensureVisible(find.byKey(const Key('cv_add_skill_button')));
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pump();
    verify(() => updateSkills(any())).called(1);
    verifyNever(() => analyze(any()));
    gate.complete(const Right(null));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Flutter')), findsOneWidget);
    verifyNoMoreInteractions(updateSkills);
  });

  testWidgets('an added skill is still shown after reopening the CV screen',
      (tester) async {
    var skills = const ['Python'];
    when(() => profile(any())).thenAnswer(
      (_) async => Right(skillsProfile(skills)),
    );
    when(() => updateSkills(any())).thenAnswer((invocation) async {
      skills = List<String>.from(
        (invocation.positionalArguments.first as UpdateSkillsParams).skills,
      );
      return const Right(null);
    });
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> mount() {
      return tester.pumpWidget(
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
    }

    await mount();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cv_new_skill')), 'Flutter');
    await tester.ensureVisible(find.byKey(const Key('cv_add_skill_button')));
    await tester.tap(find.byKey(const Key('cv_add_skill_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Flutter')), findsOneWidget);
    await tester.tap(find.byKey(const Key('app_back_button')));
    await tester.pumpAndSettle();
    await cubit.close();
    cubit = buildCubit();
    await mount();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cv_skill_Python')), findsOneWidget);
    expect(find.byKey(const Key('cv_skill_Flutter')), findsOneWidget);
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  testWidgets('Arabic and English results keep the directional back arrow',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(processed));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpScreen(tester, const Locale('ar'));
      await _expectBackArrow(tester, mirrored: true);
      final arabicBack =
          tester.getCenter(find.byKey(const Key('app_back_button')));
      final arabicTitle = tester.getCenter(find.text('اكمال الملف الشخصي'));
      expect(arabicBack.dx, greaterThan(arabicTitle.dx));

      await pumpScreen(tester, const Locale('en'));
      await _expectBackArrow(tester, mirrored: false);
      final englishBack =
          tester.getCenter(find.byKey(const Key('app_back_button')));
      final englishTitle = tester.getCenter(find.text('Complete profile'));
      expect(englishBack.dx, lessThan(englishTitle.dx));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
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
