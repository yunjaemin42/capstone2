import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  final String? fcmToken;
  const LoginScreen({super.key, this.fcmToken});

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
                  const String myIp = '172.20.86.203'; 
                  const String url = 'http://' + myIp + ':5000/api/login';

                  try {
                    // 💡 1. 콘솔에서 신호가 제대로 출발했는지 확인!
                    print("🚀 서버로 로그인 요청 출발: $url"); 

                    // 서버로 아이디와 비밀번호 전송
                    final response = await http.post(
                      Uri.parse(url),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        "user_id": _idController.text,
                        "password": _pwController.text,
                      }),
                    ).timeout(const Duration(seconds: 5)); // 🔥 5초 타임아웃 추가!

                    // 💡 2. 서버가 뭐라고 대답했는지 콘솔에 출력!
                    print("✅ 서버 응답 도착, 상태 코드: ${response.statusCode}"); 

                    // 서버가 200(성공)을 외치면 메인 화면으로 넘어갑니다.
                    if (response.statusCode == 200) {
                      // FCM 토큰을 서버에 등록
                      final fcmToken = widget.fcmToken;
                      if (fcmToken != null) {
                        try {
                          await http.post(
                            Uri.parse('http://$myIp:5000/api/notification/register-token'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              "user_id": _idController.text,
                              "token": fcmToken,
                            }),
                          );
                          print("✅ FCM 토큰 등록 완료");
                        } catch (e) {
                          print("⚠️ FCM 토큰 등록 실패: $e");
                        }
                      }

                      if (!context.mounted) return;

                      FocusScope.of(context).unfocus();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen(userId: _idController.text)),
                      );
                    } else {
                      // 실패하면 실패 이유를 알려주는 작은 알림창을 띄웁니다.
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('아이디나 비밀번호가 틀렸습니다.')),
                      );
                    }
                  } catch (e) {
                    // 🔥 3. 앱이 멈추지 않고 여기에 진짜 에러 이유를 토해냅니다!
                    print("🚨 앗! 에러 발생 (진짜 범인): $e"); 
                    
                    // 인터넷 연결이 안 되거나 주소가 틀렸을 때
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('서버 연결 실패: $e')),
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