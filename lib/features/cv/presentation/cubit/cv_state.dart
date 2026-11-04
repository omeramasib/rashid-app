part of 'cv_cubit.dart';

enum CvAnalysisStop { failed, timedOut, clientCancelled }

abstract class CvState extends Equatable {
  const CvState();

  @override
  List<Object?> get props => [];
}

class CvInitial extends CvState {}

class CvReady extends CvState {
  final PersistedCvRecord? preserved;

  const CvReady({this.preserved});

  @override
  List<Object?> get props => [preserved];
}

class CvFileSelected extends CvState {
  final SelectedCvFile file;
  final PersistedCvRecord? preserved;

  const CvFileSelected({required this.file, this.preserved});

  @override
  List<Object?> get props => [file, preserved];
}

class CvFileRejected extends CvState {
  final CvFileProblem problem;
  final PersistedCvRecord? preserved;

  const CvFileRejected(this.problem, {this.preserved});

  @override
  List<Object?> get props => [problem, preserved];
}

class CvUploading extends CvState {
  final String fileName;
  final int sent;
  final int total;
  final PersistedCvRecord? preserved;

  const CvUploading({
    required this.fileName,
    required this.sent,
    required this.total,
    this.preserved,
  });

  @override
  List<Object?> get props => [fileName, sent, total, preserved];
}

class CvSavingUpload extends CvState {
  final String cvId;
  final String fileName;

  const CvSavingUpload({required this.cvId, required this.fileName});

  @override
  List<Object?> get props => [cvId, fileName];
}

class CvAwaitingPersistence extends CvState {
  final String cvId;
  final String? fileName;
  final bool missingUser;
  final PersistedCvRecord? preserved;

  const CvAwaitingPersistence({
    required this.cvId,
    this.fileName,
    this.missingUser = false,
    this.preserved,
  });

  @override
  List<Object?> get props => [cvId, fileName, missingUser, preserved];
}

class CvUploadSaved extends CvState {
  final String cvId;
  final String? fileName;

  const CvUploadSaved({required this.cvId, this.fileName});

  @override
  List<Object?> get props => [cvId, fileName];
}

class CvUploadFailed extends CvState {
  final String message;
  final bool cancelled;
  final PersistedCvRecord? preserved;
  final String? fileName;

  const CvUploadFailed({
    required this.message,
    this.cancelled = false,
    this.preserved,
    this.fileName,
  });

  @override
  List<Object?> get props => [message, cancelled, preserved, fileName];
}

class CvAnalyzing extends CvState {
  final String cvId;
  final String? fileName;

  const CvAnalyzing({required this.cvId, this.fileName});

  @override
  List<Object?> get props => [cvId, fileName];
}

class CvAnalysisFailed extends CvState {
  final String cvId;
  final String message;
  final CvAnalysisStop stop;

  const CvAnalysisFailed({
    required this.cvId,
    required this.message,
    required this.stop,
  });

  @override
  List<Object?> get props => [cvId, message, stop];
}

class CvAnalyzed extends CvState {
  final String cvId;
  final CvAnalysisResult result;
  final bool statusPersisted;
  final List<String> skills;
  final bool skillAdded;

  /// True only after GET /cv/me reports this CV as processed.
  final bool profileConfirmed;

  const CvAnalyzed({
    required this.cvId,
    required this.result,
    required this.statusPersisted,
    required this.skills,
    this.skillAdded = false,
    this.profileConfirmed = false,
  });

  @override
  List<Object?> get props => [
        cvId,
        result,
        statusPersisted,
        skills,
        skillAdded,
        profileConfirmed,
      ];
}

class CvAnalysisRecorded extends CvState {
  final String cvId;

  const CvAnalysisRecorded({required this.cvId});

  @override
  List<Object?> get props => [cvId];
}

class CvProfileLoading extends CvState {
  const CvProfileLoading();
}

class CvProfileLoadFailed extends CvState {
  final Failure failure;

  const CvProfileLoadFailed(this.failure);

  @override
  List<Object?> get props => [failure.runtimeType, failure.message];
}

class CvPendingAnalysis extends CvState {
  final String cvId;

  const CvPendingAnalysis({required this.cvId});

  @override
  List<Object?> get props => [cvId];
}

class CvAnalysisInProgress extends CvState {
  final String cvId;

  const CvAnalysisInProgress({required this.cvId});

  @override
  List<Object?> get props => [cvId];
}

class CvStorageReadFailed extends CvState {
  final String message;

  const CvStorageReadFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class CvSessionExpired extends CvState {}

class SkillsUpdating extends CvState {
  final String? cvId;
  final CvAnalysisResult? result;
  final bool statusPersisted;
  final List<String> skills;

  const SkillsUpdating({
    this.cvId,
    this.result,
    this.statusPersisted = false,
    this.skills = const [],
  });

  @override
  List<Object?> get props => [cvId, result, statusPersisted, skills];
}

class SkillsUpdated extends CvState {}

class SkillDeleting extends CvState {
  final String? cvId;
  final CvAnalysisResult? result;
  final bool statusPersisted;
  final List<String> skills;

  const SkillDeleting({
    this.cvId,
    this.result,
    this.statusPersisted = false,
    this.skills = const [],
  });

  @override
  List<Object?> get props => [cvId, result, statusPersisted, skills];
}

class SkillDeleted extends CvState {}

class CvError extends CvState {
  final String message;
  final Failure? failure;
  final String? cvId;
  final CvAnalysisResult? result;
  final bool statusPersisted;
  final List<String> skills;

  const CvError(
    this.message, {
    this.failure,
    this.cvId,
    this.result,
    this.statusPersisted = false,
    this.skills = const [],
  });

  @override
  List<Object?> get props =>
      [message, failure, cvId, result, statusPersisted, skills];
}
