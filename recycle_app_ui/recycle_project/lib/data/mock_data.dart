/// 지금은 예시 데이터예요.
/// 나중에 백엔드(EC2) GET /api/history, /api/statistics 응답으로 이 부분만 바꾸면 됩니다.

class Defect {
  final String title; // 예: 라벨 미제거
  final String source; // 예: AI 이미지 판별
  const Defect(this.title, this.source);
}

class Inspection {
  final String id;
  final String item; // 페트병, 캔, 유리병, 종이
  final String bin; // 수거함 이름
  final DateTime time;
  final bool passed;
  final List<Defect> defects;
  final String? imageUrl; // S3 결함 이미지 URL (없으면 자리표시)

  const Inspection({
    required this.id,
    required this.item,
    required this.bin,
    required this.time,
    required this.passed,
    this.defects = const [],
    this.imageUrl,
  });

  /// 목록 아이콘에 들어갈 글자
  String get initial {
    switch (item) {
      case '페트병':
        return 'P';
      case '캔':
        return 'C';
      case '유리병':
        return 'G';
      case '종이':
        return 'R';
      default:
        return item.isNotEmpty ? item.substring(0, 1) : '?';
    }
  }
}

final List<Inspection> mockInspections = [
  Inspection(
    id: '1',
    item: '페트병',
    bin: '2번 수거함',
    time: DateTime(2026, 9, 29, 14, 20),
    passed: false,
    defects: const [
      Defect('라벨 미제거', 'AI 이미지 판별'),
      Defect('내부 오염 감지', 'UV 형광 · 무게 센서'),
    ],
  ),
  Inspection(
      id: '2',
      item: '캔',
      bin: '2번 수거함',
      time: DateTime(2026, 9, 29, 11, 5),
      passed: true),
  Inspection(
      id: '3',
      item: '페트병',
      bin: '1번 수거함',
      time: DateTime(2026, 9, 29, 9, 12),
      passed: true),
  Inspection(
      id: '4',
      item: '유리병',
      bin: '1번 수거함',
      time: DateTime(2026, 9, 28, 19, 42),
      passed: true),
  Inspection(
    id: '5',
    item: '페트병',
    bin: '2번 수거함',
    time: DateTime(2026, 9, 28, 15, 30),
    passed: false,
    defects: const [Defect('뚜껑 미분리', 'AI 이미지 판별')],
  ),
  Inspection(
      id: '6',
      item: '캔',
      bin: '1번 수거함',
      time: DateTime(2026, 9, 28, 8, 47),
      passed: true),
];

/// 결함 종류별 안내 문구
const Map<String, String> defectTips = {
  '라벨 미제거': '라벨을 떼어주세요',
  '내부 오염 감지': '내용물을 비우고 헹궈주세요',
  '뚜껑 미분리': '뚜껑을 분리해주세요',
};

/// 통계 예시 값
const weeklyCounts = [2, 3, 1, 4, 2, 5, 1]; // 월~일
const monthlyCounts = [12, 18, 9, 15]; // 1~4주
const itemRatios = {'페트병': 0.45, '캔': 0.25, '유리병': 0.18, '종이': 0.12};

/// 사용자 예시 값
const userName = '조현준';
const joinedDays = 42;
const monthCount = 32;
const passRate = 84;
const points = 1240;
const monthPoints = 320;

// ---- 날짜 표시 도우미 ----
String two(int n) => n.toString().padLeft(2, '0');
String hhmm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
String fullDate(DateTime t) =>
    '${t.year}.${two(t.month)}.${two(t.day)} ${hhmm(t)}';

/// "오늘 14:20" / "어제 19:42" / "9월 27일"
String relativeTime(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime(2026, 9, 29, 14, 30); // 시연용 기준 시각. 실제로는 DateTime.now()
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘 ${hhmm(t)}';
  if (diff == 1) return '어제 ${hhmm(t)}';
  return '${t.month}월 ${t.day}일';
}

String dayLabel(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime(2026, 9, 29, 14, 30);
  final diff = DateTime(n.year, n.month, n.day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  final md = '${t.month}월 ${t.day}일';
  if (diff == 0) return '오늘 · $md';
  if (diff == 1) return '어제 · $md';
  return md;
}
