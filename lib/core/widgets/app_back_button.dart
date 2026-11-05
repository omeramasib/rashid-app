import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Direction-aware back control.
///
/// [BackButtonIcon] uses an icon that mirrors with [Directionality]:
/// left in LTR, right in RTL. A [Row] then places it on the leading edge.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButton(
      key: const Key('app_back_button'),
      color: AppColors.black100,
      onPressed: () => Navigator.pop(context),
    );
  }
}
