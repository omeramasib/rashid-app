import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/core/theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeBody(),
    _PerformanceBody(),
    _MoreBody(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: _pages[_currentIndex]),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.black10, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home_outlined, index: 0, isHome: true),
          _navItem(icon: Icons.show_chart_rounded, index: 1),
          _navItem(icon: Icons.menu, index: 2),
        ],
      ),
    );
  }

  Widget _navItem(
      {required IconData icon, required int index, bool isHome = false}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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
            'الرئيسية',
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
            title: 'محكاة بوصف وظيفي محدد',
            description:
                'ادخل الوصف الوظيفي للمقابلة التي ترغب في التقديم لها\nستكون المحاكاة مخصصة حسب الوصف',
            icon: Icons.description_outlined,
            onTap: () => Navigator.pushNamed(
              context,
              RoutesName.simulationQuestion,
              arguments: 'job_description',
            ),
          ),
          const SizedBox(height: 10),
          _SimulationCard(
            title: 'محكاة حسب المجال العمل',
            description: 'يمكنك اختيار مجال عملك الذي ترغب في عمل محاكاة له',
            icon: Icons.description_outlined,
            onTap: () => Navigator.pushNamed(
              context,
              RoutesName.simulationQuestion,
              arguments: 'career_field',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
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
              'مرحبًا محمد  في راشد!\nجاهز لتحسين مهاراتك في المقابلات؟',
              style:
                  AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
              textAlign: TextAlign.right,
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
            'شارك اخر نتيجة لك',
            style:
                AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
            textAlign: TextAlign.right,
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
                  'مشاركة نتيجتي',
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
            'عدد مرات المحاكاة',
            style:
                AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
            textAlign: TextAlign.right,
          ),
          const Spacer(),
          Text(
            '4',
            style: AppTypography.regular(
                fontSize: 20, color: AppColors.primarySet2),
            textAlign: TextAlign.right,
          ),
        ],
      ),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    title,
                    style: AppTypography.regular(
                        fontSize: 15, color: AppColors.white),
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
              style:
                  AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
              textAlign: TextAlign.right,
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
                'ابدأ المحاكاة',
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
              'أدائك',
              style: AppTypography.bold(fontSize: 20, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 16),
          _BestResultBanner(),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                  child:
                      _StatCard(label: 'متوسط الأداء', value: '72%', icon: Icons.star_outline)),
              SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'عدد مرات المحاكاة',
                      value: '4',
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
                      'أفضل نتيجة لك',
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
                        'مشاركة نتيجتي',
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
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
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
              style: AppTypography.regular(fontSize: 12, color: AppColors.fontColor)),
          const Spacer(),
          Text(value,
              style: AppTypography.regular(fontSize: 20, color: AppColors.primarySet2)),
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
            'سجل مقابلات',
            style: AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          _interviewRow('مقابلة محاكاة في البرمجة', '25 نوفمبر 2024', 'ممتاز',
              AppColors.primary),
          const Divider(height: 1, color: AppColors.black10),
          _interviewRow('مقابلة محاكاة في البرمجة', '25 نوفمبر 2024', 'متوسط',
              const Color(0xFFF5A90B)),
          const Divider(height: 1, color: AppColors.black10),
          _interviewRow('مقابلة محاكاة في البرمجة', '25 نوفمبر 2024', 'سيء',
              AppColors.error),
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
            'المزيد',
            style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
          ),
          const SizedBox(height: 24),
          _menuTile(
            context,
            Icons.person_outline,
            'الملف الشخصي',
            onTap: () => Navigator.pushNamed(context, RoutesName.profile),
          ),
          _menuTile(
            context,
            Icons.badge_outlined,
            'اكمال الملف الشخصي',
            onTap: () => Navigator.pushNamed(context, RoutesName.completeProfile),
          ),
          _menuTile(context, Icons.help_outline, 'المساعدة'),
          _menuTile(context, Icons.info_outline, 'عن التطبيق'),
          _menuTile(
            context,
            Icons.logout,
            'تسجيل الخروج',
            isDestructive: true,
            onTap: () async {
              final storage = GetIt.instance<SecureStorageService>();
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
            textAlign: TextAlign.right,
          ),
          trailing: const Icon(Icons.chevron_left,
              color: AppColors.hintColor, size: 20),
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
