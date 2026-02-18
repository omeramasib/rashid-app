import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Almarai';

  static const FontWeight lightWeight = FontWeight.w300;
  static const FontWeight regularWeight = FontWeight.w400;
  static const FontWeight boldWeight = FontWeight.w700;
  static const FontWeight extraBoldWeight = FontWeight.w800;

  static const double s5 = 5.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s11 = 11.0;
  static const double s12 = 12.0;
  static const double s13 = 13.0;
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s16 = 16.0;
  static const double s17 = 17.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s22 = 22.0;
  static const double s24 = 24.0;
  static const double s25 = 25.0;
  static const double s26 = 26.0;
  static const double s28 = 28.0;
  static const double s30 = 30.0;

  static TextStyle _getTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextOverflow? overflow,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
      overflow: overflow,
    );
  }

  static TextStyle regular({
    double fontSize = s15,
    required Color color,
    TextDecoration? decoration,
    TextOverflow? overflow,
    double? letterSpacing,
    double? height,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontWeight: regularWeight,
      color: color,
      decoration: decoration,
      overflow: overflow,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle bold({
    double fontSize = s18,
    required Color color,
    TextOverflow? overflow,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontWeight: boldWeight,
      color: color,
      overflow: overflow,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle extraBold({
    double fontSize = s18,
    required Color color,
    TextOverflow? overflow,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontWeight: extraBoldWeight,
      color: color,
      overflow: overflow,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle lightStyle({
    double fontSize = s15,
    required Color color,
    TextOverflow? overflow,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontWeight: lightWeight,
      color: color,
      overflow: overflow,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
