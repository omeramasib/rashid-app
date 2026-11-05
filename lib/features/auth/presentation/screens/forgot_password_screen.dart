import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../domain/password_reset_validation.dart';
import '../cubit/password/password_cubit.dart';
import 'password_flow_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  PasswordCubit? _cubit;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cubit == null) {
      _cubit = context.read<PasswordCubit>();
      _cubit!.clearFlow();
    }
  }

  @override
  void dispose() {
    _cubit?.clearFlow();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return BlocConsumer<PasswordCubit, PasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PasswordStatus.emailAccepted) {
          FocusScope.of(context).unfocus();
          Navigator.pushNamed(context, RoutesName.otpVerification);
        }
      },
      builder: (context, state) => PasswordFlowPage(
        title: strings.translate('forgot_password'),
        description: strings.translate('password_help'),
        children: [
          if (state.failure != null)
            PasswordIssueBanner(failure: state.failure!),
          Form(
            key: _formKey,
            child: TextFormField(
              key: const Key('forgotEmail'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              enabled: !state.isBusy,
              decoration: InputDecoration(
                labelText: strings.translate('email'),
                errorText: state.failure?.fields.contains('email') == true
                    ? strings.translate('reset_email_error')
                    : null,
              ),
              validator: (value) =>
                  PasswordResetValidation.isValidEmail(value ?? '')
                      ? null
                      : strings.translate('reset_email_error'),
              onFieldSubmitted: (_) => _submit(state),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('requestCode'),
            onPressed: state.isBusy ? null : () => _submit(state),
            child: state.status == PasswordStatus.submittingEmail
                ? const CircularProgressIndicator()
                : Text(strings.translate('continue')),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: state.isBusy
                ? null
                : () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                          context, RoutesName.login, (_) => false);
                    }
                  },
            child: Text(strings.translate('back_to_login')),
          ),
        ],
      ),
    );
  }

  void _submit(PasswordState state) {
    if (state.isBusy || !_formKey.currentState!.validate()) return;
    _cubit!.requestCode(_email.text);
  }
}
