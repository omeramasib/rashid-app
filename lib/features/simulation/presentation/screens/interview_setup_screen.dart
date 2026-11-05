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

class InterviewSetupScreen extends HookWidget {
  const InterviewSetupScreen({super.key, required this.initialMode});

  final InterviewStartMode initialMode;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InterviewCubit>();
    final jobController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final mode = useState(initialMode);
    final interviewType = useState(InterviewOptions.types.first);
    final difficulty = useState('medium');
    final language = useState(
      Localizations.localeOf(context).languageCode == 'ar'
          ? 'Arabic'
          : 'English',
    );
    final questionCount = useState(InterviewOptions.defaultQuestions);
    final selectedTitle = useState<String?>(null);
    final manualOverride = useState(false);
    useListenable(jobController);
    useListenable(descriptionController);

    useEffect(() {
      cubit.loadCv();
      cubit.preloadAd();
      return null;
    }, [cubit]);

    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: BlocListener<InterviewCubit, InterviewState>(
        listenWhen: (previous, current) =>
            previous.phase == InterviewPhase.starting &&
            current.phase == InterviewPhase.inProgress,
        listener: (context, state) {
          if (!context.mounted) return;
          final route = ModalRoute.of(context);
          if (route != null && !route.isCurrent) return;
          Navigator.pushNamed(
            context,
            RoutesName.simulationQuestion,
            arguments: context.read<InterviewCubit>(),
          );
        },
        child: BlocBuilder<InterviewCubit, InterviewState>(
          builder: (context, state) {
            final byJob = mode.value == InterviewStartMode.byJob;
            final titles = state.cvJobTitles;
            final chosenTitle = titles.contains(selectedTitle.value)
                ? selectedTitle.value!
                : (titles.isEmpty ? '' : titles.first);
            final useCvTitle =
                byJob && titles.isNotEmpty && !manualOverride.value;
            final roleText = useCvTitle ? chosenTitle : jobController.text;
            final input = collapseInterviewWhitespace(
              byJob ? roleText : descriptionController.text,
            );
            final minLength = byJob
                ? InterviewOptions.minJobFieldLength
                : InterviewOptions.minJobDescriptionLength;
            final maxLength = byJob
                ? InterviewOptions.maxJobFieldLength
                : InterviewOptions.maxJobDescriptionLength;
            final valid =
                input.length >= minLength && input.length <= maxLength;
            final showInvalid = input.isNotEmpty && !valid;
            final starting = state.phase == InterviewPhase.starting;
            final showEmptyTitles = byJob &&
                !useCvTitle &&
                state.cvChecked &&
                state.cvLoadFailure == null &&
                state.cvId != null &&
                titles.isEmpty;
            return Scaffold(
              backgroundColor: AppColors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    InterviewTopBar(
                      title:
                          AppLocalizations.tr(context, 'interview_setup_title'),
                      onBack: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          InterviewChoiceGroup(
                            label: AppLocalizations.tr(
                              context,
                              'interview_mode_label',
                            ),
                            options: [
                              InterviewChoice(
                                InterviewStartMode.byJob.name,
                                AppLocalizations.tr(
                                    context, 'interview_mode_job'),
                              ),
                              InterviewChoice(
                                InterviewStartMode.byJobDescription.name,
                                AppLocalizations.tr(
                                  context,
                                  'interview_mode_description',
                                ),
                              ),
                            ],
                            selected: mode.value.name,
                            onSelected: (value) {
                              mode.value =
                                  value == InterviewStartMode.byJob.name
                                      ? InterviewStartMode.byJob
                                      : InterviewStartMode.byJobDescription;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.tr(
                              context,
                              !byJob
                                  ? 'interview_job_description_label'
                                  : useCvTitle
                                      ? (titles.length == 1
                                          ? 'interview_cv_job_title_label'
                                          : 'interview_cv_job_title_select')
                                      : 'interview_job_field_label',
                            ),
                            style: AppTypography.regular(
                              fontSize: 14,
                              color: AppColors.fontColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!byJob)
                            TextField(
                              key: const Key('interview_description_input'),
                              controller: descriptionController,
                              minLines: 4,
                              maxLines: 8,
                              maxLength: maxLength,
                              textAlign: TextAlign.start,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.tr(
                                  context,
                                  'interview_job_description_hint',
                                ),
                                errorText: showInvalid
                                    ? AppLocalizations.tr(
                                        context,
                                        input.length < minLength
                                            ? 'interview_description_short'
                                            : 'interview_description_long',
                                      )
                                    : null,
                              ),
                            )
                          else if (useCvTitle && titles.length == 1)
                            _SelectedJobTitle(title: chosenTitle)
                          else if (useCvTitle)
                            _JobTitleDropdown(
                              titles: titles,
                              selected: chosenTitle,
                              enabled: !starting,
                              onSelected: (value) =>
                                  selectedTitle.value = value,
                            )
                          else ...[
                            if (showEmptyTitles) ...[
                              Text(
                                key: const Key('interview_cv_job_titles_empty'),
                                AppLocalizations.tr(
                                  context,
                                  'interview_cv_job_titles_empty',
                                ),
                                style: AppTypography.regular(
                                  fontSize: 13,
                                  color: AppColors.hintColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            TextField(
                              key: const Key('interview_job_input'),
                              controller: jobController,
                              minLines: 1,
                              maxLines: 3,
                              maxLength: maxLength,
                              textAlign: TextAlign.start,
                              onChanged: (_) => manualOverride.value = true,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.tr(
                                  context,
                                  'interview_job_field_hint',
                                ),
                                errorText: showInvalid
                                    ? AppLocalizations.tr(
                                        context,
                                        'interview_job_field_invalid',
                                      )
                                    : null,
                              ),
                            ),
                          ],
                          if (byJob && useCvTitle)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const Key('interview_cv_job_title_other'),
                                onPressed: starting
                                    ? null
                                    : () => manualOverride.value = true,
                                child: Text(
                                  AppLocalizations.tr(
                                    context,
                                    'interview_cv_job_title_other',
                                  ),
                                ),
                              ),
                            )
                          else if (byJob && titles.isNotEmpty)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key:
                                    const Key('interview_cv_job_title_from_cv'),
                                onPressed: starting
                                    ? null
                                    : () => manualOverride.value = false,
                                child: Text(
                                  AppLocalizations.tr(
                                    context,
                                    'interview_cv_job_title_label',
                                  ),
                                ),
                              ),
                            ),
                          if (useCvTitle && showInvalid)
                            Text(
                              AppLocalizations.tr(
                                context,
                                'interview_job_field_invalid',
                              ),
                              style: AppTypography.regular(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          const SizedBox(height: 8),
                          InterviewChoiceGroup(
                            label: AppLocalizations.tr(
                              context,
                              'interview_type_label',
                            ),
                            selected: interviewType.value,
                            onSelected: (value) => interviewType.value = value,
                            options: [
                              for (final type in InterviewOptions.types)
                                InterviewChoice(
                                  type,
                                  AppLocalizations.tr(
                                    context,
                                    'interview_type_$type',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InterviewChoiceGroup(
                            label: AppLocalizations.tr(
                              context,
                              'interview_difficulty_label',
                            ),
                            selected: difficulty.value,
                            onSelected: (value) => difficulty.value = value,
                            options: [
                              for (final level in InterviewOptions.difficulties)
                                InterviewChoice(
                                  level,
                                  AppLocalizations.tr(
                                    context,
                                    'interview_difficulty_$level',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InterviewChoiceGroup(
                            label: AppLocalizations.tr(
                              context,
                              'interview_language_label',
                            ),
                            selected: language.value,
                            onSelected: (value) => language.value = value,
                            options: [
                              InterviewChoice(
                                'English',
                                AppLocalizations.tr(
                                    context, 'language_english'),
                              ),
                              InterviewChoice(
                                'Arabic',
                                AppLocalizations.tr(context, 'language_arabic'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.tr(
                                context, 'interview_count_label'),
                            style: AppTypography.regular(
                              fontSize: 14,
                              color: AppColors.fontColor,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                key: const Key('interview_count_minus'),
                                onPressed: questionCount.value >
                                        InterviewOptions.minQuestions
                                    ? () => questionCount.value -= 1
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Text(
                                '${questionCount.value}',
                                key: const Key('interview_count_value'),
                                style: AppTypography.bold(
                                  fontSize: 18,
                                  color: AppColors.fontColor,
                                ),
                              ),
                              IconButton(
                                key: const Key('interview_count_plus'),
                                onPressed: questionCount.value <
                                        InterviewOptions.maxQuestions
                                    ? () => questionCount.value += 1
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          if (!state.cvChecked)
                            Text(
                              AppLocalizations.tr(
                                context,
                                'interview_cv_checking',
                              ),
                              style: AppTypography.regular(
                                fontSize: 13,
                                color: AppColors.hintColor,
                              ),
                            )
                          else if (state.cvId != null)
                            Text(
                              key: const Key('interview_cv_used'),
                              AppLocalizations.tr(context, 'interview_cv_used'),
                              style: AppTypography.regular(
                                fontSize: 13,
                                color: AppColors.fontColor,
                              ),
                            ),
                          if (state.cvLoadFailure != null) ...[
                            const SizedBox(height: 12),
                            InterviewErrorBanner(
                              messageKey:
                                  const Key('interview_cv_titles_error'),
                              actionKey: const Key('interview_cv_retry'),
                              message: AppLocalizations.tr(
                                context,
                                'interview_cv_job_titles_error',
                              ),
                              actionLabel: AppLocalizations.tr(
                                context,
                                'interview_retry',
                              ),
                              onAction: starting ? null : cubit.retryLoadCv,
                            ),
                          ],
                          if (state.phase == InterviewPhase.startFailed &&
                              state.error != null) ...[
                            const SizedBox(height: 12),
                            InterviewErrorBanner(
                              message:
                                  interviewErrorText(context, state.error!),
                              actionLabel: AppLocalizations.tr(
                                context,
                                state.failedSimulationId == null
                                    ? 'interview_start_again'
                                    : 'interview_retry',
                              ),
                              onAction: starting
                                  ? null
                                  : () {
                                      if (state.failedSimulationId == null) {
                                        cubit.start(
                                          mode: mode.value,
                                          input: byJob
                                              ? roleText
                                              : descriptionController.text,
                                          interviewType: interviewType.value,
                                          difficulty: difficulty.value,
                                          language: language.value,
                                          numQuestions: questionCount.value,
                                        );
                                      } else {
                                        cubit.retryStart();
                                      }
                                    },
                            ),
                          ],
                          const SizedBox(height: 16),
                          InterviewActionButton(
                            key: const Key('interview_start_button'),
                            label: AppLocalizations.tr(
                              context,
                              starting
                                  ? 'interview_starting'
                                  : 'interview_start',
                            ),
                            busy: starting,
                            onPressed: !valid || !state.cvChecked || starting
                                ? null
                                : () => cubit.start(
                                      mode: mode.value,
                                      input: byJob
                                          ? roleText
                                          : descriptionController.text,
                                      interviewType: interviewType.value,
                                      difficulty: difficulty.value,
                                      language: language.value,
                                      numQuestions: questionCount.value,
                                    ),
                          ),
                          const SizedBox(height: 24),
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
}

class _SelectedJobTitle extends StatelessWidget {
  const _SelectedJobTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(),
      child: Text(
        title,
        key: const Key('interview_cv_job_title'),
        textAlign: TextAlign.start,
        style: AppTypography.regular(
          fontSize: 14,
          color: AppColors.fontColor,
        ),
      ),
    );
  }
}

class _JobTitleDropdown extends StatelessWidget {
  const _JobTitleDropdown({
    required this.titles,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> titles;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const Key('interview_cv_job_title_dropdown'),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(),
      items: [
        for (final title in titles)
          DropdownMenuItem<String>(
            value: title,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ),
      ],
      onChanged: enabled
          ? (value) {
              if (value != null) onSelected(value);
            }
          : null,
    );
  }
}
