import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../app/root_navigator.dart';
import '../../app/routes_name.dart';
import 'rashed_session.dart';

/// Sends the user to sign-in when the Rashed session is cleared elsewhere,
/// including a rejected Rashed bearer.
class RashedSessionNavigator extends StatefulWidget {
  const RashedSessionNavigator({
    super.key,
    required this.session,
    required this.child,
  });

  final RashedSession session;
  final Widget child;

  @override
  State<RashedSessionNavigator> createState() => _RashedSessionNavigatorState();
}

class _RashedSessionNavigatorState extends State<RashedSessionNavigator> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.session.onCleared.listen((_) {
      rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        RoutesName.login,
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
