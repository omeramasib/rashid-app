import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/theme/theme.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key, this.phoneNumber, this.email});

  final String? phoneNumber;
  final String? email;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactInfo = widget.phoneNumber ?? widget.email ?? '';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.fontColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'تحقق من الرمز',
              style: AppTypography.bold(fontSize: 24, color: AppColors.fontColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'أدخل رمز التحقق المرسل إلى $contactInfo',
              style:
                  AppTypography.regular(fontSize: 16, color: AppColors.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _controllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لم يصلك الرمز؟',
                  style:
                      AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'إعادة الإرسال',
                    style:
                        AppTypography.bold(fontSize: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RoutesName.home,
                  (route) => false,
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'تحقق',
                  style: AppTypography.bold(fontSize: 16, color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
