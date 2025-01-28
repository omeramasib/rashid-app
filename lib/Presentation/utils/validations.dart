import 'package:flutter/cupertino.dart';

class Validations {
    static String? textValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return 'Please enter text';
    } else {
      return null;
    }
  }
  static String? validatePassword(String value, BuildContext context) {
    if (value.isEmpty) {
      return "Please enter password";
    } else if (value.length < 8) {
      return "Password must be at least 8 characters";
    } else {
      return null;
    }
  }
 static String? validateEmail(String value, BuildContext context) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex =  RegExp(pattern.toString());
    if (value.isEmpty) {
      return "Please enter email";
    } else if (!regex.hasMatch(value)) {
      return "Please enter valid email";
    } else {
      return null;
    }
  }

}