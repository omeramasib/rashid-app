import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import '../../../../Presentation/utils/buttons.dart';
import '../../../../Presentation/utils/colors.dart';
import '../../../../Presentation/utils/custom_snackbars.dart';
import '../../../../Presentation/utils/fonts.dart';
import '../../../../Presentation/utils/images.dart';
import '../../../../Presentation/utils/styles.dart';
import '../../../../Presentation/utils/validations.dart';
import '../cubit/register/register_cubit.dart';

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
    var isValid = registerFormKey.currentState!.validate();
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

  /// Build LinkedIn sign-in button with LinkedIn branding
  Widget _buildLinkedInButton({
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
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate("register"),
          selectionColor: ColorsManager.primaryColor,
          style: getBoldStyle(
            color: ColorsManager.mainColor,
            fontSize: FontSizeManager.s20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: ColorsManager.blackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: registerFormKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: height * 0.2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6747E7),
                        Color(0xFF5862E8),
                        Color(0xFF2FAAEC),
                      ],
                      stops: [0.0, 0.14, 0.54],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate("register_des"),
                              style: getRegularStyle(
                                color: ColorsManager.whiteColor,
                                fontSize: FontSizeManager.s18,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          ImageManages.rashedImage,
                          height: 130,
                          width: 130,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorsManager.bodyColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Name Field
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: SizedBox(
                          height: height * 0.08,
                          width: double.infinity,
                          child: TextFormField(
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            controller: _nameTextEditingController,
                            validator: (value) =>
                                Validations.textValidation(value!, context),
                            decoration: InputDecoration(
                              fillColor: ColorsManager.whiteColor,
                              filled: true,
                              labelText: AppLocalizations.of(context)!
                                  .translate("fullName"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.01),

                      // Email Field
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 5, left: 20, right: 20),
                        child: SizedBox(
                          height: height * 0.08,
                          width: double.infinity,
                          child: TextFormField(
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailTextEditingController,
                            validator: (value) =>
                                Validations.validateEmail(value!, context),
                            decoration: InputDecoration(
                              fillColor: ColorsManager.whiteColor,
                              filled: true,
                              labelText: AppLocalizations.of(context)!
                                  .translate("email"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.01),

                      // Password Field
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 5, left: 20, right: 20),
                        child: SizedBox(
                          height: height * 0.08,
                          width: double.infinity,
                          child: BlocBuilder<RegisterCubit, RegisterState>(
                            builder: (context, state) {
                              return TextFormField(
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: !(state is ViewPasswordState &&
                                    state.enabled),
                                controller: _passwordTextEditingController,
                                validator: (value) =>
                                    Validations.validatePassword(
                                        value!, context),
                                decoration: InputDecoration(
                                  fillColor: ColorsManager.whiteColor,
                                  filled: true,
                                  labelText: AppLocalizations.of(context)!
                                      .translate("password"),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      context
                                              .read<RegisterCubit>()
                                              .isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: ColorsManager.defaultGreyColor,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<RegisterCubit>()
                                          .viewPassword();
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.01),

                      // Register Button
                      BlocConsumer<RegisterCubit, RegisterState>(
                        listener: (context, state) {
                          if (state is RegisterSuccess) {
                            CustomSnackBars.sucssesSnackBar(
                              context: context,
                              message: "Register Successfully",
                            );
                            Navigator.pushReplacementNamed(
                              context,
                              RoutesName.linkedinImport,
                            );
                          } else if (state is RegisterFailure) {
                            CustomSnackBars.errorSnackBar(
                              context: context,
                              message: state.message,
                            );
                          }
                        },
                        builder: (context, state) {
                          if (state is RegisterLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: ColorsManager.mainColor,
                              ),
                            );
                          }

                          return ButtonsManager.primaryButton(
                            text: AppLocalizations.of(context)!
                                .translate("sign_up"),
                            context: context,
                            onPressed: register,
                          );
                        },
                      ),
                      SizedBox(height: height * 0.02),
                      // Divider with "OR" text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                AppLocalizations.of(context)!.translate('or'),
                                style: const TextStyle(
                                  color: ColorsManager.defaultGreyColor,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      // LinkedIn Register Button
                      BlocBuilder<RegisterCubit, RegisterState>(
                        builder: (context, state) {
                          if (state is RegisterLinkedInLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0A66C2),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildLinkedInButton(
                              text: AppLocalizations.of(context)!
                                  .translate('login_with_linkedin'),
                              onPressed: registerWithLinkedIn,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: height * 0.03),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
