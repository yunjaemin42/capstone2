import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final String myIp = '192.168.45.13';

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ==============================================================
  // 🚨 [절대 돈 땃쥐 구역] 🚨 백엔드로 데이터를 쏘는 마법의 함수
  // ==============================================================
  Future<void> _registerUser() async {
    // 💡 수정 완료: const를 final로 바꾸고, 글자 결합을 $ 기호로 예쁘게 수정!
    final String url = 'http://$myIp:5000/api/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": _idController.text,
          "password": _pwController.text,
          "name": _nameController.text,
          "phone": _phoneController.text,
          "birthdate": _birthController.text,
          "address": _addressController.text,
          "sensitivity": "mid" 
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 🎉')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          // 💡 수정 완료: + 대신 $ 기호 사용
          SnackBar(content: Text('가입 실패: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // 💡 수정 완료: + 대신 $ 기호 사용
        SnackBar(content: Text('에러 발생: $e')),
      );
    }
  }

  // ==============================================================
  // 🚨 [새로운 돈 땃쥐 구역] 🚨 중복확인과 예쁜 팝업을 담당하는 함수들
  // ==============================================================
  Future<void> _checkIdDuplicate() async {
    final String userId = _idController.text.trim();

    if (userId.isEmpty) {
      _showResultDialog("아이디를 입력해주세요.");
      return;
    }

    // 💡 수정 완료: const -> final 및 $ 기호 사용
    final String url = 'http://$myIp:5000/api/check-id';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          _showResultDialog(data['message']);
        } else {
          _showResultDialog(data['message']); 
        }
      } else {
        _showResultDialog("서버 통신 오류가 발생했습니다.");
      }
    } catch (e) {
      // 💡 수정 완료: + 대신 $ 기호 사용
      _showResultDialog("네트워크 에러: $e");
    }
  }

  // 🎨 피그마 디자인과 100% 일치하는 팝업창
  void _showResultDialog(String message) { 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
        ),
        titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 8),
        contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        title: const Text(
          '아이디 중복확인 여부',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Colors.grey), 
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), 
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text('회원가입', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1.0)),
              const SizedBox(height: 40),
              
              _buildInput('아이디 설정', _idController, isId: true, hint: '아이디 입력'),
              _buildInput('비밀번호 설정', _pwController, isObscure: true, hint: '비밀번호 입력'),
              _buildInput('비밀번호 확인', _pwConfirmController, isObscure: true, hint: '비밀번호 입력'),
              _buildInput('이름', _nameController, hint: '본인 이름 입력'),
              _buildInput('휴대폰 번호', _phoneController, hint: "'-' 구분 없이 입력"),
              _buildInput('생년월일', _birthController, hint: '8자리 입력'),
              _buildInput('주소', _addressController, hint: '주소 입력'),

              const SizedBox(height: 40),
              
              SizedBox(
                height: 56, 
                child: ElevatedButton(
                  onPressed: _registerUser, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainBlue ?? Colors.blueAccent, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
                    elevation: 0,
                  ),
                  child: const Text('회원가입 하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {String? hint, bool isObscure = false, bool isId = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isObscure,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hint, 
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12), 
                  ),
                ),
              ),
              if (isId) ...[
                const SizedBox(width: 16),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    // 💡 수정 완료: 드디어 껍데기 버튼에 새 생명을 불어넣었습니다!
                    onPressed: _checkIdDuplicate, 
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('중복확인', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}