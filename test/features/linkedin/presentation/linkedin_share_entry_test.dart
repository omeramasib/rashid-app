import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_share_request.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_report.dart';
import 'package:rashed_app/features/simulation/domain/usecases/finish_interview_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_interview_report_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_simulations_history_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/retry_interview_generation_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_description_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/submit_answer_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_result_screen.dart';

class _StartByJob extends Mock implements StartInterviewByJobUseCase {}

class _StartByDescription extends Mock
    implements StartInterviewByJobDescriptionUseCase {}

class _Retry extends Mock implements RetryInterviewGenerationUseCase {}

class _Submit extends Mock implements SubmitAnswerUseCase {}

class _Finish extends Mock implements FinishInterviewUseCase {}

class _Report extends Mock implements GetInterviewReportUseCase {}

class _History extends Mock implements GetSimulationsHistoryUseCase {}

class _Profile extends Mock implements GetMyCvProfileUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetInterviewReportParams(simulationId: 'sim'));
    registerFallbackValue(NoParams());
  });

  testWidgets('the result screen shares its own simulation id', (tester) async {
    final report = _Report();
    when(() => report(any())).thenAnswer(
      (_) async => const Right(InterviewReport(
        simulationId: 'sim-owned',
        score: 82,
        questions: [
          InterviewReportQuestion(
            id: 'q-1',
            questionText: 'Question',
            isSkipped: false,
          ),
        ],
      )),
    );
    final cubit = InterviewCubit(
      startInterviewByJobUseCase: _StartByJob(),
      startInterviewByJobDescriptionUseCase: _StartByDescription(),
      retryInterviewGenerationUseCase: _Retry(),
      submitAnswerUseCase: _Submit(),
      finishInterviewUseCase: _Finish(),
      getInterviewReportUseCase: report,
      getSimulationsHistoryUseCase: _History(),
      getMyCvProfileUseCase: _Profile(),
    );
    addTearDown(cubit.close);
    await cubit.openCompletedReport('sim-owned');

    Object? arguments;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: BlocProvider.value(
        value: cubit,
        child: const InterviewResultScreen(),
      ),
      onGenerateRoute: (settings) {
        arguments = settings.arguments;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SizedBox.shrink(),
        );
      },
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interview_share_button')));
    await tester.pumpAndSettle();

    expect(
      (arguments! as LinkedInShareRequest).simulationId,
      'sim-owned',
    );
    expect((arguments! as LinkedInShareRequest).resultLabel, '82');
    verify(
      () => report(const GetInterviewReportParams(simulationId: 'sim-owned')),
    ).called(1);
  });
}
