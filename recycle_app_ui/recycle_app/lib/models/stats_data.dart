// GET /api/statistics  응답 모델
// Backend JSON 예시:
// {
//   "total": 50,
//   "contaminated": 10,
//   "contaminationRate": 20.0,
//   "byItemType": { "plastic_pet": 23, "can": 12, "glass": 15 }
// }

const _itemTypeLabel = <String, String>{
  'plastic_pet': '페트병',
  'can': '캔',
  'glass': '유리병',
  'paper': '종이',
};

class StatsData {
  final int total;               // 전체 투입 건수
  final int contaminated;        // 반환(오염) 건수
  final double contaminationRate; // 오염률 (0.0 ~ 100.0)
  final Map<String, int> byItemType; // 품목별 건수 (키: "plastic_pet" 등)

  const StatsData({
    required this.total,
    required this.contaminated,
    required this.contaminationRate,
    required this.byItemType,
  });

  factory StatsData.fromJson(Map<String, dynamic> j) => StatsData(
        total: j['total'] as int,
        contaminated: j['contaminated'] as int,
        contaminationRate: (j['contaminationRate'] as num).toDouble(),
        byItemType: Map<String, int>.from(
          (j['byItemType'] as Map)
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
        ),
      );

  /// byItemType의 키를 한글로 변환한 Map (UI 표시용)
  Map<String, int> get byItemTypeKo => {
        for (final e in byItemType.entries)
          (_itemTypeLabel[e.key] ?? e.key): e.value,
      };
}
