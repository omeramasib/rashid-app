import 'package:flutter/widgets.dart';

import '../../../app_localizations.dart';
import 'cubit/linkedin_share_state.dart';

String linkedInShareNoticeText(
    BuildContext context, LinkedInShareNotice notice) {
  final key = switch (notice) {
    LinkedInShareNotice.none => '',
    LinkedInShareNotice.sessionExpired => 'linkedin_session_expired',
    LinkedInShareNotice.reconnect => 'linkedin_permission_required',
    LinkedInShareNotice.notFound => 'linkedin_not_found',
    LinkedInShareNotice.previewExpired => 'linkedin_preview_expired',
    LinkedInShareNotice.publishUnconfirmed => 'linkedin_unconfirmed',
    LinkedInShareNotice.unavailable => 'linkedin_unavailable',
    LinkedInShareNotice.cancelled => 'linkedin_cancelled',
    LinkedInShareNotice.invalidState => 'linkedin_invalid_state',
    LinkedInShareNotice.missingPermission => 'linkedin_permission_required',
    LinkedInShareNotice.accountConflict => 'linkedin_account_conflict',
    LinkedInShareNotice.generic => 'linkedin_generic_error',
  };
  if (key.isEmpty) return '';
  return AppLocalizations.tr(context, key);
}
