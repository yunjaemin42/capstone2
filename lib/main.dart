import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'login_screen.dart'; // 보고 싶은 화면 파일명으로 변경하세요

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Secure App',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.mainBlue),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // 여기에 보고 싶은 화면 이름을 넣습니다. (예: SplashScreen(), SignupScreen())
    );
  }
}