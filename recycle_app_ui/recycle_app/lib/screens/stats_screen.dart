import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<StatsData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiService.getStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatsData>(
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

        final stats = snap.data!;
        final passRate = stats.total > 0
            ? (100 - stats.contaminationRate).toStringAsFixed(1)
            : '0.0';
        final byItemKo = stats.byItemTypeKo;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text('나의 통계', style: ts(22, weight: FontWeight.w700)),
            const SizedBox(height: 16),

            // 전체 요약 카드
            AppCard(
              color: AppColors.dark,
              borderColor: null,
              radius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전체 분리배출 현황',
                      style: ts(13,
                          weight: FontWeight.w500, color: AppColors.mint)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Stat('${stats.total}회', '총 투입'),
                      _Stat('${stats.contaminated}회', '반환'),
                      _Stat('$passRate%', '통과율'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 품목별 투입 현황
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: gap([
                  Text('품목별 투입 현황', style: ts(15, weight: FontWeight.w700)),
                  for (final e in byItemKo.entries)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: ts(14, weight: FontWeight.w500)),
                            Text(
                              stats.total > 0
                                  ? '${(e.value / stats.total * 100).round()}%'
                                  : '0%',
                              style: ts(13,
                                  weight: FontWeight.w700,
                                  color: AppColors.gray),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stats.total > 0
                                ? e.value / stats.total
                                : 0,
                            minHeight: 8,
                            backgroundColor: AppColors.line,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                ], 14),
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
