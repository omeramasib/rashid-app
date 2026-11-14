import 'package:flutter/material.dart';

import '../../../app_localizations.dart';
import '../domain/linkedin_auth_conflicts.dart';

class LinkedInEmailConflictNotice extends StatelessWidget {
  const LinkedInEmailConflictNotice({
    super.key,
    required this.onSignInWithEmail,
  });

  final VoidCallback onSignInWithEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.message(
            context,
            LinkedInAuthConflicts.emailAccountExists,
          ),
          key: const Key('linkedin_email_conflict_message'),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const Key('sign_in_with_email'),
            onPressed: onSignInWithEmail,
            child: Text(AppLocalizations.tr(context, 'sign_in_with_email')),
          ),
        ),
      ],
    );
  }
}
