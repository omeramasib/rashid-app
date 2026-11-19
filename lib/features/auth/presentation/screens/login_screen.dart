import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rashed_app/Presentation/utils/custom_snackbars.dart';
import 'package:rashed_app/Presentation/utils/validations.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/localization/app_text_direction.dart';
import 'package:rashed_app/core/theme/theme.dart';

import '../cubit/login/login_cubit.dart';
import '../linkedin_email_conflict_notice.dart';
import '../widgets/auth_form_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: BlocConsumer<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccess) {
                CustomSnackBars.sucssesSnackBar(
                  context: context,
                  message: localizations.translate('login_successfully'),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RoutesName.home,
                  (route) => false,
                );
              } else if (state is LoginFailure && !state.offerEmailSignIn) {
                CustomSnackBars.errorSnackBar(
                  context: context,
                  message: AppLocalizations.message(context, state.message),
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<LoginCubit>();
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthScreenHeader(
                        title: localizations.translate('login'),
                      ),
                      const AuthWelcomeBanner(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AuthFormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthTextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                hint: localizations.translate('email'),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: (value) =>
                                    Validations.validateEmail(value!, context),
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _passwordController,
                                hint: localizations.translate('password'),
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                obscureText: !cubit.isPasswordVisible,
                                validator: (value) =>
                                    Validations.validatePassword(
                                        value!, context),
                                suffix: AuthPasswordVisibilityButton(
                                  visible: cubit.isPasswordVisible,
                                  onPressed: cubit.viewPassword,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.forgotPassword,
                                      arguments: _emailController.text.trim(),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primarySet2,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(48, 40),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    alignment: AlignmentDirectional.centerStart,
                                  ),
                                  child: Text(
                                    localizations.translate('forgot_password'),
                                    style: AppTypography.regular(
                                      fontSize: 14,
                                      color: AppColors.primarySet2,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (state is LoginLoading)
                                const AuthButtonProgress()
                              else
                                AuthPrimaryButton(
                                  text: localizations.translate('login'),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      cubit.loginWithEmail(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(height: 20),
                              AuthCreateAccountLink(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.register,
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              AuthOrDivider(
                                label: localizations.translate('or'),
                              ),
                              const SizedBox(height: 16),
                              if (state is LoginLinkedInLoading)
                                const AuthButtonProgress()
                              else
                                AuthLinkedInButton(
                                  label: localizations
                                      .translate('linkedin_import_button'),
                                  onPressed: () =>
                                      cubit.loginWithLinkedIn(context),
                                ),
                              if (state is LoginFailure &&
                                  state.offerEmailSignIn) ...[
                                const SizedBox(height: 12),
                                LinkedInEmailConflictNotice(
                                  onSignInWithEmail: () =>
                                      _emailFocus.requestFocus(),
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
