import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/theme/theme.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  int _step = 0;

  final TextEditingController _nameController =
      TextEditingController(text: 'محمد نصار');
  final TextEditingController _jobTitleController =
      TextEditingController(text: 'مصمم تجربة المستخدم');
  final TextEditingController _newSkillController = TextEditingController();

  final List<String> _skills = <String>[
    'تصميم تجربة المستخدم',
    'UX UI',
    'Agile',
    'حل المشاكل',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _newSkillController.dispose();
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
              _buildTopBar(),
              if (_step < 3) _buildStepper(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final String title = _step == 3 ? 'اكمال الملف الشخصي' : 'الملف الشخصي';
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
                  title,
                  style:
                      AppTypography.regular(fontSize: 20, color: AppColors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _stepChip(text: 'حمل سيرتك', isActive: _step == 0)),
          const SizedBox(width: 8),
          Expanded(child: _stepChip(text: 'تحليل السيرة', isActive: _step == 1)),
          const SizedBox(width: 8),
          Expanded(child: _stepChip(text: 'نتيجة التحليل', isActive: _step == 2)),
        ],
      ),
    );
  }

  Widget _stepChip({required String text, required bool isActive}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.regular(
          fontSize: 13,
          color: isActive ? AppColors.white : AppColors.hintColor,
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) return _buildUploadStep();
    if (_step == 1) return _buildProcessingStep();
    if (_step == 2) return _buildResultStep();
    return _buildSuccessStep();
  }

  Widget _buildUploadStep() {
    return _stepShell(
      topText: 'سنقوم بتحليل السيرة الذاتية لاستخراج\nمهاراتك ومعلوماتك الأساسية!',
      subtitle: 'الملفات المدعومة: PDF فقط',
      footer: Column(
        children: [
          Container(
            width: double.infinity,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload, size: 34, color: AppColors.hintColor),
                const SizedBox(height: 6),
                Text(
                  'حمل سيرتك الذاتية',
                  style: AppTypography.regular(
                    fontSize: 13,
                    color: AppColors.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _primaryCta(
            text: 'ابدأ التحليل الآن',
            onTap: () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingStep() {
    return _stepShell(
      topText: 'نقوم بمعالجة سيرتك الذاتية... لن يستغرق\nالأمر وقتًا طويلاً!',
      subtitle: null,
      footer: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              strokeWidth: 10,
              backgroundColor: AppColors.black10,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 36),
          _primaryCta(
            text: 'التالي',
            onTap: () => setState(() => _step = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _label('الإسم'),
          const SizedBox(height: 8),
          _input(_nameController),
          const SizedBox(height: 14),
          _label('المسمى الوظيفي'),
          const SizedBox(height: 8),
          _input(_jobTitleController),
          const SizedBox(height: 14),
          Text(
            'هذه مهاراتك المستخرجة، هل ترغب في إضافة المزيد؟',
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _skills.remove(skill);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.hintColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            skill,
                            style: AppTypography.regular(
                              fontSize: 14,
                              color: AppColors.primarySet2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 26,
                color: AppColors.primarySet2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newSkillController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'إضافة مهارة جديدة',
                    hintStyle: AppTypography.regular(
                      fontSize: 14,
                      color: AppColors.hintColor,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    final String trimmed = value.trim();
                    if (trimmed.isEmpty) return;
                    setState(() {
                      _skills.add(trimmed);
                      _newSkillController.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _primaryCta(
            text: 'حفظ واستمرار',
            onTap: () => setState(() => _step = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 28),
          _chatBubble(
            'رائع محمد! ملفك الشخصي جاهز الآن\nمع راشد مستقبلك في أمان ودايمًا كسبان',
            width: double.infinity,
            fontSize: 18,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: SvgPicture.asset(
              ImageManages.rashedImage,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          _primaryCta(
            text: 'ابدأ المحاكاة الأولى',
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesName.home,
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _stepShell({
    required String topText,
    required String? subtitle,
    required Widget footer,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _chatBubble(topText, width: 300, fontSize: 17),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: SvgPicture.asset(ImageManages.rashedImage, fit: BoxFit.contain),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }

  Widget _chatBubble(String text, {required double width, required double fontSize}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.black10),
      ),
      child: Text(
        text,
        style: AppTypography.regular(
          fontSize: fontSize,
          color: AppColors.black100,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.regular(fontSize: 16, color: AppColors.black100),
    );
  }

  Widget _input(TextEditingController controller) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      style: AppTypography.regular(fontSize: 17, color: AppColors.primarySet2),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.black10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.black10),
        ),
      ),
    );
  }

  Widget _primaryCta({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTypography.bold(fontSize: 19, color: AppColors.white),
        ),
      ),
    );
  }
}
