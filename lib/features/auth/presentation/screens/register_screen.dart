import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rashed_app/Presentation/utils/custom_snackbars.dart';
import 'package:rashed_app/Presentation/utils/validations.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/theme/theme.dart';

import '../cubit/register/register_cubit.dart';
import '../linkedin_email_conflict_notice.dart';
import '../widgets/auth_form_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameTextEditingController =
      TextEditingController();
  final TextEditingController _emailTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController();

  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameTextEditingController.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  void register() {
    final isValid = registerFormKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    registerFormKey.currentState!.save();
    context.read<RegisterCubit>().registerWithEmail(
          name: _nameTextEditingController.text.trim(),
          email: _emailTextEditingController.text.trim(),
          password: _passwordTextEditingController.text.trim(),
        );
  }

  void registerWithLinkedIn() {
    context.read<RegisterCubit>().registerWithLinkedIn(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: BlocConsumer<RegisterCubit, RegisterState>(
            listener: (context, state) {
              if (state is RegisterSuccess) {
                CustomSnackBars.sucssesSnackBar(
                  context: context,
                  message: strings.translate('register_successfully'),
                );
                Navigator.pushReplacementNamed(
                  context,
                  RoutesName.linkedinImport,
                );
              } else if (state is RegisterFailure && !state.offerEmailSignIn) {
                CustomSnackBars.errorSnackBar(
                  context: context,
                  message: AppLocalizations.message(
                    context,
                    state.message,
                  ),
                );
              }
            },
            builder: (context, state) {
              final passwordVisible =
                  state is ViewPasswordState && state.enabled;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 24),
                child: Form(
                  key: registerFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthScreenHeader(
                        title: strings.translate('register'),
                      ),
                      const AuthWelcomeBanner(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AuthFormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthTextField(
                                controller: _nameTextEditingController,
                                hint: strings.translate('full_name'),
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: (value) =>
                                    Validations.textValidation(value!, context),
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _emailTextEditingController,
                                hint: strings.translate('email'),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: (value) =>
                                    Validations.validateEmail(value!, context),
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _passwordTextEditingController,
                                hint: strings.translate('password'),
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                obscureText: !passwordVisible,
                                validator: (value) =>
                                    Validations.validatePassword(
                                        value!, context),
                                suffix: AuthPasswordVisibilityButton(
                                  visible: passwordVisible,
                                  onPressed: () {
                                    context
                                        .read<RegisterCubit>()
                                        .viewPassword();
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (state is RegisterLoading)
                                const AuthButtonProgress()
                              else
                                AuthPrimaryButton(
                                  text: strings.translate('sign_up'),
                                  onPressed: register,
                                ),
                              const SizedBox(height: 32),
                              AuthOrDivider(label: strings.translate('or')),
                              const SizedBox(height: 16),
                              if (state is RegisterLinkedInLoading)
                                const AuthButtonProgress()
                              else
                                AuthLinkedInButton(
                                  label: strings
                                      .translate('linkedin_import_button'),
                                  onPressed: registerWithLinkedIn,
                                ),
                              if (state is RegisterFailure &&
                                  state.offerEmailSignIn) ...[
                                const SizedBox(height: 12),
                                LinkedInEmailConflictNotice(
                                  onSignInWithEmail: () {
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.login,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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
