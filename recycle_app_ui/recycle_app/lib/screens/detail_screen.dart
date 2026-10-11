import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DetailScreen extends StatelessWidget {
  final Inspection data;
  const DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tip = data.reason != null ? defectTips[data.reason] : null;

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
                  Text('검수 상세', style: ts(17, weight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // 결함 이미지 (S3)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 190,
                      color: AppColors.line,
                      alignment: Alignment.center,
                      child: data.imageUrl != null
                          ? Image.network(data.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 190)
                          : Text('결함 이미지 (S3)',
                              style: ts(13,
                                  weight: FontWeight.w500,
                                  color: AppColors.muted)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(data.passed,
                        label: data.passed ? '통과' : '반환됨'),
                  ),
                  const SizedBox(height: 6),
                  Text(data.item, style: ts(22, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(fullDate(data.time),
                      style: ts(13, color: AppColors.muted)),

                  if (data.reason != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: gap([
                          Text('반환 사유',
                              style: ts(15, weight: FontWeight.w700)),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Text(data.reason!,
                                  style: ts(14, weight: FontWeight.w500)),
                            ],
                          ),
                        ], 12),
                      ),
                    ),
                  ],

                  if (tip != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      color: AppColors.greenBg,
                      borderColor: null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: gap([
                          Text('이렇게 버려주세요',
                              style: ts(15, weight: FontWeight.w700)),
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: AppColors.green,
                                    shape: BoxShape.circle),
                                child: Text('1',
                                    style: ts(12,
                                        weight: FontWeight.w700,
                                        color: AppColors.white)),
                              ),
                              const SizedBox(width: 10),
                              Text(tip, style: ts(14)),
                            ],
                          ),
                        ], 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('확인했어요',
                      style: ts(16,
                          weight: FontWeight.w700, color: AppColors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
