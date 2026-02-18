import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/theme/theme.dart';

class LinkedinImportScreen extends StatefulWidget {
  const LinkedinImportScreen({super.key});

  @override
  State<LinkedinImportScreen> createState() => _LinkedinImportScreenState();
}

class _LinkedinImportScreenState extends State<LinkedinImportScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildTopBar(),
                const SizedBox(height: 28),
                _buildChatBubble(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: SvgPicture.asset(
                    ImageManages.rashedImage,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                _buildConsentRow(),
                const SizedBox(height: 18),
                _buildLinkedinButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.chevron_right, size: 30, color: AppColors.black100),
          ),
        ),
        Expanded(
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                'إنشاء حساب جديد',
                style: AppTypography.regular(fontSize: 20, color: AppColors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildChatBubble() {
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
            'مرحبًا! هل ترغب بأن أستورد معلومات\nمهاراتك من لينكد ان؟ هذا سيساعدني في\nتجهيز ملفك الشخصي بشكل أفضل!',
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

  Widget _buildConsentRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreed = !_agreed),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _agreed ? AppColors.primarySet2 : AppColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.black20),
            ),
            child: _agreed
                ? const Icon(Icons.check, color: AppColors.white, size: 18)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'أوافق على استيراد بياناتي من LinkedIn لتحسين\nملفي الشخصي',
            style: AppTypography.regular(fontSize: 17, color: AppColors.fontColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedinButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, RoutesName.completeProfile);
      },
      child: Opacity(
        opacity: _agreed ? 1 : 0.75,
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
                'تسجيل بواسطة لينكد ان',
                style: AppTypography.regular(fontSize: 17, color: AppColors.white),
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
