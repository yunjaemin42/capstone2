import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  //메모리 청소 코드..?
  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '로그인',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // 아이디 입력칸
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: '아이디 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 비밀번호 입력칸
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 로그인 버튼
              ElevatedButton(
                onPressed: () async {
                  // 여기 IP 주소 부분 내(해민) 터미널에서 찾은 IPv4 주소로 변경할 것
                  const String myIp = '192.168.45.13'; 
                  const String url = 'http://' + myIp + ':5000/api/login';

                  try {
                    // 서버로 아이디와 비밀번호 전송
                    final response = await http.post(
                      Uri.parse(url),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        "user_id": _idController.text,
                        "password": _pwController.text,
                      }),
                    );

                    // 서버가 200(성공)을 외치면 메인 화면으로 넘어갑니다.
                    if (response.statusCode == 200) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainScreen()),
                      );
                    } else {
                      // 실패하면 실패 이유를 알려주는 작은 알림창을 띄웁니다.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('아이디나 비밀번호가 틀렸습니다.')),
                      );
                    }
                  } catch (e) {
                    // 인터넷 연결이 안 되거나 주소가 틀렸을 때
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('서버와 연결할 수 없습니다.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // 하단 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('아이디 찾기', style: TextStyle(color: Colors.grey)),
                  ),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('비밀번호 찾기', style: TextStyle(color: Colors.grey)),
                  ),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      // Navigator.push를 쓰면 새 화면(회원가입)으로 넘어가고, 
                      // 나중에 폰의 '뒤로 가기'를 누르면 다시 로그인 화면으로 돌아올 수 있어요!
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                    child: const Text('회원가입', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}