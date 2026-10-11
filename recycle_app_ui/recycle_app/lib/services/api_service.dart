import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/inspection.dart';
import '../models/stats_data.dart';
import '../models/user_data.dart';
import '../data/mock_data.dart' show mockInspections, mockStats, mockUser;

// ── EC2 서버 주소 ──────────────────────────────────────
// 실제 서버 IP 로 교체하세요.
const _base = 'http://YOUR_EC2_IP/api';

// 개발 중 실서버 없이 mock 데이터로 실행하려면 true 로 설정하세요.
const _useMock = true;
// ───────────────────────────────────────────────────────

class ApiService {
  // ─────────────────────────────────────────────
  // 검수 이력 목록
  // GET $_base/history?limit=50
  //
  // 응답 JSON:
  // {
  //   "count": 6,
  //   "records": [
  //     {
  //       "id": "uuid",
  //       "date": "2026-09-29T14:20:00.000Z",
  //       "itemType": "plastic_pet",
  //       "contaminated": false,
  //       "reason": "라벨 미제거",
  //       "imageUrl": null
  //     }
  //   ]
  // }
  // ─────────────────────────────────────────────
  static Future<List<Inspection>> getInspections() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockInspections;
    }

    final res = await http.get(Uri.parse('$_base/history?limit=50'));
    if (res.statusCode != 200) throw Exception('history 요청 실패 (${res.statusCode})');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['records'] as List)
        .map((e) => Inspection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────
  // 통계 데이터
  // GET $_base/statistics
  //
  // 응답 JSON:
  // {
  //   "total": 50,
  //   "contaminated": 10,
  //   "contaminationRate": 20.0,
  //   "byItemType": { "plastic_pet": 23, "can": 12, "glass": 15 }
  // }
  // ─────────────────────────────────────────────
  static Future<StatsData> getStats() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockStats;
    }

    final res = await http.get(Uri.parse('$_base/statistics'));
    if (res.statusCode != 200) throw Exception('statistics 요청 실패 (${res.statusCode})');
    return StatsData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────
  // 사용자 정보
  // GET $_base/user
  //
  // 응답 JSON:
  // {
  //   "name": "사용자",
  //   "joinedDays": 1,
  //   "monthCount": 6,
  //   "passRate": 83,
  //   "points": 50,
  //   "monthPoints": 50,
  //   "grade": "새싹 등급",
  //   "improvementMessage": null,
  //   "notifReturn": true,
  //   "notifWeekly": false
  // }
  // ─────────────────────────────────────────────
  static Future<UserData> getUser() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockUser;
    }

    final res = await http.get(Uri.parse('$_base/user'));
    if (res.statusCode != 200) throw Exception('user 요청 실패 (${res.statusCode})');
    return UserData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
