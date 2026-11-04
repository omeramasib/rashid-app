import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../../../core/localization/app_text_direction.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/answer_evaluation.dart';
import '../../domain/entities/interview_question.dart';
import '../cubit/interview_cubit.dart';
import '../interview_error_text.dart';
import '../widgets/interview_widgets.dart';

class InterviewEvaluationScreen extends StatelessWidget {
  const InterviewEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: BlocListener<InterviewCubit, InterviewState>(
        listenWhen: (previous, current) =>
            previous.phase != InterviewPhase.finished &&
            current.phase == InterviewPhase.finished,
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.pushNamed(
            context,
            RoutesName.simulationResult,
            arguments: context.read<InterviewCubit>(),
          );
        },
        child: BlocBuilder<InterviewCubit, InterviewState>(
          builder: (context, state) {
            final question = state.currentQuestion;
            final evaluation =
                question == null ? null : state.evaluations[question.id];
            final routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
            return Scaffold(
              backgroundColor: AppColors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    InterviewTopBar(
                      title: AppLocalizations.tr(
                        context,
                        'interview_questions_title',
                      ),
                      onBack: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          InterviewProgressBar(
                            current: state.questions.isEmpty
                                ? 0
                                : state.currentIndex + 1,
                            total: state.questions.length,
                          ),
                          const SizedBox(height: 20),
                          if (question == null || evaluation == null)
                            Text(
                              AppLocalizations.tr(
                                context,
                                'interview_empty_session',
                              ),
                              key: const Key('interview_empty_evaluation'),
                              style: AppTypography.regular(
                                fontSize: 16,
                                color: AppColors.fontColor,
                              ),
                            )
                          else
                            _review(context, question, evaluation),
                          if (state.error != null && routeCurrent) ...[
                            const SizedBox(height: 12),
                            InterviewErrorBanner(
                              message:
                                  interviewErrorText(context, state.error!),
                              actionLabel: interviewSessionClosed(state.error!)
                                  ? AppLocalizations.tr(
                                      context,
                                      'interview_finish_session',
                                    )
                                  : null,
                              onAction: interviewSessionClosed(state.error!)
                                  ? () =>
                                      context.read<InterviewCubit>().finish()
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 14),
                          _actions(context, state),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _review(
    BuildContext context,
    InterviewQuestion question,
    AnswerEvaluation evaluation,
  ) {
    final answer =
        context.read<InterviewCubit>().state.submittedAnswers[question.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          key: const Key('interview_question_text'),
          style:
              AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
        ),
        if (answer != null && answer.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            answer,
            key: const Key('interview_submitted_answer'),
            style:
                AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          AppLocalizations.tr(context, 'evaluate_answer'),
          style:
              AppTypography.regular(fontSize: 18, color: AppColors.primarySet2),
        ),
        const SizedBox(height: 8),
        if (evaluation.skipped)
          Text(
            AppLocalizations.tr(context, 'interview_skipped'),
            key: const Key('interview_skipped'),
            style:
                AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
          )
        else ...[
          if (evaluation.score != null)
            Text(
              AppLocalizations.tr(context, 'interview_question_score', {
                'score': '${evaluation.score}',
              }),
              key: const Key('interview_question_score'),
              style:
                  AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
            ),
          if (_hasItems(evaluation.strengths)) ...[
            const SizedBox(height: 10),
            _points(context, 'positives', evaluation.strengths!),
          ],
          if (_hasItems(evaluation.weaknesses)) ...[
            const SizedBox(height: 10),
            _points(context, 'negatives', evaluation.weaknesses!),
          ],
          if (evaluation.suggestedAnswer != null &&
              evaluation.suggestedAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              AppLocalizations.tr(context, 'interview_suggested_title'),
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              evaluation.suggestedAnswer!,
              key: const Key('interview_suggested_answer'),
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.fontColor,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _points(BuildContext context, String titleKey, List<String> points) {
    return Column(
      key: Key('interview_$titleKey'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tr(context, titleKey),
          style:
              AppTypography.regular(fontSize: 13, color: AppColors.hintColor),
        ),
        for (final point in points)
          Text(
            point,
            style:
                AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
          ),
      ],
    );
  }

  Widget _actions(BuildContext context, InterviewState state) {
    final cubit = context.read<InterviewCubit>();
    final finishing = state.phase == InterviewPhase.finishing;
    return Row(
      children: [
        if (state.currentIndex > 0) ...[
          Expanded(
            child: InterviewActionButton(
              key: const Key('interview_previous_button'),
              label: AppLocalizations.tr(context, 'previous'),
              primary: false,
              onPressed: state.requestInFlight
                  ? null
                  : () {
                      cubit.previous();
                      Navigator.pop(context);
                    },
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: InterviewActionButton(
            key: const Key('interview_next_button'),
            label: AppLocalizations.tr(
              context,
              state.isLastQuestion ? 'interview_finish' : 'next',
            ),
            busy: finishing,
            onPressed: state.requestInFlight
                ? null
                : () {
                    final last = state.isLastQuestion;
                    cubit.next();
                    if (!last) Navigator.pop(context);
                  },
          ),
        ),
      ],
    );
  }

  bool _hasItems(List<String>? values) => values != null && values.isNotEmpty;
}
