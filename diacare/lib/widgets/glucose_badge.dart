import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class GlucoseBadge extends StatelessWidget {
  final String status;

  const GlucoseBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bgColor;
    Color textColor;
    String label = status;

    if (lower.contains('low') || lower.contains('hypo')) {
      bgColor = AppColors.danger.withValues(alpha: 0.15);
      textColor = AppColors.danger;
      label = 'Low Glucose';
    } else if (lower.contains('high') || lower.contains('elevated')) {
      bgColor = AppColors.warning.withValues(alpha: 0.18);
      textColor = const Color(0xFFD97706);
      label = 'High Glucose';
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
      label = 'In Target';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
