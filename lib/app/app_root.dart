import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/emergency/emergency_controller.dart';
import '../features/emergency/emergency_state.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';
import '../features/settings/settings_controller.dart';

class ArtemisApp extends ConsumerStatefulWidget {
  const ArtemisApp({super.key});

  @override
  ConsumerState<ArtemisApp> createState() => _ArtemisAppState();
}

class _ArtemisAppState extends ConsumerState<ArtemisApp> {
  bool _emergencyVisible = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.listen<EmergencyState>(emergencyControllerProvider, (previous, next) {
      final shouldShow = next.phase == EmergencyPhase.countdown ||
          next.phase == EmergencyPhase.sending ||
          next.phase == EmergencyPhase.sent ||
          next.phase == EmergencyPhase.error ||
          next.phase == EmergencyPhase.canceled;
      if (shouldShow && !_emergencyVisible) {
        _emergencyVisible = true;
        router.push('/emergency').then((_) {
          _emergencyVisible = false;
        });
      }
    });
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Artemis',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
