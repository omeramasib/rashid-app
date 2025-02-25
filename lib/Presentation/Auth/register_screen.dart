import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rashed_app/Logic/cubits/auth/register/cubit/register_cubit.dart';
import 'package:rashed_app/Presentation/utils/colors.dart';
import 'package:rashed_app/Presentation/utils/fonts.dart';
import 'package:rashed_app/Presentation/utils/styles.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Data/repositories/Auth/register_repository.dart';
import '../utils/buttons.dart';
import '../utils/custom_snackbars.dart';
import '../utils/images.dart';
import '../utils/validations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => RegisterCubit(
          RegisterRepository(),
        ),
        child: const RegisterScreen(),
      ),
      settings: routeSettings,
    );
  }
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
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  void login() {
    var isValid = registerFormKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    registerFormKey.currentState!.save();
    context.read<RegisterCubit>().singup(
          name: _nameTextEditingController.text.trim(),
          email: _emailTextEditingController.text.trim(),
          password: _passwordTextEditingController.text.trim(),
        );
  }

  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
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
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: registerFormKey,
          child: Column(
            spacing: height * 0.01,
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
                          height: height * 0.09,
                          width: double.infinity,
                          child: TextFormField(
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.text,
                            controller: _nameTextEditingController,
                            validator: (value) => Validations.textValidation(
                              value!,
                              context,
                            ),
                            decoration: InputDecoration(
                              fillColor: ColorsManager.whiteColor,
                              filled: true,
                              labelText: AppLocalizations.of(context)!
                                  .translate("full_name"),
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
                      Padding(
                        padding: const EdgeInsets.only(
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
                            validator: (value) =>
                                  Validations.validateEmail(
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
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          left: 20,
                          right: 20,
                        ),
                        child: SizedBox(
                          height: height * 0.08,
                          width: double.infinity,
                          child: BlocBuilder<RegisterCubit, RegisterState>(
                            builder: (context, state) {
                              return TextFormField(
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
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
                      SizedBox(
                        height: height * 0.02,
                      ),

                      BlocConsumer<RegisterCubit, RegisterState>(
                        listener: (context, state) {
                          if (state is RegisterSuccess) {
                            CustomSnackBars.sucssesSnackBar(
                              context: context,
                              message: state.message,
                            );
                            // Navigator.pushReplacementNamed(
                            //   context,
                            //   RoutesName.homeScreen,
                            // );
                          } else if (state is RegisterFailure) {
                            CustomSnackBars.errorSnackBar(
                              context: context,
                              message: state.errorMessage,
                            );
                          }
                        },
                        builder: (context, state) {
                          if (state is RegisterOnProgress) {
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
                            onPressed: login,
                          );
                        },
                      ),

                      // ButtonsManager.primaryButton(
                      //   text: AppLocalizations.of(context)!
                      //       .translate("sign_up"),
                      //   onPressed: () {},
                      //   context: context,
                      // ),

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
                                  .translate("already_have_an_account"),
                              style: getRegularStyle(
                                  color: ColorsManager.defaultGreyColor),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                AppLocalizations.of(context)!
                                    .translate("login"),
                                style: getRegularStyle(
                                  color: ColorsManager.blueColor,
                                  fontSize: FontSizeManager.s16,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      )
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
