import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

enum _Filter { all, passed, failed }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final all = mockInspections;
    final passedCount = all.where((e) => e.passed).length;
    final failedCount = all.length - passedCount;

    final list = all.where((e) {
      if (filter == _Filter.passed) return e.passed;
      if (filter == _Filter.failed) return !e.passed;
      return true;
    }).toList();

    // 날짜별로 묶기
    final groups = <String, List<Inspection>>{};
    for (final e in list) {
      groups.putIfAbsent(dayLabel(e.time), () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('검수 이력', style: ts(22, weight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          children: [
            _chip('전체 ${all.length}', _Filter.all),
            const SizedBox(width: 8),
            _chip('통과 $passedCount', _Filter.passed),
            const SizedBox(width: 8),
            _chip('반환 $failedCount', _Filter.failed),
          ],
        ),
        for (final entry in groups.entries) ...[
          const SizedBox(height: 16),
          Text(
            entry.key,
            style: ts(13, weight: FontWeight.w700, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: gap(
                entry.value
                    .map(
                      (e) => InspectionTile(
                        data: e,
                        subtitle: '${hhmm(e.time)} · ${e.bin}',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(data: e),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                14,
              ),
            ),
          ),
        ],
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text('기록이 없어요', style: ts(14, color: AppColors.muted)),
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, _Filter value) {
    final active = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.dark : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: AppColors.line),
        ),
        child: Text(
          label,
          style: ts(
            13,
            weight: FontWeight.w500,
            color: active ? AppColors.white : AppColors.gray,
          ),
        ),
      ),
    );
  }
}
