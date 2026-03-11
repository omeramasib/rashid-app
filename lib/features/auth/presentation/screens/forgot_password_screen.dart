import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rashed_app/Presentation/utils/custom_snackbars.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/features/auth/presentation/cubit/password/password_cubit.dart';
import '../../../../Presentation/utils/buttons.dart';
import '../../../../Presentation/utils/colors.dart';
import '../../../../Presentation/utils/images.dart';
import '../../../../Presentation/utils/styles.dart';
import '../../../../Presentation/utils/fonts.dart';
import '../../../../Presentation/utils/validations.dart';
import '../../../../app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<PasswordCubit, PasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            CustomSnackBars.sucssesSnackBar(
              context: context,
              message: localizations.translate('verification_code_sent'),
            );
            Navigator.pushNamed(
              context,
              RoutesName.otpVerification,
            );
          } else if (state is PasswordError) {
            CustomSnackBars.errorSnackBar(
              context: context,
              message: state.message,
            );
          }
        },
        builder: (context, state) {
          PasswordCubit cubit = context.read<PasswordCubit>();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: height * 0.12),
                    Center(
                      child: SvgPicture.asset(
                        ImageManages.rashedImage,
                        height: 130,
                        width: 130,
                      ),
                    ),
                    SizedBox(height: height * 0.04),
                    Text(
                      localizations.translate('forgot_password'),
                      style: getBoldStyle(
                        color: ColorsManager.fontColor,
                        fontSize: FontSizeManager.s20,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      localizations.translate('forgot_password_description'),
                      style: getRegularStyle(
                        color: ColorsManager.hintStyleColor,
                        fontSize: FontSizeManager.s14,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: height * 0.03),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('email'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) =>
                          Validations.validateEmail(value!, context),
                    ),
                    SizedBox(height: height * 0.05),
                    state is PasswordLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ButtonsManager.primaryButton(
                            text: localizations.translate('send_email'),
                            context: context,
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                // handle send email
                                cubit.forgotPassword(emailController.text);
                              }
                            },
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
