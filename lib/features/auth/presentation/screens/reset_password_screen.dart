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

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final token = '1234'; // add token from OTP

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<PasswordCubit, PasswordState>(
        listener: (context, state) {
          if (state is ResetPasswordSuccess) {
            CustomSnackBars.sucssesSnackBar(
              context: context,
              message: localizations.translate('password_reset_seccessfully'),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesName.login,
              (route) => false,
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
          return  SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: SvgPicture.asset(
                      ImageManages.rashedImage,
                      height: 130,
                      width: 130,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    localizations.translate('reset_password'),
                    style: getBoldStyle(
                      color: ColorsManager.fontColor,
                      fontSize: FontSizeManager.s20,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !cubit.isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: localizations.translate('new_password'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                          icon: Icon(
                            cubit.isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            cubit.viewPassword();
                          },
                        ),
                    ),
                    validator: (value) =>
                        Validations.validatePassword(value!, context),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !cubit.isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: localizations.translate('confirm_password'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                          icon: Icon(
                            cubit.isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            cubit.viewPassword();
                          },
                        ),
                    ),
                    validator: (confirmPassword) =>
                        Validations.validateConfirmPassword(
                            newPasswordController.text,
                            confirmPassword!,
                            context),
                  ),
                  const SizedBox(height: 20),
                  state is PasswordLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ButtonsManager.primaryButton(
                    text: localizations.translate('reset_password'),
                    context: context,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // handle Reset password
                        cubit.resetPassword(
                          token,
                           newPasswordController.text);
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
