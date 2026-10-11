import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool weekly = true;

  @override
  Widget build(BuildContext context) {
    final counts = weekly ? weeklyCounts : monthlyCounts;
    final labels =
        weekly ? ['월', '화', '수', '목', '금', '토', '일'] : ['1주', '2주', '3주', '4주'];
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final total = counts.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('나의 통계', style: ts(22, weight: FontWeight.w700)),
        const SizedBox(height: 16),

        // 주간/월간 전환
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _seg('주간', weekly, () => setState(() => weekly = true)),
              const SizedBox(width: 4),
              _seg('월간', !weekly, () => setState(() => weekly = false)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 막대그래프
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(weekly ? '이번 주 투입' : '이번 달 투입',
                      style: ts(15, weight: FontWeight.w700)),
                  Text('총 $total회',
                      style: ts(13,
                          weight: FontWeight.w700, color: AppColors.green)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < counts.length; i++)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 26,
                            height: 110 * counts[i] / maxCount,
                            decoration: BoxDecoration(
                              color: counts[i] == maxCount
                                  ? AppColors.green
                                  : AppColors.mint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(labels[i],
                              style: ts(12,
                                  weight: FontWeight.w500,
                                  color: AppColors.muted)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 품목별 비율
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: gap([
              Text('품목별 비율', style: ts(15, weight: FontWeight.w700)),
              for (final e in itemRatios.entries)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: ts(14, weight: FontWeight.w500)),
                        Text('${(e.value * 100).round()}%',
                            style: ts(13,
                                weight: FontWeight.w700,
                                color: AppColors.gray)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value,
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
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.dark : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              style: ts(13,
                  weight: FontWeight.w700,
                  color: active ? AppColors.white : AppColors.muted)),
        ),
      ),
    );
  }
}
