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

void openLinkedInShare(
  BuildContext context, {
  required String simulationId,
  String? resultLabel,
}) {
  final id = simulationId.trim();
  if (id.isEmpty) return;
  Navigator.of(context).pushNamed(
    RoutesName.linkedinShare,
    arguments: LinkedInShareRequest(
      simulationId: id,
      resultLabel: resultLabel,
    ),
  );
}
