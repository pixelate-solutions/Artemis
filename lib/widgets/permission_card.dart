import 'package:flutter/material.dart';

import 'glass_card.dart';
import 'buttons.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Grant Permissions',
                  onPressed: onRequest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: 'Open Settings',
                  onPressed: onOpenSettings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
