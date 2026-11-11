import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/root_navigator.dart';
import '../../../app/routes_name.dart';
import 'cubit/linkedin_share_cubit.dart';
import 'cubit/linkedin_share_state.dart';

class LinkedInShareRouteObserver extends NavigatorObserver {
  VoidCallback? onChanged;

  void _notify() => onChanged?.call();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _notify();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();
}

/// Opens the share screen after an OAuth return, including a cold start.
///
/// The return itself never publishes. Splash and login stay in place until
/// the existing Rashed session has chosen a destination.
class LinkedInSharePresenter extends StatefulWidget {
  final Widget child;
  final LinkedInShareRouteObserver observer;
  final LinkedInShareCubit cubit;

  const LinkedInSharePresenter({
    super.key,
    required this.child,
    required this.observer,
    required this.cubit,
  });

  @override
  State<LinkedInSharePresenter> createState() => _LinkedInSharePresenterState();
}

class _LinkedInSharePresenterState extends State<LinkedInSharePresenter> {
  var _shownGeneration = 0;
  StreamSubscription<LinkedInShareState>? _subscription;

  @override
  void initState() {
    super.initState();
    widget.observer.onChanged = _schedule;
    _subscription = widget.cubit.stream.listen((_) => _schedule());
    _schedule();
  }

  @override
  void didUpdateWidget(LinkedInSharePresenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.observer.onChanged = _schedule;
  }

  @override
  void dispose() {
    if (widget.observer.onChanged == _schedule) {
      widget.observer.onChanged = null;
    }
    _subscription?.cancel();
    super.dispose();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _present();
    });
  }

  void _present() {
    final generation = widget.cubit.state.returnGeneration;
    if (generation == 0 || generation == _shownGeneration) return;
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    String? top;
    navigator.popUntil((route) {
      top = route.settings.name;
      return true;
    });
    if (top == null ||
        top == RoutesName.splash ||
        top == RoutesName.login ||
        top == RoutesName.register) {
      return;
    }
    if (top == RoutesName.linkedinShare) {
      _shownGeneration = generation;
      return;
    }
    _shownGeneration = generation;
    navigator.pushNamed(RoutesName.linkedinShare);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
