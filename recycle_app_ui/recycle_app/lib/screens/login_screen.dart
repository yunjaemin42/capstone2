import 'package:flutter/material.dart';
import '../theme.dart';
import 'main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _keepLogin = false;
  bool _obscurePw = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _login() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 72),

              // ── 로고 ────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('뚝딱뚝딱', style: ts(28, weight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      '올바른 분리배출, AI가 함께 확인해요',
                      style: ts(14, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ── 이메일 ───────────────────────────────────────
              AuthField(
                controller: _emailCtrl,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // ── 비밀번호 ─────────────────────────────────────
              AuthField(
                controller: _pwCtrl,
                hint: '비밀번호를 입력해주세요',
                obscure: _obscurePw,
                suffix: VisibilityToggle(
                  visible: !_obscurePw,
                  onTap: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              const SizedBox(height: 10),

              // ── 로그인 상태 유지 + 비밀번호 찾기 ──────────────
              Row(
                children: [
                  AuthCheckbox(
                    value: _keepLogin,
                    onChanged: (v) =>
                        setState(() => _keepLogin = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _keepLogin = !_keepLogin),
                    child: Text(
                      '로그인 상태 유지',
                      style: ts(13, color: AppColors.gray),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '비밀번호 찾기',
                      style: ts(13, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── 로그인 버튼 ──────────────────────────────────
              FilledButton(
                onPressed: _login,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '로그인',
                  style:
                      ts(16, weight: FontWeight.w700, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 32),

              // ── 회원가입 링크 ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '아직 회원이 아신가요?  ',
                    style: ts(14, color: AppColors.gray),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SignUpScreen()),
                    ),
                    child: Text(
                      '회원가입',
                      style: ts(14,
                          weight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 공통 위젯 ────────────────────────────────────────────────

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: ts(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ts(15, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}

class VisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const VisibilityToggle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.muted,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

class AuthCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const AuthCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.dark,
        checkColor: AppColors.white,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
