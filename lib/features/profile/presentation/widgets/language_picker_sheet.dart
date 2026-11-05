import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/localization/localization_bloc.dart';
import 'package:rashed_app/core/localization/localization_event.dart';
import 'package:rashed_app/core/theme/theme.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final selected =
        context.read<LocalizationBloc>().state.locale.languageCode;
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.tr(context, 'language'),
                textAlign: TextAlign.center,
                style: AppTypography.bold(
                  fontSize: 18,
                  color: AppColors.fontColor,
                ),
              ),
              const SizedBox(height: 12),
              _option(
                context,
                code: 'ar',
                label: AppLocalizations.tr(context, 'language_arabic'),
                selected: selected == 'ar',
              ),
              _option(
                context,
                code: 'en',
                label: AppLocalizations.tr(context, 'language_english'),
                selected: selected == 'en',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String code,
    required String label,
    required bool selected,
  }) {
    return ListTile(
      key: Key('language_$code'),
      title: Text(
        label,
        style: AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primarySet2)
          : null,
      onTap: () {
        final bloc = context.read<LocalizationBloc>();
        Navigator.pop(context);
        bloc.add(ChangeLanguage(Locale(code)));
      },
    );
  }
}
