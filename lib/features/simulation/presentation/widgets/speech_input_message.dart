import 'package:flutter/material.dart';

import '../../../../app_localizations.dart';
import '../../../../core/speech/speech_recognition_service.dart';
import '../cubit/speech_input_cubit.dart';
import 'interview_widgets.dart';

/// Localized feedback for a denied, unavailable, or failed speech session.
class SpeechInputMessage extends StatelessWidget {
  const SpeechInputMessage({
    super.key,
    required this.state,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final SpeechInputState state;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final messageKey = speechMessageKey(state);
    if (messageKey == null) return const SizedBox.shrink();
    final settings =
        state.status == SpeechInputStatus.permissionPermanentlyDenied;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InterviewErrorBanner(
        message: AppLocalizations.tr(context, messageKey),
        messageKey: const Key('speech_message'),
        actionKey: const Key('speech_message_action'),
        actionLabel: AppLocalizations.tr(
          context,
          settings ? 'speech_open_settings' : 'speech_dismiss',
        ),
        onAction: settings ? onOpenSettings : onDismiss,
      ),
    );
  }
}

/// Translation key for [state], or null when nothing should be shown.
String? speechMessageKey(SpeechInputState state) {
  switch (state.status) {
    case SpeechInputStatus.permissionDenied:
      return 'speech_permission_denied';
    case SpeechInputStatus.permissionPermanentlyDenied:
      return 'speech_permission_permanently_denied';
    case SpeechInputStatus.unavailable:
      return state.error == SpeechErrorCategory.languageUnavailable
          ? 'speech_language_unavailable'
          : 'speech_unavailable';
    case SpeechInputStatus.error:
      return switch (state.error) {
        SpeechErrorCategory.noSpeech => 'speech_no_speech',
        SpeechErrorCategory.audio ||
        SpeechErrorCategory.busy ||
        SpeechErrorCategory.interrupted =>
          'speech_interrupted',
        SpeechErrorCategory.network => 'speech_network',
        _ => 'speech_error_generic',
      };
    default:
      return null;
  }
}
