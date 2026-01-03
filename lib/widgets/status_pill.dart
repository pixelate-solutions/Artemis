import 'package:flutter/material.dart';

import '../app/constants.dart';

enum StatusPillType {
  connected,
  scanning,
  disconnected,
  error,
}

class AnimatedStatusPill extends StatelessWidget {
  const AnimatedStatusPill({
    super.key,
    required this.label,
    required this.type,
  });

  final String label;
  final StatusPillType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      StatusPillType.connected => AppColors.accent,
      StatusPillType.scanning => AppColors.primary,
      StatusPillType.error => Colors.redAccent,
      StatusPillType.disconnected => Colors.grey,
    };
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
