import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart' show AuthField, AuthCheckbox, VisibilityToggle;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  bool _emailChecked = false;
  bool _obscurePw = true;
  bool _obscurePwConfirm = true;

  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeNotif = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  void _syncAll() {
    final all = _agreeTerms && _agreePrivacy && _agreeNotif;
    if (all != _agreeAll) setState(() => _agreeAll = all);
  }

  void _toggleAll(bool? v) {
    final val = v ?? false;
    setState(() {
      _agreeAll = val;
      _agreeTerms = val;
      _agreePrivacy = val;
      _agreeNotif = val;
    });
  }

  bool get _canSubmit => _agreeTerms && _agreePrivacy;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    try {
      await ApiService.updateUser(
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
      );
    } catch (_) {
      // 전송 실패해도 가입 진행
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        backgroundColor: AppColors.light,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('회원가입', style: ts(17, weight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 이름 ────────────────────────────────────────
            _LabeledField(
              label: '이름',
              child: AuthField(
                controller: _nameCtrl,
                hint: '이름을 입력해주세요',
              ),
            ),
            const SizedBox(height: 20),

            // ── 이메일 + 중복확인 ────────────────────────────
            Text('이메일',
                style: ts(13, weight: FontWeight.w600, color: AppColors.gray)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AuthField(
                    controller: _emailCtrl,
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _emailChecked = true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.greenBg,
                      foregroundColor: AppColors.green,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(
                      '중복 확인',
                      style:
                          ts(13, weight: FontWeight.w600, color: AppColors.green),
                    ),
                  ),
                ),
              ],
            ),
            if (_emailChecked) ...[
              const SizedBox(height: 6),
              Text(
                '사용할 수 있는 이메일이에요',
                style: ts(12, color: AppColors.green),
              ),
            ],
            const SizedBox(height: 20),

            // ── 비밀번호 ─────────────────────────────────────
            Text('비밀번호',
                style: ts(13, weight: FontWeight.w600, color: AppColors.gray)),
            const SizedBox(height: 6),
            AuthField(
              controller: _pwCtrl,
              hint: '영문, 숫자 포함 8자 이상',
              obscure: _obscurePw,
              suffix: VisibilityToggle(
                visible: !_obscurePw,
                onTap: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '영문, 숫자 포함 8자 이상',
              style: ts(12, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            // ── 비밀번호 확인 ─────────────────────────────────
            _LabeledField(
              label: '비밀번호 확인',
              child: AuthField(
                controller: _pwConfirmCtrl,
                hint: '비밀번호를 한 번 더 입력해주세요',
                obscure: _obscurePwConfirm,
                suffix: VisibilityToggle(
                  visible: !_obscurePwConfirm,
                  onTap: () =>
                      setState(() => _obscurePwConfirm = !_obscurePwConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 약관 동의 카드 ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _TermsRow(
                    label: '전체 동의',
                    value: _agreeAll,
                    bold: true,
                    onChanged: _toggleAll,
                  ),
                  Divider(height: 1, thickness: 1, color: AppColors.line),
                  _TermsRow(
                    label: '[필수] 서비스 이용약관 동의',
                    value: _agreeTerms,
                    onChanged: (v) {
                      setState(() => _agreeTerms = v ?? false);
                      _syncAll();
                    },
                  ),
                  _TermsRow(
                    label: '[필수] 개인정보 수집 및 이용 동의',
                    value: _agreePrivacy,
                    onChanged: (v) {
                      setState(() => _agreePrivacy = v ?? false);
                      _syncAll();
                    },
                  ),
                  _TermsRow(
                    label: '[선택] 반환 알림 푸시 수신 동의',
                    value: _agreeNotif,
                    onChanged: (v) {
                      setState(() => _agreeNotif = v ?? false);
                      _syncAll();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── 가입하기 버튼 ─────────────────────────────────
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dark,
                disabledBackgroundColor: AppColors.line,
                foregroundColor: AppColors.white,
                disabledForegroundColor: AppColors.muted,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '가입하기',
                style: ts(16, weight: FontWeight.w700, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 헬퍼 위젯 ────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: ts(13, weight: FontWeight.w600, color: AppColors.gray)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool bold;
  final ValueChanged<bool?> onChanged;

  const _TermsRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AuthCheckbox(value: value, onChanged: onChanged),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: bold
                    ? ts(14, weight: FontWeight.w700)
                    : ts(13, color: AppColors.gray),
              ),
            ),
            if (!bold)
              Text('보기', style: ts(12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
