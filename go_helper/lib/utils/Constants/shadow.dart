import 'package:flutter/material.dart';

class HShadows {
  HShadows._();

  // Black/Grey Shadows
  static List<BoxShadow> get greyShadowStrong => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  static double get buttonElevation => 6.0;
  static Color get buttonShadowColor => Colors.black.withOpacity(0.25);
}
