import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Mock 포인트 내역 데이터
class _PointItem {
  final DateTime date;
  final String description;
  final int points; // 양수: 적립, 음수: 사용

  const _PointItem(this.date, this.description, this.points);
}

final _mockPointHistory = [
  _PointItem(DateTime(2026, 9, 29, 14, 20), '페트병 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 29, 11, 5), '캔 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 29, 9, 12), '페트병 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 28, 19, 42), '유리병 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 28, 8, 47), '캔 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 25, 13, 0), '포인트 사용', -100),
  _PointItem(DateTime(2026, 9, 22, 10, 30), '페트병 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 20, 16, 15), '유리병 통과 적립', 10),
  _PointItem(DateTime(2026, 9, 18, 9, 0), '캔 통과 적립', 10),
];

class PointsHistoryScreen extends StatelessWidget {
  final int totalPoints;
  final int monthPoints;

  const PointsHistoryScreen({
    super.key,
    required this.totalPoints,
    required this.monthPoints,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<_PointItem>>{};
    for (final e in _mockPointHistory) {
      groups.putIfAbsent(dayLabel(e.date), () => []).add(e);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 뒤로가기
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.dark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('포인트 내역', style: ts(17, weight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // 포인트 요약 카드
                  AppCard(
                    color: AppColors.dark,
                    borderColor: null,
                    radius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('보유 포인트',
                            style: ts(13,
                                weight: FontWeight.w500,
                                color: AppColors.mint)),
                        const SizedBox(height: 6),
                        Text(
                          '${_comma(totalPoints)}P',
                          style: ts(28,
                              weight: FontWeight.w900,
                              color: AppColors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이번 달 +${monthPoints}P 적립',
                          style: ts(13, color: AppColors.mint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 날짜별 내역
                  for (final entry in groups.entries) ...[
                    Text(entry.key,
                        style: ts(13,
                            weight: FontWeight.w700,
                            color: AppColors.muted)),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 16),
                      child: Column(
                        children: [
                          for (int i = 0; i < entry.value.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                  height: 1, color: AppColors.line),
                            _PointRow(item: entry.value[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final _PointItem item;
  const _PointRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isEarn = item.points > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description,
                  style: ts(14, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(hhmm(item.date),
                  style: ts(12, color: AppColors.muted)),
            ],
          ),
          Text(
            '${isEarn ? '+' : ''}${item.points}P',
            style: ts(15,
                weight: FontWeight.w700,
                color: isEarn ? AppColors.green : AppColors.red),
          ),
        ],
      ),
    );
  }
}

String _comma(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
