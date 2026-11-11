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
  generic,
}

class LinkedInShareState extends Equatable {
  final LinkedInSharePhase phase;
  final String? simulationId;
  final String? resultLabel;
  final LinkedInConnectionStatus? connection;
  final LinkedInSharePreview? preview;
  final String? postUrl;
  final LinkedInShareNotice notice;
  final int returnGeneration;

  const LinkedInShareState({
    this.phase = LinkedInSharePhase.initial,
    this.simulationId,
    this.resultLabel,
    this.connection,
    this.preview,
    this.postUrl,
    this.notice = LinkedInShareNotice.none,
    this.returnGeneration = 0,
  });

  bool get showDisconnect =>
      connection != null &&
      (connection!.connected || connection!.needsReconnect) &&
      phase != LinkedInSharePhase.publishing &&
      phase != LinkedInSharePhase.startingOAuth;

  @override
  List<Object?> get props => [
        phase,
        simulationId,
        resultLabel,
        connection,
        preview,
        postUrl,
        notice,
        returnGeneration,
      ];
}
