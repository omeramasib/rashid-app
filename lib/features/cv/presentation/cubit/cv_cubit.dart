import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/cv_local_datasource.dart';
import '../../domain/cv_file_rules.dart';
import '../../domain/entities/cv_analysis_result.dart';
import '../../domain/entities/cv_profile.dart';
import '../../domain/entities/persisted_cv_record.dart';
import '../../domain/entities/selected_cv_file.dart';
import '../../domain/usecases/analyze_cv_usecase.dart';
import '../../domain/usecases/delete_skill_usecase.dart';
import '../../domain/usecases/get_my_cv_profile_usecase.dart';
import '../../domain/usecases/update_skills_usecase.dart';
import '../../domain/usecases/upload_cv_usecase.dart';

part 'cv_state.dart';

class CvCubit extends Cubit<CvState> {
  final UploadCvUseCase uploadCvUseCase;
  final AnalyzeCvUseCase analyzeCvUseCase;
  final UpdateSkillsUseCase updateSkillsUseCase;
  final DeleteSkillUseCase deleteSkillUseCase;
  final GetMyCvProfileUseCase getMyCvProfileUseCase;
  final CvLocalDataSource localDataSource;
  final SecureStorageService secureStorage;

  SelectedCvFile? _selected;
  bool _selectionUploaded = false;
  PersistedCvRecord? _persisted;
  String? _memoryCvId;
  String? _memoryFileName;
  String? _activeUserId;
  bool _operationInFlight = false;
  bool _profileRequestInFlight = false;
  CvAnalysisResult? _sessionResult;

  CvCubit({
    required this.uploadCvUseCase,
    required this.analyzeCvUseCase,
    required this.updateSkillsUseCase,
    required this.deleteSkillUseCase,
    required this.getMyCvProfileUseCase,
    required this.localDataSource,
    required this.secureStorage,
  }) : super(const CvReady());

  /// Loads the server profile for the signed-in user.
  ///
  /// Does not upload or analyze. A network failure stays a load failure.
  Future<void> load() async {
    if (_operationInFlight || _profileRequestInFlight) return;
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
    _profileRequestInFlight = true;
    try {
      PersistedCvRecord? record;
      try {
        record = await localDataSource.read(userId);
      } on CacheException catch (e) {
        if (!isClosed && _selected == null) {
          emit(CvStorageReadFailed(e.message));
        }
        return;
      }
      _persisted = record;
      if (isClosed || _operationInFlight || _memoryCvId != null) return;
      if (_selected != null && _selectionUploaded == false) {
        _emit(CvFileSelected(file: _selected!, preserved: record));
        return;
      }
      _emit(const CvProfileLoading());
      final result = await getMyCvProfileUseCase(NoParams());
      if (isClosed || _operationInFlight || _memoryCvId != null) return;
      await result.fold((failure) async {
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          _emit(CvSessionExpired());
          return;
        }
        _emit(CvProfileLoadFailed(failure));
      }, (profile) async {
        await _applyRemoteProfile(profile);
      });
    } catch (_) {
      if (!isClosed) {
        _emit(const CvProfileLoadFailed(
          ServerFailure('Unexpected CV profile response'),
        ));
      }
    } finally {
      _profileRequestInFlight = false;
    }
  }

  Future<void> refreshProfile() => load();

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
    if (_operationInFlight ||
        _memoryCvId != null ||
        _profileRequestInFlight ||
        (!_savedAnalysisAllowed && _selected == null)) {
      return;
    }
    _operationInFlight = true;
    try {
      final file = _selected;
      if (file != null && !_selectionUploaded) {
        await _uploadThenAnalyze(file);
        return;
      }
      if (!_savedAnalysisAllowed) return;
      final saved = _persisted;
      if (saved != null && !saved.analysisCompleted) {
        await _analyzeOnly(saved.uploadedCvId);
      }
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> retryAnalysis() async {
    if (_operationInFlight || _memoryCvId != null || _profileRequestInFlight) {
      return;
    }
    final current = state;
    if (current is! CvAnalysisFailed ||
        current.stop == CvAnalysisStop.timedOut) {
      return;
    }
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
    await _saveSkills(skills, continueAfterSave: true);
  }

  /// Appends one skill and stores the complete list.
  ///
  /// Empty values and case-insensitive duplicates are ignored. The returned
  /// flag is true only after GET /cv/me has replaced the visible profile.
  Future<bool> addSkill(String raw, {List<String>? existing}) async {
    if (_operationInFlight) return false;
    final trimmed = raw.trim();
    final current =
        List<String>.of(existing ?? _skillSnapshot()?.skills ?? const []);
    if (trimmed.isEmpty || _hasSkill(current, trimmed)) return false;
    return _saveSkills(
      [...current, trimmed],
      continueAfterSave: false,
    );
  }

  /// Drops a skill from the visible draft. The server list changes on save.
  void omitSkill(String skill) {
    if (_operationInFlight) return;
    final previous = _skillSnapshot();
    if (previous == null) return;
    final skills = [...previous.skills]..remove(skill);
    final current = state;
    if (current is CvError) {
      _emit(CvError(
        current.message,
        failure: current.failure,
        cvId: previous.cvId,
        result: previous.result,
        statusPersisted: previous.statusPersisted,
        skills: skills,
      ));
      return;
    }
    _emit(CvAnalyzed(
      cvId: previous.cvId,
      result: previous.result,
      statusPersisted: previous.statusPersisted,
      skills: skills,
    ));
  }

  Future<void> deleteSkill(String skill) async {
    if (_operationInFlight) return;
    final previous = _skillSnapshot();
    _operationInFlight = true;
    _emit(_deleting(previous));
    try {
      final result = await deleteSkillUseCase(DeleteSkillParams(skill: skill));
      if (isClosed) return;
      await result.fold((failure) async {
        _emitSkillFailure(failure, previous: previous);
      }, (_) async {
        await _refreshProfileAfterSkillChange(
          continueAfterSave: true,
          previous: previous,
        );
      });
    } finally {
      _operationInFlight = false;
    }
  }

  bool _hasSkill(List<String> skills, String skill) {
    final needle = skill.toLowerCase();
    return skills.any((item) => item.trim().toLowerCase() == needle);
  }

  Future<bool> _saveSkills(
    List<String> skills, {
    required bool continueAfterSave,
  }) async {
    if (_operationInFlight) return false;
    final previous = _skillSnapshot();
    _operationInFlight = true;
    _emit(_updating(previous));
    try {
      final result =
          await updateSkillsUseCase(UpdateSkillsParams(skills: skills));
      if (isClosed) return false;
      return await result.fold<Future<bool>>((failure) async {
        _emitSkillFailure(failure, previous: previous);
        return false;
      }, (_) async {
        return _refreshProfileAfterSkillChange(
          continueAfterSave: continueAfterSave,
          previous: previous,
        );
      });
    } finally {
      _operationInFlight = false;
    }
  }

  void _emitSkillFailure(Failure failure, {_SkillSnapshot? previous}) {
    if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
      _emit(CvSessionExpired());
      return;
    }
    _emit(CvError(
      failure.message,
      failure: failure,
      cvId: previous?.cvId,
      result: previous?.result,
      statusPersisted: previous?.statusPersisted ?? false,
      skills: List<String>.of(previous?.skills ?? const []),
    ));
  }

  SkillsUpdating _updating(_SkillSnapshot? previous) {
    return SkillsUpdating(
      cvId: previous?.cvId,
      result: previous?.result,
      statusPersisted: previous?.statusPersisted ?? false,
      skills: List<String>.of(previous?.skills ?? const []),
    );
  }

  SkillDeleting _deleting(_SkillSnapshot? previous) {
    return SkillDeleting(
      cvId: previous?.cvId,
      result: previous?.result,
      statusPersisted: previous?.statusPersisted ?? false,
      skills: List<String>.of(previous?.skills ?? const []),
    );
  }

  _SkillSnapshot? _skillSnapshot() {
    final current = state;
    if (current is CvAnalyzed) {
      return _SkillSnapshot(
        cvId: current.cvId,
        result: current.result,
        statusPersisted: current.statusPersisted,
        skills: current.skills,
      );
    }
    if (current is SkillsUpdating &&
        current.cvId != null &&
        current.result != null) {
      return _SkillSnapshot(
        cvId: current.cvId!,
        result: current.result!,
        statusPersisted: current.statusPersisted,
        skills: current.skills,
      );
    }
    if (current is SkillDeleting &&
        current.cvId != null &&
        current.result != null) {
      return _SkillSnapshot(
        cvId: current.cvId!,
        result: current.result!,
        statusPersisted: current.statusPersisted,
        skills: current.skills,
      );
    }
    if (current is CvError && current.cvId != null && current.result != null) {
      return _SkillSnapshot(
        cvId: current.cvId!,
        result: current.result!,
        statusPersisted: current.statusPersisted,
        skills: current.skills,
      );
    }
    return null;
  }

  bool get _savedAnalysisAllowed {
    final current = state;
    if (current is CvPendingAnalysis || current is CvUploadSaved) return true;
    if (current is CvAnalysisFailed &&
        current.stop != CvAnalysisStop.timedOut) {
      return true;
    }
    return false;
  }

  /// GET returns the newest processed CV, which can be older than an upload
  /// that has not succeeded yet. That older id must not replace the pending one.
  bool _hasNewerUnprocessedUpload(CvProfile profile) {
    final local = _persisted;
    return local != null &&
        !local.analysisCompleted &&
        local.uploadedCvId != profile.cvId;
  }

  Future<void> _applyRemoteProfile(CvProfile? profile) async {
    if (profile != null && _hasNewerUnprocessedUpload(profile)) {
      _emit(CvPendingAnalysis(cvId: _persisted!.uploadedCvId));
      return;
    }
    if (profile == null) {
      _emit(const CvReady());
      return;
    }
    await _syncLocalFromProfile(profile);
    if (isClosed) return;
    switch (profile.status) {
      case CvAnalysisStatus.pending:
        _emit(CvPendingAnalysis(cvId: profile.cvId));
      case CvAnalysisStatus.inProgress:
        _emit(CvAnalysisInProgress(cvId: profile.cvId));
      case CvAnalysisStatus.failed:
        _emit(CvAnalysisFailed(
          cvId: profile.cvId,
          message: '',
          stop: CvAnalysisStop.failed,
        ));
      case CvAnalysisStatus.processed:
        final result = profile.toAnalysisResult();
        _sessionResult = result;
        _emit(CvAnalyzed(
          cvId: profile.cvId,
          result: result,
          statusPersisted: true,
          skills: result.skills,
          profileConfirmed: true,
        ));
    }
  }

  Future<void> _syncLocalFromProfile(CvProfile profile) async {
    if (_hasNewerUnprocessedUpload(profile)) return;
    final analyzed = profile.status == CvAnalysisStatus.processed;
    final next = PersistedCvRecord(
      uploadedCvId: profile.cvId,
      analyzedCvId: analyzed ? profile.cvId : null,
    );
    if (_persisted == next) return;
    _persisted = next;
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      await localDataSource.write(userId, next);
    } on CacheException {
      // Ids may stay in memory for this session. Profile text is not stored.
    }
  }

  /// Replaces the in-memory profile with GET /cv/me.
  ///
  /// [continueAfterSave] keeps the existing save-and-continue transition.
  /// Adding a skill leaves the refreshed profile as the current state.
  Future<bool> _refreshProfileAfterSkillChange({
    required bool continueAfterSave,
    required _SkillSnapshot? previous,
  }) async {
    final refreshed = await getMyCvProfileUseCase(NoParams());
    if (isClosed) return false;
    return refreshed.fold((failure) {
      _emitSkillFailure(failure, previous: previous);
      return false;
    }, (profile) {
      final applied = _emitRefreshedProfile(
        profile,
        skillAdded: !continueAfterSave,
      );
      if (continueAfterSave) {
        _emit(SkillsUpdated());
        return true;
      }
      if (applied) return true;
      _emitSkillFailure(
        const ServerFailure('Your skills could not be refreshed'),
        previous: previous,
      );
      return false;
    });
  }

  bool _emitRefreshedProfile(CvProfile? profile, {bool skillAdded = false}) {
    if (profile == null ||
        profile.status != CvAnalysisStatus.processed ||
        _hasNewerUnprocessedUpload(profile)) {
      return false;
    }
    final result = profile.toAnalysisResult();
    _sessionResult = result;
    final cvId = _persisted?.uploadedCvId ?? profile.cvId;
    _emit(CvAnalyzed(
      cvId: cvId,
      result: result,
      statusPersisted: true,
      skills: result.skills,
      skillAdded: skillAdded,
      profileConfirmed: true,
    ));
    return true;
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
        skills: analysis.skills,
      ));
      await _refreshAfterAnalysis(cvId);
    });
  }

  /// Confirms the profile without replacing a just-analyzed CV with an older one.
  Future<void> _refreshAfterAnalysis(String cvId) async {
    final refreshed = await getMyCvProfileUseCase(NoParams());
    if (isClosed) return;
    refreshed.fold((_) {}, (profile) {
      if (profile == null || profile.cvId != cvId) return;
      if (profile.status != CvAnalysisStatus.processed) return;
      final serverResult = profile.toAnalysisResult();
      final current = state;
      if (current is CvAnalyzed &&
          current.profileConfirmed &&
          current.cvId == cvId &&
          current.result == serverResult) {
        return;
      }
      _sessionResult = serverResult;
      _emit(CvAnalyzed(
        cvId: cvId,
        result: serverResult,
        statusPersisted: true,
        skills: serverResult.skills,
        profileConfirmed: true,
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
      final current = state as CvAnalyzed;
      _emit(CvAnalyzed(
        cvId: cvId,
        result: _sessionResult!,
        statusPersisted: true,
        skills: _sessionResult!.skills,
        profileConfirmed: current.profileConfirmed,
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

class _SkillSnapshot {
  final String cvId;
  final CvAnalysisResult result;
  final bool statusPersisted;
  final List<String> skills;

  const _SkillSnapshot({
    required this.cvId,
    required this.result,
    required this.statusPersisted,
    required this.skills,
  });
}
