import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeAll;
  const HomeScreen({super.key, required this.onSeeAll});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<(List<Inspection>, UserData)> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      ApiService.getInspections(),
      ApiService.getUser(),
    ]).then((r) => (r[0] as List<Inspection>, r[1] as UserData));
  }

  void _openDetail(BuildContext context, Inspection data) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DetailScreen(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<Inspection>, UserData)>(
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

        final (inspections, user) = snap.data!;
        final recent = inspections.take(3).toList();
        final latestFail = inspections.where((e) => !e.passed).firstOrNull;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text('안녕하세요, ${user.name.substring(1)}님',
                style: ts(22, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('오늘도 올바른 분리배출 해볼까요?',
                style: ts(14, color: AppColors.gray)),
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
                      style: ts(13,
                          weight: FontWeight.w500, color: AppColors.mint)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Stat('${user.monthCount}회', '투입'),
                      _Stat('${user.passRate}%', '통과율'),
                      _Stat('${_comma(user.points)}P', '포인트'),
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
                          Text(relativeTime(latestFail.time),
                              style: ts(12, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          latestFail.reason != null
                              ? '${latestFail.reason}로 반환됐어요'
                              : '반환된 품목이 있어요',
                          style: ts(16, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(latestFail.item,
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
            SectionHeader('최근 검수',
                action: '전체보기', onAction: widget.onSeeAll),
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
      },
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

String _comma(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
