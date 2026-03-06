import 'package:flutter/cupertino.dart';
import 'package:rashed_app/app_localizations.dart';

class Validations {
    static String? textValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return AppLocalizations.of(context)!.translate("please_enter_text");
    } else {
      return null;
    }
  }
  static String? validatePassword(String value, BuildContext context) {
    if (value.isEmpty) {
      return AppLocalizations.of(context)!.translate("please_enter_password");
    } else if (value.length < 8) {
      return AppLocalizations.of(context)!.translate("password_must_be");
    } else {
      return null;
    }
  }
  static String? validateConfirmPassword(String password, String confirmPassword, BuildContext context) {
   if (confirmPassword.isEmpty) {
      return AppLocalizations.of(context)!.translate("please_enter_confirm_password");
    } else if(password != confirmPassword){
      return AppLocalizations.of(context)!.translate("confirm_password_not_match");
    } 
    else {
      return null;
    }
  }
 static String? validateEmail(String value, BuildContext context) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex =  RegExp(pattern.toString());
    if (value.isEmpty) {
      return AppLocalizations.of(context)!.translate("please_enter_email");
    } else if (!regex.hasMatch(value)) {
      return AppLocalizations.of(context)!.translate("please_enter_valid_email");
    } else {
      return null;
    }
  }

}