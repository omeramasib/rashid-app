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
    LinkedInShareNotice.alreadySharedDifferent =>
      'linkedin_already_shared_different',
    LinkedInShareNotice.confirmationRequired =>
      'linkedin_confirmation_required',
    LinkedInShareNotice.shareNotFound => 'linkedin_share_not_found',
    LinkedInShareNotice.shareNotDeletable => 'linkedin_share_not_deletable',
    LinkedInShareNotice.otherActivePosts => 'linkedin_other_active_posts',
    LinkedInShareNotice.readyToRepublish => 'linkedin_ready_to_republish',
    LinkedInShareNotice.network => 'linkedin_network_error',
    LinkedInShareNotice.generic => 'linkedin_generic_error',
  };
  if (key.isEmpty) return '';
  return AppLocalizations.tr(context, key);
}
