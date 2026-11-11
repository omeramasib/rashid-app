import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../app_localizations.dart';
import '../../../../core/theme/theme.dart';
import '../cubit/speech_input_cubit.dart';
import 'interview_widgets.dart';

/// Recording panel under the answer field with the Done button.
class SpeechListeningIndicator extends HookWidget {
  const SpeechListeningIndicator({
    super.key,
    required this.status,
    required this.partialText,
    required this.onDone,
  });

  final SpeechInputStatus status;
  final String partialText;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final pulse =
        useAnimationController(duration: const Duration(milliseconds: 900));
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final listening = status == SpeechInputStatus.listening;
    useEffect(() {
      if (listening && !reduceMotion) {
        pulse.repeat(reverse: true);
      } else {
        pulse.value = 1;
      }
      return null;
    }, [listening, reduceMotion]);

    final labelKey = switch (status) {
      SpeechInputStatus.listening => 'speech_listening',
      SpeechInputStatus.processing => 'speech_processing',
      _ => 'speech_preparing',
    };
    return Container(
      key: const Key('speech_listening_indicator'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.3, end: 1).animate(pulse),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    AppLocalizations.tr(context, labelKey),
                    key: const Key('speech_status_label'),
                    style: AppTypography.bold(
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (partialText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              partialText,
              key: const Key('speech_partial_text'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.hintColor,
              ),
            ),
          ],
          const SizedBox(height: 10),
          InterviewActionButton(
            key: const Key('speech_done_button'),
            label: AppLocalizations.tr(context, 'speech_done'),
            busy: status == SpeechInputStatus.processing,
            onPressed: listening ? onDone : null,
          ),
        ],
      ),
    );
  }
}
