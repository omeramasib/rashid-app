import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rashed_app/Presentation/utils/colors.dart';
import 'package:rashed_app/Presentation/utils/fonts.dart';
import 'package:rashed_app/Presentation/utils/styles.dart';

class ButtonsManager {
  static Widget primaryButton({
    required String text,
    required Function onPressed,
    required BuildContext context,
    Color? buttonColor,
    Color? textColor,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
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
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.08,
        child: Center(
          child: Text(
            text,
            style: getBoldStyle(
              color: textColor ?? ColorsManager.whiteColor,
              fontSize: fontSize ?? FontSizeManager.s16,
            ),
          ),
        ),
      ),
    );
  }

  // secondary button
  static Widget secondaryButton({
    required String text,
    required Function onPressed,
    required BuildContext context,
    Key? key,
    Size? minimumSize,
    Size? maximumSize,
    Color? buttonColor,
    Color? textColor,
    double? fontSize,
  }) {
    return ElevatedButton(
      key: key,
      style: ElevatedButton.styleFrom(
        minimumSize: minimumSize ??
            Size(MediaQuery.of(context).size.width * 0.8,
                MediaQuery.of(context).size.height * 0.07),
        maximumSize: maximumSize ??
            Size(MediaQuery.of(context).size.width * 0.8,
                MediaQuery.of(context).size.height * 0.07),
        textStyle: getRegularStyle(
          color: ColorsManager.whiteColor,
          fontSize: fontSize ?? FontSizeManager.s15,
        ),
        backgroundColor: buttonColor ?? ColorsManager.mainColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        HapticFeedback.heavyImpact();
        onPressed();
      },
      child: Text(
        text,
        style: getRegularStyle(
          color: textColor ?? ColorsManager.whiteColor,
          fontSize: fontSize ?? FontSizeManager.s15,
        ),
      ),
    );
  }
}
