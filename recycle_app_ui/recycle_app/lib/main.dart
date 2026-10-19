import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

export 'screens/main_shell.dart';

void main() {
  runApp(const RecycleApp());
}

class RecycleApp extends StatelessWidget {
  const RecycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뚝딱뚝딱 재활용',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const LoginScreen(),
    );
  }
}
