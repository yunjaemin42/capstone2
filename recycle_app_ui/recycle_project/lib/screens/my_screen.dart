import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool returnAlert = true; // 반환 알림
  bool weeklyReport = false; // 주간 리포트

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('마이', style: ts(22, weight: FontWeight.w700)),
        const SizedBox(height: 16),

        // 프로필
        AppCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.green, shape: BoxShape.circle),
                child: Text(userName.substring(1, 2),
                    style: ts(20,
                        weight: FontWeight.w700, color: AppColors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: ts(18, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('가입 $joinedDays일 · 누적 $monthCount회',
                        style: ts(12, color: AppColors.muted)),
                  ],
                ),
              ),
              const Pill('새싹 등급', fg: AppColors.green, bg: AppColors.greenBg),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 포인트
        AppCard(
          color: AppColors.dark,
          borderColor: null,
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('보유 포인트',
                  style: ts(13, weight: FontWeight.w500, color: AppColors.mint)),
              const SizedBox(height: 6),
              Text('${points.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}P',
                  style: ts(28, weight: FontWeight.w900, color: AppColors.white)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('이번 달 +${monthPoints}P',
                      style: ts(13, color: AppColors.mint)),
                  GestureDetector(
                    onTap: () {}, // TODO: 포인트 내역 화면
                    child: Text('내역 보기 →',
                        style: ts(13,
                            weight: FontWeight.w700, color: AppColors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 개선 기록
        AppCard(
          color: AppColors.greenBg,
          borderColor: null,
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text('라벨 미제거 반환이 지난달보다 60% 줄었어요',
              style: ts(14, weight: FontWeight.w500)),
        ),
        const SizedBox(height: 16),

        // 알림 설정
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('알림 설정', style: ts(15, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              _switchRow('반환 알림', returnAlert,
                  (v) => setState(() => returnAlert = v)),
              _switchRow('주간 리포트', weeklyReport,
                  (v) => setState(() => weeklyReport = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 메뉴
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _menu('분리배출 가이드'),
              _menu('공지사항'),
              _menu('문의하기'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {}, // TODO: 로그아웃
          child: Text('로그아웃',
              style: ts(13, weight: FontWeight.w500, color: AppColors.muted)),
        ),
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ts(14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.white,
          activeTrackColor: AppColors.green,
          inactiveThumbColor: AppColors.white,
          inactiveTrackColor: AppColors.line,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }

  Widget _menu(String label) {
    return ListTile(
      dense: true,
      title: Text(label, style: ts(14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: () {}, // TODO: 각 메뉴 화면
    );
  }
}
