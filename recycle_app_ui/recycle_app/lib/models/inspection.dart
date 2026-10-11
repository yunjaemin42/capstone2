// GET /api/history  응답 record 모델
// Backend JSON 예시 (records 배열의 원소):
// {
//   "id": "uuid",
//   "date": "2026-09-29T14:20:00.000Z",
//   "itemType": "plastic_pet",
//   "contaminated": false,
//   "reason": "라벨 미제거",
//   "imageUrl": "https://s3.amazonaws.com/bucket/img.jpg"
// }

const _itemTypeLabel = <String, String>{
  'plastic_pet': '페트병',
  'can': '캔',
  'glass': '유리병',
  'paper': '종이',
};

class Inspection {
  final String id;
  final String item;    // 한글 표시명 (itemType 매핑: "plastic_pet" → "페트병" 등)
  final DateTime time;
  final bool passed;    // contaminated의 반전
  final String? reason; // 반환 사유 (정상이면 null)
  final String? imageUrl;

  const Inspection({
    required this.id,
    required this.item,
    required this.time,
    required this.passed,
    this.reason,
    this.imageUrl,
  });

  factory Inspection.fromJson(Map<String, dynamic> j) => Inspection(
        id: j['id'] as String,
        item: _itemTypeLabel[j['itemType']] ?? j['itemType'] as String,
        time: DateTime.parse(j['date'] as String).toLocal(),
        passed: !(j['contaminated'] as bool),
        reason: j['reason'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemType': item,
        'date': time.toIso8601String(),
        'contaminated': !passed,
        if (reason != null) 'reason': reason,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  /// 목록 아이콘에 표시할 첫 글자
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
