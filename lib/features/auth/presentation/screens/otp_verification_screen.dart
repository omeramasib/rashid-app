import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../domain/password_reset_validation.dart';
import '../cubit/password/password_cubit.dart';
import 'password_flow_ui.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with WidgetsBindingObserver {
  final _code = TextEditingController();
  PasswordCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cubit == null) {
      _cubit = context.read<PasswordCubit>();
      _code.text = _cubit!.state.otp;
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cubit?.refreshCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return BlocConsumer<PasswordCubit, PasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PasswordStatus.resendAccepted,
      listener: (context, state) {
        _code.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.translate('password_request_accepted')),
        ));
      },
      builder: (context, state) => PasswordFlowPage(
        title: strings.translate('verification_code_title'),
        description:
            '${strings.translate('verification_code_hint')} ${state.email}. '
            '${strings.translate('password_request_accepted')}',
        children: [
          if (state.failure != null)
            PasswordIssueBanner(failure: state.failure!),
          TextField(
            key: const Key('otpCode'),
            controller: _code,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            maxLength: 6,
            decoration: InputDecoration(
              labelText: strings.translate('verification_code'),
              counterText: '',
              errorText: state.failure?.fields.contains('otp') == true
                  ? strings.translate('reset_enter_code')
                  : null,
            ),
            onChanged: _cubit!.setOtp,
          ),
          const SizedBox(height: 12),
          Text(strings.translate('code_expires'), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton(
            key: const Key('resendCode'),
            onPressed: state.remainingSeconds > 0 || state.isBusy
                ? null
                : _cubit!.resendCode,
            child: state.status == PasswordStatus.resending
                ? const CircularProgressIndicator()
                : Text(state.remainingSeconds > 0
                    ? strings.translate('resend_wait_seconds', {
                        'seconds': '${state.remainingSeconds}',
                      })
                    : strings.translate('resend_code')),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('continueToPassword'),
            onPressed: state.isBusy
                ? null
                : () {
                    if (!PasswordResetValidation.isValidOtp(_code.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(strings.translate('reset_enter_code')),
                      ));
                      return;
                    }
                    FocusScope.of(context).unfocus();
                    Navigator.pushNamed(context, RoutesName.resetPassword);
                  },
            child: Text(strings.translate('continue')),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const Key('changeEmail'),
            onPressed: state.isBusy
                ? null
                : () {
                    _cubit!.setOtp('');
                    Navigator.pop(context);
                  },
            child: Text(strings.translate('change_email')),
          ),
        ],
      ),
    );
  }
}
