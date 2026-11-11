import 'package:flutter/material.dart';

import '../../../../app_localizations.dart';
import '../../../../core/theme/theme.dart';
import '../cubit/speech_input_cubit.dart';

/// Microphone button shown at the trailing edge of the answer field.
class SpeechInputButton extends StatelessWidget {
  const SpeechInputButton({
    super.key,
    required this.status,
    required this.onStart,
    required this.onStop,
  });

  final SpeechInputStatus status;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final listening = status == SpeechInputStatus.listening;
    final busy = status.isActive && !listening;
    final tooltip = AppLocalizations.tr(
      context,
      listening ? 'speech_mic_stop_tooltip' : 'speech_mic_tooltip',
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          enabled: !busy,
          label: tooltip,
          excludeSemantics: true,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Material(
                key: const Key('speech_mic_button'),
                color: busy
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary,
                shape: const CircleBorder(),
                elevation: listening ? 3 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: busy ? null : (listening ? onStop : onStart),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              listening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              key: Key(
                                listening ? 'speech_mic_stop' : 'speech_mic',
                              ),
                              size: 22,
                              color: AppColors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
