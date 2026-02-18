import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/theme/theme.dart';

class InterviewQuestionScreen extends StatefulWidget {
  const InterviewQuestionScreen({super.key, this.simulationType});

  final String? simulationType;

  @override
  State<InterviewQuestionScreen> createState() => _InterviewQuestionScreenState();
}

class _InterviewQuestionScreenState extends State<InterviewQuestionScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

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
                      _questionCard(),
                      const SizedBox(height: 14),
                      _answerCard(),
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

  Widget _questionCard() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      child: Text(
        'ما هي نقاط قوتك وكيف تستفيد منها في العمل؟',
        style: AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
      ),
    );
  }

  Widget _answerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'إجابتك',
            style: AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            maxLines: 7,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ادخل إجابتك لهذا السؤال',
              hintStyle:
                  AppTypography.regular(fontSize: 12, color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _secondaryButton(
            text: 'الغاء',
            onTap: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _primaryButton(
            text: 'حفظ واستمرار',
            onTap: () => Navigator.pushNamed(
              context,
              RoutesName.simulationEvaluation,
            ),
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
        child: Text(
          text,
          style: AppTypography.bold(fontSize: 16, color: AppColors.white),
        ),
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
        child: Text(
          text,
          style: AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
        ),
      ),
    );
  }
}
