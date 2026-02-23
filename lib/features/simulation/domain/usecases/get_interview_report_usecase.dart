import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_report.dart';
import '../repositories/interview_repository.dart';

class GetInterviewReportUseCase
    implements UseCase<InterviewReport, GetInterviewReportParams> {
  final InterviewRepository repository;

  GetInterviewReportUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewReport>> call(
      GetInterviewReportParams params) async {
    return await repository.getReport(params.simulationId);
  }
}

class GetInterviewReportParams extends Equatable {
  final String simulationId;

  const GetInterviewReportParams({required this.simulationId});

  @override
  List<Object> get props => [simulationId];
}
