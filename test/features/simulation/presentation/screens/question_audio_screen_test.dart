import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/audio/question_audio_player.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/simulation/domain/entities/answer_evaluation.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_start_response.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';
import 'package:rashed_app/features/simulation/domain/interview_options.dart';
import 'package:rashed_app/features/simulation/domain/usecases/finish_interview_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_interview_report_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_simulations_history_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/retry_interview_generation_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_description_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/submit_answer_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/question_audio_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/speech_input_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_evaluation_screen.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_question_screen.dart';
import 'package:rashed_app/features/simulation/presentation/widgets/question_audio_control.dart';

import '../../../../helpers/fake_question_audio.dart';
import '../../../../helpers/fake_speech.dart';

class _StartByJob extends Mock implements StartInterviewByJobUseCase {}

class _StartByDescription extends Mock
    implements StartInterviewByJobDescriptionUseCase {}

class _Retry extends Mock implements RetryInterviewGenerationUseCase {}

class _Submit extends Mock implements SubmitAnswerUseCase {}

class _Finish extends Mock implements FinishInterviewUseCase {}

class _Report extends Mock implements GetInterviewReportUseCase {}

class _History extends Mock implements GetSimulationsHistoryUseCase {}

class _Profile extends Mock implements GetMyCvProfileUseCase {}

class LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const LoadedLocalizationsDelegate(this.loaded);

  final Map<String, AppLocalizations> loaded;

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
  const evaluation = AnswerEvaluation(
    questionId: 'q-1',
    score: 70,
    skipped: false,
  );

  late _StartByJob startByJob;
  late _Submit submit;
  late _Profile profile;
  late InterviewCubit interview;
  late ScriptedQuestionAudioApi api;
  late FakeQuestionAudioPlayer player;
  late QuestionAudioCubit audio;
  late SpeechInputCubit speech;
  late Future<Either<Failure, QuestionAudio>> Function(String id) respond;

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
      numQuestions: 5,
    ));
    registerFallbackValue(const StartInterviewByJobDescriptionParams(
      jobDescription: 'A sufficiently long job description.',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 5,
    ));
    registerFallbackValue(
      const RetryInterviewGenerationParams(simulationId: 'sim'),
    );
    registerFallbackValue(const SubmitAnswerParams(
      questionId: 'q-1',
      skipped: false,
    ));
    registerFallbackValue(const FinishInterviewParams(simulationId: 'sim'));
    registerFallbackValue(const GetInterviewReportParams(simulationId: 'sim'));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    startByJob = _StartByJob();
    submit = _Submit();
    profile = _Profile();
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    when(() => submit(any())).thenAnswer((_) async => const Right(evaluation));
    respond = (id) async => Right(readyQuestionAudio(id));
    api = ScriptedQuestionAudioApi((id) => respond(id));
    player = FakeQuestionAudioPlayer();
    audio = QuestionAudioCubit(getQuestionAudio: api, player: player);
    speech = SpeechInputCubit(
      speech: FakeSpeechRecognitionService(),
      permissions: FakeMicrophonePermissionService(),
    );
    interview = InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: _StartByDescription(),
      retryInterviewGenerationUseCase: _Retry(),
      submitAnswerUseCase: submit,
      finishInterviewUseCase: _Finish(),
      getInterviewReportUseCase: _Report(),
      getSimulationsHistoryUseCase: _History(),
      getMyCvProfileUseCase: profile,
    );
  });

  tearDown(() async {
    await interview.close();
    if (!audio.isClosed) await audio.close();
    if (!speech.isClosed) await speech.close();
  });

  Future<void> start(
    List<InterviewQuestion> questions,
  ) async {
    when(() => startByJob(any())).thenAnswer(
      (_) async => Right(InterviewStartResponse(
        simulationId: 'sim-1',
        interviewSettingId: 'setting-1',
        questions: questions,
      )),
    );
    await interview.start(
      mode: InterviewStartMode.byJob,
      input: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      numQuestions: questions.length,
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
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
          value: speech,
          child: BlocProvider.value(
            value: audio,
            child: const InterviewQuestionScreen(),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        final page = settings.name == RoutesName.simulationEvaluation
            ? const InterviewEvaluationScreen()
            : const SizedBox.shrink();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider.value(value: interview, child: page),
        );
      },
    ));
  }

  testWidgets('question text renders while audio is still pending',
      (tester) async {
    final gate = Completer<Either<Failure, QuestionAudio>>();
    respond = (_) => gate.future;
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me about yourself.'),
    ]);
    await pump(tester);
    await tester.pump();

    expect(find.text('Tell me about yourself.'), findsOneWidget);
    expect(find.byKey(const Key('question_audio_preparing')), findsOneWidget);
    expect(api.calls, ['q-1']);
    gate.complete(Right(readyQuestionAudio('q-1')));
    await tester.pump();
  });

  testWidgets('play, pause, and replay follow the player', (tester) async {
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me about yourself.'),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('question_audio_play')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('question_audio_pause')), findsOneWidget);
    expect(player.playCalls, 1);

    await tester.tap(find.byKey(const Key('question_audio_pause')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('question_audio_resume')), findsOneWidget);

    await tester.tap(find.byKey(const Key('question_audio_resume')));
    await tester.pumpAndSettle();
    player.emit(QuestionAudioPlayerSignal.completed);
    await tester.pump();
    expect(find.byKey(const Key('question_audio_replay')), findsOneWidget);
  });

  testWidgets('disabled speech adds no control and makes no request',
      (tester) async {
    await start(const [
      InterviewQuestion(
        id: 'q-1',
        questionText: 'Tell me about yourself.',
        audio: QuestionAudioHint(status: QuestionAudioStatus.disabled),
      ),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Tell me about yourself.'), findsOneWidget);
    expect(find.byKey(const Key('question_audio_play')), findsNothing);
    expect(find.byKey(const Key('question_audio_preparing')), findsNothing);
    expect(api.calls, isEmpty);
  });

  testWidgets('failed audio can be retried without blocking the answer',
      (tester) async {
    await start(const [
      InterviewQuestion(
        id: 'q-1',
        questionText: 'Tell me about yourself.',
        audio: QuestionAudioHint(status: QuestionAudioStatus.failed),
      ),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Audio unavailable'), findsOneWidget);
    expect(find.byKey(const Key('interview_answer_input')), findsOneWidget);
    expect(api.calls, isEmpty);

    await tester.tap(find.byKey(const Key('question_audio_retry')));
    await tester.pumpAndSettle();
    expect(api.calls, ['q-1']);
    expect(find.byKey(const Key('question_audio_play')), findsOneWidget);
  });

  testWidgets('Arabic uses the RTL layout and translated control',
      (tester) async {
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'حدثني عن نفسك.'),
    ]);
    await pump(tester, locale: const Locale('ar'));
    await tester.pumpAndSettle();

    final direction = tester.widget<Directionality>(
      find
          .descendant(
            of: find.byType(InterviewQuestionScreen),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(direction.textDirection, TextDirection.rtl);
    expect(find.text('تشغيل السؤال'), findsOneWidget);
  });

  testWidgets('an answered question does not request audio until play',
      (tester) async {
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me about yourself.'),
    ]);
    await interview.submit('My answer');
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Tell me about yourself.'), findsOneWidget);
    expect(api.calls, isEmpty);
    expect(find.byKey(const Key('question_audio_play')), findsOneWidget);

    await tester.tap(find.byKey(const Key('question_audio_play')));
    await tester.pumpAndSettle();
    expect(api.calls, ['q-1']);
  });

  testWidgets('starting the microphone stops question playback',
      (tester) async {
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me about yourself.'),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('question_audio_play')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('speech_mic_button')));
    await tester.pumpAndSettle();

    expect(player.suspendCalls, greaterThan(0));
    expect(audio.state.playback, QuestionPlaybackStatus.paused);
    expect(speech.state.status.isActive, isTrue);
    expect(find.byKey(const Key('interview_submit_button')), findsOneWidget);
  });

  testWidgets('the second question is requested only when it is shown',
      (tester) async {
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me about yourself.'),
      InterviewQuestion(id: 'q-2', questionText: 'How do you handle feedback?'),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();
    expect(api.calls, ['q-1']);

    await tester.enterText(
      find.byKey(const Key('interview_answer_input')),
      'My answer',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('interview_submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('How do you handle feedback?'), findsOneWidget);
    expect(api.calls, ['q-1', 'q-2']);
  });

  testWidgets('a rejected session is not shown as missing audio',
      (tester) async {
    respond = (_) async =>
        const Left(UnauthorizedFailure('Could not validate credentials'));
    await start(const [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me about yourself.'),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Sign in again to continue this interview.'),
      findsOneWidget,
    );
    expect(find.text('Audio unavailable'), findsNothing);
    expect(find.text('Tell me about yourself.'), findsOneWidget);
    expect(api.calls, ['q-1']);
  });

  testWidgets('the control disables play while recording', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        LoadedLocalizationsDelegate(loaded),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: QuestionAudioControl(
          state: const QuestionAudioState(
            questionId: 'q-1',
            backend: QuestionAudioStatus.ready,
            playback: QuestionPlaybackStatus.ready,
          ),
          questionId: 'q-1',
          recording: true,
          onPlay: () {},
          onPause: () {},
          onResume: () {},
          onReplay: () {},
          onRetry: () {},
        ),
      ),
    ));

    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('question_audio_play')))
          .onPressed,
      isNull,
    );
  });
}
