import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary       = Color(0xFFB1004E);
  static const Color primaryDark   = Color(0xFF8A003C);
  static const Color primaryLight  = Color(0xFFD4006A);

  // Neutrals
  static const Color white         = Color(0xFFFFFFFF);
  static const Color lightGrey     = Color(0xFFF5F5F5);
  static const Color borderGrey    = Color(0xFFE0E0E0);
  static const Color hintGrey      = Color(0xFF9E9E9E);
  static const Color textGrey      = Color(0xFF616161);
  static const Color textDark      = Color(0xFF212121);

  // Semantic
  static const Color error         = Color(0xFFD32F2F);
  static const Color success       = Color(0xFF388E3C);
  static const Color warning       = Color(0xFFF57C00);
  static const Color urgent        = Color(0xFFFF1744);

  // Special
  static const Color referralBg    = Color(0xFFFFEBF3);
  static const Color chipBg        = Color(0xFFFCE4EC);
  static const Color cardShadow    = Color(0x1A000000);

  // Gradient stops
  static const Color gradientStart = Color(0xFFDF0B33);
  static const Color gradientEnd = Color(0xFFAB0857);
  
  static const List<Color> splashGradient = [
    Color(0xFFFF4081),
    Color(0xFFB1004E),
    Color(0xFF7B003A),
  ];

  static const List<Color> fabGradient = [
    Color(0xFFD4006A),
    Color(0xFFB1004E),
  ];
}
