import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/interview_start_response.dart';
import '../entities/interview_report.dart';
import '../entities/interview_simulation_history.dart';

abstract class InterviewRepository {
  Future<Either<Failure, InterviewStartResponse>> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  });

  Future<Either<Failure, InterviewStartResponse>> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  });

  Future<Either<Failure, void>> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  });

  Future<Either<Failure, void>> finishInterview(String simulationId);

  Future<Either<Failure, InterviewReport>> getReport(String simulationId);

  Future<Either<Failure, List<InterviewSimulationHistory>>>
      getSimulationsHistory();
}
