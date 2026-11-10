import 'package:flutter/material.dart';

/// Sizes, borders and colors of the OTP boxes.
@immutable
class SmartOtpStyle {
  const SmartOtpStyle({
    this.boxWidth = 48,
    this.boxHeight = 56,
    this.spacing = 8,
    this.borderWidth = 1,
    this.focusedBorderWidth = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.borderColor,
    this.focusedBorderColor,
    this.filledBorderColor,
    this.errorBorderColor,
    this.disabledBorderColor,
    this.fillColor,
    this.focusedFillColor,
    this.filledFillColor,
    this.errorFillColor,
    this.disabledFillColor,
    this.textStyle,
    this.cursorColor,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
  }) : assert(boxWidth > 0),
       assert(boxHeight > 0),
       assert(spacing >= 0),
       assert(borderWidth >= 0),
       assert(focusedBorderWidth >= 0);

  final double boxWidth;
  final double boxHeight;
  final double spacing;
  final double borderWidth;
  final double focusedBorderWidth;
  final BorderRadius borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? filledBorderColor;
  final Color? errorBorderColor;
  final Color? disabledBorderColor;
  final Color? fillColor;
  final Color? focusedFillColor;
  final Color? filledFillColor;
  final Color? errorFillColor;
  final Color? disabledFillColor;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final Duration animationDuration;
  final Curve animationCurve;
}
