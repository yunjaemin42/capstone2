import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';

/// 흰 배경 + 얇은 테두리 + 둥근 모서리 카드
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.borderColor = AppColors.line,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
  }
}

/// 작은 알약 모양 라벨 (통과/반환/등급 등)
class Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const Pill(this.text, {super.key, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: ts(12, weight: FontWeight.w700, color: fg)),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool passed;
  final String? label;
  const StatusBadge(this.passed, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Pill(
      label ?? (passed ? '통과' : '반환'),
      fg: passed ? AppColors.green : AppColors.red,
      bg: passed ? AppColors.greenBg : AppColors.redBg,
    );
  }
}

/// 제목 + 오른쪽 작은 글자 (예: 최근 검수 · 전체보기)
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: ts(17, weight: FontWeight.w700)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: ts(13, weight: FontWeight.w500, color: AppColors.muted)),
          ),
      ],
    );
  }
}

/// 검수 목록 한 줄
class InspectionTile extends StatelessWidget {
  final Inspection data;
  final String subtitle;
  final VoidCallback? onTap;
  const InspectionTile(
      {super.key, required this.data, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ok = data.passed;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ok ? AppColors.greenBg : AppColors.redBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(data.initial,
                style: ts(15,
                    weight: FontWeight.w700,
                    color: ok ? AppColors.green : AppColors.red)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.item, style: ts(15, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: ts(12, color: AppColors.muted)),
              ],
            ),
          ),
          StatusBadge(ok),
        ],
      ),
    );
  }
}

/// 위젯 사이에 간격을 끼워 넣는 도우미
List<Widget> gap(List<Widget> items, double space) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: space));
    out.add(items[i]);
  }
  return out;
}
