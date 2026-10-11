// 개발·테스트용 Mock 데이터 & 날짜 유틸
//
// 모델 클래스(Inspection, StatsData, UserData)는
// lib/models/ 에 정의되어 있으며, 하단 export 로 여기서도 사용 가능합니다.
// 화면 파일들의 import 경로를 바꾸지 않아도 됩니다.

export '../models/inspection.dart';
export '../models/stats_data.dart';
export '../models/user_data.dart';

import '../models/inspection.dart';
import '../models/stats_data.dart';
import '../models/user_data.dart';

// ─────────────────────────────────────────────
// 반환 사유별 안내 문구 (detail_screen 에서 사용)
// ─────────────────────────────────────────────
const Map<String, String> defectTips = {
  '라벨 미제거': '라벨을 떼어주세요',
  '내부 오염 감지': '내용물을 비우고 헹궈주세요',
  '뚜껑 미분리': '뚜껑을 분리해주세요',
};

// ─────────────────────────────────────────────
// Mock 검수 이력 (API 미연결 시 fallback)
// ─────────────────────────────────────────────
final List<Inspection> mockInspections = [
  Inspection(
    id: '1',
    item: '페트병',
    time: DateTime(2026, 9, 29, 14, 20),
    passed: false,
    reason: '라벨 미제거',
  ),
  Inspection(
    id: '2',
    item: '캔',
    time: DateTime(2026, 9, 29, 11, 5),
    passed: true,
  ),
  Inspection(
    id: '3',
    item: '페트병',
    time: DateTime(2026, 9, 29, 9, 12),
    passed: true,
  ),
  Inspection(
    id: '4',
    item: '유리병',
    time: DateTime(2026, 9, 28, 19, 42),
    passed: true,
  ),
  Inspection(
    id: '5',
    item: '페트병',
    time: DateTime(2026, 9, 28, 15, 30),
    passed: false,
    reason: '뚜껑 미분리',
  ),
  Inspection(
    id: '6',
    item: '캔',
    time: DateTime(2026, 9, 28, 8, 47),
    passed: true,
  ),
];

// Mock 통계 (API 미연결 시 fallback)
final StatsData mockStats = const StatsData(
  total: 54,
  contaminated: 8,
  contaminationRate: 14.8,
  byItemType: {'plastic_pet': 25, 'can': 15, 'glass': 10, 'paper': 4},
);

// Mock 사용자 (API 미연결 시 fallback)
final UserData mockUser = const UserData(
  name: '조현준',
  joinedDays: 42,
  monthCount: 32,
  passRate: 84,
  points: 1240,
  monthPoints: 320,
  grade: '새싹 등급',
  improvementMessage: '라벨 미제거 반환이 지난달보다 60% 줄었어요',
  notifReturn: true,
  notifWeekly: false,
);

// ─────────────────────────────────────────────
// 날짜 표시 유틸
// ─────────────────────────────────────────────
String _two(int n) => n.toString().padLeft(2, '0');

String hhmm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String fullDate(DateTime t) =>
    '${t.year}.${_two(t.month)}.${_two(t.day)} ${hhmm(t)}';

/// "오늘 14:20" / "어제 19:42" / "9월 27일"
String relativeTime(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘 ${hhmm(t)}';
  if (diff == 1) return '어제 ${hhmm(t)}';
  return '${t.month}월 ${t.day}일';
}

/// "오늘 · 9월 29일" / "어제 · 9월 28일" / "9월 27일"
String dayLabel(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = DateTime(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime(t.year, t.month, t.day)).inDays;
  final md = '${t.month}월 ${t.day}일';
  if (diff == 0) return '오늘 · $md';
  if (diff == 1) return '어제 · $md';
  return md;
}
