import 'package:flutter/material.dart';

import '../../../../app_localizations.dart';
import '../../../../core/localization/app_text_direction.dart';
import '../../../../core/theme/theme.dart';

class InterviewTopBar extends StatelessWidget {
  const InterviewTopBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final rtl = AppTextDirection.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: AppLocalizations.tr(context, 'previous'),
            child: GestureDetector(
              key: const Key('interview_back_button'),
              onTap: onBack,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  key: const Key('interview_back_icon'),
                   Icons.chevron_left,
                  size: 30,
                  color: AppColors.black100,
                ),
              ),
            ),
          ),
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class InterviewProgressBar extends StatelessWidget {
  const InterviewProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final fraction = total <= 0 ? 0.0 : (current / safeTotal).clamp(0.0, 1.0);
    return Column(
      key: const Key('interview_progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            AppLocalizations.tr(context, 'progress_of', {
              'current': '$current',
              'total': '$total',
            }),
            style: AppTypography.regular(
              fontSize: 12,
              color: AppColors.fontColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InterviewActionButton extends StatelessWidget {
  const InterviewActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool primary;

  bool get enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: primary && enabled ? AppColors.primaryGradient : null,
            color: !primary
                ? AppColors.white
                : enabled
                    ? null
                    : AppColors.black20,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  label,
                  style: primary
                      ? AppTypography.bold(
                          fontSize: 16,
                          color: AppColors.white,
                        )
                      : AppTypography.regular(
                          fontSize: 16,
                          color: AppColors.fontColor,
                        ),
                ),
        ),
      ),
    );
  }
}

class InterviewChoiceGroup extends StatelessWidget {
  const InterviewChoiceGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<InterviewChoice> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTypography.regular(fontSize: 14, color: AppColors.fontColor),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.label),
                selected: option.value == selected,
                onSelected: (_) => onSelected(option.value),
                selectedColor: AppColors.primary,
                labelStyle: AppTypography.regular(
                  fontSize: 13,
                  color: option.value == selected
                      ? AppColors.white
                      : AppColors.fontColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class InterviewChoice {
  const InterviewChoice(this.value, this.label);

  final String value;
  final String label;
}

class InterviewErrorBanner extends StatelessWidget {
  const InterviewErrorBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.messageKey = const Key('interview_error_message'),
    this.actionKey = const Key('interview_error_action'),
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key messageKey;
  final Key actionKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            key: messageKey,
            style: AppTypography.regular(fontSize: 13, color: AppColors.error),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              key: actionKey,
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
