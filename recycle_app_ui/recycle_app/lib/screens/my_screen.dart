import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'points_history_screen.dart';

const _keyReturnAlert = 'notif_return_alert';
const _keyWeeklyReport = 'notif_weekly_report';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool returnAlert = true;
  bool weeklyReport = false;
  late Future<UserData> _future;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _load();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedReturn = prefs.getBool(_keyReturnAlert);
    final savedWeekly = prefs.getBool(_keyWeeklyReport);
    setState(() {
      if (savedReturn != null) returnAlert = savedReturn;
      if (savedWeekly != null) weeklyReport = savedWeekly;
    });
  }

  Future<void> _saveReturnAlert(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReturnAlert, value);
  }

  Future<void> _saveWeeklyReport(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyReport, value);
  }

  void _load() {
    _future = ApiService.getUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('데이터를 불러오지 못했어요', style: ts(14, color: AppColors.muted)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final user = snap.data!;
        final pointsStr = user.points.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );

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
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      user.name.length > 1
                          ? user.name.substring(1, 2)
                          : user.name,
                      style: ts(
                        20,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: ts(18, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          '가입 ${user.joinedDays}일 · 누적 ${user.monthCount}회',
                          style: ts(12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGradeTable(context, user.grade),
                    child: Pill(
                      user.grade,
                      fg: AppColors.green,
                      bg: AppColors.greenBg,
                    ),
                  ),
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
                  Text(
                    '보유 포인트',
                    style: ts(
                      13,
                      weight: FontWeight.w500,
                      color: AppColors.mint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pointsStr}P',
                    style: ts(
                      28,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '이번 달 +${user.monthPoints}P',
                        style: ts(13, color: AppColors.mint),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PointsHistoryScreen(
                              totalPoints: user.points,
                              monthPoints: user.monthPoints,
                            ),
                          ),
                        ),
                        child: Text(
                          '내역 보기 →',
                          style: ts(
                            13,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 개선 기록 (메시지가 있을 때만 표시)
            if (user.improvementMessage != null) ...[
              AppCard(
                color: AppColors.greenBg,
                borderColor: null,
                radius: 14,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  user.improvementMessage!,
                  style: ts(14, weight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 알림 설정
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('알림 설정', style: ts(15, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _switchRow(
                    '반환 알림',
                    returnAlert,
                    (v) {
                      setState(() => returnAlert = v);
                      _saveReturnAlert(v);
                    },
                  ),
                  _switchRow(
                    '주간 리포트',
                    weeklyReport,
                    (v) {
                      setState(() => weeklyReport = v);
                      _saveWeeklyReport(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 메뉴
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [_menu('분리배출 가이드')],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {},
              child: Text(
                '로그아웃',
                style: ts(13, weight: FontWeight.w500, color: AppColors.muted),
              ),
            ),
          ],
        );
      },
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
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.green,
          inactiveThumbColor: AppColors.white,
          inactiveTrackColor: AppColors.line,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }

  void _showGradeTable(BuildContext context, String currentGrade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GradeTableSheet(currentGrade: currentGrade),
    );
  }

  Widget _menu(String label) {
    return ListTile(
      dense: true,
      title: Text(label, style: ts(14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: () {},
    );
  }
}

// ─── 등급표 바텀시트 ────────────────────────────────────────
class _GradeTableSheet extends StatelessWidget {
  final String currentGrade;
  const _GradeTableSheet({required this.currentGrade});

  static const _grades = [
    ('새싹 등급', '분리배출 1 ~ 30회'),
    ('초록 등급', '분리배출 31 ~ 70회'),
    ('에코 등급', '분리배출 71 ~ 120회'),
    ('마스터 등급', '분리배출 121 ~ 200회'),
    ('에코마스터', '분리배출 201회 이상'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('등급표', style: ts(18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('분리배출 횟수에 따라 등급이 올라가요',
                style: ts(13, color: AppColors.muted)),
            const SizedBox(height: 16),
            for (final (name, condition) in _grades) ...[
              _GradeRow(
                name: name,
                condition: condition,
                isCurrent: name == currentGrade,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final String name;
  final String condition;
  final bool isCurrent;
  const _GradeRow(
      {required this.name, required this.condition, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.greenBg : AppColors.light,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent ? Border.all(color: AppColors.green) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: ts(14,
                        weight: FontWeight.w700,
                        color:
                            isCurrent ? AppColors.green : AppColors.dark)),
                const SizedBox(height: 2),
                Text(condition, style: ts(12, color: AppColors.muted)),
              ],
            ),
          ),
          if (isCurrent)
            Pill('현재', fg: AppColors.green, bg: AppColors.white),
        ],
      ),
    );
  }
}
