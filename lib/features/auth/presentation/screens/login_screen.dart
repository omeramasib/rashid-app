import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rashed_app/app/routes_name.dart';
import '../../../../Presentation/utils/buttons.dart';
import '../../../../Presentation/utils/colors.dart';
import '../../../../Presentation/utils/custom_snackbars.dart';
import '../../../../Presentation/utils/images.dart';
import '../../../../Presentation/utils/styles.dart';
import '../../../../Presentation/utils/fonts.dart';
import '../../../../Presentation/utils/validations.dart';
import '../../../../app_localizations.dart';
import '../cubit/login/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// Build LinkedIn sign-in button with LinkedIn branding
  Widget _buildLinkedInButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A66C2), // LinkedIn blue
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LinkedIn icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'in',
                  style: TextStyle(
                    color: Color(0xFF0A66C2),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<LoginCubit, LoginState>(
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
          } else if (state is LoginFailure) {
            CustomSnackBars.errorSnackBar(
              context: context,
              message: state.message,
            );
          }
        },
        builder: (context, state) {
          LoginCubit cubit = context.read<LoginCubit>();
          return SingleChildScrollView(
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
                      localizations.translate('login'),
                      style: getBoldStyle(
                        color: ColorsManager.fontColor,
                        fontSize: FontSizeManager.s20,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !cubit.isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: localizations.translate('password'),
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
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: Text(
                          localizations.translate('forgot_password'),
                          style:
                              const TextStyle(color: ColorsManager.mainColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    state is LoginLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ButtonsManager.primaryButton(
                            text: localizations.translate('login'),
                            context: context,
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                cubit.loginWithEmail(
                                  email: emailController.text,
                                  password: passwordController.text,
                                );
                              }
                            },
                          ),
                    const SizedBox(height: 20),
                    // Divider with "OR" text
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            localizations.translate('or'),
                            style: const TextStyle(
                              color: ColorsManager.defaultGreyColor,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // LinkedIn Login Button
                    state is LoginLinkedInLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildLinkedInButton(
                            context: context,
                            text:
                                localizations.translate('login_with_linkedin'),
                            onPressed: () {
                              print(
                                  'DEBUG: LoginScreen - Login with LinkedIn clicked');
                              cubit.loginWithLinkedIn(context);
                            },
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            localizations.translate('do_not_have_account'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, RoutesName.register);
                          },
                          child: Text(
                            localizations.translate('register'),
                            style:
                                const TextStyle(color: ColorsManager.mainColor),
                          ),
                        ),
                      ],
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
