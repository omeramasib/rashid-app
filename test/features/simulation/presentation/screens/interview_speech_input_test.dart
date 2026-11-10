import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/speech/microphone_permission_service.dart';
import 'package:rashed_app/core/speech/speech_recognition_service.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/simulation/domain/entities/answer_evaluation.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_start_response.dart';
import 'package:rashed_app/features/simulation/domain/interview_options.dart';
import 'package:rashed_app/features/simulation/domain/usecases/finish_interview_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_interview_report_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_simulations_history_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/retry_interview_generation_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_description_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/submit_answer_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/speech_input_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_question_screen.dart';
import 'package:rashed_app/features/simulation/presentation/widgets/interview_widgets.dart';

import '../../../../helpers/fake_speech.dart';

class MockStartByJob extends Mock implements StartInterviewByJobUseCase {}

class MockStartByDescription extends Mock
    implements StartInterviewByJobDescriptionUseCase {}

class MockRetry extends Mock implements RetryInterviewGenerationUseCase {}

class MockSubmit extends Mock implements SubmitAnswerUseCase {}

class MockFinish extends Mock implements FinishInterviewUseCase {}

class MockReport extends Mock implements GetInterviewReportUseCase {}

class MockHistory extends Mock implements GetSimulationsHistoryUseCase {}

class MockProfile extends Mock implements GetMyCvProfileUseCase {}

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

void main() {
  final loaded = <String, AppLocalizations>{};
  const first = InterviewQuestion(
    id: 'q-1',
    questionText: 'Tell me about a project.',
    position: 1,
  );
  const second = InterviewQuestion(
    id: 'q-2',
    questionText: 'How do you handle feedback?',
    position: 2,
  );
  const started = InterviewStartResponse(
    simulationId: 'sim-1',
    interviewSettingId: 'setting-1',
    questions: [first, second],
  );
  const evaluation = AnswerEvaluation(
    questionId: 'q-1',
    score: 70,
    skipped: false,
  );

  final answerField = find.byKey(const Key('interview_answer_input'));
  final mic = find.byKey(const Key('speech_mic_button'));
  final done = find.byKey(const Key('speech_done_button'));
  final submitButton = find.byKey(const Key('interview_submit_button'));

  late MockStartByJob startByJob;
  late MockSubmit submit;
  late InterviewCubit interview;
  late FakeSpeechRecognitionService speech;
  late FakeMicrophonePermissionService permissions;
  late SpeechInputCubit speechCubit;

  setUpAll(() async {
    for (final code in ['en', 'ar']) {
      final strings = AppLocalizations(Locale(code));
      await strings.loadJsonLanguage();
      loaded[code] = strings;
    }
    registerFallbackValue(const StartInterviewByJobParams(
      jobField: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 2,
    ));
    registerFallbackValue(NoParams());
    registerFallbackValue(const SubmitAnswerParams(
      questionId: 'q-1',
      skipped: false,
    ));
  });

  setUp(() {
    startByJob = MockStartByJob();
    submit = MockSubmit();
    when(() => startByJob(any())).thenAnswer((_) async => const Right(started));
    when(() => submit(any())).thenAnswer((_) async => const Right(evaluation));
    final profile = MockProfile();
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    interview = InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: MockStartByDescription(),
      retryInterviewGenerationUseCase: MockRetry(),
      submitAnswerUseCase: submit,
      finishInterviewUseCase: MockFinish(),
      getInterviewReportUseCase: MockReport(),
      getSimulationsHistoryUseCase: MockHistory(),
      getMyCvProfileUseCase: profile,
    );
    speech = FakeSpeechRecognitionService();
    permissions = FakeMicrophonePermissionService();
    speechCubit = SpeechInputCubit(speech: speech, permissions: permissions);
  });

  tearDown(() async {
    await interview.close();
    if (!speechCubit.isClosed) await speechCubit.close();
  });

  Future<void> pumpQuestion(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    String language = 'English',
  }) async {
    await interview.start(
      mode: InterviewStartMode.byJob,
      input: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: language,
      numQuestions: 2,
    );
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [
        LoadedLocalizationsDelegate(loaded),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BlocProvider.value(
        value: interview,
        child: BlocProvider.value(
          value: speechCubit,
          child: const InterviewQuestionScreen(),
        ),
      ),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String answerText(WidgetTester tester) =>
      tester.widget<TextField>(answerField).controller!.text;

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<InterviewActionButton>(submitButton).enabled;

  Future<void> startRecording(WidgetTester tester) async {
    await tester.tap(mic);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mic sits inside the answer field in English and Arabic',
      (tester) async {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await pumpQuestion(tester, locale: locale);
      expect(
        find.descendant(of: answerField, matching: mic),
        findsOneWidget,
      );
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(of: mic, matching: find.byType(Tooltip)).first,
      );
      expect(
        tooltip.message,
        locale.languageCode == 'ar' ? 'أجب بصوتك' : 'Answer by voice',
      );
      expect(tester.widget<Material>(mic).color, AppColors.primary);
      expect(
          tester.getSize(find.ancestor(
            of: mic,
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == 48 && w.height == 48,
            ),
          )),
          const Size(48, 48));
    }
    expect(permissions.requestCalls, 0);
  });

  testWidgets('tapping the mic asks permission and starts listening',
      (tester) async {
    await pumpQuestion(tester);
    expect(permissions.requestCalls, 0);

    await startRecording(tester);

    expect(permissions.requestCalls, 1);
    expect(speech.listenCalls, 1);
    expect(find.text('Listening...'), findsOneWidget);
    expect(done, findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('submit is disabled while recording and returns after done',
      (tester) async {
    await pumpQuestion(tester);
    await tester.enterText(answerField, 'Typed answer');
    await tester.pump();
    expect(submitEnabled(tester), isTrue);

    await startRecording(tester);
    expect(submitEnabled(tester), isFalse);
    await tester.tap(submitButton);
    await tester.pump();
    verifyNever(() => submit(any()));

    speech.finalOnStop = 'spoken part';
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(submitEnabled(tester), isTrue);
    verifyNever(() => submit(any()));
  });

  testWidgets('transcript is appended once to typed text and stays editable',
      (tester) async {
    await pumpQuestion(tester);
    await tester.enterText(
      answerField,
      'I have five years of Flutter experience.',
    );
    await startRecording(tester);

    speech.partial('I worked');
    await tester.pump();
    speech.partial('I worked on several');
    await tester.pump();
    expect(answerText(tester), 'I have five years of Flutter experience.');
    expect(find.text('I worked on several'), findsOneWidget);

    speech.finalOnStop = 'I worked on several production mobile applications.';
    await tester.tap(done);
    await tester.pumpAndSettle();
    speech.callbacks!.onDone();
    await tester.pumpAndSettle();

    expect(
      answerText(tester),
      'I have five years of Flutter experience. '
      'I worked on several production mobile applications.',
    );
    expect(tester.widget<TextField>(answerField).enabled, isNot(false));
    expect(tester.widget<TextField>(answerField).readOnly, isFalse);

    await tester.enterText(answerField, 'Edited final answer.');
    await tester.pump();
    expect(answerText(tester), 'Edited final answer.');
    verifyNever(() => submit(any()));
  });

  testWidgets('a second recording appends after the first', (tester) async {
    await pumpQuestion(tester);
    await startRecording(tester);
    speech.finalOnStop = 'First part.';
    await tester.tap(done);
    await tester.pumpAndSettle();

    await startRecording(tester);
    speech.finalOnStop = 'Second part.';
    await tester.tap(done);
    await tester.pumpAndSettle();

    expect(answerText(tester), 'First part. Second part.');
  });

  testWidgets('empty recognition keeps the typed answer', (tester) async {
    await pumpQuestion(tester);
    await tester.enterText(answerField, 'Keep this');
    await startRecording(tester);

    await tester.tap(done);
    await tester.pump(speechCubit.finalizeTimeout);
    await tester.pumpAndSettle();

    expect(answerText(tester), 'Keep this');
    expect(
      find.text(
          "We didn't catch any speech. Tap the microphone and try again."),
      findsOneWidget,
    );
  });

  testWidgets('denied permission shows a message and does not listen',
      (tester) async {
    permissions.result = MicrophonePermissionResult.denied;
    await pumpQuestion(tester);
    await startRecording(tester);
    await tester.pumpAndSettle();

    expect(speech.listenCalls, 0);
    expect(find.byKey(const Key('speech_message')), findsOneWidget);
    expect(done, findsNothing);
  });

  testWidgets('permanently denied permission offers to open settings',
      (tester) async {
    permissions.result = MicrophonePermissionResult.permanentlyDenied;
    await pumpQuestion(tester);
    await startRecording(tester);
    await tester.pumpAndSettle();

    expect(speech.listenCalls, 0);
    expect(find.text('Open Settings'), findsOneWidget);
    await tester.tap(find.byKey(const Key('speech_message_action')));
    await tester.pump();
    expect(permissions.settingsCalls, 1);
  });

  testWidgets('recognition errors show a friendly message', (tester) async {
    await pumpQuestion(tester);
    await startRecording(tester);
    for (var attempt = 0;
        attempt < speechCubit.maxConsecutiveFailures;
        attempt++) {
      speech.callbacks!.onError(SpeechErrorCategory.audio);
      await tester.pump();
      await tester.pump(speechCubit.restartDelay);
    }
    await tester.pumpAndSettle();

    expect(
      find.text('Recording was interrupted. Tap the microphone to try again.'),
      findsOneWidget,
    );
  });

  testWidgets('double tapping the mic starts one session', (tester) async {
    await pumpQuestion(tester);
    await tester.tap(mic);
    await tester.tap(mic, warnIfMissed: false);
    await tester.pump();
    await tester.pump();
    await tester.tap(mic, warnIfMissed: false);
    await tester.pump();

    expect(permissions.requestCalls, 1);
    expect(speech.listenCalls, 1);
  });

  testWidgets('changing question cancels and ignores stale results',
      (tester) async {
    await pumpQuestion(tester);
    await startRecording(tester);
    final oldCallbacks = speech.callbacks!;

    interview.next();
    await tester.pumpAndSettle();
    expect(find.text('How do you handle feedback?'), findsOneWidget);
    expect(speech.cancelCalls, 1);

    oldCallbacks.onResult('stale answer for q-1', true);
    await tester.pumpAndSettle();
    expect(answerText(tester), isEmpty);
  });

  testWidgets('leaving the screen stops recognition', (tester) async {
    await pumpQuestion(tester);
    await startRecording(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(speech.cancelCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('Arabic interview listens in Arabic even with English UI',
      (tester) async {
    speech.locales = ['en_US', 'ar_SA'];
    await pumpQuestion(tester, language: 'Arabic');
    await startRecording(tester);

    expect(speech.lastLocaleId, 'ar_SA');
  });

  testWidgets('English interview listens in English with Arabic UI',
      (tester) async {
    await pumpQuestion(
      tester,
      locale: const Locale('ar'),
      language: 'English',
    );
    await startRecording(tester);

    expect(speech.lastLocaleId, 'en_US');
    expect(find.text('جاري الاستماع...'), findsOneWidget);
    expect(find.text('إنهاء'), findsOneWidget);
  });

  testWidgets('submit sends the edited text through the existing cubit',
      (tester) async {
    await pumpQuestion(tester);
    await tester.enterText(answerField, 'Typed.');
    await startRecording(tester);
    speech.finalOnStop = 'Spoken.';
    await tester.tap(done);
    await tester.pumpAndSettle();
    await tester.enterText(answerField, '${answerText(tester)} Edited.');
    await tester.pump();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final params = verify(() => submit(captureAny())).captured.single
        as SubmitAnswerParams;
    expect(params.answerText, 'Typed. Spoken. Edited.');
    expect(params.questionId, 'q-1');
    expect(params.skipped, isFalse);
  });
}
