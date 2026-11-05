import 'package:flutter/material.dart';

import '../../../../app_localizations.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/password_reset_problem.dart';
import '../../../../core/theme/theme.dart';

String passwordErrorText(
    AppLocalizations strings, PasswordResetProblem problem) {
  final key = switch (problem) {
    PasswordResetProblem.invalidEmail => 'reset_email_error',
    PasswordResetProblem.invalidOtp => 'reset_invalid_code',
    PasswordResetProblem.expiredOtp => 'reset_expired_code',
    PasswordResetProblem.confirmationMismatch => 'reset_password_mismatch',
    PasswordResetProblem.validation => 'reset_validation_error',
    PasswordResetProblem.timeout => 'reset_timeout',
    PasswordResetProblem.offline => 'reset_offline',
    PasswordResetProblem.server => 'reset_server_error',
    PasswordResetProblem.unknown => 'reset_unknown_error',
  };
  return strings.translate(key);
}

class PasswordFlowPage extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const PasswordFlowPage({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(title,
                      style: AppTypography.bold(
                          fontSize: 24, color: AppColors.fontColor),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(description,
                      style: AppTypography.regular(
                          fontSize: 16, color: AppColors.hintColor),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordIssueBanner extends StatelessWidget {
  final PasswordResetFailure failure;

  const PasswordIssueBanner({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Semantics(
        liveRegion: true,
        child: Text(
          passwordErrorText(strings, failure.problem),
          style: const TextStyle(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
