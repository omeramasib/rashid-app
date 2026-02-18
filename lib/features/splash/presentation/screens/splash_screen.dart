import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/core/theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    final storage = GetIt.instance<SecureStorageService>();
    final token = await storage.read(key: 'token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.home,
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Image.asset(
                      ImageManages.appLogo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 137,
              right: 137,
              bottom: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: const SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: 0.32,
                    backgroundColor: AppColors.black20,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primarySet2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
