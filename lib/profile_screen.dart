import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('계정 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildListTile('아이디 설정'),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildListTile('비밀번호 설정'),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildListTile('이름 설정'),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildListTile('그 외 개인정보 설정'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // 나중에 화면 이동 기능을 넣을 자리
      },
    );
  }
}