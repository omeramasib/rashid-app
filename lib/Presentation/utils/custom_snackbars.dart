import 'package:flutter/material.dart';
import 'package:rashed_app/Presentation/utils/styles.dart';
import 'package:toastification/toastification.dart';

class CustomSnackBars {
  static void sucssesSnackBar(
      {required String message, required BuildContext context}) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      backgroundColor: Colors.green,
      showProgressBar: false,
      icon: const Icon(
        Icons.check,
        color: Colors.white,
      ),
      title: Text(
        message,
        style: getRegularStyle(color: Colors.white, fontSize: 16),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void errorSnackBar(
      {required String message, required BuildContext context}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      showProgressBar: false,
      backgroundColor: Colors.red,
      icon: const Icon(
        Icons.error,
        color: Colors.white,
      ),
      title: Text(
        message,
        style: getRegularStyle(color: Colors.white, fontSize: 16),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void warningSnackBar(
    {required String message, required BuildContext context}
  ){
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      showProgressBar: false,
      backgroundColor: Colors.yellow,
      icon: const Icon(
        Icons.error,
        color: Colors.white,
      ),
      title: Text(
        message,
        style: getRegularStyle(color: Colors.white, fontSize: 16),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
