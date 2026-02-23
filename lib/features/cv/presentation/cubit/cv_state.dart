part of 'cv_cubit.dart';

abstract class CvState extends Equatable {
  const CvState();

  @override
  List<Object?> get props => [];
}

class CvInitial extends CvState {}

class CvUploading extends CvState {}

class CvUploaded extends CvState {
  final Cv cv;

  const CvUploaded(this.cv);

  @override
  List<Object?> get props => [cv];
}

class CvAnalyzing extends CvState {}

class CvAnalyzed extends CvState {
  final CvAnalysisResult result;

  const CvAnalyzed(this.result);

  @override
  List<Object?> get props => [result];
}

class SkillsUpdating extends CvState {}

class SkillsUpdated extends CvState {}

class SkillDeleting extends CvState {}

class SkillDeleted extends CvState {}

class CvError extends CvState {
  final String message;

  const CvError(this.message);

  @override
  List<Object?> get props => [message];
}
