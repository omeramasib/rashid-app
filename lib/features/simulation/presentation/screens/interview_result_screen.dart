import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../Presentation/utils/images.dart';
import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../../../core/localization/app_text_direction.dart';
import '../../../../core/theme/theme.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../domain/entities/interview_finish_result.dart';
import '../../domain/entities/interview_report.dart';
import '../cubit/interview_cubit.dart';
import '../interview_error_text.dart';
import '../widgets/interview_widgets.dart';

class InterviewResultScreen extends StatelessWidget {
  const InterviewResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: BlocBuilder<InterviewCubit, InterviewState>(
            builder: (context, state) {
              final result = state.finishResult;
              return ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  InterviewProgressBar(
                    current: result?.totalQuestions ?? state.questions.length,
                    total: result?.totalQuestions ?? state.questions.length,
                  ),
                  const SizedBox(height: 16),
                  if (result == null)
                    Text(
                      AppLocalizations.tr(context, 'interview_empty_session'),
                      style: AppTypography.regular(
                        fontSize: 16,
                        color: AppColors.fontColor,
                      ),
                    )
                  else
                    _summary(context, result),
                  const SizedBox(height: 16),
                  _report(context, state),
                  const SizedBox(height: 16),
                  _share(context),
                  const SizedBox(height: 12),
                  InterviewActionButton(
                    key: const Key('interview_keep_improving'),
                    label: AppLocalizations.tr(context, 'keep_improving'),
                    onPressed: () {
                      context.read<InterviewCubit>().prepareAnother();
                      Navigator.popUntil(
                        context,
                        (route) =>
                            route.settings.name == RoutesName.simulationSetup ||
                            route.isFirst,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  InterviewActionButton(
                    key: const Key('interview_back_home'),
                    label: AppLocalizations.tr(context, 'back_home'),
                    primary: false,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      RoutesName.home,
                      (route) => false,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, InterviewFinishResult result) {
    final band = performanceBandLabel(context, result.performanceStatus);
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: SvgPicture.asset(ImageManages.rashedImage),
        ),
        if (band != null && band.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            band,
            key: const Key('interview_band'),
            style: AppTypography.regular(
              fontSize: 20,
              color: AppColors.primarySet2,
            ),
          ),
        ],
        if (result.score != null) ...[
          const SizedBox(height: 8),
          Text(
            '${result.score}',
            key: const Key('interview_result_score'),
            style: AppTypography.bold(fontSize: 32, color: AppColors.fontColor),
          ),
        ],
        const SizedBox(height: 8),
        _counts(context, result),
        if (result.reportSummary != null &&
            result.reportSummary!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            result.reportSummary!,
            key: const Key('interview_result_summary'),
            textAlign: TextAlign.center,
            style: AppTypography.regular(
              fontSize: 16,
              color: AppColors.hintColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _counts(BuildContext context, InterviewFinishResult result) {
    final lines = <String>[
      if (result.totalQuestions != null)
        AppLocalizations.tr(context, 'interview_total_count', {
          'count': '${result.totalQuestions}',
        }),
      if (result.answeredQuestions != null)
        AppLocalizations.tr(context, 'interview_answered_count', {
          'count': '${result.answeredQuestions}',
        }),
      if (result.skippedQuestions != null)
        AppLocalizations.tr(context, 'interview_skipped_count', {
          'count': '${result.skippedQuestions}',
        }),
      if (result.unansweredQuestions != null)
        AppLocalizations.tr(context, 'interview_unanswered_count', {
          'count': '${result.unansweredQuestions}',
        }),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final line in lines)
          Text(
            line,
            style:
                AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
          ),
      ],
    );
  }

  Widget _report(BuildContext context, InterviewState state) {
    if (state.reportLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child:
              CircularProgressIndicator(key: Key('interview_report_loading')),
        ),
      );
    }
    if (state.reportFailure != null) {
      return InterviewErrorBanner(
        message: interviewErrorText(context, state.reportFailure!),
        actionLabel: AppLocalizations.tr(context, 'interview_report_retry'),
        onAction: () => context.read<InterviewCubit>().loadReport(),
      );
    }
    final report = state.report;
    if (report == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.finishResult?.reportSummary == null &&
            report.reportSummary != null &&
            report.reportSummary!.trim().isNotEmpty)
          Text(
            report.reportSummary!,
            key: const Key('interview_result_summary'),
            style:
                AppTypography.regular(fontSize: 16, color: AppColors.hintColor),
          ),
        _listSection(context, 'interview_strengths', report.strengths),
        _listSection(context, 'interview_improvements', report.improvements),
        _listSection(
          context,
          'interview_recommendations',
          report.recommendations,
        ),
        if (report.questions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            AppLocalizations.tr(context, 'interview_question_review'),
            style: AppTypography.bold(fontSize: 16, color: AppColors.fontColor),
          ),
          for (final question in report.questions) _question(context, question),
        ],
      ],
    );
  }

  Widget _listSection(
    BuildContext context,
    String titleKey,
    List<String>? values,
  ) {
    if (values == null || values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        key: Key(titleKey),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr(context, titleKey),
            style:
                AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
          ),
          for (final value in values)
            Text(
              value,
              style: AppTypography.regular(
                  fontSize: 14, color: AppColors.fontColor),
            ),
        ],
      ),
    );
  }

  Widget _question(BuildContext context, InterviewReportQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style:
                AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
          ),
          if (question.isSkipped)
            Text(
              AppLocalizations.tr(context, 'interview_skipped'),
              style: AppTypography.regular(
                  fontSize: 13, color: AppColors.hintColor),
            )
          else if (question.evaluationScore != null)
            Text(
              AppLocalizations.tr(context, 'interview_question_score', {
                'score': '${question.evaluationScore}',
              }),
              style: AppTypography.regular(
                  fontSize: 13, color: AppColors.fontColor),
            ),
          if (question.suggestedAnswer != null &&
              question.suggestedAnswer!.trim().isNotEmpty)
            Text(
              question.suggestedAnswer!,
              style: AppTypography.regular(
                  fontSize: 13, color: AppColors.hintColor),
            ),
        ],
      ),
    );
  }

  Widget _share(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final sharing = homeState is HomeSharing;
        final status = homeState is HomeShared
            ? AppLocalizations.tr(context, 'interview_share_sent')
            : homeState is HomeError
                ? AppLocalizations.message(context, homeState.message)
                : null;
        return Column(
          children: [
            InterviewActionButton(
              key: const Key('interview_share_button'),
              label: AppLocalizations.tr(context, 'share_linkedin_result'),
              busy: sharing,
              onPressed: sharing
                  ? null
                  : () => context.read<HomeCubit>().shareLastInterviewResult(),
            ),
            if (status != null && status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                status,
                key: const Key('interview_share_status'),
                style: AppTypography.regular(
                  fontSize: 13,
                  color: homeState is HomeError
                      ? AppColors.error
                      : AppColors.fontColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
