import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/core/widgets/app_back_button.dart';
import 'package:rashed_app/features/cv/domain/cv_file_rules.dart';
import 'package:rashed_app/features/cv/domain/entities/selected_cv_file.dart';
import 'package:rashed_app/features/cv/presentation/cubit/cv_cubit.dart';
import 'package:rashed_app/features/simulation/domain/interview_options.dart';
import 'package:rashed_app/features/simulation/presentation/interview_navigation.dart';

enum _CvView {
  upload,
  processing,
  results,
  recorded,
  success,
  loading,
  loadFailed,
  inProgress,
}

class CompleteProfileScreen extends HookWidget {
  const CompleteProfileScreen({super.key, this.resumeInterview});

  /// Set when interview simulation sent the user here to finish a CV.
  final InterviewStartMode? resumeInterview;

  @override
  Widget build(BuildContext context) {
    final newSkill = useTextEditingController();
    final picking = useState(false);
    final unreadable = useState(false);
    final cubit = context.read<CvCubit>();
    final resumed = useRef(false);
    useEffect(() {
      cubit.load();
      return null;
    }, const []);

    return BlocConsumer<CvCubit, CvState>(
      listener: (context, state) {
        if (!context.mounted || resumed.value) return;
        if (state is CvSessionExpired) {
          resumed.value = true;
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.login,
            (route) => false,
          );
          return;
        }
        final mode = resumeInterview;
        if (mode == null || state is! CvAnalyzed || !state.profileConfirmed) {
          return;
        }
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        resumed.value = true;
        Navigator.pushReplacementNamed(
          context,
          RoutesName.simulationSetup,
          arguments: InterviewStartMode.byJob,
        );
      },
      builder: (context, state) {
        final phase = _phase(state);
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, phase),
                if (phase != _CvView.success && phase != _CvView.recorded)
                  _buildStepper(context, state, phase),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildBody(
                      context,
                      state,
                      phase,
                      picking: picking,
                      unreadable: unreadable,
                      newSkill: newSkill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitNewSkill(
    BuildContext context,
    TextEditingController input,
  ) async {
    final saved = await context.read<CvCubit>().addSkill(input.text);
    if (!context.mounted || !saved) return;
    input.clear();
  }

  String _skillFailureText(BuildContext context, CvError state) {
    final failure = state.failure;
    if (failure is RequestTimeoutFailure) {
      return _t(context, 'cv_profile_timeout');
    }
    if (failure is NetworkFailure) return _t(context, 'cv_profile_offline');
    return _t(context, 'cv_skills_save_failed');
  }

  _CvView _phase(CvState state) {
    if (state is SkillsUpdated) return _CvView.success;
    if (state is CvProfileLoading) return _CvView.loading;
    if (state is CvProfileLoadFailed) return _CvView.loadFailed;
    if (state is CvAnalysisInProgress) return _CvView.inProgress;
    if (state is CvUploading ||
        state is CvSavingUpload ||
        state is CvAnalyzing) {
      return _CvView.processing;
    }
    if (state is CvAnalysisRecorded) return _CvView.recorded;
    if (_profileResults(state) != null) return _CvView.results;
    return _CvView.upload;
  }

  bool _skillInputEnabled(CvState state) {
    return state is! SkillsUpdating && state is! SkillDeleting;
  }

  Widget _buildBody(
    BuildContext context,
    CvState state,
    _CvView phase, {
    required ValueNotifier<bool> picking,
    required ValueNotifier<bool> unreadable,
    required TextEditingController newSkill,
  }) {
    switch (phase) {
      case _CvView.loading:
        return _buildLoading(context);
      case _CvView.loadFailed:
        return _buildLoadFailed(context, state);
      case _CvView.inProgress:
        return _buildInProgress(context);
      case _CvView.processing:
        return _buildProcessing(context, state);
      case _CvView.results:
        return _buildResultStep(context, state, newSkill);
      case _CvView.recorded:
        return _buildRecorded(context);
      case _CvView.success:
        return _buildSuccessStep(context);
      case _CvView.upload:
        return _buildUploadStep(context, state, picking, unreadable);
    }
  }

  Widget _buildTopBar(BuildContext context, _CvView phase) {
    final title = phase == _CvView.results || phase == _CvView.success
        ? _t(context, 'cv_result_title')
        : _t(context, 'cv_title');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  title,
                  style: AppTypography.regular(
                    fontSize: 20,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepper(BuildContext context, CvState state, _CvView phase) {
    final waiting = state is CvPendingAnalysis ||
        state is CvUploadSaved ||
        state is CvAnalysisFailed;
    final active = phase == _CvView.processing || phase == _CvView.inProgress
        ? 1
        : phase == _CvView.results
            ? 2
            : waiting
                ? 1
                : 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stepChip(
              text: _t(context, 'cv_step_upload'),
              isActive: active == 0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _stepChip(
              text: _t(context, 'cv_step_analyze'),
              isActive: active == 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _stepChip(
              text: _t(context, 'cv_step_result'),
              isActive: active == 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepChip({required String text, required bool isActive}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.regular(
          fontSize: 13,
          color: isActive ? AppColors.white : AppColors.hintColor,
        ),
      ),
    );
  }

  Widget _buildUploadStep(
    BuildContext context,
    CvState state,
    ValueNotifier<bool> picking,
    ValueNotifier<bool> unreadable,
  ) {
    final cubit = context.read<CvCubit>();
    final selected = state is CvFileSelected ? state.file : null;
    final canStart = selected != null ||
        state is CvUploadSaved ||
        state is CvPendingAnalysis;
    final topText = state is CvPendingAnalysis
        ? _t(context, 'cv_pending')
        : state is CvUploadSaved
            ? _t(context, 'cv_ready_existing')
            : state is CvAnalysisFailed
                ? state.stop == CvAnalysisStop.timedOut
                    ? _t(context, 'cv_analysis_timeout')
                    : _t(context, 'cv_profile_failed')
                : state is CvReady
                    ? _t(context, 'cv_profile_empty')
                    : _t(context, 'cv_intro');
    return _stepShell(
      topText: topText,
      subtitle: state is CvReady
          ? _t(context, 'cv_intro')
          : _t(context, 'cv_pdf_only'),
      footer: Column(
        children: [
          if (_messageFor(context, state, unreadable.value) != null) ...[
            Text(
              _messageFor(context, state, unreadable.value)!,
              key: const Key('cv_status_message'),
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (state is CvUploadFailed && state.preserved != null) ...[
            Text(
              _t(context, 'cv_previous_kept'),
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.fontColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            key: const Key('cv_pick_file'),
            onTap: picking.value
                ? null
                : () => _pickFile(context, picking, unreadable),
            child: Container(
              width: double.infinity,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.black10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload,
                      size: 34, color: AppColors.hintColor),
                  const SizedBox(height: 6),
                  Text(
                    selected == null
                        ? _t(context, 'cv_pick')
                        : '${selected.name} · ${_formatSize(context, selected.sizeBytes)}',
                    key: const Key('cv_selected_file'),
                    textAlign: TextAlign.center,
                    style: AppTypography.regular(
                      fontSize: 13,
                      color: AppColors.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (state is CvReady) ...[
            Text(
              _t(context, 'cv_pdf_only'),
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.hintColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (state is CvAwaitingPersistence)
            _primaryCta(
              key: const Key('cv_retry_persistence'),
              text: _t(context, 'cv_retry_save'),
              onTap: cubit.retryPersistence,
            )
          else if (state is CvAnalysisFailed &&
              state.stop == CvAnalysisStop.timedOut)
            _primaryCta(
              key: const Key('cv_refresh_status'),
              text: _t(context, 'cv_refresh'),
              onTap: cubit.refreshProfile,
            )
          else if (state is CvAnalysisFailed)
            _primaryCta(
              key: const Key('cv_retry_analysis'),
              text: _t(context, 'cv_retry_analysis'),
              onTap: cubit.retryAnalysis,
            )
          else
            _primaryCta(
              key: const Key('cv_start_analysis'),
              text: _t(context, 'cv_start'),
              onTap: canStart ? cubit.startAnalysis : null,
            ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return _stepShell(
      topText: _t(context, 'cv_profile_loading'),
      subtitle: null,
      footer: const SizedBox(
        key: Key('cv_profile_loading'),
        width: 72,
        height: 72,
        child: CircularProgressIndicator(strokeWidth: 8),
      ),
    );
  }

  Widget _buildLoadFailed(BuildContext context, CvState state) {
    final failure = state is CvProfileLoadFailed ? state.failure : null;
    return _stepShell(
      topText: _t(context, 'cv_profile_load_failed'),
      subtitle: null,
      footer: Column(
        children: [
          Text(
            failure == null
                ? _t(context, 'cv_profile_load_failed')
                : _loadFailureText(context, failure),
            key: const Key('cv_status_message'),
            textAlign: TextAlign.center,
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 20),
          _primaryCta(
            key: const Key('cv_profile_retry'),
            text: _t(context, 'cv_profile_retry'),
            onTap: context.read<CvCubit>().load,
          ),
        ],
      ),
    );
  }

  Widget _buildInProgress(BuildContext context) {
    return _stepShell(
      topText: _t(context, 'cv_in_progress'),
      subtitle: null,
      footer: Column(
        children: [
          const SizedBox(
            key: Key('cv_in_progress'),
            width: 72,
            height: 72,
            child: CircularProgressIndicator(strokeWidth: 8),
          ),
          const SizedBox(height: 20),
          _primaryCta(
            key: const Key('cv_refresh_status'),
            text: _t(context, 'cv_refresh'),
            onTap: context.read<CvCubit>().refreshProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing(BuildContext context, CvState state) {
    final cubit = context.read<CvCubit>();
    final uploading = state is CvUploading;
    final progress = uploading && state.total > 0
        ? (state.sent / state.total).clamp(0, 1).toDouble()
        : null;
    final finishedSending =
        uploading && state.total > 0 && state.sent >= state.total;
    final label = state is CvSavingUpload
        ? _t(context, 'cv_saving')
        : state is CvAnalyzing
            ? _t(context, 'cv_analyzing')
            : finishedSending
                ? _t(context, 'cv_upload_finishing')
                : _t(context, 'cv_uploading');
    return _stepShell(
      topText: label,
      subtitle: _t(context, 'cv_cancel_note'),
      footer: Column(
        children: [
          if (uploading) ...[
            LinearProgressIndicator(
              key: const Key('cv_progress'),
              value: progress,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.black10,
            ),
            const SizedBox(height: 8),
            Text(
              progress == null ? '' : '${(progress * 100).round()}%',
              key: const Key('cv_progress_label'),
            ),
          ] else
            const SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(strokeWidth: 8),
            ),
          const SizedBox(height: 20),
          _primaryCta(
            key: const Key('cv_cancel'),
            text: _t(context, 'cv_cancel'),
            onTap: cubit.cancelActiveRequest,
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep(
    BuildContext context,
    CvState state,
    TextEditingController newSkill,
  ) {
    final profile = _profileResults(state)!;
    final name = profile.fullName.trim().isEmpty
        ? _t(context, 'cv_none')
        : profile.fullName;
    final titles =
        profile.jobTitles.where((title) => title.trim().isNotEmpty).toList();
    final skills = profile.skills;
    final canEditSkills = _skillInputEnabled(state);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state is! CvAnalyzed || profile.statusPersisted) ...[
            Text(
              _t(context, 'cv_profile_completed'),
              key: const Key('cv_profile_completed'),
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.fontColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (state is CvAnalyzed && !profile.statusPersisted) ...[
            Text(
              _t(context, 'cv_persistence_pending'),
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.fontColor,
              ),
            ),
            const SizedBox(height: 8),
            _primaryCta(
              key: const Key('cv_retry_persistence'),
              text: _t(context, 'cv_retry_save'),
              onTap: context.read<CvCubit>().retryPersistence,
            ),
            const SizedBox(height: 14),
          ],
          _label(_t(context, 'cv_name')),
          const SizedBox(height: 8),
          _valueBox(name, const Key('cv_full_name')),
          const SizedBox(height: 14),
          _label(_t(context, 'cv_job_title')),
          const SizedBox(height: 8),
          if (titles.isEmpty)
            _valueBox(_t(context, 'cv_none'), const Key('cv_job_titles'))
          else
            ...titles.map(
              (title) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _valueBox(title, Key('cv_job_title_$title')),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            _t(context, 'cv_skills_prompt'),
            style: AppTypography.regular(
              fontSize: 14,
              color: AppColors.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            key: const Key('cv_skills_box'),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in skills)
                      _skillChip(context, skill, constraints.maxWidth, state),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Semantics(
                button: true,
                label: _t(context, 'cv_add_skill'),
                child: GestureDetector(
                  key: const Key('cv_add_skill_button'),
                  onTap: canEditSkills
                      ? () => _submitNewSkill(context, newSkill)
                      : null,
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 26,
                    color: canEditSkills
                        ? AppColors.primarySet2
                        : AppColors.hintColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('cv_new_skill'),
                  controller: newSkill,
                  enabled: canEditSkills,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _t(context, 'cv_add_skill'),
                    hintStyle: AppTypography.regular(
                      fontSize: 14,
                      color: AppColors.hintColor,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: canEditSkills
                      ? (_) => _submitNewSkill(context, newSkill)
                      : null,
                ),
              ),
            ],
          ),
          if (profile.skillAdded && state is! CvError) ...[
            const SizedBox(height: 8),
            Text(
              _t(context, 'cv_skill_added'),
              key: const Key('cv_skill_added_message'),
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.success,
              ),
            ),
          ],
          if (profile.error != null) ...[
            const SizedBox(height: 8),
            Text(
              _skillFailureText(context, profile.error!),
              key: const Key('cv_status_message'),
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _primaryCta(
            key: const Key('cv_save_skills'),
            text: _t(context, 'cv_save'),
            onTap: canEditSkills
                ? () => context
                    .read<CvCubit>()
                    .updateSkills(List<String>.of(skills))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRecorded(BuildContext context) {
    return _stepShell(
      topText: _t(context, 'cv_completed_no_payload'),
      subtitle: null,
      footer: const SizedBox(height: 8),
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 28),
          _chatBubble(_t(context, 'cv_success'),
              width: double.infinity, fontSize: 18),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child:
                SvgPicture.asset(ImageManages.rashedImage, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          _primaryCta(
            text: _t(context, 'cv_start_simulation'),
            onTap: () => openInterviewSimulation(
              context,
              InterviewStartMode.byJob,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    ValueNotifier<bool> picking,
    ValueNotifier<bool> unreadable,
  ) async {
    final cubit = context.read<CvCubit>();
    picking.value = true;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (!context.mounted) return;
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        unreadable.value = true;
        return;
      }
      unreadable.value = false;
      await cubit.selectFile(
        SelectedCvFile(
          name: file.name,
          sizeBytes: file.size,
          bytes: bytes,
        ),
      );
    } finally {
      if (context.mounted) picking.value = false;
    }
  }

  String? _messageFor(BuildContext context, CvState state, bool unreadable) {
    if (unreadable) return _t(context, 'cv_file_unreadable');
    if (state is CvFileRejected) {
      switch (state.problem) {
        case CvFileProblem.empty:
          return _t(context, 'cv_file_empty');
        case CvFileProblem.extension:
          return _t(context, 'cv_file_extension');
        case CvFileProblem.tooLarge:
          return _t(context, 'cv_file_too_large');
        case CvFileProblem.notPdf:
          return _t(context, 'cv_file_not_pdf');
      }
    }
    if (state is CvUploadFailed) {
      if (state.cancelled) return _t(context, 'cv_upload_cancelled');
      return state.message.isEmpty
          ? _t(context, 'cv_upload_failed')
          : AppLocalizations.message(context, state.message);
    }
    if (state is CvAnalysisFailed) {
      switch (state.stop) {
        case CvAnalysisStop.clientCancelled:
          return _t(context, 'cv_analysis_cancelled');
        case CvAnalysisStop.timedOut:
          return null;
        case CvAnalysisStop.failed:
          return state.message.isEmpty
              ? null
              : AppLocalizations.message(context, state.message);
      }
    }
    if (state is CvAwaitingPersistence) {
      return state.missingUser
          ? _t(context, 'cv_missing_user')
          : _t(context, 'cv_persistence_pending');
    }
    if (state is CvStorageReadFailed) {
      return AppLocalizations.message(context, state.message);
    }
    return null;
  }

  Widget _stepShell({
    required String topText,
    required String? subtitle,
    required Widget footer,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _chatBubble(topText, width: 300, fontSize: 17),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child:
                SvgPicture.asset(ImageManages.rashedImage, fit: BoxFit.contain),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.regular(
                fontSize: 13,
                color: AppColors.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }

  Widget _chatBubble(String text,
      {required double width, required double fontSize}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.black10),
      ),
      child: Text(
        text,
        style: AppTypography.regular(
          fontSize: fontSize,
          color: AppColors.black100,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.regular(fontSize: 16, color: AppColors.black100),
    );
  }

  Widget _skillChip(
    BuildContext context,
    String skill,
    double maxWidth,
    CvState state,
  ) {
    return Container(
      key: Key('cv_skill_$skill'),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTypography.regular(
            fontSize: 14,
            color: AppColors.primarySet2,
            height: 1.4,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: GestureDetector(
                  key: Key('cv_remove_skill_$skill'),
                  onTap: _skillInputEnabled(state)
                      ? () => context.read<CvCubit>().omitSkill(skill)
                      : null,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.hintColor,
                  ),
                ),
              ),
            ),
            TextSpan(text: _softBreak(skill)),
          ],
        ),
      ),
    );
  }

  /// Gives long unbroken skill names a place to wrap without changing
  /// the value that is saved.
  String _softBreak(String value) {
    const limit = 16;
    final buffer = StringBuffer();
    var run = 0;
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(char);
      if (char.trim().isEmpty) {
        run = 0;
        continue;
      }
      run++;
      if (run >= limit) {
        buffer.write('\u200b');
        run = 0;
      }
    }
    return buffer.toString();
  }

  Widget _valueBox(String text, Key key) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.black10),
      ),
      child: Text(
        text,
        style:
            AppTypography.regular(fontSize: 17, color: AppColors.primarySet2),
      ),
    );
  }

  Widget _primaryCta({
    Key? key,
    required String text,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap == null ? null : AppColors.primaryGradient,
          color: onTap == null ? AppColors.black20 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTypography.bold(fontSize: 19, color: AppColors.white),
        ),
      ),
    );
  }

  String _loadFailureText(BuildContext context, Failure failure) {
    if (failure is RequestTimeoutFailure) {
      return _t(context, 'cv_profile_timeout');
    }
    if (failure is NetworkFailure) return _t(context, 'cv_profile_offline');
    if (failure.message.trim().isEmpty) {
      return _t(context, 'cv_profile_load_failed');
    }
    return AppLocalizations.message(context, failure.message);
  }

  String _t(BuildContext context, String key) {
    final value = AppLocalizations.of(context)?.translate(key) ?? '';
    return value.isEmpty ? key : value;
  }

  String _formatSize(BuildContext context, int bytes) {
    if (bytes < 1024) return '$bytes ${_t(context, 'size_b')}';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} ${_t(context, 'size_kb')}';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${_t(context, 'size_mb')}';
  }
}

class _ProfileResults {
  final String fullName;
  final List<String> jobTitles;
  final List<String> skills;
  final bool statusPersisted;
  final bool skillAdded;
  final CvError? error;

  const _ProfileResults({
    required this.fullName,
    required this.jobTitles,
    required this.skills,
    required this.statusPersisted,
    required this.skillAdded,
    this.error,
  });
}

_ProfileResults? _profileResults(CvState state) {
  if (state is CvAnalyzed) {
    return _ProfileResults(
      fullName: state.result.fullName,
      jobTitles: state.result.jobTitles,
      skills: state.skills,
      statusPersisted: state.statusPersisted,
      skillAdded: state.skillAdded,
    );
  }
  if (state is SkillsUpdating && state.cvId != null && state.result != null) {
    return _ProfileResults(
      fullName: state.result!.fullName,
      jobTitles: state.result!.jobTitles,
      skills: state.skills,
      statusPersisted: state.statusPersisted,
      skillAdded: false,
    );
  }
  if (state is SkillDeleting && state.cvId != null && state.result != null) {
    return _ProfileResults(
      fullName: state.result!.fullName,
      jobTitles: state.result!.jobTitles,
      skills: state.skills,
      statusPersisted: state.statusPersisted,
      skillAdded: false,
    );
  }
  if (state is CvError && state.cvId != null && state.result != null) {
    return _ProfileResults(
      fullName: state.result!.fullName,
      jobTitles: state.result!.jobTitles,
      skills: state.skills,
      statusPersisted: state.statusPersisted,
      skillAdded: false,
      error: state,
    );
  }
  return null;
}
