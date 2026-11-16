import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../Presentation/utils/images.dart';
import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/localization/app_text_direction.dart';
import '../../../../core/theme/theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../simulation/presentation/widgets/interview_widgets.dart';
import '../cubit/linkedin_share_cubit.dart';
import '../cubit/linkedin_share_state.dart';
import '../linkedin_post_link.dart';
import '../linkedin_share_request.dart';
import '../linkedin_share_text.dart';

class LinkedInShareScreen extends HookWidget {
  const LinkedInShareScreen({super.key, this.cubit, this.openPost});

  final LinkedInShareCubit? cubit;
  final Future<bool> Function(String? url)? openPost;

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final request = routeArgs is LinkedInShareRequest ? routeArgs : null;
    final controller = cubit ?? di.sl<LinkedInShareCubit>();
    useEffect(() {
      if (request == null) return null;
      controller.begin(
        simulationId: request.simulationId,
        resultLabel: request.resultLabel,
      );
      return null;
    }, [controller, request?.simulationId, request?.resultLabel]);

    return BlocProvider.value(
      value: controller,
      child: BlocListener<LinkedInShareCubit, LinkedInShareState>(
        listenWhen: (previous, current) =>
            current.notice == LinkedInShareNotice.sessionExpired &&
            previous.notice != LinkedInShareNotice.sessionExpired,
        listener: (context, state) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.login,
            (route) => false,
          );
        },
        child: _LinkedInShareView(
          openPost: openPost ?? openVerifiedLinkedInPost,
        ),
      ),
    );
  }
}

class _LinkedInShareView extends StatelessWidget {
  const _LinkedInShareView({required this.openPost});

  final Future<bool> Function(String? url) openPost;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: BlocBuilder<LinkedInShareCubit, LinkedInShareState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    AppLocalizations.tr(context, 'linkedin_share_title'),
                    key: const Key('linkedin_share_title'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bold(
                      fontSize: 20,
                      color: AppColors.fontColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      ImageManages.linkedinImage,
                      height: 48,
                      width: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.phase == LinkedInSharePhase.published &&
                      state.connection?.canPublish == true)
                    Text(
                      AppLocalizations.tr(context, 'linkedin_connected'),
                      textAlign: TextAlign.center,
                      style: AppTypography.regular(
                        fontSize: 13,
                        color: AppColors.primarySet2,
                      ),
                    ),
                  if (state.resultLabel != null &&
                      state.resultLabel!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.resultLabel!,
                      key: const Key('linkedin_result_label'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bold(
                        fontSize: 16,
                        color: AppColors.fontColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _body(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, LinkedInShareState state) {
    switch (state.phase) {
      case LinkedInSharePhase.initial:
      case LinkedInSharePhase.checkingConnection:
      case LinkedInSharePhase.startingOAuth:
      case LinkedInSharePhase.loadingPreview:
      case LinkedInSharePhase.publishing:
      case LinkedInSharePhase.markingDeleted:
        return _busy(
          context,
          state.phase == LinkedInSharePhase.publishing
              ? AppLocalizations.tr(context, 'linkedin_publishing')
              : state.phase == LinkedInSharePhase.markingDeleted
                  ? AppLocalizations.tr(context, 'linkedin_marking_deleted')
                  : null,
        );
      case LinkedInSharePhase.waitingForOAuthReturn:
        return _message(
          context,
          AppLocalizations.tr(context, 'linkedin_waiting'),
        );
      case LinkedInSharePhase.connectionRequired:
        return _connect(context, state);
      case LinkedInSharePhase.previewReady:
        return _preview(context, state);
      case LinkedInSharePhase.alreadyShared:
        return _alreadyShared(context, state);
      case LinkedInSharePhase.published:
        return _published(context, state);
      case LinkedInSharePhase.error:
        return _error(context, state);
    }
  }

  Widget _busy(BuildContext context, String? label) {
    return Column(
      children: [
        const CircularProgressIndicator(key: Key('linkedin_share_loading')),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(
            label,
            key: const Key('linkedin_publishing_label'),
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.fontColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _connect(BuildContext context, LinkedInShareState state) {
    final reconnect = state.connection?.needsReconnect ?? false;
    return Column(
      children: [
        Text(
          AppLocalizations.tr(context, 'linkedin_connect_body'),
          key: const Key('linkedin_connect_body'),
          textAlign: TextAlign.center,
          style: AppTypography.regular(
            fontSize: 14,
            color: AppColors.fontColor,
          ),
        ),
        const SizedBox(height: 16),
        InterviewActionButton(
          key: const Key('linkedin_connect_button'),
          label: AppLocalizations.tr(
            context,
            reconnect ? 'linkedin_reconnect' : 'linkedin_connect',
          ),
          onPressed: () => context.read<LinkedInShareCubit>().connect(),
        ),
        const SizedBox(height: 8),
        _cancel(context),
        _disconnect(context, state),
      ],
    );
  }

  Widget _preview(BuildContext context, LinkedInShareState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.connection?.canPublish == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.tr(context, 'linkedin_connected'),
              key: const Key('linkedin_connected_label'),
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.primarySet2,
              ),
            ),
          ),
        if (state.notice == LinkedInShareNotice.readyToRepublish) ...[
          Text(
            AppLocalizations.tr(context, 'linkedin_ready_to_republish'),
            key: const Key('linkedin_ready_to_republish'),
            textAlign: TextAlign.center,
            style: AppTypography.bold(
              fontSize: 16,
              color: AppColors.fontColor,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          AppLocalizations.tr(context, 'linkedin_preview'),
          style: AppTypography.bold(fontSize: 14, color: AppColors.fontColor),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            state.preview?.text ?? '',
            key: const Key('linkedin_preview_text'),
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.fontColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.tr(context, 'linkedin_publish_body'),
          key: const Key('linkedin_publish_body'),
          textAlign: TextAlign.center,
          style: AppTypography.regular(
            fontSize: 13,
            color: AppColors.hintColor,
          ),
        ),
        const SizedBox(height: 16),
        InterviewActionButton(
          key: const Key('linkedin_publish_button'),
          label: AppLocalizations.tr(context, 'linkedin_publish'),
          onPressed: () => context.read<LinkedInShareCubit>().publish(),
        ),
        const SizedBox(height: 8),
        _cancel(context),
        _disconnect(context, state),
      ],
    );
  }

  Widget _alreadyShared(BuildContext context, LinkedInShareState state) {
    final different =
        state.notice == LinkedInShareNotice.alreadySharedDifferent;
    final blocked = state.notice == LinkedInShareNotice.otherActivePosts ||
        state.republishBlocked;
    final titleKey = state.notice == LinkedInShareNotice.otherActivePosts
        ? 'linkedin_other_active_posts'
        : different
            ? 'linkedin_already_shared_different'
            : 'linkedin_already_shared';
    final postUrl = state.postUrl;
    final shareId = state.activeShareId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.tr(context, titleKey),
          key: Key(
            state.notice == LinkedInShareNotice.otherActivePosts
                ? 'linkedin_other_active_posts'
                : different
                    ? 'linkedin_already_different'
                    : 'linkedin_already_shared_label',
          ),
          textAlign: TextAlign.center,
          style: AppTypography.bold(fontSize: 16, color: AppColors.fontColor),
        ),
        if (blocked &&
            state.notice != LinkedInShareNotice.otherActivePosts) ...[
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr(context, 'linkedin_other_active_posts'),
            key: const Key('linkedin_other_active_posts'),
            textAlign: TextAlign.center,
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.fontColor,
            ),
          ),
        ],
        if (state.preview?.text != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              state.preview!.text,
              key: const Key('linkedin_preview_text'),
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.fontColor,
              ),
            ),
          ),
        ],
        if (postUrl != null) ...[
          const SizedBox(height: 16),
          InterviewActionButton(
            key: const Key('linkedin_view_published_post'),
            label: AppLocalizations.tr(context, 'linkedin_view_published_post'),
            onPressed: () => openPost(postUrl),
          ),
        ],
        if (shareId != null && shareId.isNotEmpty) ...[
          const SizedBox(height: 8),
          InterviewActionButton(
            key: const Key('linkedin_mark_deleted'),
            label: AppLocalizations.tr(context, 'linkedin_mark_deleted'),
            primary: false,
            onPressed: () => _confirmDeleted(context),
          ),
        ],
        const SizedBox(height: 8),
        InterviewActionButton(
          key: const Key('linkedin_back_performance'),
          label: AppLocalizations.tr(context, 'linkedin_back_performance'),
          primary: false,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.home,
            (route) => false,
            arguments: HomeScreen.performanceTab,
          ),
        ),
      ],
    );
  }

  Widget _published(BuildContext context, LinkedInShareState state) {
    final postUrl = state.postUrl;
    return Column(
      children: [
        Text(
          AppLocalizations.tr(context, 'linkedin_published'),
          key: const Key('linkedin_published_label'),
          textAlign: TextAlign.center,
          style: AppTypography.bold(fontSize: 16, color: AppColors.fontColor),
        ),
        if (postUrl != null) ...[
          const SizedBox(height: 16),
          InterviewActionButton(
            key: const Key('linkedin_open_post'),
            label: AppLocalizations.tr(context, 'linkedin_open_post'),
            onPressed: () => openPost(postUrl),
          ),
        ],
        const SizedBox(height: 8),
        InterviewActionButton(
          key: const Key('linkedin_back_performance'),
          label: AppLocalizations.tr(context, 'linkedin_back_performance'),
          primary: false,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.home,
            (route) => false,
            arguments: HomeScreen.performanceTab,
          ),
        ),
      ],
    );
  }

  Widget _error(BuildContext context, LinkedInShareState state) {
    final cubit = context.read<LinkedInShareCubit>();
    return Column(
      children: [
        Text(
          linkedInShareNoticeText(context, state.notice),
          key: const Key('linkedin_share_error'),
          textAlign: TextAlign.center,
          style: AppTypography.regular(fontSize: 14, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        if (state.notice == LinkedInShareNotice.previewExpired)
          InterviewActionButton(
            key: const Key('linkedin_refresh_preview'),
            label: AppLocalizations.tr(context, 'linkedin_refresh_preview'),
            onPressed: cubit.refreshPreview,
          ),
        if (state.notice == LinkedInShareNotice.reconnect ||
            state.notice == LinkedInShareNotice.missingPermission)
          InterviewActionButton(
            key: const Key('linkedin_connect_button'),
            label: AppLocalizations.tr(context, 'linkedin_reconnect'),
            onPressed: cubit.connect,
          ),
        const SizedBox(height: 8),
        _cancel(context),
      ],
    );
  }

  Future<void> _confirmDeleted(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            AppLocalizations.tr(
              dialogContext,
              'linkedin_delete_confirm_title',
            ),
            key: const Key('linkedin_delete_confirm_title'),
          ),
          content: Text(
            AppLocalizations.tr(
              dialogContext,
              'linkedin_delete_confirm_body',
            ),
            key: const Key('linkedin_delete_confirm_body'),
          ),
          actions: [
            TextButton(
              key: const Key('linkedin_delete_cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                AppLocalizations.tr(dialogContext, 'linkedin_cancel'),
              ),
            ),
            TextButton(
              key: const Key('linkedin_delete_confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                AppLocalizations.tr(dialogContext, 'linkedin_confirm'),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<LinkedInShareCubit>().markDeletedOnLinkedIn();
    }
  }

  Widget _cancel(BuildContext context) {
    return InterviewActionButton(
      key: const Key('linkedin_cancel'),
      label: AppLocalizations.tr(context, 'linkedin_cancel'),
      primary: false,
      onPressed: () => Navigator.maybePop(context),
    );
  }

  Widget _disconnect(BuildContext context, LinkedInShareState state) {
    if (!state.showDisconnect) return const SizedBox.shrink();
    return TextButton(
      key: const Key('linkedin_disconnect'),
      onPressed: () => context.read<LinkedInShareCubit>().disconnect(),
      child: Text(AppLocalizations.tr(context, 'linkedin_disconnect')),
    );
  }

  Widget _message(BuildContext context, String message) {
    return Text(
      message,
      key: const Key('linkedin_waiting'),
      textAlign: TextAlign.center,
      style: AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
    );
  }
}
