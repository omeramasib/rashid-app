import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/core/widgets/app_back_button.dart';
import 'package:rashed_app/features/cv/domain/cv_file_rules.dart';
import 'package:rashed_app/features/cv/domain/entities/selected_cv_file.dart';
import 'package:rashed_app/features/cv/presentation/cubit/cv_cubit.dart';

enum _CvView { upload, processing, results, recorded, success }

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  bool _showSuccess = false;
  bool _picking = false;
  bool _unreadable = false;
  String _fullName = '';
  List<String> _titles = const [];
  List<String> _skills = const [];
  String? _appliedCvId;
  final TextEditingController _newSkillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CvCubit>().load();
  }

  @override
  void dispose() {
    _newSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CvCubit, CvState>(
      listener: _onState,
      builder: (context, state) {
        final phase = _phase(state);
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, phase),
                if (phase != _CvView.success && phase != _CvView.recorded)
                  _buildStepper(context, phase),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildBody(context, state, phase),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onState(BuildContext context, CvState state) {
    if (state is CvSessionExpired) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.login,
        (route) => false,
      );
      return;
    }
    if (state is CvAnalyzed && _appliedCvId != state.cvId) {
      _appliedCvId = state.cvId;
      _fullName = state.result.fullName;
      _titles = List<String>.of(state.result.jobTitles);
      _skills = List<String>.of(state.result.skills);
    }
    if (state is SkillsUpdated) {
      _showSuccess = true;
    } else if (state is CvUploading || state is CvFileSelected) {
      _showSuccess = false;
    }
  }

  _CvView _phase(CvState state) {
    if (_showSuccess) return _CvView.success;
    if (state is CvUploading ||
        state is CvSavingUpload ||
        state is CvAnalyzing) {
      return _CvView.processing;
    }
    if (state is CvAnalysisRecorded) return _CvView.recorded;
    if (state is CvAnalyzed ||
        ((state is SkillsUpdating || state is CvError) &&
            _appliedCvId != null)) {
      return _CvView.results;
    }
    return _CvView.upload;
  }

  Widget _buildBody(BuildContext context, CvState state, _CvView phase) {
    switch (phase) {
      case _CvView.processing:
        return _buildProcessing(context, state);
      case _CvView.results:
        return _buildResultStep(context, state);
      case _CvView.recorded:
        return _buildRecorded(context);
      case _CvView.success:
        return _buildSuccessStep(context);
      case _CvView.upload:
        return _buildUploadStep(context, state);
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

  Widget _buildStepper(BuildContext context, _CvView phase) {
    final active = phase == _CvView.processing
        ? 1
        : phase == _CvView.results
            ? 2
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

  Widget _buildUploadStep(BuildContext context, CvState state) {
    final cubit = context.read<CvCubit>();
    final selected = state is CvFileSelected ? state.file : null;
    final canStart = selected != null || state is CvUploadSaved;
    return _stepShell(
      topText: state is CvUploadSaved
          ? _t(context, 'cv_ready_existing')
          : _t(context, 'cv_intro'),
      subtitle: _t(context, 'cv_pdf_only'),
      footer: Column(
        children: [
          if (_messageFor(context, state) != null) ...[
            Text(
              _messageFor(context, state)!,
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
            onTap: _picking ? null : () => _pickFile(context),
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
                        : '${selected.name} · ${_formatSize(selected.sizeBytes)}',
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
          if (state is CvAwaitingPersistence)
            _primaryCta(
              key: const Key('cv_retry_persistence'),
              text: _t(context, 'cv_retry_save'),
              onTap: cubit.retryPersistence,
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

  Widget _buildResultStep(BuildContext context, CvState state) {
    final name = _fullName.trim().isEmpty ? _t(context, 'cv_none') : _fullName;
    final titles = _titles.where((title) => title.trim().isNotEmpty).toList();
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
          if (state is CvAnalyzed && !state.statusPersisted) ...[
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
                    for (final skill in _skills)
                      _skillChip(skill, constraints.maxWidth),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 26,
                color: AppColors.primarySet2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('cv_new_skill'),
                  controller: _newSkillController,
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _t(context, 'cv_add_skill'),
                    hintStyle: AppTypography.regular(
                      fontSize: 14,
                      color: AppColors.hintColor,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || _skills.contains(trimmed)) return;
                    setState(() {
                      _skills = [..._skills, trimmed];
                      _newSkillController.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          if (state is CvError) ...[
            const SizedBox(height: 8),
            Text(
              state.message,
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
            onTap: state is SkillsUpdating
                ? null
                : () => context.read<CvCubit>().updateSkills(List.of(_skills)),
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
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesName.home,
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final cubit = context.read<CvCubit>();
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (!mounted) return;
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _unreadable = true);
        return;
      }
      setState(() => _unreadable = false);
      await cubit.selectFile(
        SelectedCvFile(
          name: file.name,
          sizeBytes: file.size,
          bytes: bytes,
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _messageFor(BuildContext context, CvState state) {
    if (_unreadable) return _t(context, 'cv_file_unreadable');
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
          : state.message;
    }
    if (state is CvAnalysisFailed) {
      switch (state.stop) {
        case CvAnalysisStop.clientCancelled:
          return _t(context, 'cv_analysis_cancelled');
        case CvAnalysisStop.timedOut:
          return _t(context, 'cv_analysis_timeout');
        case CvAnalysisStop.failed:
          return state.message.isEmpty
              ? _t(context, 'cv_analysis_failed')
              : state.message;
      }
    }
    if (state is CvAwaitingPersistence) {
      return state.missingUser
          ? _t(context, 'cv_missing_user')
          : _t(context, 'cv_persistence_pending');
    }
    if (state is CvStorageReadFailed) return state.message;
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

  Widget _skillChip(String skill, double maxWidth) {
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
                  onTap: () => setState(() => _skills.remove(skill)),
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

  String _t(BuildContext context, String key) {
    final value = AppLocalizations.of(context)?.translate(key) ?? '';
    return value.isEmpty ? key : value;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
