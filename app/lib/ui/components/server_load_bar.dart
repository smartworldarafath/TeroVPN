import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';

class ServerLoadBar extends StatelessWidget {
  final int percentage;
  final bool showLabel;

  const ServerLoadBar({
    super.key,
    required this.percentage,
    this.showLabel = true,
  });

  Color get _tierColor {
    if (percentage < 60) return const Color(0xFF2CFFCC); // Green / Cyan
    if (percentage < 85) return const Color(0xFFFFB800); // Yellow
    return const Color(0xFFDC3251); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _tierColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _tierColor.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Text(
            '$percentage%',
            style: ProtonTypography.labelSmall.copyWith(
              color: ProtonColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
