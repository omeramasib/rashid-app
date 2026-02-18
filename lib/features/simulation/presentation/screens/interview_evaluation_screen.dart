import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/theme/theme.dart';

class InterviewEvaluationScreen extends StatelessWidget {
  const InterviewEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildProgress(1),
                      const SizedBox(height: 20),
                      _headerCard('ما هي نقاط قوتك وكيف تستفيد منها في العمل؟'),
                      const SizedBox(height: 14),
                      _headerCard('إجابتك', trailing: Icons.keyboard_arrow_down_rounded),
                      const SizedBox(height: 14),
                      _evaluationCard(),
                      const SizedBox(height: 14),
                      _actions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
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
                  'الإجابة على أسئلة المقابلة',
                  style: AppTypography.regular(fontSize: 20, color: AppColors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
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

  Widget _headerCard(String text, {IconData? trailing}) {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (trailing != null) Icon(trailing, color: AppColors.fontColor),
          const Spacer(),
          Text(
            text,
            style: AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
          ),
        ],
      ),
    );
  }

  Widget _evaluationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تقييم إجابتك',
            style: AppTypography.regular(fontSize: 18, color: AppColors.primarySet2),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(value: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  'احترافية وقوة إجابتك',
                  style: AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _feedbackBox('السلبيات', const ['⚠️ إجابة عامة', '⚠️ دون تحليل'])),
              const SizedBox(width: 8),
              Expanded(child: _feedbackBox('الإيجابيات', const ['✅ إجابة واضحة', '✅ لغة احترافية'])),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'هذه إجابتي المقترحة لك! \nلإبراز خبراتك في هذا السؤال، يمكنك الإجابة على النحو التالي...',
              style: AppTypography.regular(fontSize: 13, color: AppColors.fontColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackBox(String title, List<String> points) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: AppTypography.regular(fontSize: 12, color: AppColors.hintColor)),
          const SizedBox(height: 8),
          ...points.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(e, style: AppTypography.regular(fontSize: 12, color: AppColors.fontColor)),
              )),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _secondaryButton(
            text: 'السابق',
            onTap: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _primaryButton(
            text: 'التالي',
            onTap: () => Navigator.pushNamed(context, RoutesName.simulationResult),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(text, style: AppTypography.bold(fontSize: 16, color: AppColors.white)),
      ),
    );
  }

  Widget _secondaryButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(text, style: AppTypography.regular(fontSize: 16, color: AppColors.fontColor)),
      ),
    );
  }
}
