import '../../../../core/error/failures.dart';

/// Start failed. [cause] keeps the original failure type.
/// [simulationId] is set when the backend returned `X-Simulation-Id`.
class InterviewStartFailure extends Failure {
  final Failure cause;
  final String? simulationId;

  const InterviewStartFailure(this.cause, {this.simulationId}) : super('');

  @override
  String get message => cause.message;

  @override
  List<Object> get props => [cause, simulationId ?? ''];
}
