import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../widgets/glass_card.dart';
import 'emergency_controller.dart';
import 'emergency_state.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergency = ref.watch(emergencyControllerProvider);
    final controller = ref.read(emergencyControllerProvider.notifier);

    final title = switch (emergency.phase) {
      EmergencyPhase.countdown => 'EMERGENCY ACTIVATED',
      EmergencyPhase.sending => 'SENDING ALERT',
      EmergencyPhase.sent => 'ALERT SENT',
      EmergencyPhase.canceled => 'CANCELED',
      EmergencyPhase.error => 'ERROR',
      _ => 'EMERGENCY',
    };

    return WillPopScope(
      onWillPop: () async {
        return emergency.phase != EmergencyPhase.countdown &&
            emergency.phase != EmergencyPhase.sending;
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.55),
        body: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.transparent),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassCard(
                        borderRadius: 32,
                        child: Column(
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            if (emergency.phase == EmergencyPhase.countdown)
                              Text(
                                emergency.remainingSeconds.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              )
                            else if (emergency.statusText != null)
                              Text(
                                emergency.statusText!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            if (emergency.phase == EmergencyPhase.countdown) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Alert will be sent when timer hits 0',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (emergency.phase == EmergencyPhase.countdown)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: () async {
                                  await controller.cancel();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('CANCEL'),
                              ),
                            if (emergency.phase == EmergencyPhase.sent ||
                                emergency.phase == EmergencyPhase.error ||
                                emergency.phase == EmergencyPhase.canceled)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: () async {
                                  await controller.reset();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('DONE'),
                              ),
                            if (emergency.phase == EmergencyPhase.sent) ...[
                              const SizedBox(height: 20),
                              Text(
                                emergency.notifiedContacts.isEmpty
                                    ? 'No contacts configured'
                                    : 'Contacts notified',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              ...emergency.notifiedContacts.map((contact) {
                                return Text(
                                  '${contact.name} (${contact.phone})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
