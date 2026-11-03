import 'package:flutter/material.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import 'password_flow_ui.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return PasswordFlowPage(
      title: strings.translate('reset_success_title'),
      description: strings.translate('reset_success_message'),
      children: [
        ElevatedButton(
          key: const Key('backToLogin'),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, RoutesName.login, (_) => false),
          child: Text(strings.translate('back_to_login')),
        ),
      ],
    );
  }
}
