import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../../../core/localization/app_text_direction.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/interview_options.dart';
import '../cubit/interview_cubit.dart';
import '../interview_error_text.dart';
import '../widgets/interview_widgets.dart';

class InterviewQuestionScreen extends HookWidget {
  const InterviewQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final state = context.watch<InterviewCubit>().state;
    final question = state.currentQuestion;
    final savedAnswer =
        question == null ? null : state.submittedAnswers[question.id];
    useEffect(() {
      controller.text = savedAnswer ?? '';
      return null;
    }, [question?.id, savedAnswer]);
    useListenable(controller);

    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: BlocListener<InterviewCubit, InterviewState>(
        listenWhen: (previous, current) =>
            (previous.phase == InterviewPhase.submitting &&
                current.phase == InterviewPhase.inProgress &&
                current.error == null) ||
            (previous.phase != InterviewPhase.finished &&
                current.phase == InterviewPhase.finished),
        listener: (context, next) {
          if (!context.mounted) return;
          if (ModalRoute.of(context)?.isCurrent != true) return;
          final cubit = context.read<InterviewCubit>();
          if (next.phase == InterviewPhase.finished) {
            Navigator.pushNamed(
              context,
              RoutesName.simulationResult,
              arguments: cubit,
            );
            return;
          }
          Navigator.pushNamed(
            context,
            RoutesName.simulationEvaluation,
            arguments: cubit,
          );
        },
        child: PopScope(
          canPop: state.simulationId == null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _confirmFinish(context);
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            body: SafeArea(
              child: Column(
                children: [
                  InterviewTopBar(
                    title: AppLocalizations.tr(
                      context,
                      'interview_questions_title',
                    ),
                    onBack: () => _confirmFinish(context),
                  ),
                  Expanded(child: _body(context, state, controller)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    InterviewState state,
    TextEditingController controller,
  ) {
    final question = state.currentQuestion;
    if (question == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.tr(context, 'interview_empty_questions'),
          key: const Key('interview_empty_questions'),
          style:
              AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
        ),
      );
    }
    final evaluation = state.evaluations[question.id];
    final readOnly = evaluation != null;
    final submitting = state.phase == InterviewPhase.submitting;
    final canSubmit =
        controller.text.trim().isNotEmpty && !submitting && !readOnly;
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        InterviewProgressBar(
          current: state.currentIndex + 1,
          total: state.questions.length,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (question.category != null)
                Text(
                  question.category!,
                  style: AppTypography.regular(
                    fontSize: 12,
                    color: AppColors.hintColor,
                  ),
                ),
              Text(
                question.questionText,
                key: const Key('interview_question_text'),
                style: AppTypography.regular(
                  fontSize: 16,
                  color: AppColors.fontColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.tr(context, 'your_answer'),
          style:
              AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('interview_answer_input'),
          controller: controller,
          enabled: !readOnly && !submitting,
          readOnly: readOnly,
          maxLines: 7,
          maxLength: InterviewOptions.maxAnswerLength,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: AppLocalizations.tr(context, 'answer_hint'),
            filled: true,
            fillColor: AppColors.white,
          ),
        ),
        if (state.error != null && routeCurrent) ...[
          const SizedBox(height: 8),
          InterviewErrorBanner(
            message: interviewErrorText(context, state.error!),
            actionLabel: interviewSessionClosed(state.error!)
                ? AppLocalizations.tr(context, 'interview_finish_session')
                : null,
            onAction: interviewSessionClosed(state.error!)
                ? () => context.read<InterviewCubit>().finish()
                : null,
          ),
        ],
        const SizedBox(height: 14),
        if (readOnly)
          Row(
            children: [
              Expanded(
                child: InterviewActionButton(
                  label: AppLocalizations.tr(
                    context,
                    state.isLastQuestion ? 'interview_finish' : 'next',
                  ),
                  busy: state.phase == InterviewPhase.finishing,
                  onPressed: state.requestInFlight
                      ? null
                      : () => context.read<InterviewCubit>().next(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InterviewActionButton(
                  key: const Key('interview_view_review'),
                  label: AppLocalizations.tr(context, 'interview_view_review'),
                  primary: false,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RoutesName.simulationEvaluation,
                    arguments: context.read<InterviewCubit>(),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: InterviewActionButton(
                  key: const Key('interview_skip_button'),
                  label: AppLocalizations.tr(context, 'interview_skip'),
                  primary: false,
                  busy: submitting,
                  onPressed: submitting
                      ? null
                      : () => context.read<InterviewCubit>().skip(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InterviewActionButton(
                  key: const Key('interview_submit_button'),
                  label: AppLocalizations.tr(
                    context,
                    submitting ? 'interview_submitting' : 'interview_submit',
                  ),
                  busy: submitting,
                  onPressed: canSubmit
                      ? () =>
                          context.read<InterviewCubit>().submit(controller.text)
                      : null,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

Future<void> _confirmFinish(BuildContext context) async {
  final cubit = context.read<InterviewCubit>();
  final phase = cubit.state.phase;
  if (phase == InterviewPhase.finishing || phase == InterviewPhase.finished) {
    return;
  }
  final finishNow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title:
            Text(AppLocalizations.tr(dialogContext, 'interview_finish_title')),
        content:
            Text(AppLocalizations.tr(dialogContext, 'interview_finish_body')),
        actions: [
          TextButton(
            key: const Key('interview_keep_going'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
                AppLocalizations.tr(dialogContext, 'interview_keep_going')),
          ),
          TextButton(
            key: const Key('interview_finish_now'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
                AppLocalizations.tr(dialogContext, 'interview_finish_now')),
          ),
        ],
      );
    },
  );
  if (finishNow == true) cubit.finish();
}
