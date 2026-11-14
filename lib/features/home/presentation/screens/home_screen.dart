import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/di/injection_container.dart' as di;
import 'package:rashed_app/features/home/presentation/cubit/simulation_history_count_cubit.dart';
import 'package:rashed_app/features/simulation/domain/interview_options.dart';
import 'package:rashed_app/features/simulation/presentation/interview_navigation.dart';
import 'package:rashed_app/core/auth/end_rashed_session.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_local_datasource.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';
import 'package:rashed_app/features/performance/domain/shareable_simulation.dart';
import 'package:rashed_app/features/performance/presentation/cubit/performance_cubit.dart';
import 'package:rashed_app/features/performance/presentation/performance_format.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/interview_error_text.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_share_request.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({super.key, this.simulationHistoryCountCubit});

  static const int performanceTab = 1;

  final SimulationHistoryCountCubit? simulationHistoryCountCubit;

  static const _pages = [
    _HomeBody(),
    _PerformanceBody(),
    _MoreBody(),
  ];

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final initialTab = routeArgs == performanceTab ? performanceTab : 0;
    final currentIndex = useState(initialTab);
    final countCubit = useMemoized(_resolveCountCubit, [
      simulationHistoryCountCubit,
    ]);
    useEffect(() {
      countCubit?.load();
      return () {
        if (simulationHistoryCountCubit == null) {
          countCubit?.close();
        }
      };
    }, [countCubit]);
    final screen = Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: _pages[currentIndex.value]),
        bottomNavigationBar: _buildBottomBar(currentIndex),
      ),
    );
    if (countCubit == null) return screen;
    return BlocProvider.value(value: countCubit, child: screen);
  }

  SimulationHistoryCountCubit? _resolveCountCubit() {
    if (simulationHistoryCountCubit != null) return simulationHistoryCountCubit;
    if (!di.sl.isRegistered<SimulationHistoryCountCubit>()) return null;
    return di.sl<SimulationHistoryCountCubit>();
  }

  Widget _buildBottomBar(ValueNotifier<int> currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.black10, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home_outlined,
            index: 0,
            currentIndex: currentIndex,
            isHome: true,
          ),
          _navItem(
            icon: Icons.show_chart_rounded,
            index: 1,
            currentIndex: currentIndex,
          ),
          _navItem(
            icon: Icons.menu,
            index: 2,
            currentIndex: currentIndex,
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required int index,
    required ValueNotifier<int> currentIndex,
    bool isHome = false,
  }) {
    final isSelected = currentIndex.value == index;
    return GestureDetector(
      onTap: () => currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: isHome && isSelected
            ? ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Icon(icon, size: 28, color: AppColors.white),
              )
            : Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.hintColor,
              ),
      ),
    );
  }
}

class _HomeBody extends HookWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(_homePerformanceCubit);
    useEffect(() {
      final resolved = cubit;
      if (resolved == null) return null;
      resolved.load();
      return resolved.close;
    }, [cubit]);

    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'home_title'),
            style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
          ),
          const SizedBox(height: 10),
          _WelcomeBanner(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: _HomeShareCard()),
              const SizedBox(width: 12),
              Expanded(child: _SimCountCard()),
            ],
          ),
          const SizedBox(height: 10),
          _SimulationCard(
            title: AppLocalizations.tr(context, 'sim_by_job'),
            description: AppLocalizations.tr(context, 'sim_by_job_desc'),
            icon: Icons.description_outlined,
            onTap: () => _openSimulation(
              context,
              InterviewStartMode.byJobDescription,
            ),
          ),
          const SizedBox(height: 10),
          _SimulationCard(
            title: AppLocalizations.tr(context, 'sim_by_field'),
            description: AppLocalizations.tr(context, 'sim_by_field_desc'),
            icon: Icons.description_outlined,
            onTap: () => _openSimulation(
              context,
              InterviewStartMode.byJob,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
    if (cubit == null) return scroll;
    return BlocProvider.value(
      value: cubit,
      child: BlocListener<PerformanceCubit, PerformanceState>(
        listenWhen: (previous, current) =>
            current is PerformanceFailure &&
            current.failure is UnauthorizedFailure &&
            previous is! PerformanceFailure,
        listener: (context, state) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.login,
            (route) => false,
          );
        },
        child: scroll,
      ),
    );
  }
}

PerformanceCubit? _homePerformanceCubit() {
  if (!di.sl.isRegistered<PerformanceCubit>()) return null;
  return di.sl<PerformanceCubit>();
}

PerformanceCubit? _performanceCubitOf(BuildContext context) {
  try {
    return context.read<PerformanceCubit>();
  } on ProviderNotFoundException {
    return null;
  }
}

SimulationHistoryCountCubit? _countCubitOf(BuildContext context) {
  try {
    return context.read<SimulationHistoryCountCubit>();
  } on ProviderNotFoundException {
    return null;
  }
}

Future<void> _openSimulation(
  BuildContext context,
  InterviewStartMode mode,
) async {
  await openInterviewSimulation(context, mode);
  if (!context.mounted) return;
  await _countCubitOf(context)?.refresh();
  if (!context.mounted) return;
  await _performanceCubitOf(context)?.load();
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: -10,
            bottom: 0,
            child: SvgPicture.asset(
              ImageManages.rashedImage,
              height: 150,
              width: 150,
            ),
          ),
          Positioned(
            left: 16,
            top: 40,
            right: 160,
            child: Text(
              AppLocalizations.tr(context, 'home_welcome'),
              style: AppTypography.regular(
                  fontSize: 14, color: AppColors.fontColor),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableShareTarget extends StatelessWidget {
  const _UnavailableShareTarget({
    required this.shareKey,
    required this.child,
  });

  final Key shareKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      key: shareKey,
      ignoring: true,
      child: Opacity(
        opacity: 0.45,
        child: Semantics(
          button: true,
          enabled: false,
          child: child,
        ),
      ),
    );
  }
}

class _HomeShareCard extends StatelessWidget {
  const _HomeShareCard();

  @override
  Widget build(BuildContext context) {
    final cubit = _performanceCubitOf(context);
    if (cubit == null) {
      return const _ShareCard(
        action: _UnavailableShareTarget(
          shareKey: Key('home_share_card_disabled'),
          child: _ShareMyResultButton(expanded: true),
        ),
      );
    }
    return BlocBuilder<PerformanceCubit, PerformanceState>(
      builder: (context, state) {
        if (state is PerformanceInitial || state is PerformanceLoading) {
          return const _ShareCard(
            action: SizedBox(
              height: 34,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    key: Key('home_share_loading'),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          );
        }
        if (state is PerformanceFailure) {
          return _ShareCard(
            action: Column(
              children: [
                Text(
                  interviewErrorText(context, state.failure),
                  key: const Key('home_share_error'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.regular(
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                ),
                GestureDetector(
                  key: const Key('home_share_retry'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.read<PerformanceCubit>().load(),
                  child: Text(
                    AppLocalizations.tr(context, 'interview_retry'),
                    style: AppTypography.regular(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final summary = state is PerformanceSuccess ? state.summary : null;
        final interview = summary == null
            ? null
            : latestShareableInterview(summary.recentInterviews);
        if (interview == null) {
          return const _ShareCard(
            action: _UnavailableShareTarget(
              shareKey: Key('home_share_card_disabled'),
              child: _ShareMyResultButton(expanded: true),
            ),
          );
        }
        final label = recentInterviewShareLabel(
          interview,
          AppLocalizations.tr(context, 'performance_mock_interview'),
        );
        return _ShareCard(
          action: _LinkedInShareControl(
            simulationId: interview.simulationId,
            resultLabel: label,
            enabledKey: const Key('home_share_button'),
            disabledKey: const Key('home_share_card_disabled'),
            child: const _ShareMyResultButton(expanded: true),
          ),
        );
      },
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.action});

  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.share_outlined,
                size: 24, color: AppColors.primarySet2),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'share_last_result'),
            key: const Key('home_share_title'),
            style:
                AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
            textAlign: TextAlign.start,
          ),
          const Spacer(),
          action,
        ],
      ),
    );
  }
}

class _ShareMyResultButton extends StatelessWidget {
  const _ShareMyResultButton({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      AppLocalizations.tr(context, 'share_my_result'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.regular(
        fontSize: 11,
        color: AppColors.white,
      ),
    );
    return Container(
      height: 34,
      width: expanded ? double.infinity : null,
      padding: expanded ? null : const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expanded) Flexible(child: text) else text,
          const SizedBox(width: 6),
          const Icon(Icons.share_outlined, size: 16, color: AppColors.white),
        ],
      ),
    );
  }
}

class _LinkedInShareControl extends HookWidget {
  const _LinkedInShareControl({
    required this.simulationId,
    required this.resultLabel,
    required this.enabledKey,
    required this.disabledKey,
    required this.child,
  });

  final String? simulationId;
  final String? resultLabel;
  final Key enabledKey;
  final Key disabledKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final guard = useMemoized(LinkedInShareLaunchGuard.new);
    final id = simulationId?.trim();
    if (id == null || id.isEmpty) {
      return _UnavailableShareTarget(shareKey: disabledKey, child: child);
    }
    return GestureDetector(
      key: enabledKey,
      behavior: HitTestBehavior.opaque,
      onTap: () => guard.run(
        () => openLinkedInShare(
          context,
          simulationId: id,
          resultLabel: resultLabel,
        ),
      ),
      child: child,
    );
  }
}

class _SimCountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.sentiment_satisfied_alt_outlined,
                size: 24, color: AppColors.primarySet2),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'sim_count'),
            style:
                AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
            textAlign: TextAlign.start,
          ),
          const Spacer(),
          const _SimulationCountText(),
        ],
      ),
    );
  }
}

class _SimulationCountText extends StatelessWidget {
  const _SimulationCountText();

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.regular(
      fontSize: 20,
      color: AppColors.primarySet2,
    );
    final cubit = _countCubitOf(context);
    if (cubit == null) return const SizedBox(width: 18, height: 18);
    return BlocBuilder<SimulationHistoryCountCubit,
        SimulationHistoryCountState>(
      builder: (context, state) {
        if (state is SimulationHistoryCountSuccess) {
          return Text(
            '${state.totalSimulations}',
            key: const Key('sim_history_count'),
            style: style,
            textAlign: TextAlign.start,
          );
        }
        if (state is SimulationHistoryCountFailure) {
          return GestureDetector(
            key: const Key('sim_history_count_retry'),
            behavior: HitTestBehavior.opaque,
            onTap: () => context.read<SimulationHistoryCountCubit>().refresh(),
            child: Text(
              '—',
              key: const Key('sim_history_count'),
              style: style,
              textAlign: TextAlign.start,
            ),
          );
        }
        return const SizedBox(
          key: Key('sim_history_count_loading'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }
}

class _SimulationCard extends StatelessWidget {
  const _SimulationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTypography.regular(
                        fontSize: 15,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 24, color: AppColors.primarySet2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.regular(
                  fontSize: 12, color: AppColors.fontColor),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 12),
            Container(
              height: 38,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.tr(context, 'start_simulation'),
                style:
                    AppTypography.regular(fontSize: 12, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceBody extends HookWidget {
  const _PerformanceBody();

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => GetIt.instance<PerformanceCubit>());
    useEffect(() {
      cubit.load();
      return () {
        cubit.close();
      };
    }, [cubit]);

    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<PerformanceCubit, PerformanceState>(
        listenWhen: (previous, current) =>
            current is PerformanceFailure &&
            current.failure is UnauthorizedFailure &&
            previous is! PerformanceFailure,
        listener: (context, state) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.login,
            (route) => false,
          );
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      AppLocalizations.tr(context, 'performance'),
                      style: AppTypography.bold(
                        fontSize: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state is PerformanceSuccess)
                    _PerformanceContent(summary: state.summary)
                  else if (state is PerformanceFailure)
                    _PerformanceFailureView(failure: state.failure)
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          key: Key('performance_loading'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PerformanceContent extends StatelessWidget {
  const _PerformanceContent({required this.summary});

  final PerformanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final placeholder = AppLocalizations.tr(context, 'performance_no_score');
    return Column(
      children: [
        _BestResultBanner(
          score: performanceScoreText(summary.bestScore, placeholder),
          simulationId: bestShareableSimulationId(summary),
          resultLabel: summary.bestScore == null
              ? null
              : performanceScoreText(summary.bestScore, ''),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: AppLocalizations.tr(context, 'avg_performance'),
                value: performanceScoreText(summary.averageScore, placeholder),
                icon: Icons.star_outline,
                valueKey: const Key('performance_average'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: AppLocalizations.tr(context, 'sim_count'),
                value: performanceCountText(
                  summary.totalSimulations,
                  placeholder,
                ),
                icon: Icons.sentiment_satisfied_alt_outlined,
                valueKey: const Key('performance_total'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InterviewLog(interviews: summary.recentInterviews),
      ],
    );
  }
}

class _PerformanceFailureView extends StatelessWidget {
  const _PerformanceFailureView({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            interviewErrorText(context, failure),
            key: const Key('performance_error'),
            textAlign: TextAlign.center,
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const Key('performance_retry'),
            onPressed: () => context.read<PerformanceCubit>().load(),
            child: Text(AppLocalizations.tr(context, 'interview_retry')),
          ),
        ],
      ),
    );
  }
}

class _BestResultBanner extends StatelessWidget {
  const _BestResultBanner({
    required this.score,
    required this.simulationId,
    required this.resultLabel,
  });

  final String score;
  final String? simulationId;
  final String? resultLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 159,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            top: -10,
            bottom: 0,
            child: SvgPicture.asset(
              ImageManages.rashedImage,
              height: 150,
              width: 150,
            ),
          ),
          Positioned(
            right: 14,
            top: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      score,
                      key: const Key('performance_best'),
                      style: AppTypography.bold(
                          fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.tr(context, 'best_result'),
                      style: AppTypography.regular(
                          fontSize: 12, color: AppColors.fontColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _LinkedInShareControl(
                  simulationId: simulationId,
                  resultLabel: resultLabel,
                  enabledKey: const Key('performance_best_share'),
                  disabledKey: const Key('performance_best_share_disabled'),
                  child: const _ShareMyResultButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueKey,
  });
  final String label;
  final String? value;
  final IconData icon;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: AppColors.primarySet2),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: AppTypography.regular(
                  fontSize: 12, color: AppColors.fontColor)),
          const Spacer(),
          Text(value!,
              key: valueKey,
              style: AppTypography.regular(
                  fontSize: 20, color: AppColors.primarySet2)),
        ],
      ),
    );
  }
}

class _InterviewLog extends StatelessWidget {
  const _InterviewLog({required this.interviews});

  final List<RecentInterview> interviews;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            AppLocalizations.tr(context, 'interview_log'),
            style:
                AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 12),
          if (interviews.isEmpty)
            Text(
              AppLocalizations.tr(context, 'performance_empty_history'),
              key: const Key('performance_empty_history'),
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.hintColor,
              ),
            )
          else
            for (var index = 0; index < interviews.length; index++) ...[
              if (index > 0) const Divider(height: 1, color: AppColors.black10),
              _InterviewRow(
                interview: interviews[index],
                languageCode: languageCode,
              ),
            ],
        ],
      ),
    );
  }
}

class _InterviewRow extends StatelessWidget {
  const _InterviewRow({
    required this.interview,
    required this.languageCode,
  });

  final RecentInterview interview;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final title = recentInterviewTitle(
      interview.jobField,
      AppLocalizations.tr(context, 'performance_mock_interview'),
    );
    final date = formatCompletedAt(interview.completedAt, languageCode);
    final badge = performanceStatusLabel(
      interview.performanceStatus,
      (key) => AppLocalizations.tr(context, key),
    );
    final badgeColor = _statusColor(interview.performanceStatus);
    final resultLabel = recentInterviewShareLabel(interview, title);
    return GestureDetector(
      key: Key('performance_interview_${interview.simulationId}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _openRecentInterview(context, interview.simulationId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              key: Key('performance_share_${interview.simulationId}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => openLinkedInShare(
                context,
                simulationId: interview.simulationId,
                resultLabel: resultLabel,
              ),
              child: const Padding(
                padding: EdgeInsetsDirectional.only(end: 8),
                child: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.primarySet2,
                ),
              ),
            ),
            if (badge != null && badgeColor != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.regular(fontSize: 14, color: badgeColor),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTypography.regular(
                      fontSize: 14,
                      color: AppColors.fontColor,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTypography.regular(
                        fontSize: 12,
                        color: AppColors.hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRecentInterview(BuildContext context, String simulationId) {
  final cubit = GetIt.instance<InterviewCubit>();
  cubit.openCompletedReport(simulationId);
  Navigator.pushNamed(
    context,
    RoutesName.simulationResult,
    arguments: cubit,
  );
}

Color? _statusColor(PerformanceStatus? status) {
  switch (status) {
    case PerformanceStatus.excellent:
      return AppColors.primary;
    case PerformanceStatus.average:
      return const Color(0xFFF5A90B);
    case PerformanceStatus.poor:
      return AppColors.error;
    case null:
      return null;
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'more'),
            style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
          ),
          const SizedBox(height: 24),
          _menuTile(
            context,
            Icons.person_outline,
            AppLocalizations.tr(context, 'cv_title'),
            onTap: () => Navigator.pushNamed(context, RoutesName.profile),
          ),
          _menuTile(
            context,
            Icons.badge_outlined,
            AppLocalizations.tr(context, 'cv_result_title'),
            onTap: () =>
                Navigator.pushNamed(context, RoutesName.completeProfile),
          ),
          _menuTile(context, Icons.help_outline,
              AppLocalizations.tr(context, 'help')),
          _menuTile(context, Icons.info_outline,
              AppLocalizations.tr(context, 'about_app')),
          _menuTile(
            context,
            Icons.logout,
            AppLocalizations.tr(context, 'logout'),
            isDestructive: true,
            onTap: () async {
              _countCubitOf(context)?.clearSession();
              final session = GetIt.instance<RashedSession>();
              final userId = await session.readUserId();
              if (userId != null && userId.isNotEmpty) {
                await GetIt.instance<CvLocalDataSource>().delete(userId);
              }
              if (context.mounted) {
                await endRashedSession(context, session);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String label, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.fontColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: AppTypography.regular(fontSize: 16, color: color),
            textAlign: TextAlign.start,
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.hintColor,
            size: 20,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
