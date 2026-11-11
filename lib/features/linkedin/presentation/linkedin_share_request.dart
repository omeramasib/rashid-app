import 'package:flutter/material.dart';

import '../../../app/routes_name.dart';

class LinkedInShareRequest {
  final String simulationId;
  final String? resultLabel;

  const LinkedInShareRequest({
    required this.simulationId,
    this.resultLabel,
  });
}

/// Drops a second share launch while the first route is still opening.
class LinkedInShareLaunchGuard {
  var _busy = false;

  Future<void> run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }
}

Future<void> openLinkedInShare(
  BuildContext context, {
  required String simulationId,
  String? resultLabel,
}) {
  final id = simulationId.trim();
  if (id.isEmpty) return Future<void>.value();
  return Navigator.of(context)
      .pushNamed(
        RoutesName.linkedinShare,
        arguments: LinkedInShareRequest(
          simulationId: id,
          resultLabel: resultLabel,
        ),
      )
      .then((_) {});
}
