import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/cv_local_datasource.dart';
import '../../domain/cv_file_rules.dart';
import '../../domain/entities/cv_analysis_result.dart';
import '../../domain/entities/persisted_cv_record.dart';
import '../../domain/entities/selected_cv_file.dart';
import '../../domain/usecases/analyze_cv_usecase.dart';
import '../../domain/usecases/delete_skill_usecase.dart';
import '../../domain/usecases/update_skills_usecase.dart';
import '../../domain/usecases/upload_cv_usecase.dart';

part 'cv_state.dart';

class CvCubit extends Cubit<CvState> {
  final UploadCvUseCase uploadCvUseCase;
  final AnalyzeCvUseCase analyzeCvUseCase;
  final UpdateSkillsUseCase updateSkillsUseCase;
  final DeleteSkillUseCase deleteSkillUseCase;
  final CvLocalDataSource localDataSource;
  final SecureStorageService secureStorage;

  SelectedCvFile? _selected;
  bool _selectionUploaded = false;
  PersistedCvRecord? _persisted;
  String? _memoryCvId;
  String? _memoryFileName;
  String? _activeUserId;
  bool _operationInFlight = false;
  CvAnalysisResult? _sessionResult;

  CvCubit({
    required this.uploadCvUseCase,
    required this.analyzeCvUseCase,
    required this.updateSkillsUseCase,
    required this.deleteSkillUseCase,
    required this.localDataSource,
    required this.secureStorage,
  }) : super(const CvReady());

  Future<void> load() async {
    if (_operationInFlight) return;
    final userId = await secureStorage.read(key: 'user_id');
    if (userId == null || userId.isEmpty) {
      if (_activeUserId != null) {
        _memoryCvId = null;
        _selected = null;
        _selectionUploaded = false;
      }
      _activeUserId = null;
      _persisted = null;
      if (!isClosed && _memoryCvId == null) emit(const CvReady());
      return;
    }
    if (_memoryCvId != null && userId == _activeUserId) return;
    if (userId != _activeUserId) {
      _memoryCvId = null;
      _selected = null;
      _selectionUploaded = false;
      _sessionResult = null;
    }
    _activeUserId = userId;
    try {
      final record = await localDataSource.read(userId);
      _persisted = record;
      if (isClosed || _operationInFlight || _memoryCvId != null) return;
      if (_selected != null && _selectionUploaded == false) {
        _emit(CvFileSelected(file: _selected!, preserved: record));
        return;
      }
      if (record == null) {
        emit(const CvReady());
      } else if (record.analysisCompleted) {
        emit(CvAnalysisRecorded(cvId: record.uploadedCvId));
      } else {
        emit(CvUploadSaved(cvId: record.uploadedCvId));
      }
    } on CacheException catch (e) {
      if (!isClosed && _selected == null) emit(CvStorageReadFailed(e.message));
    }
  }

  Future<void> selectFile(SelectedCvFile file) async {
    if (_operationInFlight) return;
    final problem = CvFileRules.validate(file);
    if (problem != null) {
      _selected = null;
      _selectionUploaded = false;
      _emit(CvFileRejected(problem, preserved: _persisted));
      return;
    }
    _selected = file;
    _selectionUploaded = false;
    _emit(CvFileSelected(file: file, preserved: _persisted));
  }

  /// One user action: upload, persist the id, then analyze.
  /// A previously persisted unanalyzed CV is analyzed without another upload.
  Future<void> startAnalysis() async {
    if (_operationInFlight || _memoryCvId != null) return;
    _operationInFlight = true;
    try {
      final file = _selected;
      if (file != null && !_selectionUploaded) {
        await _uploadThenAnalyze(file);
        return;
      }
      final saved = _persisted;
      if (saved != null && !saved.analysisCompleted) {
        await _analyzeOnly(saved.uploadedCvId);
      }
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> retryAnalysis() async {
    if (_operationInFlight || _memoryCvId != null) return;
    final saved = _persisted;
    if (saved == null || saved.analysisCompleted) return;
    _operationInFlight = true;
    try {
      await _analyzeOnly(saved.uploadedCvId);
    } finally {
      _operationInFlight = false;
    }
  }

  /// Writes the in-memory upload id. Does not upload or analyze.
  Future<void> retryPersistence() async {
    if (_operationInFlight) return;
    final cvId = _memoryCvId;
    if (cvId == null) {
      if (_sessionResult != null &&
          _persisted != null &&
          !_persisted!.analysisCompleted) {
        await _persistAnalyzedFlag(_persisted!.uploadedCvId);
      }
      return;
    }
    _operationInFlight = true;
    try {
      final saved = await _writeUploaded(cvId, _memoryFileName ?? '');
      if (!saved || isClosed) return;
      _selectionUploaded = true;
      _memoryCvId = null;
      _emit(CvUploadSaved(cvId: cvId, fileName: _memoryFileName));
    } finally {
      _operationInFlight = false;
    }
  }

  void cancelActiveRequest() {
    uploadCvUseCase.cancel();
    analyzeCvUseCase.cancel();
  }

  Future<void> updateSkills(List<String> skills) async {
    if (_operationInFlight) return;
    _emit(SkillsUpdating());
    final result =
        await updateSkillsUseCase(UpdateSkillsParams(skills: skills));
    result.fold(
      (failure) => _emit(CvError(failure.message)),
      (_) => _emit(SkillsUpdated()),
    );
  }

  Future<void> deleteSkill(String skill) async {
    if (_operationInFlight) return;
    _emit(SkillDeleting());
    final result = await deleteSkillUseCase(DeleteSkillParams(skill: skill));
    result.fold(
      (failure) => _emit(CvError(failure.message)),
      (_) => _emit(SkillDeleted()),
    );
  }

  Future<void> _uploadThenAnalyze(SelectedCvFile file) async {
    final preserved = _persisted;
    _emit(CvUploading(
      fileName: file.name,
      sent: 0,
      total: file.sizeBytes,
      preserved: preserved,
    ));
    final result = await uploadCvUseCase(UploadCvParams(
      bytes: file.bytes,
      fileName: file.name,
      onProgress: (sent, total) {
        if (!_operationInFlight || isClosed) return;
        _emit(CvUploading(
          fileName: file.name,
          sent: sent,
          total: total,
          preserved: preserved,
        ));
      },
    ));
    if (isClosed) return;
    final uploaded = result.fold<String?>((failure) {
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        _emit(CvSessionExpired());
        return null;
      }
      _emit(CvUploadFailed(
        message: failure.message,
        cancelled: failure is RequestCancelledFailure,
        preserved: preserved,
        fileName: file.name,
      ));
      return null;
    }, (cv) => cv.cvId);
    if (uploaded == null) return;

    final saved = await _writeUploaded(uploaded, file.name);
    if (!saved || isClosed) return;
    _selectionUploaded = true;
    _memoryCvId = null;
    await _analyzeOnly(uploaded, fileName: file.name);
  }

  Future<bool> _writeUploaded(String cvId, String fileName) async {
    _memoryCvId = cvId;
    _memoryFileName = fileName;
    _emit(CvSavingUpload(cvId: cvId, fileName: fileName));
    final userId = await secureStorage.read(key: 'user_id');
    if (userId == null || userId.isEmpty) {
      _emit(CvAwaitingPersistence(
        cvId: cvId,
        fileName: fileName,
        missingUser: true,
        preserved: _persisted,
      ));
      return false;
    }
    final next = PersistedCvRecord(uploadedCvId: cvId, analyzedCvId: null);
    try {
      await localDataSource.write(userId, next);
    } on CacheException {
      _emit(CvAwaitingPersistence(
        cvId: cvId,
        fileName: fileName,
        preserved: _persisted,
      ));
      return false;
    }
    _persisted = next;
    _activeUserId = userId;
    return true;
  }

  Future<void> _analyzeOnly(String cvId, {String? fileName}) async {
    if (_persisted?.uploadedCvId != cvId) return;
    _emit(CvAnalyzing(cvId: cvId, fileName: fileName));
    final result = await analyzeCvUseCase(AnalyzeCvParams(cvId: cvId));
    if (isClosed) return;
    await result.fold<Future<void>>((failure) async {
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        _emit(CvSessionExpired());
        return;
      }
      _emit(CvAnalysisFailed(
        cvId: cvId,
        message: failure.message,
        stop: _stopFor(failure),
      ));
    }, (analysis) async {
      _sessionResult = analysis;
      final persisted = await _persistAnalyzedFlag(cvId);
      _emit(CvAnalyzed(
        cvId: cvId,
        result: analysis,
        statusPersisted: persisted,
      ));
    });
  }

  Future<bool> _persistAnalyzedFlag(String cvId) async {
    final userId = await secureStorage.read(key: 'user_id');
    if (userId == null || userId.isEmpty) return false;
    final next = PersistedCvRecord(uploadedCvId: cvId, analyzedCvId: cvId);
    try {
      await localDataSource.write(userId, next);
    } on CacheException {
      return false;
    }
    _persisted = next;
    if (_sessionResult != null && !isClosed && state is CvAnalyzed) {
      _emit(CvAnalyzed(
        cvId: cvId,
        result: _sessionResult!,
        statusPersisted: true,
      ));
    }
    return true;
  }

  CvAnalysisStop _stopFor(Failure failure) {
    if (failure is RequestCancelledFailure) {
      return CvAnalysisStop.clientCancelled;
    }
    if (failure is RequestTimeoutFailure || failure is GatewayTimeoutFailure) {
      return CvAnalysisStop.timedOut;
    }
    return CvAnalysisStop.failed;
  }

  void _emit(CvState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() {
    cancelActiveRequest();
    return super.close();
  }
}
