import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rashed_app/Presentation/utils/images.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/features/auth/presentation/widgets/auth_form_widgets.dart';

class LinkedinImportScreen extends HookWidget {
  const LinkedinImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agreed = useState(false);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final illustrationHeight =
        math.min(449.0, math.max(240.0, screenHeight * 0.48));
    final consent = AppLocalizations.tr(context, 'linkedin_import_consent');

    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        AuthScreenHeader(
                          title: AppLocalizations.tr(
                            context,
                            'linkedin_import_title',
                          ),
                          fontSize: 20,
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          image: true,
                          label: AppLocalizations.tr(
                            context,
                            'linkedin_import_greeting',
                          ),
                          child: Image.asset(
                            ImageManages.linkedinImportIllustration,
                            height: illustrationHeight,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        MergeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.bodyBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      consent,
                                      textAlign: TextAlign.start,
                                      style: AppTypography.regular(
                                        fontSize: 14,
                                        color: AppColors.navyTitle,
                                        height: 1.7,
                                      ),
                                    ),
                                  ),
                                  AuthConsentCheckbox(
                                    value: agreed.value,
                                    onChanged: (value) => agreed.value = value,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AuthLinkedInButton(
                          label: AppLocalizations.tr(
                            context,
                            'linkedin_import_button',
                          ),
                          filled: true,
                          enabled: agreed.value,
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              RoutesName.completeProfile,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
