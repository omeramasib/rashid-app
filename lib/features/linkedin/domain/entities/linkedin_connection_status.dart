import 'package:equatable/equatable.dart';

enum LinkedInConnectionState {
  notConnected,
  active,
  expired,
  revoked,
  reauthorizationRequired,
  unknown,
}

class LinkedInConnectionStatus extends Equatable {
  final bool connected;
  final bool publishingEnabled;
  final bool reauthorizationRequired;
  final LinkedInConnectionState connectionStatus;
  final DateTime? expiresAt;
  final String? name;

  const LinkedInConnectionStatus({
    required this.connected,
    required this.publishingEnabled,
    required this.reauthorizationRequired,
    required this.connectionStatus,
    this.expiresAt,
    this.name,
  });

  /// Publishing is a separate grant from signing in with LinkedIn.
  bool get canPublish =>
      connected &&
      publishingEnabled &&
      !reauthorizationRequired &&
      connectionStatus == LinkedInConnectionState.active;

  bool get needsReconnect =>
      !canPublish &&
      (connected ||
          reauthorizationRequired ||
          connectionStatus == LinkedInConnectionState.expired ||
          connectionStatus == LinkedInConnectionState.revoked ||
          connectionStatus == LinkedInConnectionState.reauthorizationRequired);

  @override
  List<Object?> get props => [
        connected,
        publishingEnabled,
        reauthorizationRequired,
        connectionStatus,
        expiresAt,
        name,
      ];
}
