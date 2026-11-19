import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../Presentation/utils/images.dart';
import '../../../../app_localizations.dart';
import '../../../../core/theme/theme.dart';
import '../cubit/interview_cubit.dart';

/// Pixel width of every pose file. Decode requests never exceed it.
const int rashedPoseSourcePixels = 480;

const Duration _entranceDuration = Duration(milliseconds: 420);
const Duration _idleDuration = Duration(milliseconds: 1500);
const Duration _nudgeDuration = Duration(milliseconds: 360);
const Duration _busyDuration = Duration(milliseconds: 900);
const Duration rashedCelebrateDuration = Duration(milliseconds: 1200);

enum RashedPose { welcome, thinking, coaching, encouraging, success, support }

enum RashedMotion { entrance, idle, nudge, busy, celebrate, none }

enum RashedMascotLayout { inline, stacked }

extension RashedPoseAsset on RashedPose {
  String get asset {
    switch (this) {
      case RashedPose.welcome:
        return ImageManages.rashedWelcome;
      case RashedPose.thinking:
        return ImageManages.rashedThinking;
      case RashedPose.coaching:
        return ImageManages.rashedCoaching;
      case RashedPose.encouraging:
        return ImageManages.rashedEncouraging;
      case RashedPose.success:
        return ImageManages.rashedSuccess;
      case RashedPose.support:
        return ImageManages.rashedSupport;
    }
  }
}

class InterviewMascotAppearance extends Equatable {
  const InterviewMascotAppearance({
    required this.pose,
    required this.motion,
    required this.messageKey,
  });

  final RashedPose pose;
  final RashedMotion motion;
  final String messageKey;

  @override
  List<Object?> get props => [pose, motion, messageKey];
}

/// Reads interview and presentation state. Does not change it.
///
/// Overlapping conditions resolve in this order: error, submitting or
/// finishing, starting, recording, answering, waiting, then setup.
InterviewMascotAppearance interviewMascotAppearance({
  required InterviewPhase phase,
  required bool hasError,
  required bool recording,
  required bool answering,
}) {
  if (hasError) {
    return const InterviewMascotAppearance(
      pose: RashedPose.support,
      motion: RashedMotion.none,
      messageKey: 'mascot_error',
    );
  }
  if (phase == InterviewPhase.submitting) {
    return const InterviewMascotAppearance(
      pose: RashedPose.coaching,
      motion: RashedMotion.busy,
      messageKey: 'mascot_submitting',
    );
  }
  if (phase == InterviewPhase.finishing) {
    return const InterviewMascotAppearance(
      pose: RashedPose.coaching,
      motion: RashedMotion.busy,
      messageKey: 'mascot_finishing',
    );
  }
  if (phase == InterviewPhase.starting) {
    return const InterviewMascotAppearance(
      pose: RashedPose.coaching,
      motion: RashedMotion.busy,
      messageKey: 'mascot_starting',
    );
  }
  if (recording) {
    return const InterviewMascotAppearance(
      pose: RashedPose.encouraging,
      motion: RashedMotion.none,
      messageKey: 'mascot_listening',
    );
  }
  if (answering) {
    return const InterviewMascotAppearance(
      pose: RashedPose.encouraging,
      motion: RashedMotion.none,
      messageKey: 'mascot_answering',
    );
  }
  if (phase == InterviewPhase.inProgress) {
    return const InterviewMascotAppearance(
      pose: RashedPose.thinking,
      motion: RashedMotion.idle,
      messageKey: 'mascot_thinking',
    );
  }
  if (phase == InterviewPhase.finished) {
    return const InterviewMascotAppearance(
      pose: RashedPose.success,
      motion: RashedMotion.none,
      messageKey: 'mascot_result_default',
    );
  }
  return const InterviewMascotAppearance(
    pose: RashedPose.welcome,
    motion: RashedMotion.entrance,
    messageKey: 'mascot_welcome',
  );
}

/// Settled result pose. Bands match [performanceBandLabel]: excellent,
/// average, and poor. Anything else, including a missing result, is support.
InterviewMascotAppearance interviewResultMascot(String? performanceStatus) {
  switch (performanceStatus) {
    case 'excellent':
      return const InterviewMascotAppearance(
        pose: RashedPose.success,
        motion: RashedMotion.none,
        messageKey: 'mascot_result_excellent',
      );
    case 'average':
      return const InterviewMascotAppearance(
        pose: RashedPose.encouraging,
        motion: RashedMotion.none,
        messageKey: 'mascot_result_average',
      );
    case 'poor':
      return const InterviewMascotAppearance(
        pose: RashedPose.support,
        motion: RashedMotion.none,
        messageKey: 'mascot_result_poor',
      );
    default:
      return const InterviewMascotAppearance(
        pose: RashedPose.support,
        motion: RashedMotion.none,
        messageKey: 'mascot_result_default',
      );
  }
}

int mascotCacheWidth(double logicalSize, double devicePixelRatio) {
  final requested = (logicalSize * devicePixelRatio).round();
  if (requested < 1) return 1;
  if (requested > rashedPoseSourcePixels) return rashedPoseSourcePixels;
  return requested;
}

ImageProvider<Object> rashedPoseProvider(RashedPose pose, int cacheWidth) {
  return ResizeImage(
    AssetImage(pose.asset),
    width: cacheWidth,
  );
}

class RashedMascot extends HookWidget {
  const RashedMascot({
    super.key,
    required this.pose,
    this.motion = RashedMotion.none,
    this.size = 88,
    this.message,
    this.layout = RashedMascotLayout.inline,
    this.alsoPrecache = const [],
  });

  final RashedPose pose;
  final RashedMotion motion;
  final double size;
  final String? message;
  final RashedMascotLayout layout;
  final List<RashedPose> alsoPrecache;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ticking = TickerMode.valuesOf(context).enabled;
    final cacheWidth = mascotCacheWidth(
      size,
      MediaQuery.devicePixelRatioOf(context),
    );
    final entrance = useAnimationController(duration: _entranceDuration);
    final idle = useAnimationController(duration: _idleDuration);
    final nudge = useAnimationController(duration: _nudgeDuration);
    final busy = useAnimationController(duration: _busyDuration);
    final celebrate = useAnimationController(duration: rashedCelebrateDuration);
    final previousMessage = useRef<String?>(null);
    final announce = useState(false);
    final extraKey = alsoPrecache.map((item) => item.name).join(',');
    final imageConfig = createLocalImageConfiguration(context);

    useEffect(() {
      final previous = previousMessage.value;
      previousMessage.value = message;
      final text = message;
      if (previous == null ||
          text == null ||
          text.isEmpty ||
          previous == text) {
        return null;
      }
      announce.value = true;
      var cancelled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!cancelled && context.mounted) announce.value = false;
      });
      return () => cancelled = true;
    }, [message]);

    useEffect(() {
      final poses = <RashedPose>{pose, ...alsoPrecache};
      for (final item in poses) {
        unawaited(_precachePose(
          rashedPoseProvider(item, cacheWidth),
          imageConfig,
        ));
      }
      return null;
    }, [pose, cacheWidth, extraKey]);

    useEffect(() {
      if (motion != RashedMotion.entrance || reduce) {
        entrance.value = motion == RashedMotion.entrance ? 0 : 1;
        return null;
      }
      entrance.forward(from: 0);
      return null;
    }, [motion, reduce]);

    useEffect(() {
      if (motion != RashedMotion.idle || reduce || !ticking) {
        idle.stop();
        idle.value = 0;
        return null;
      }
      idle.forward(from: 0);
      return () => idle.stop();
    }, [motion, reduce, ticking]);

    useEffect(() {
      if (motion != RashedMotion.nudge || reduce) {
        nudge.stop();
        nudge.value = 0;
        return null;
      }
      nudge.forward(from: 0);
      return null;
    }, [motion, reduce]);

    useEffect(() {
      if (motion != RashedMotion.busy || reduce || !ticking) {
        busy.stop();
        busy.value = 0;
        return null;
      }
      busy.repeat(reverse: true);
      return () => busy.stop();
    }, [motion, reduce, ticking]);

    useEffect(() {
      if (motion != RashedMotion.celebrate || reduce) {
        celebrate.stop();
        celebrate.value = 0;
        return null;
      }
      if (celebrate.isAnimating || celebrate.value > 0) return null;
      celebrate.forward(from: 0);
      return null;
    }, [motion, reduce]);

    final character = AnimatedBuilder(
      animation: Listenable.merge([entrance, idle, nudge, busy, celebrate]),
      builder: (context, child) {
        final entranceT =
            motion == RashedMotion.entrance && !reduce ? entrance.value : 1.0;
        final idleWave = motion == RashedMotion.idle && !reduce
            ? math.sin(idle.value * math.pi * 6)
            : 0.0;
        final busyWave = motion == RashedMotion.busy && !reduce
            ? math.sin(busy.value * math.pi)
            : 0.0;
        final nudgeWave = motion == RashedMotion.nudge && !reduce
            ? math.sin(nudge.value * math.pi)
            : 0.0;
        final celebrateWave = motion == RashedMotion.celebrate && !reduce
            ? math.sin(celebrate.value * math.pi)
            : 0.0;
        final scale = (motion == RashedMotion.entrance && !reduce
                ? 0.9 + 0.1 * Curves.easeOutBack.transform(entranceT)
                : 1.0) *
            (1 + 0.025 * busyWave) *
            (1 + 0.05 * nudgeWave) *
            (1 + 0.08 * celebrateWave);
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              key: const Key('rashed_mascot_halo'),
              opacity: (0.55 * busyWave).clamp(0.0, 1.0),
              child: Container(
                width: size * 0.62,
                height: size * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
            Opacity(
              opacity: entranceT.clamp(0.0, 1.0),
              child: Transform.translate(
                key: const Key('rashed_mascot_motion'),
                offset: Offset(0, -3 * idleWave + (1 - entranceT) * 12),
                child: Transform.scale(
                  scale: scale.clamp(0.5, 1.3),
                  child: child,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BurstPainter(
                    motion == RashedMotion.celebrate && !reduce
                        ? celebrate.value
                        : 0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Image(
            key: ValueKey(pose),
            image: rashedPoseProvider(pose, cacheWidth),
            width: size,
            height: size,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );

    final bubble = message == null || message!.isEmpty
        ? null
        : Semantics(
            liveRegion: announce.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  message!,
                  key: const Key('rashed_mascot_message'),
                  textAlign: layout == RashedMascotLayout.stacked
                      ? TextAlign.center
                      : TextAlign.start,
                  style: AppTypography.regular(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.fontColor,
                  ),
                ),
              ),
            ),
          );

    final figure = SizedBox(width: size, height: size, child: character);
    if (layout == RashedMascotLayout.stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          figure,
          if (bubble != null) ...[
            const SizedBox(height: 8),
            bubble,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        figure,
        if (bubble != null) ...[
          const SizedBox(width: 8),
          Expanded(child: bubble),
        ],
      ],
    );
  }
}

/// Plays the completion celebration once per visit, then shows [appearance].
///
/// The flag lives in this widget's state, so a rebuild does not replay it.
/// Covering the route and coming back keeps that state. A new route plays it
/// again. Reduced motion skips the celebration.
class InterviewResultMascot extends HookWidget {
  const InterviewResultMascot({
    super.key,
    required this.appearance,
    required this.message,
  });

  final InterviewMascotAppearance appearance;
  final String message;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final celebrating = useState(!reduce);
    useEffect(() {
      if (!celebrating.value) return null;
      final timer = Timer(rashedCelebrateDuration, () {
        if (context.mounted) celebrating.value = false;
      });
      return timer.cancel;
    }, const []);
    return RashedMascot(
      key: const Key('interview_result_mascot'),
      pose: celebrating.value ? RashedPose.success : appearance.pose,
      motion: celebrating.value ? RashedMotion.celebrate : RashedMotion.none,
      alsoPrecache: [appearance.pose],
      size: 140,
      message: message,
      layout: RashedMascotLayout.stacked,
    );
  }
}

class InterviewQuestionMascot extends HookWidget {
  const InterviewQuestionMascot({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.phase,
    required this.hasError,
    required this.recording,
    required this.compact,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final InterviewPhase phase;
  final bool hasError;
  final bool recording;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasText = useListenableSelector(
      controller,
      () => controller.text.trim().isNotEmpty,
    );
    final focused = useListenableSelector(
      focusNode,
      () => focusNode.hasFocus,
    );
    final appearance = interviewMascotAppearance(
      phase: phase,
      hasError: hasError,
      recording: recording,
      answering: hasText || focused,
    );
    final reduce = MediaQuery.disableAnimationsOf(context);
    final text =
        compact ? null : AppLocalizations.tr(context, appearance.messageKey);
    return AnimatedSize(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: RashedMascot(
        key: const Key('interview_question_mascot'),
        pose: appearance.pose,
        motion: appearance.motion,
        size: compact ? 44 : 64,
        message: text,
      ),
    );
  }
}

Future<void> _precachePose(
  ImageProvider<Object> provider,
  ImageConfiguration configuration,
) {
  final completer = Completer<void>();
  final stream = provider.resolve(configuration);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, synchronousCall) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
    onError: (exception, stackTrace) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t);

  final double t;

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.primaryAccent,
    AppColors.secondary,
    AppColors.warning,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = Offset(size.width / 2, size.height * 0.4);
    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * math.pi * 2 + 0.35;
      final distance = (size.shortestSide * 0.18 + (i % 3) * 7) * t;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: (1 - t) * 0.9);
      if (i.isEven) {
        canvas.drawCircle(pos, 2.4, paint);
      } else {
        canvas.drawCircle(pos, 1.6, paint);
        canvas.drawCircle(pos.translate(3, -2), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.t != t;
}
