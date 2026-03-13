import 'package:flutter/material.dart';

class EqChartDefaults {
  EqChartDefaults._();

  static const Color ink = Color(0xFF112331);
  static const Color softInk = Color(0xFF5F7183);
  static const Color grid = Color(0xFFDAE2EA);
  static const Color axis = Color(0xFF8BA0B3);
  static const Color surface = Color(0xFFF4F7FA);
  static const Color accentBlue = Color(0xFF2B80FF);
  static const Color accentGreen = Color(0xFF13C3A3);
  static const Color accentOrange = Color(0xFFFF9F1C);
  static const Color accentRose = Color(0xFFEF476F);
  static const Color accentPurple = Color(0xFF8A79FF);

  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);

  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const TextStyle axisTextStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: softInk,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ink,
  );

  static const TextStyle legendTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ink,
  );

  static const TextStyle centerTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: ink,
  );

  static const TextStyle centerSubTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: softInk,
  );
}
