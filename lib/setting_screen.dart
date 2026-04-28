import 'package:flutter/material.dart';
import 'app_colors.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int _sensitivity = 1; // 0: 둔감, 1: 보통, 2: 민감

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('민감도 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    RadioListTile(
                      title: const Text('둔감'),
                      value: 0,
                      groupValue: _sensitivity,
                      activeColor: AppColors.mainBlue,
                      onChanged: (val) {
                        setState(() { _sensitivity = val as int; });
                      },
                    ),
                    RadioListTile(
                      title: const Text('보통'),
                      value: 1,
                      groupValue: _sensitivity,
                      activeColor: AppColors.mainBlue,
                      onChanged: (val) {
                        setState(() { _sensitivity = val as int; });
                      },
                    ),
                    RadioListTile(
                      title: const Text('민감'),
                      value: 2,
                      groupValue: _sensitivity,
                      activeColor: AppColors.mainBlue,
                      onChanged: (val) {
                        setState(() { _sensitivity = val as int; });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '민감도 설정을 통해 알림 빈도와 배터리 소모를 줄여 감지를 최적화합니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}