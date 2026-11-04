import 'package:flutter/material.dart';

/// Text direction for the saved app language.
class AppTextDirection {
  AppTextDirection._();

  static TextDirection of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }
}
