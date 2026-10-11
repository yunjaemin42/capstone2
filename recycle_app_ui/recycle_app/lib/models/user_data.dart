// GET /api/user  응답 모델
// Backend JSON 예시:
// {
//   "name":               "조현준",
//   "joinedDays":         42,
//   "monthCount":         32,       // 이번 달 투입 횟수
//   "passRate":           84,       // 통과율 (%)
//   "points":             1240,     // 누적 포인트
//   "monthPoints":        320,      // 이번 달 획득 포인트
//   "grade":              "새싹 등급", // 사용자 등급
//   "improvementMessage": "라벨 미제거 반환이 지난달보다 60% 줄었어요", // null 가능
//   "notifReturn":        true,     // 반환 알림 수신 여부
//   "notifWeekly":        false     // 주간 리포트 수신 여부
// }

class UserData {
  final String name;
  final int joinedDays;          // 가입 후 경과 일수
  final int monthCount;          // 이번 달 투입 횟수
  final int passRate;            // 이번 달 통과율 (%)
  final int points;              // 누적 포인트
  final int monthPoints;         // 이번 달 획득 포인트
  final String grade;            // 사용자 등급 (예: 새싹 등급)
  final String? improvementMessage; // 개선 안내 문구 (없으면 null → 카드 숨김)
  final bool notifReturn;        // 반환 알림 수신 여부
  final bool notifWeekly;        // 주간 리포트 수신 여부

  const UserData({
    required this.name,
    required this.joinedDays,
    required this.monthCount,
    required this.passRate,
    required this.points,
    required this.monthPoints,
    required this.grade,
    this.improvementMessage,
    required this.notifReturn,
    required this.notifWeekly,
  });

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
        name: j['name'] as String,
        joinedDays: j['joinedDays'] as int,
        monthCount: j['monthCount'] as int,
        passRate: j['passRate'] as int,
        points: j['points'] as int,
        monthPoints: j['monthPoints'] as int,
        grade: j['grade'] as String,
        improvementMessage: j['improvementMessage'] as String?,
        notifReturn: j['notifReturn'] as bool,
        notifWeekly: j['notifWeekly'] as bool,
      );
}
