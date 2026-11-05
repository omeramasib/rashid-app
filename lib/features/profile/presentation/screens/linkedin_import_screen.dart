import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/core/widgets/app_back_button.dart';

class LinkedinImportScreen extends HookWidget {
  const LinkedinImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agreed = useState(false);
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildTopBar(context),
                const SizedBox(height: 28),
                _buildChatBubble(context),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: SvgPicture.asset(
                    ImageManages.rashedImage,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                _buildConsentRow(context, agreed),
                const SizedBox(height: 18),
                _buildLinkedinButton(context, agreed.value),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const AppBackButton(),
        Expanded(
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                AppLocalizations.tr(context, 'linkedin_import_title'),
                style:
                    AppTypography.regular(fontSize: 20, color: AppColors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildChatBubble(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.black10),
          ),
          child: Text(
            AppLocalizations.tr(context, 'linkedin_import_greeting'),
            textAlign: TextAlign.center,
            style: AppTypography.regular(
              fontSize: 17,
              color: AppColors.fontColor,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentRow(BuildContext context, ValueNotifier<bool> agreed) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => agreed.value = !agreed.value,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: agreed.value ? AppColors.primarySet2 : AppColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.black20),
            ),
            child: agreed.value
                ? const Icon(Icons.check, color: AppColors.white, size: 18)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppLocalizations.tr(context, 'linkedin_import_consent'),
            style:
                AppTypography.regular(fontSize: 17, color: AppColors.fontColor),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedinButton(BuildContext context, bool agreed) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, RoutesName.completeProfile);
      },
      child: Opacity(
        opacity: agreed ? 1 : 0.75,
        child: Container(
          width: double.infinity,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF86A1EA), Color(0xFF7997E9)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'in',
                  style: TextStyle(
                    color: Color(0xFF3E6DDD),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.tr(context, 'linkedin_import_button'),
                style:
                    AppTypography.regular(fontSize: 17, color: AppColors.white),
              ),
              const Spacer(),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}
