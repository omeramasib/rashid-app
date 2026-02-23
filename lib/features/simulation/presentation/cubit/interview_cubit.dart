import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/interview_report.dart';
import '../../domain/entities/interview_simulation_history.dart';
import '../../domain/usecases/finish_interview_usecase.dart';
import '../../domain/usecases/get_interview_report_usecase.dart';
import '../../domain/usecases/get_simulations_history_usecase.dart';
import '../../domain/usecases/start_interview_by_job_description_usecase.dart';
import '../../domain/usecases/start_interview_by_job_usecase.dart';
import '../../domain/usecases/submit_answer_usecase.dart';

part 'interview_state.dart';

class InterviewCubit extends Cubit<InterviewState> {
  final StartInterviewByJobUseCase startInterviewByJobUseCase;
  final StartInterviewByJobDescriptionUseCase
      startInterviewByJobDescriptionUseCase;
  final SubmitAnswerUseCase submitAnswerUseCase;
  final FinishInterviewUseCase finishInterviewUseCase;
  final GetInterviewReportUseCase getInterviewReportUseCase;
  final GetSimulationsHistoryUseCase getSimulationsHistoryUseCase;

  InterviewCubit({
    required this.startInterviewByJobUseCase,
    required this.startInterviewByJobDescriptionUseCase,
    required this.submitAnswerUseCase,
    required this.finishInterviewUseCase,
    required this.getInterviewReportUseCase,
    required this.getSimulationsHistoryUseCase,
  }) : super(InterviewInitial());

  Future<void> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  }) async {
    emit(InterviewStarting());
    final result = await startInterviewByJobUseCase(
      StartInterviewByJobParams(
        jobField: jobField,
        interviewType: interviewType,
        difficulty: difficulty,
        language: language,
        simulationType: simulationType,
        numQuestions: numQuestions,
      ),
    );

    result.fold(
      (failure) => emit(InterviewError(failure.message)),
      (response) => emit(InterviewInProgress(
        simulationId: response.simulationId,
        questions: response.questions,
        currentIndex: 0,
      )),
    );
  }

  Future<void> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  }) async {
    emit(InterviewStarting());
    final result = await startInterviewByJobDescriptionUseCase(
      StartInterviewByJobDescriptionParams(
        jobDescription: jobDescription,
        interviewType: interviewType,
        difficulty: difficulty,
        language: language,
        simulationType: simulationType,
        numQuestions: numQuestions,
      ),
    );

    result.fold(
      (failure) => emit(InterviewError(failure.message)),
      (response) => emit(InterviewInProgress(
        simulationId: response.simulationId,
        questions: response.questions,
        currentIndex: 0,
      )),
    );
  }

  Future<void> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
    required String simulationId,
    required List<InterviewQuestion> questions,
    required int currentIndex,
  }) async {
    emit(AnswerSubmitting(
      simulationId: simulationId,
      questions: questions,
      currentIndex: currentIndex,
    ));

    final result = await submitAnswerUseCase(
      SubmitAnswerParams(
        questionId: questionId,
        skipped: skipped,
        answerText: answerText,
      ),
    );

    result.fold(
      (failure) => emit(InterviewError(failure.message)),
      (_) {
        // Navigate to next question if available
        if (currentIndex + 1 < questions.length) {
          emit(InterviewInProgress(
            simulationId: simulationId,
            questions: questions,
            currentIndex: currentIndex + 1,
          ));
        } else {
          // If no more questions, finish the interview
          finishInterview(simulationId);
        }
      },
    );
  }

  Future<void> finishInterview(String simulationId) async {
    emit(InterviewFinishing());
    final finishResult = await finishInterviewUseCase(
      FinishInterviewParams(simulationId: simulationId),
    );

    await finishResult.fold(
      (failure) async => emit(InterviewError(failure.message)),
      (_) async {
        // Fetch report after successfully finishing
        final reportResult = await getInterviewReportUseCase(
          GetInterviewReportParams(simulationId: simulationId),
        );

        reportResult.fold(
          (failure) => emit(InterviewError(failure.message)),
          (report) => emit(InterviewFinished(report)),
        );
      },
    );
  }

  Future<void> getHistory() async {
    emit(InterviewHistoryLoading());
    final result = await getSimulationsHistoryUseCase(NoParams());
    result.fold(
      (failure) => emit(InterviewError(failure.message)),
      (history) => emit(InterviewHistoryLoaded(history)),
    );
  }
}
