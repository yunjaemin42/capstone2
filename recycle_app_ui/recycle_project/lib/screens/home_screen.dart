import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSeeAll; // '전체보기' 누르면 이력 탭으로
  const HomeScreen({super.key, required this.onSeeAll});

  void _openDetail(BuildContext context, Inspection data) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    final recent = mockInspections.take(3).toList();
    final latestFail = mockInspections.where((e) => !e.passed).firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        // 인사말
        Text('안녕하세요, 현준님', style: ts(22, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('오늘도 올바른 분리배출 해볼까요?', style: ts(14, color: AppColors.gray)),
        const SizedBox(height: 16),

        // 이번 달 요약
        AppCard(
          color: AppColors.dark,
          borderColor: null,
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이번 달 나의 분리배출',
                  style: ts(13, weight: FontWeight.w500, color: AppColors.mint)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat('$monthCount회', '투입'),
                  _Stat('$passRate%', '통과율'),
                  _Stat('${_comma(points)}P', '포인트'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 최근 반환 알림
        if (latestFail != null) ...[
          GestureDetector(
            onTap: () => _openDetail(context, latestFail),
            child: AppCard(
              borderColor: AppColors.redLine,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatusBadge(false),
                      Text('10분 전', style: ts(12, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      latestFail.defects.isNotEmpty
                          ? '${latestFail.defects.first.title}로 반환됐어요'
                          : '반환된 품목이 있어요',
                      style: ts(16, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${latestFail.item} · ${latestFail.bin}',
                      style: ts(13, color: AppColors.gray)),
                  const SizedBox(height: 8),
                  Text('사유 확인하기 →',
                      style: ts(13,
                          weight: FontWeight.w700, color: AppColors.green)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 최근 검수
        SectionHeader('최근 검수', action: '전체보기', onAction: onSeeAll),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: gap(
              recent
                  .map((e) => InspectionTile(
                        data: e,
                        subtitle: relativeTime(e.time),
                        onTap: () => _openDetail(context, e),
                      ))
                  .toList(),
              14,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: ts(26, weight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 2),
        Text(label, style: ts(12, color: AppColors.mint)),
      ],
    );
  }
}

String _comma(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
