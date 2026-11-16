import 'package:equatable/equatable.dart';

import '../../domain/entities/linkedin_connection_status.dart';
import '../../domain/entities/linkedin_share_preview.dart';

enum LinkedInSharePhase {
  initial,
  checkingConnection,
  connectionRequired,
  startingOAuth,
  waitingForOAuthReturn,
  loadingPreview,
  previewReady,
  publishing,
  markingDeleted,
  alreadyShared,
  published,
  error,
}

enum LinkedInShareNotice {
  none,
  sessionExpired,
  reconnect,
  notFound,
  previewExpired,
  publishUnconfirmed,
  unavailable,
  cancelled,
  invalidState,
  missingPermission,
  accountConflict,
  alreadySharedDifferent,
  confirmationRequired,
  shareNotFound,
  shareNotDeletable,
  otherActivePosts,
  readyToRepublish,
  network,
  generic,
}

const linkedInDifferentContentCode = 'ALREADY_PUBLISHED_DIFFERENT_CONTENT';
const linkedInShareNotDeletableCode = 'SHARE_NOT_EXTERNALLY_DELETABLE';

class LinkedInShareState extends Equatable {
  final LinkedInSharePhase phase;
  final String? simulationId;
  final String? resultLabel;
  final LinkedInConnectionStatus? connection;
  final LinkedInSharePreview? preview;
  final String? postUrl;
  final String? activeShareId;
  final bool republishBlocked;
  final LinkedInShareNotice notice;
  final int returnGeneration;

  const LinkedInShareState({
    this.phase = LinkedInSharePhase.initial,
    this.simulationId,
    this.resultLabel,
    this.connection,
    this.preview,
    this.postUrl,
    this.activeShareId,
    this.republishBlocked = false,
    this.notice = LinkedInShareNotice.none,
    this.returnGeneration = 0,
  });

  bool get showDisconnect =>
      connection != null &&
      (connection!.connected || connection!.needsReconnect) &&
      phase != LinkedInSharePhase.publishing &&
      phase != LinkedInSharePhase.markingDeleted &&
      phase != LinkedInSharePhase.startingOAuth;

  @override
  List<Object?> get props => [
        phase,
        simulationId,
        resultLabel,
        connection,
        preview,
        postUrl,
        activeShareId,
        republishBlocked,
        notice,
        returnGeneration,
      ];
}
