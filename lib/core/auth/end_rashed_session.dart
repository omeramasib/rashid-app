import 'package:flutter/widgets.dart';

import '../../app/routes_name.dart';
import 'rashed_session.dart';

/// Ends the Rashed session and returns to email sign-in.
///
/// Clerk is left untouched. A Clerk sign-out must not call this.
Future<void> endRashedSession(
  BuildContext context,
  RashedSession session,
) async {
  await session.clear();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(
    context,
    RoutesName.login,
    (route) => false,
  );
}
