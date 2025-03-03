import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rashed_app/Data/Repositories/Auth/login_repository.dart';
import 'package:rashed_app/Logic/cubits/auth/login/login_cubit.dart';
import 'package:rashed_app/Presentation/utils/colors.dart';
import 'package:rashed_app/Presentation/utils/fonts.dart';
import 'package:rashed_app/Presentation/utils/styles.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/buttons.dart';
import '../utils/custom_snackbars.dart';
import '../utils/images.dart';
import '../utils/validations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => LoginCubit(
          LoginRepository(),
        ),
        child: const LoginScreen(),
      ),
      settings: routeSettings,
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailTextEditingController =
      TextEditingController();

  final TextEditingController _passwordTextEditingController =
      TextEditingController();

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  @override
  void dispose() {
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  void login() {
    var isValid = loginFormKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    loginFormKey.currentState!.save();
    context.read<LoginCubit>().login(
          email: _emailTextEditingController.text.trim(),
          password: _passwordTextEditingController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate("login"),
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
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: loginFormKey,
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
                                  .translate("login_des"),
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
              SizedBox(
                height: height * 0.01,
              ),
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
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 20,
                          right: 20,
                        ),
                        child: SizedBox(
                          height: height * 0.08,
                          width: double.infinity,
                          child: TextFormField(
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailTextEditingController,
                            validator: (value) => Validations.validateEmail(
                              value!,
                              context,
                            ),
                            decoration: InputDecoration(
                              fillColor: ColorsManager.whiteColor,
                              filled: true,
                              labelText: AppLocalizations.of(context)!
                                  .translate("email"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintStyle: getRegularStyle(
                                color: ColorsManager.hintStyleColor,
                                fontSize: FontSizeManager.s14,
                              ),
                              labelStyle: getBoldStyle(
                                color: ColorsManager.hintStyleColor,
                                fontSize: FontSizeManager.s14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 5,
                          left: 20,
                          right: 20,
                        ),
                        child: SizedBox(
                          height: height * 0.08,
                          width: double.infinity,
                          child: BlocBuilder<LoginCubit, LoginState>(
                            builder: (context, state) {
                              return TextFormField(
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                obscureText: !(state is ViewPasswordState &&
                                    state.enabled),
                                controller: _passwordTextEditingController,
                                validator: (value) =>
                                    Validations.validatePassword(
                                  value!,
                                  context,
                                ),
                                decoration: InputDecoration(
                                  fillColor: ColorsManager.whiteColor,
                                  filled: true,
                                  labelText: AppLocalizations.of(context)!
                                      .translate("password"),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      context
                                              .read<LoginCubit>()
                                              .isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: ColorsManager.defaultGreyColor,
                                    ),
                                    onPressed: () {
                                      context.read<LoginCubit>().viewPassword();
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintStyle: getRegularStyle(
                                    color: ColorsManager.hintStyleColor,
                                    fontSize: FontSizeManager.s14,
                                  ),
                                  labelStyle: getBoldStyle(
                                    color: ColorsManager.hintStyleColor,
                                    fontSize: FontSizeManager.s14,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate("forgot_password"),
                              style: getRegularStyle(
                                color: ColorsManager.blueColor,
                                fontSize: FontSizeManager.s16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      BlocConsumer<LoginCubit, LoginState>(
                        listener: (context, state) {
                          if (state is LoginSuccess) {
                            CustomSnackBars.sucssesSnackBar(
                              context: context,
                              message: state.message,
                            );
                            // Navigator.pushReplacementNamed(
                            //   context,
                            //   RoutesName.homeScreen,
                            // );
                          } else if (state is LoginFailure) {
                            CustomSnackBars.errorSnackBar(
                              context: context,
                              message: state.errorMessage,
                            );
                          }
                        },
                        builder: (context, state) {
                          if (state is LoginOnProgress) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: ColorsManager.mainColor,
                              ),
                            );
                          }

                          return ButtonsManager.primaryButton(
                            text: AppLocalizations.of(context)!
                                .translate("login"),
                            context: context,
                            onPressed: login,
                          );

                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: height * 0.02,
                            left: 20,
                            right: 20,
                              ),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate("dont_have_account"),
                              style: getRegularStyle(
                                  color: ColorsManager.defaultGreyColor),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, RoutesName.register);
                              },
                              child: Text(
                                AppLocalizations.of(context)!
                                    .translate("sign_up"),
                                style: getRegularStyle(
                                  color: ColorsManager.blueColor,
                                  fontSize: FontSizeManager.s16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: width * 0.45,
                            child: const Divider(
                              color: ColorsManager.defaultGreyColor,
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.translate("or"),
                            style: getRegularStyle(
                                color: ColorsManager.defaultGreyColor),
                          ),
                          SizedBox(
                            width: width * 0.45,
                            child: const Divider(
                              color: ColorsManager.defaultGreyColor,
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          top: 10,
                          left: 10,
                          right: 10,
                        ),
                        width: double.infinity,
                        height: height * 0.08,
                        decoration: BoxDecoration(
                          color: ColorsManager.whiteColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: width * 0.05,
                            ),
                            Image.asset(
                              ImageManages.linkedinImage,
                            ),
                            SizedBox(
                              width: width * 0.03,
                            ),
                            Text(
                              AppLocalizations.of(context)!
                                  .translate("login_with_linkedin"),
                              style: getRegularStyle(
                                color: ColorsManager.fontColor,
                                fontSize: FontSizeManager.s16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: height * 0.03,
                      ),
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
