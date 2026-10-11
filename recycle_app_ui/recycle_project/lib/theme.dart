import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma 디자인에서 쓴 색상 (발표자료와 같은 초록 계열)
class AppColors {
  static const dark = Color(0xFF182619);
  static const green = Color(0xFF4F8F5B);
  static const light = Color(0xFFF7F5EE);
  static const white = Color(0xFFFFFFFF);
  static const line = Color(0xFFE1DFD3);
  static const gray = Color(0xFF5B6B5E);
  static const muted = Color(0xFF8A9A8C);
  static const red = Color(0xFFC0392B);
  static const redBg = Color(0xFFF8E1DE);
  static const redLine = Color(0xFFE8B4AC);
  static const greenBg = Color(0xFFE3F0E3);
  static const mint = Color(0xFFBFD8C0);
}

/// 자주 쓰는 글자 스타일을 짧게 만드는 함수
TextStyle ts(double size,
    {FontWeight weight = FontWeight.w400, Color color = AppColors.dark}) {
  return TextStyle(fontSize: size, fontWeight: weight, color: color);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      surface: AppColors.light,
    ),
    scaffoldBackgroundColor: AppColors.light,
  );
  return base.copyWith(
    textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
      bodyColor: AppColors.dark,
      displayColor: AppColors.dark,
    ),
  );
}
