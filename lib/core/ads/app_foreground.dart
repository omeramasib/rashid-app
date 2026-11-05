import 'package:flutter/widgets.dart';

/// Whether the Flutter app is in the resumed lifecycle state.
///
/// A missing lifecycle state counts as resumed so tests and the first frame
/// do not hold the interview start.
abstract class AppForegroundSignal {
  bool get isResumed;

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);
}

class AlwaysResumedForeground implements AppForegroundSignal {
  const AlwaysResumedForeground();

  @override
  bool get isResumed => true;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class WidgetsAppForeground extends AppForegroundSignal
    with WidgetsBindingObserver {
  WidgetsAppForeground() {
    WidgetsBinding.instance.addObserver(this);
  }

  final List<VoidCallback> _listeners = <VoidCallback>[];

  @override
  bool get isResumed {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}
