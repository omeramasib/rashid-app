import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../Presentation/utils/images.dart';
import '../../../../app_localizations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_back_button.dart';

class AuthScreenHeader extends StatelessWidget {
  const AuthScreenHeader({
    super.key,
    required this.title,
    this.fontSize = 18,
  });

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.regular(
                fontSize: fontSize,
                color: AppColors.navyTitle,
                height: 1.4,
              ),
            ),
          ),
          if (canPop)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppBackButton(),
            ),
        ],
      ),
    );
  }
}

class AuthWelcomeBanner extends StatelessWidget {
  const AuthWelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AspectRatio(
        aspectRatio: 360 / 167,
        child: Image.asset(
          ImageManages.authWelcomeBanner,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bodyBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
        child: child,
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      style: AppTypography.regular(
        fontSize: 14,
        color: AppColors.fontColor,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffix,
        border: _border(BorderSide.none),
        enabledBorder: _border(BorderSide.none),
        focusedBorder: _border(
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: _border(const BorderSide(color: AppColors.error)),
        focusedErrorBorder: _border(
          const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  OutlineInputBorder _border(BorderSide side) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: side,
    );
  }
}

class AuthPasswordVisibilityButton extends StatelessWidget {
  const AuthPasswordVisibilityButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.translate(
      visible ? 'hide_password' : 'show_password',
    );
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: SvgPicture.asset(ImageManages.authEye),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTypography.bold(
                    fontSize: 16,
                    color: AppColors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthLinkedInButton extends StatelessWidget {
  const AuthLinkedInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool enabled;

  static const LinearGradient filledGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3D83FF), Color(0xFF236DDF)],
  );

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.white : AppColors.fontColor;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled ? null : AppColors.white,
          gradient: filled ? filledGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(ImageManages.authLinkedIn),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.regular(
                          fontSize: 16,
                          color: foreground,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.black20, thickness: 1, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: AppTypography.regular(
              fontSize: 18,
              color: AppColors.fontColor,
              height: 1.4,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.black20, thickness: 1, height: 1),
        ),
      ],
    );
  }
}

class AuthCreateAccountLink extends StatelessWidget {
  const AuthCreateAccountLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          strings.translate('do_not_have_account'),
          textAlign: TextAlign.center,
          style: AppTypography.regular(
            fontSize: 14,
            color: AppColors.hintColor,
            height: 1.5,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3D83FF),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(48, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return AuthLinkedInButton.filledGradient.createShader(bounds);
            },
            child: Text(
              strings.translate('register'),
              style: AppTypography.regular(
                fontSize: 14,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthConsentCheckbox extends StatelessWidget {
  const AuthConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(ImageManages.authCheckboxBox),
                  if (value) SvgPicture.asset(ImageManages.authCheckboxCheck),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthButtonProgress extends StatelessWidget {
  const AuthButtonProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
