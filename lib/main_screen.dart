import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:flutter_svg/svg.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'setting_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 처음에 보여줄 탭 (0번 = 홈)

  // 탭을 누를 때마다 보여줄 4개의 방 목록
  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const SettingScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.mainBlue,
        unselectedItemColor: AppColors.textGray,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/icon_home.svg',
              width: 24, height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0 ? AppColors.mainBlue : AppColors.textGray,
                BlendMode.srcIn,
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/icon_history.svg',
              width: 24, height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1 ? AppColors.mainBlue : AppColors.textGray,
                BlendMode.srcIn,
              ),
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/icon_setting.svg',
              width: 24, height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2 ? AppColors.mainBlue : AppColors.textGray,
                BlendMode.srcIn,
              ),
            ),
            label: 'Setting',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/icon_profile.svg',
              width: 24, height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3 ? AppColors.mainBlue : AppColors.textGray,
                BlendMode.srcIn,
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}