import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum MicrophonePermissionResult { granted, denied, permanentlyDenied }

/// The only place that asks for microphone and speech permissions.
///
/// The speech plugin is initialized after this reports [granted], so it never
/// shows a second system prompt.
abstract class MicrophonePermissionService {
  /// Requests what is still missing. Never prompts for a permission the OS
  /// already reports as permanently denied or restricted.
  Future<MicrophonePermissionResult> request();

  Future<bool> openSettings();
}

class PermissionHandlerMicrophoneService
    implements MicrophonePermissionService {
  /// Speech recognition is a separate permission on iOS only.
  PermissionHandlerMicrophoneService({bool? needsSpeechPermission})
      : _needsSpeech = needsSpeechPermission ?? (!kIsWeb && Platform.isIOS);

  final bool _needsSpeech;

  @override
  Future<MicrophonePermissionResult> request() async {
    final permissions = [
      Permission.microphone,
      if (_needsSpeech) Permission.speech,
    ];
    for (final permission in permissions) {
      var status = await permission.status;
      if (_isGranted(status)) continue;
      if (_isBlocked(status)) {
        return MicrophonePermissionResult.permanentlyDenied;
      }
      status = await permission.request();
      if (_isGranted(status)) continue;
      return _isBlocked(status)
          ? MicrophonePermissionResult.permanentlyDenied
          : MicrophonePermissionResult.denied;
    }
    return MicrophonePermissionResult.granted;
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  bool _isGranted(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  bool _isBlocked(PermissionStatus status) =>
      status.isPermanentlyDenied || status.isRestricted;
}
