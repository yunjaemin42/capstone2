import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/my_screen.dart';

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
      home: const MainShell(),
    );
  }
}

/// 하단 탭(홈 · 이력 · 통계 · 마이)으로 화면을 바꾸는 틀
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onSeeAll: () => setState(() => index = 1)),
      const HistoryScreen(),
      const StatsScreen(),
      const MyScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: screens)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          elevation: 0,
          selectedItemColor: AppColors.green,
          unselectedItemColor: AppColors.muted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: '이력'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: '통계'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: '마이'),
          ],
        ),
      ),
    );
  }
}
