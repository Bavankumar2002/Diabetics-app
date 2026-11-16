import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class NutrientProgressBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final String unit;
  final Color progressColor;
  final bool isCompact;

  const NutrientProgressBar({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    this.unit = 'g',
    required this.progressColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).round();

    final valueText = isCompact
        ? '${consumed.toStringAsFixed(consumed % 1 == 0 ? 0 : 1)}/${goal.toStringAsFixed(0)} $unit'
        : '${consumed.toStringAsFixed(1)} / ${goal.toStringAsFixed(0)} $unit ($percentage%)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                valueText,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: isCompact ? 6 : 8,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
