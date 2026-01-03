import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../settings/settings_controller.dart';
import 'emergency_controller.dart';
import 'emergency_state.dart';

class EmergencyHubScreen extends ConsumerWidget {
  const EmergencyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergency = ref.watch(emergencyControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(emergencyControllerProvider.notifier);

    final status = switch (emergency.phase) {
      EmergencyPhase.countdown => 'Countdown running',
      EmergencyPhase.sending => 'Sending alert',
      EmergencyPhase.sent => 'Alert sent',
      EmergencyPhase.canceled => 'Canceled',
      EmergencyPhase.error => 'Error',
      _ => 'Idle',
    };

    return AppScaffold(
      appBar: const GlassAppBar(title: 'Emergency'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Countdown: ${settings.countdownSeconds}s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this to simulate an emergency without BLE hardware.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Trigger Emergency',
                  onPressed: () => controller.startSession(
                    payload: 'PANIC',
                    deviceId: 'TEST',
                  ),
                  icon: Icons.warning_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
