import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rashed_app/Presentation/utils/colors.dart';
import 'package:rashed_app/Presentation/utils/fonts.dart';
import 'package:rashed_app/Presentation/utils/styles.dart';
import 'package:rashed_app/app_localizations.dart';

class LinkedinSignup extends StatefulWidget {
  const LinkedinSignup({super.key});

  @override
  State<LinkedinSignup> createState() => _LinkedinSignupState();
}

class _LinkedinSignupState extends State<LinkedinSignup> {
  @override
  Widget build(BuildContext context) {
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
    );
  }
}