import 'package:bloc/bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/linkedin_authorization_launcher.dart';
import '../../data/linkedin_pending_share_store.dart';
import '../../domain/entities/linkedin_connection_status.dart';
import '../../domain/entities/linkedin_publish_result.dart';
import '../../domain/linkedin_oauth_return_link.dart';
import '../../domain/linkedin_urls.dart';
import '../../domain/usecases/disconnect_linkedin_usecase.dart';
import '../../domain/usecases/get_linkedin_status_usecase.dart';
import '../../domain/usecases/mark_linkedin_share_deleted_usecase.dart';
import '../../domain/usecases/preview_linkedin_share_usecase.dart';
import '../../domain/usecases/publish_linkedin_share_usecase.dart';
import '../../domain/usecases/start_linkedin_oauth_usecase.dart';
import 'linkedin_share_state.dart';

/// Lets the next browser return through after a new authorization attempt.
class LinkedInReturnGate {
  String? _lastKey;

  void allowNext() {
    _lastKey = null;
  }

  bool claim(String key) {
    if (key == _lastKey) return false;
    _lastKey = key;
    return true;
  }
}

class LinkedInShareCubit extends Cubit<LinkedInShareState> {
  final GetLinkedInStatusUseCase getStatus;
  final StartLinkedInOAuthUseCase startOAuth;
  final PreviewLinkedInShareUseCase previewShare;
  final PublishLinkedInShareUseCase publishShare;
  final MarkLinkedInShareDeletedUseCase markDeleted;
  final DisconnectLinkedInUseCase disconnectLinkedIn;
  final LinkedInPendingShareStore pendingShare;
  final LinkedInAuthorizationLauncher launcher;
  final LinkedInReturnGate returnGate;

  var _busy = false;

  LinkedInShareCubit({
    required this.getStatus,
    required this.startOAuth,
    required this.previewShare,
    required this.publishShare,
    required this.markDeleted,
    required this.disconnectLinkedIn,
    required this.pendingShare,
    required this.launcher,
    required this.returnGate,
  }) : super(const LinkedInShareState());

  Future<void> begin({
    required String simulationId,
    String? resultLabel,
  }) async {
    final id = simulationId.trim();
    if (id.isEmpty) {
      emit(LinkedInShareState(
        phase: LinkedInSharePhase.error,
        notice: LinkedInShareNotice.notFound,
        resultLabel: resultLabel,
      ));
      return;
    }
    if (_busy) return;
    if (state.phase == LinkedInSharePhase.waitingForOAuthReturn &&
        state.simulationId == id) {
      return;
    }
    _busy = true;
    emit(LinkedInShareState(
      phase: LinkedInSharePhase.checkingConnection,
      simulationId: id,
      resultLabel: resultLabel,
    ));
    final status = await getStatus(NoParams());
    if (isClosed) return;
    await status.fold(
      (failure) async => _emitFailure(failure, simulationId: id),
      (connection) async {
        if (connection.canPublish) {
          await _loadPreview(id, connection: connection);
          return;
        }
        _busy = false;
        emit(LinkedInShareState(
          phase: LinkedInSharePhase.connectionRequired,
          simulationId: id,
          resultLabel: resultLabel ?? state.resultLabel,
          connection: connection,
        ));
      },
    );
  }

  Future<void> connect() async {
    if (_busy) return;
    final simulationId = state.simulationId?.trim();
    if (simulationId == null || simulationId.isEmpty) return;
    _busy = true;
    emit(LinkedInShareState(
      phase: LinkedInSharePhase.startingOAuth,
      simulationId: simulationId,
      resultLabel: state.resultLabel,
      connection: state.connection,
    ));
    final started = await startOAuth(
      LinkedInSimulationParams(simulationId: simulationId),
    );
    if (isClosed) return;
    await started.fold(
      (failure) async => _emitFailure(failure, simulationId: simulationId),
      (oauth) async {
        final uri = Uri.tryParse(oauth.authorizationUrl);
        if (uri == null || !isLinkedInAuthorizationUrl(uri)) {
          _busy = false;
          emit(_error(
            LinkedInShareNotice.unavailable,
            simulationId: simulationId,
          ));
          return;
        }
        await pendingShare.save(simulationId);
        returnGate.allowNext();
        final opened = await launcher.open(uri);
        if (isClosed) return;
        if (!opened) {
          await pendingShare.clear();
          _busy = false;
          emit(_error(
            LinkedInShareNotice.unavailable,
            simulationId: simulationId,
          ));
          return;
        }
        _busy = false;
        emit(LinkedInShareState(
          phase: LinkedInSharePhase.waitingForOAuthReturn,
          simulationId: simulationId,
          resultLabel: state.resultLabel,
          connection: state.connection,
        ));
      },
    );
  }

  Future<void> onOAuthReturn(LinkedInOAuthReturnLink link) async {
    if (_busy) return;
    final pending = (await pendingShare.read())?.trim();
    if (pending == null || pending.isEmpty) return;
    final coldStart = state.phase == LinkedInSharePhase.initial;
    final waiting = state.phase == LinkedInSharePhase.waitingForOAuthReturn;
    if (!coldStart && !waiting) return;

    _busy = true;
    await pendingShare.clear();
    final generation = state.returnGeneration + 1;
    final label = state.resultLabel;
    if (link.result != LinkedInOAuthResult.connected) {
      _busy = false;
      emit(_error(
        _oauthNotice(link.result),
        simulationId: pending,
        resultLabel: label,
        returnGeneration: generation,
      ));
      return;
    }

    emit(LinkedInShareState(
      phase: LinkedInSharePhase.checkingConnection,
      simulationId: pending,
      resultLabel: label,
      returnGeneration: generation,
    ));
    final status = await getStatus(NoParams());
    if (isClosed) return;
    await status.fold(
      (failure) async => _emitFailure(
        failure,
        simulationId: pending,
        returnGeneration: generation,
      ),
      (connection) async {
        if (!connection.canPublish) {
          _busy = false;
          emit(LinkedInShareState(
            phase: LinkedInSharePhase.connectionRequired,
            simulationId: pending,
            resultLabel: label,
            connection: connection,
            returnGeneration: generation,
          ));
          return;
        }
        await _loadPreview(
          pending,
          connection: connection,
          returnGeneration: generation,
        );
      },
    );
  }

  Future<void> refreshPreview() async {
    if (_busy || state.notice != LinkedInShareNotice.previewExpired) return;
    final simulationId = state.simulationId;
    if (simulationId == null || simulationId.isEmpty) return;
    _busy = true;
    await _loadPreview(simulationId, connection: state.connection);
  }

  Future<void> publish() async {
    if (_busy || state.phase != LinkedInSharePhase.previewReady) return;
    final preview = state.preview;
    final simulationId = state.simulationId;
    if (preview == null || simulationId == null) return;
    _busy = true;
    emit(LinkedInShareState(
      phase: LinkedInSharePhase.publishing,
      simulationId: simulationId,
      resultLabel: state.resultLabel,
      connection: state.connection,
      preview: preview,
      returnGeneration: state.returnGeneration,
    ));
    final result = await publishShare(PublishLinkedInParams(
      previewId: preview.previewId,
      simulationId: simulationId,
      contentSha256: preview.contentSha256,
    ));
    if (isClosed) return;
    result.fold(
      (failure) {
        if (failure is ConflictFailure &&
            failure.code == linkedInDifferentContentCode) {
          _busy = false;
          emit(LinkedInShareState(
            phase: LinkedInSharePhase.alreadyShared,
            simulationId: simulationId,
            resultLabel: state.resultLabel,
            connection: state.connection,
            preview: preview,
            postUrl: verifiedLinkedInPostUrl(failure.postUrl),
            activeShareId: failure.shareId,
            notice: LinkedInShareNotice.alreadySharedDifferent,
            returnGeneration: state.returnGeneration,
          ));
          return;
        }
        _emitFailure(failure, simulationId: simulationId);
      },
      (published) {
        _busy = false;
        final postUrl = _postUrl(published);
        if (published.alreadyPublished) {
          emit(LinkedInShareState(
            phase: LinkedInSharePhase.alreadyShared,
            simulationId: simulationId,
            resultLabel: state.resultLabel,
            connection: state.connection,
            preview: preview,
            postUrl: postUrl,
            activeShareId: published.shareId,
            returnGeneration: state.returnGeneration,
          ));
          return;
        }
        emit(LinkedInShareState(
          phase: LinkedInSharePhase.published,
          simulationId: simulationId,
          resultLabel: state.resultLabel,
          connection: state.connection,
          preview: preview,
          postUrl: postUrl,
          returnGeneration: state.returnGeneration,
        ));
      },
    );
  }

  Future<void> markDeletedOnLinkedIn() async {
    if (_busy || state.phase != LinkedInSharePhase.alreadyShared) return;
    final shareId = state.activeShareId;
    final simulationId = state.simulationId;
    if (shareId == null || shareId.isEmpty || simulationId == null) return;
    _busy = true;
    final connection = state.connection;
    final resultLabel = state.resultLabel;
    final generation = state.returnGeneration;
    emit(LinkedInShareState(
      phase: LinkedInSharePhase.markingDeleted,
      simulationId: simulationId,
      resultLabel: resultLabel,
      connection: connection,
      returnGeneration: generation,
    ));
    final result = await markDeleted(
      MarkLinkedInShareDeletedParams(shareId: shareId),
    );
    if (isClosed) return;
    await result.fold<Future<void>>(
      (failure) async {
        _emitMarkDeletedFailure(
          failure,
          simulationId: simulationId,
        );
      },
      (deleted) => _loadPreview(
        simulationId,
        connection: connection,
        returnGeneration: generation,
        blockRepublish: !deleted.allowsFreshPreview,
        readyNotice: deleted.allowsFreshPreview
            ? LinkedInShareNotice.readyToRepublish
            : LinkedInShareNotice.none,
      ),
    );
  }

  Future<void> disconnect() async {
    if (_busy) return;
    _busy = true;
    final result = await disconnectLinkedIn(NoParams());
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitFailure(
        failure,
        simulationId: state.simulationId,
      ),
      (_) async {
        await pendingShare.clear();
        _busy = false;
        emit(LinkedInShareState(
          phase: LinkedInSharePhase.connectionRequired,
          simulationId: state.simulationId,
          resultLabel: state.resultLabel,
          connection: const LinkedInConnectionStatus(
            connected: false,
            publishingEnabled: false,
            reauthorizationRequired: false,
            connectionStatus: LinkedInConnectionState.notConnected,
          ),
          returnGeneration: state.returnGeneration,
        ));
      },
    );
  }

  Future<void> _loadPreview(
    String simulationId, {
    LinkedInConnectionStatus? connection,
    int? returnGeneration,
    bool blockRepublish = false,
    LinkedInShareNotice readyNotice = LinkedInShareNotice.none,
  }) async {
    emit(LinkedInShareState(
      phase: LinkedInSharePhase.loadingPreview,
      simulationId: simulationId,
      resultLabel: state.resultLabel,
      connection: connection ?? state.connection,
      returnGeneration: returnGeneration ?? state.returnGeneration,
    ));
    final preview = await previewShare(
      LinkedInSimulationParams(simulationId: simulationId),
    );
    if (isClosed) return;
    preview.fold(
      (failure) => _emitFailure(
        failure,
        simulationId: simulationId,
        returnGeneration: returnGeneration,
      ),
      (value) {
        _busy = false;
        final generation = returnGeneration ?? state.returnGeneration;
        final currentConnection = connection ?? state.connection;
        if (blockRepublish && value.existingContentMatches == null) {
          emit(LinkedInShareState(
            phase: LinkedInSharePhase.alreadyShared,
            simulationId: simulationId,
            resultLabel: state.resultLabel,
            connection: currentConnection,
            notice: LinkedInShareNotice.otherActivePosts,
            republishBlocked: true,
            returnGeneration: generation,
          ));
          return;
        }
        if (value.existingContentMatches != null) {
          emit(LinkedInShareState(
            phase: LinkedInSharePhase.alreadyShared,
            simulationId: simulationId,
            resultLabel: state.resultLabel,
            connection: currentConnection,
            preview: value,
            postUrl: verifiedLinkedInPostUrl(value.existingPostUrl),
            activeShareId: value.existingShareId,
            republishBlocked: blockRepublish,
            notice: value.existingContentMatches == false
                ? LinkedInShareNotice.alreadySharedDifferent
                : LinkedInShareNotice.none,
            returnGeneration: generation,
          ));
          return;
        }
        emit(LinkedInShareState(
          phase: LinkedInSharePhase.previewReady,
          simulationId: simulationId,
          resultLabel: state.resultLabel,
          connection: currentConnection,
          preview: value,
          notice: readyNotice,
          returnGeneration: generation,
        ));
      },
    );
  }

  void _emitMarkDeletedFailure(
    Failure failure, {
    required String simulationId,
  }) {
    _busy = false;
    emit(_error(
      _markDeletedNotice(failure),
      simulationId: simulationId,
      resultLabel: state.resultLabel,
      connection: state.connection,
      returnGeneration: state.returnGeneration,
    ));
  }

  void _emitFailure(
    Failure failure, {
    String? simulationId,
    int? returnGeneration,
  }) {
    _busy = false;
    emit(_error(
      _noticeFor(failure),
      simulationId: simulationId ?? state.simulationId,
      resultLabel: state.resultLabel,
      connection: state.connection,
      returnGeneration: returnGeneration ?? state.returnGeneration,
    ));
  }

  LinkedInShareState _error(
    LinkedInShareNotice notice, {
    String? simulationId,
    String? resultLabel,
    LinkedInConnectionStatus? connection,
    int? returnGeneration,
  }) {
    return LinkedInShareState(
      phase: LinkedInSharePhase.error,
      simulationId: simulationId,
      resultLabel: resultLabel ?? state.resultLabel,
      connection: connection,
      notice: notice,
      returnGeneration: returnGeneration ?? state.returnGeneration,
    );
  }

  String? _postUrl(LinkedInPublishResult result) {
    return verifiedLinkedInPostUrl(result.postUrl);
  }
}

LinkedInShareNotice _noticeFor(Failure failure) {
  if (failure is UnauthorizedFailure) return LinkedInShareNotice.sessionExpired;
  if (failure is ForbiddenFailure) return LinkedInShareNotice.reconnect;
  if (failure is NotFoundFailure) return LinkedInShareNotice.notFound;
  if (failure is ConflictFailure) {
    if (failure.code == linkedInDifferentContentCode) {
      return LinkedInShareNotice.alreadySharedDifferent;
    }
    if (failure.code == linkedInShareNotDeletableCode) {
      return LinkedInShareNotice.shareNotDeletable;
    }
    return LinkedInShareNotice.previewExpired;
  }
  if (failure is NetworkFailure) return LinkedInShareNotice.network;
  if (failure is UpstreamFailure) return LinkedInShareNotice.publishUnconfirmed;
  if (failure is ServiceUnavailableFailure || failure is GoneFailure) {
    return LinkedInShareNotice.unavailable;
  }
  return LinkedInShareNotice.generic;
}

LinkedInShareNotice _markDeletedNotice(Failure failure) {
  if (failure is UnauthorizedFailure) return LinkedInShareNotice.sessionExpired;
  if (failure is ValidationFailure) {
    return LinkedInShareNotice.confirmationRequired;
  }
  if (failure is NotFoundFailure) return LinkedInShareNotice.shareNotFound;
  if (failure is ConflictFailure &&
      failure.code == linkedInShareNotDeletableCode) {
    return LinkedInShareNotice.shareNotDeletable;
  }
  if (failure is NetworkFailure) return LinkedInShareNotice.network;
  return LinkedInShareNotice.generic;
}

LinkedInShareNotice _oauthNotice(LinkedInOAuthResult result) {
  switch (result) {
    case LinkedInOAuthResult.cancelled:
      return LinkedInShareNotice.cancelled;
    case LinkedInOAuthResult.invalidState:
      return LinkedInShareNotice.invalidState;
    case LinkedInOAuthResult.missingPermission:
      return LinkedInShareNotice.missingPermission;
    case LinkedInOAuthResult.accountConflict:
      return LinkedInShareNotice.accountConflict;
    case LinkedInOAuthResult.unavailable:
      return LinkedInShareNotice.unavailable;
    case LinkedInOAuthResult.connected:
      return LinkedInShareNotice.none;
  }
}
