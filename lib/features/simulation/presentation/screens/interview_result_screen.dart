import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/theme/theme.dart';

class InterviewResultScreen extends StatelessWidget {
  const InterviewResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildProgress(5),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: SvgPicture.asset(ImageManages.rashedImage),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ممتاز',
                        style: AppTypography.regular(
                          fontSize: 20,
                          color: AppColors.primarySet2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أداء رائع! أنت جاهز تمامًا لمقابلة العمل.\nاستمر في الإبداع!',
                        textAlign: TextAlign.center,
                        style: AppTypography.regular(
                          fontSize: 16,
                          color: AppColors.hintColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _linkedinButton(),
                      const SizedBox(height: 12),
                      _primaryButton(
                        text: 'استمر بتحسين مهاراتك',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  text: 'العودة للرئيسية',
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    RoutesName.home,
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(int current) {
    const total = 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$current من $total',
          style: AppTypography.regular(fontSize: 12, color: AppColors.fontColor),
        ),
        const SizedBox(height: 4),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: current / total,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkedinButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF3E6DDD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'شارك نتيجتك على LinkedIn',
            style: AppTypography.regular(fontSize: 17, color: AppColors.white),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.white,
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
        ],
      ),
    );
  }

  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTypography.bold(fontSize: 16, color: AppColors.white),
        ),
      ),
    );
  }
}
