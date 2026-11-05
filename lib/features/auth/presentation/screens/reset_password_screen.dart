import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../../../core/error/password_reset_problem.dart';
import '../../domain/password_reset_validation.dart';
import '../cubit/password/password_cubit.dart';
import 'password_flow_ui.dart';

class ResetPasswordScreen extends HookWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final password = useTextEditingController();
    final confirmation = useTextEditingController();
    final showPassword = useState(false);
    final showConfirmation = useState(false);
    final strings = AppLocalizations.of(context)!;
    return BlocConsumer<PasswordCubit, PasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PasswordStatus.resetSuccess,
      listener: (context, state) => Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.passwordResetSuccess,
        (_) => false,
      ),
      builder: (context, state) => PasswordFlowPage(
        title: strings.translate('reset_password'),
        description: strings.translate('new_password_hint'),
        children: [
          if (state.failure != null)
            PasswordIssueBanner(failure: state.failure!),
          if (state.failure?.problem == PasswordResetProblem.invalidOtp ||
              state.failure?.problem == PasswordResetProblem.expiredOtp ||
              state.failure?.fields.contains('otp') == true)
            TextButton(
              key: const Key('editCode'),
              onPressed: () => Navigator.pop(context),
              child: Text(strings.translate('edit_code')),
            ),
          if (state.failure?.fields.contains('email') == true)
            TextButton(
              onPressed: () => Navigator.popUntil(
                context,
                ModalRoute.withName(RoutesName.forgotPassword),
              ),
              child: Text(strings.translate('change_email')),
            ),
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('newPassword'),
                  controller: password,
                  obscureText: !showPassword.value,
                  enabled: !state.isBusy,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: strings.translate('new_password'),
                    errorText:
                        state.failure?.fields.contains('new_password') == true
                            ? strings.translate('reset_password_short')
                            : null,
                    suffixIcon: IconButton(
                      key: const Key('toggleNewPassword'),
                      tooltip: strings.translate(showPassword.value
                          ? 'hide_password'
                          : 'show_password'),
                      icon: Icon(showPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => showPassword.value = !showPassword.value,
                    ),
                  ),
                  validator: (value) =>
                      PasswordResetValidation.isValidPassword(value ?? '')
                          ? null
                          : strings.translate('reset_password_short'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('confirmPassword'),
                  controller: confirmation,
                  obscureText: !showConfirmation.value,
                  enabled: !state.isBusy,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: strings.translate('confirm_password'),
                    errorText:
                        state.failure?.fields.contains('confirm_password') ==
                                true
                            ? strings.translate('reset_password_mismatch')
                            : null,
                    suffixIcon: IconButton(
                      key: const Key('toggleConfirmPassword'),
                      tooltip: strings.translate(showConfirmation.value
                          ? 'hide_password'
                          : 'show_password'),
                      icon: Icon(showConfirmation.value
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          showConfirmation.value = !showConfirmation.value,
                    ),
                  ),
                  validator: (value) => PasswordResetValidation.passwordsMatch(
                          password.text, value ?? '')
                      ? null
                      : strings.translate('reset_password_mismatch'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            key: const Key('submitReset'),
            onPressed: state.isBusy
                ? null
                : () {
                    if (!formKey.currentState!.validate()) return;
                    FocusScope.of(context).unfocus();
                    context
                        .read<PasswordCubit>()
                        .resetPassword(password.text, confirmation.text);
                  },
            child: state.status == PasswordStatus.resetting
                ? const CircularProgressIndicator()
                : Text(strings.translate('reset_password')),
          ),
        ],
      ),
    );
  }
}
