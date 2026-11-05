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
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_local_datasource.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/theme/theme.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({super.key, this.simulationHistoryCountCubit});

  final SimulationHistoryCountCubit? simulationHistoryCountCubit;

  static const _pages = [
    _HomeBody(),
    _PerformanceBody(),
    _MoreBody(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);
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

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              Expanded(child: _ShareCard()),
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

class _ShareCard extends StatelessWidget {
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
            style:
                AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
            textAlign: TextAlign.start,
          ),
          const Spacer(),
          Container(
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.tr(context, 'share_my_result'),
                  style: AppTypography.regular(
                      fontSize: 11, color: AppColors.white),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.share_outlined,
                    size: 16, color: AppColors.white),
              ],
            ),
          ),
        ],
      ),
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

class _PerformanceBody extends StatelessWidget {
  const _PerformanceBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              AppLocalizations.tr(context, 'performance'),
              style: AppTypography.bold(fontSize: 20, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 16),
          _BestResultBanner(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      label: AppLocalizations.tr(context, 'avg_performance'),
                      value: '72%',
                      icon: Icons.star_outline)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: AppLocalizations.tr(context, 'sim_count'),
                      value: null,
                      icon: Icons.sentiment_satisfied_alt_outlined)),
            ],
          ),
          const SizedBox(height: 10),
          _InterviewLog(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BestResultBanner extends StatelessWidget {
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
                      '85%',
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
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.tr(context, 'share_my_result'),
                        style: AppTypography.regular(
                            fontSize: 11, color: AppColors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.share_outlined,
                          size: 16, color: AppColors.white),
                    ],
                  ),
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
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String? value;
  final IconData icon;

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
          if (value == null)
            const _SimulationCountText()
          else
            Text(value!,
                style: AppTypography.regular(
                    fontSize: 20, color: AppColors.primarySet2)),
        ],
      ),
    );
  }
}

class _InterviewLog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          _interviewRow(
            AppLocalizations.tr(context, 'interview_programming'),
            AppLocalizations.tr(context, 'interview_sample_date'),
            AppLocalizations.tr(context, 'rating_excellent'),
            AppColors.primary,
          ),
          const Divider(height: 1, color: AppColors.black10),
          _interviewRow(
            AppLocalizations.tr(context, 'interview_programming'),
            AppLocalizations.tr(context, 'interview_sample_date'),
            AppLocalizations.tr(context, 'rating_average'),
            const Color(0xFFF5A90B),
          ),
          const Divider(height: 1, color: AppColors.black10),
          _interviewRow(
            AppLocalizations.tr(context, 'interview_programming'),
            AppLocalizations.tr(context, 'interview_sample_date'),
            AppLocalizations.tr(context, 'rating_poor'),
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _interviewRow(
      String title, String date, String badge, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: AppTypography.regular(fontSize: 14, color: badgeColor),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title,
                  style: AppTypography.regular(
                      fontSize: 14, color: AppColors.fontColor)),
              const SizedBox(height: 4),
              Text(date,
                  style: AppTypography.regular(
                      fontSize: 12, color: AppColors.hintColor)),
            ],
          ),
        ],
      ),
    );
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
              final storage = GetIt.instance<SecureStorageService>();
              final userId = await storage.read(key: 'user_id');
              if (userId != null && userId.isNotEmpty) {
                await GetIt.instance<CvLocalDataSource>().delete(userId);
              }
              await storage.delete(key: 'token');
              await storage.delete(key: 'user_id');
              await storage.delete(key: 'email');
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RoutesName.login,
                  (route) => false,
                );
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
