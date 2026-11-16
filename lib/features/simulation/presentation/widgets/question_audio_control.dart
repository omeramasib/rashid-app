import 'package:flutter/material.dart';

import '../../../../app_localizations.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/question_audio.dart';
import '../cubit/question_audio_cubit.dart';

/// Compact play control for the question that is on screen.
class QuestionAudioControl extends StatelessWidget {
  const QuestionAudioControl({
    super.key,
    required this.state,
    required this.questionId,
    required this.recording,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onReplay,
    required this.onRetry,
  });

  final QuestionAudioState state;
  final String questionId;
  final bool recording;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReplay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.questionId != questionId) return const SizedBox.shrink();
    if (state.backend == QuestionAudioStatus.disabled) {
      return const SizedBox.shrink();
    }
    if (state.issue == QuestionAudioIssue.sessionExpired) {
      return _message(
        context,
        'interview_err_unauthorized',
        key: const Key('question_audio_session'),
      );
    }
    if (state.playback == QuestionPlaybackStatus.playing) {
      return _button(
        context,
        labelKey: 'question_audio_pause',
        buttonKey: const Key('question_audio_pause'),
        icon: Icons.pause_rounded,
        onPressed: onPause,
      );
    }
    if (state.playback == QuestionPlaybackStatus.paused) {
      return _button(
        context,
        labelKey: 'question_audio_resume',
        buttonKey: const Key('question_audio_resume'),
        icon: Icons.play_arrow_rounded,
        onPressed: recording ? null : onResume,
      );
    }
    if (state.playback == QuestionPlaybackStatus.completed) {
      return _button(
        context,
        labelKey: 'question_audio_replay',
        buttonKey: const Key('question_audio_replay'),
        icon: Icons.replay_rounded,
        onPressed: recording ? null : onReplay,
      );
    }
    if (state.issue == QuestionAudioIssue.timedOut ||
        state.issue == QuestionAudioIssue.temporary ||
        state.issue == QuestionAudioIssue.unavailable ||
        state.playback == QuestionPlaybackStatus.error) {
      final unavailable = state.issue == QuestionAudioIssue.unavailable ||
          state.playback == QuestionPlaybackStatus.error ||
          state.backend == QuestionAudioStatus.failed;
      return _button(
        context,
        labelKey:
            unavailable ? 'question_audio_unavailable' : 'question_audio_retry',
        buttonKey: const Key('question_audio_retry'),
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
        muted: unavailable,
      );
    }
    if (state.playback == QuestionPlaybackStatus.loading ||
        state.backend == QuestionAudioStatus.pending ||
        state.backend == QuestionAudioStatus.processing) {
      return _preparing(context);
    }
    return _button(
      context,
      labelKey: 'question_audio_play',
      buttonKey: const Key('question_audio_play'),
      icon: Icons.volume_up_rounded,
      onPressed: recording ? null : onPlay,
    );
  }

  Widget _preparing(BuildContext context) {
    final label = AppLocalizations.tr(context, 'question_audio_preparing');
    return Semantics(
      key: const Key('question_audio_preparing'),
      label: label,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTypography.regular(
                  fontSize: 13,
                  color: AppColors.hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(BuildContext context, String labelKey, {required Key key}) {
    final label = AppLocalizations.tr(context, labelKey);
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        label,
        style: AppTypography.regular(fontSize: 13, color: AppColors.hintColor),
      ),
    );
  }

  Widget _button(
    BuildContext context, {
    required String labelKey,
    required Key buttonKey,
    required IconData icon,
    required VoidCallback? onPressed,
    bool muted = false,
  }) {
    final label = AppLocalizations.tr(context, labelKey);
    final color = muted ? AppColors.hintColor : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        child: SizedBox(
          height: 48,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: buttonKey,
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: color,
                disabledForegroundColor: AppColors.hintColor,
              ),
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.regular(fontSize: 13, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
