import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/ads/ad_consent_service.dart';
import 'package:rashed_app/core/auth/end_rashed_session.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/di/injection_container.dart' as di;
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/localization/localization_bloc.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/features/profile/presentation/widgets/connected_accounts_sheet.dart';
import 'package:rashed_app/features/profile/presentation/widgets/language_picker_sheet.dart';
import 'package:rashed_app/features/auth/presentation/cubit/profile/auth_profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.adConsent});

  final AdConsentService? adConsent;

  AdConsentService? get _consent {
    if (adConsent != null) return adConsent;
    if (!di.sl.isRegistered<AdConsentService>()) return null;
    return di.sl<AdConsentService>();
  }

  @override
  Widget build(BuildContext context) {
    final consent = _consent;
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          AppLocalizations.tr(context, 'profile_title'),
                          style: AppTypography.bold(
                            fontSize: 20,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildProfileHeaderCard(context),
                      const SizedBox(height: 14),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'about_app'),
                        icon: Icons.grid_view_outlined,
                        iconColor: AppColors.primarySet2,
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'rate_app'),
                        icon: Icons.star_border_rounded,
                        iconColor: AppColors.primarySet2,
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'privacy_policy'),
                        icon: Icons.description_outlined,
                        iconColor: AppColors.primarySet2,
                        onTap: () {},
                      ),
                      if (consent != null)
                        FutureBuilder<bool>(
                          future: consent.isPrivacyOptionsRequired(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true) {
                              return const SizedBox.shrink();
                            }
                            return _buildMenuItem(
                              key: const Key('ad_privacy_options'),
                              context: context,
                              title: AppLocalizations.tr(
                                context,
                                'ad_privacy_options',
                              ),
                              icon: Icons.privacy_tip_outlined,
                              iconColor: AppColors.primarySet2,
                              onTap: () {
                                unawaited(consent.showPrivacyOptionsForm());
                              },
                            );
                          },
                        ),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'share_app'),
                        icon: Icons.share_outlined,
                        iconColor: AppColors.primarySet2,
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'language'),
                        value: AppLocalizations.tr(
                          context,
                          context
                                      .watch<LocalizationBloc>()
                                      .state
                                      .locale
                                      .languageCode ==
                                  'ar'
                              ? 'language_arabic'
                              : 'language_english',
                        ),
                        icon: Icons.language_outlined,
                        iconColor: AppColors.primarySet2,
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: AppColors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => const LanguagePickerSheet(),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'connected_accounts'),
                        icon: Icons.link_rounded,
                        iconColor: AppColors.primarySet2,
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppColors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => BlocProvider(
                              create: (_) =>
                                  di.sl<AuthProfileCubit>()..getCurrentUser(),
                              child: const ConnectedAccountsSheet(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        title: AppLocalizations.tr(context, 'logout'),
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        onTap: () {
                          endRashedSession(context, di.sl<RashedSession>());
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 46, 12, 10),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.tr(context, 'profile_greeting'),
                      style: AppTypography.regular(
                        fontSize: 16,
                        color: AppColors.fontColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                            context, RoutesName.completeProfile);
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: -30,
          child: Center(
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C6C6),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black10.withValues(alpha: 0.8),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    Key? key,
    required BuildContext context,
    required String title,
    String? value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: iconColor),
                const Spacer(),
                if (value != null) ...[
                  Text(
                    value,
                    style: AppTypography.regular(
                      fontSize: 14,
                      color: AppColors.hintColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: AppTypography.regular(
                    fontSize: 17,
                    color: AppColors.fontColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.black10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesName.home,
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.home_filled,
              color: AppColors.hintColor,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesName.home,
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.show_chart_rounded,
              color: AppColors.hintColor,
              size: 28,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.menu_rounded,
              color: AppColors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
