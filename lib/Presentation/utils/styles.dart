import 'package:flutter/material.dart';
import 'package:rashed_app/Presentation/utils/fonts.dart';

// function to get the text style
TextStyle _getTextStyle({
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
    fontFamily: FontsManager.fontFamily,
    fontWeight: fontWeight,
    color: color,
    decoration: decoration,
    letterSpacing: letterSpacing,
    height: height,
    overflow: overflow,
  );
}

// regular style
TextStyle getRegularStyle(
    {double fontSize = FontSizeManager.s15,
    required Color color,
    TextDecoration? decoration,
    TextOverflow? overflow,
    double? letterSpacing,
    double? height}) {
  return _getTextStyle(
      fontSize: fontSize,
      fontWeight: FontWeightManager.regular,
      color: color,
      decoration: decoration,
      overflow: overflow,
      letterSpacing: letterSpacing,
      height: height);
}


// bold style
TextStyle getBoldStyle({
  double fontSize = FontSizeManager.s18,
  required Color color,
  TextOverflow? overflow,
  TextDecoration? decoration,
  double? letterSpacing,
  double? height,
}) {
  return _getTextStyle(
      fontSize: fontSize, fontWeight: FontWeightManager.bold, color: color);
}

// Extra Bold style
TextStyle getExtraBoldStyle({
  double fontSize = FontSizeManager.s18,
  required Color color,
  TextOverflow? overflow,
  TextDecoration? decoration,
  double? letterSpacing,
  double? height,
}) {
  return _getTextStyle(
      fontSize: fontSize, fontWeight: FontWeightManager.extraBold, color: color);
}