import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF6747E7);
  static const Color primaryLight = Color(0xFF5862E8);
  static const Color primaryAccent = Color(0xFF2FAAEC);
  static const Color secondary = Color(0xFF00FFF0);
  static const Color primarySet2 = Color(0xFF396AFC);

  // Black scale
  static const Color black100 = Color(0xFF141F1F);
  static const Color black60 = Color(0xFFA4ACAD);
  static const Color black40 = Color(0xFFC9CECF);
  static const Color black20 = Color(0xFFDDDFDF);
  static const Color black10 = Color(0xFFE6E9EA);
  static const Color black5 = Color(0xFFF9FAFA);

  // Aliases
  static const Color fontColor = black100;
  static const Color hintColor = black60;
  static const Color inputBg = black5;
  static const Color inputBorder = black10;
  static const Color dividerColor = black20;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Backgrounds
  static const Color bodyBackground = Color(0xFFEAF1FD);

  // Semantic
  static const Color success = Color(0xFF67C23A);
  static const Color warning = Color(0xFFE6A23C);
  static const Color error = Color(0xFFE3080C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.8, -0.2),
    end: Alignment(0.8, 0.2),
    colors: [
      Color(0xFF6747E7),
      Color(0xFF5862E8),
      Color(0xFF2FAAEC),
      Color(0xFF00FFF0),
    ],
    stops: [0.115, 0.31, 0.84, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x1A3D83FF),
      Color(0x1A236DDF),
    ],
  );
}
