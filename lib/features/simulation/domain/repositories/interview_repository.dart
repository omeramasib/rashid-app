import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/answer_evaluation.dart';
import '../entities/interview_finish_result.dart';
import '../entities/interview_report.dart';
import '../entities/interview_simulation_history.dart';
import '../entities/interview_start_response.dart';

abstract class InterviewRepository {
  Future<Either<Failure, InterviewStartResponse>> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  });

  Future<Either<Failure, InterviewStartResponse>> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  });

  Future<Either<Failure, InterviewStartResponse>> retryGeneration(
    String simulationId,
  );

  Future<Either<Failure, AnswerEvaluation>> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  });

  Future<Either<Failure, InterviewFinishResult>> finishInterview(
    String simulationId,
  );

  Future<Either<Failure, InterviewReport>> getReport(String simulationId);

  Future<Either<Failure, List<InterviewSimulationHistory>>>
      getSimulationsHistory();
}
