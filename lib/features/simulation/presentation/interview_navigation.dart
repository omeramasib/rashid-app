import 'package:flutter/widgets.dart';

import '../../../app/routes_name.dart';
import '../domain/interview_options.dart';

Future<void>? _interviewEntry;

/// Opens interview simulation once.
///
/// Taps that arrive while that route is still open share its navigation and
/// do not start another CV check.
Future<void> openInterviewSimulation(
  BuildContext context,
  InterviewStartMode mode,
) {
  final pending = _interviewEntry;
  if (pending != null) return pending;
  if (!context.mounted) return Future<void>.value();
  final route = Navigator.of(context).pushNamed(
    RoutesName.simulationSetup,
    arguments: mode,
  );
  late final Future<void> tracked;
  tracked = route.then<void>((_) {}).whenComplete(() {
    if (identical(_interviewEntry, tracked)) {
      _interviewEntry = null;
    }
  });
  _interviewEntry = tracked;
  return tracked;
}

@visibleForTesting
void resetInterviewEntryLock() {
  _interviewEntry = null;
}
