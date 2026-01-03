import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../features/contacts/contacts_controller.dart';
import '../../features/device/device_controller.dart';
import '../../features/device/device_state.dart';
import '../../features/emergency/emergency_controller.dart';
import '../../features/logs/logs_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/formatters.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_pill.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceControllerProvider);
    final contacts = ref.watch(emergencyContactsProvider);
    final logs = ref.watch(logsControllerProvider);

    final statusLabel = switch (deviceState.status) {
      BleConnectionStatus.scanning => 'Scanning',
      BleConnectionStatus.connecting => 'Connecting',
      BleConnectionStatus.connected => 'Connected',
      BleConnectionStatus.subscribed => 'Subscribed',
      BleConnectionStatus.disconnected => 'Disconnected',
    };

    final pillType = switch (deviceState.status) {
      BleConnectionStatus.scanning => StatusPillType.scanning,
      BleConnectionStatus.connected || BleConnectionStatus.subscribed =>
        StatusPillType.connected,
      _ => StatusPillType.disconnected,
    };

    final contactPreview = contacts.take(5).toList();

    return AppScaffold(
      appBar: const GlassAppBar(title: 'PRVNT'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deviceState.connectedDevice?.nickname ??
                          deviceState.connectedDevice?.name ??
                          'No device connected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                AnimatedStatusPill(label: statusLabel, type: pillType),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (contactPreview.isEmpty)
                  Text(
                    'No emergency contacts yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ...contactPreview.map((contact) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${contact.name} · ${contact.phone}'),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                logs.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return Text(
                        'No events logged yet.',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    final preview = events.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...preview.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${event.type} · ${formatTimestamp(event.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/logs'),
                          child: const Text('View All Events'),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Failed to load logs: $error'),
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
                  'Emergency',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Trigger emergency mode and notify your trusted contacts.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => ref
                        .read(emergencyControllerProvider.notifier)
                        .startSession(payload: 'PANIC', deviceId: 'MANUAL'),
                    child: const Text('Trigger Emergency'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
