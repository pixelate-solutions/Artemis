import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../models/settings.dart';
import '../../app/providers.dart';
import '../../services/permissions/permission_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  Future<AppPermissionStatus>? _permissionsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions(notify: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return AppScaffold(
      appBar: GlassAppBar(
        title: 'Settings',
        actions: [
          IconButton(
            onPressed: _refreshPermissions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FutureBuilder<AppPermissionStatus>(
            future: _permissionsFuture,
            builder: (context, snapshot) {
              final status = snapshot.data;
              final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS;
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _PermissionRow(
                      label: 'Bluetooth',
                      granted: status?.bluetoothGranted ?? false,
                    ),
                    _PermissionRow(
                      label: isApple ? 'Location (Always)' : 'Location',
                      granted: status?.locationGranted ?? false,
                    ),
                    _PermissionRow(
                      label: 'Contacts',
                      granted: status?.contactsGranted ?? false,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(permissionServiceProvider)
                                  .requestAllPermissions();
                              _refreshPermissions();
                            },
                            child: const Text('Request Permissions'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                ref.read(permissionServiceProvider).openSettings(),
                            child: const Text('Open Settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Countdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('${settings.countdownSeconds}s'),
                Slider(
                  value: settings.countdownSeconds.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  onChanged: (value) => controller.updateCountdown(value.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.mockMode,
                  onChanged: controller.updateMockMode,
                  title: const Text('Mock Mode'),
                  subtitle: const Text('Don\'t send real SMS alerts'),
                ),
                SwitchListTile(
                  value: settings.sendLocationUpdates,
                  onChanged: controller.updateSendLocationUpdates,
                  title: const Text('Location Updates'),
                  subtitle: const Text('Send location every 15s for 2 minutes'),
                ),
                SwitchListTile(
                  value: settings.autoReconnect,
                  onChanged: controller.updateAutoReconnect,
                  title: const Text('Auto-reconnect'),
                  subtitle: const Text('Reconnect to the last device automatically'),
                ),
                SwitchListTile(
                  value: settings.demoMode,
                  onChanged: controller.updateDemoMode,
                  title: const Text('Demo Mode'),
                  subtitle: const Text('Enable simulated PANIC events'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ThemePreference>(
                  value: settings.themePreference,
                  items: const [
                    DropdownMenuItem(
                      value: ThemePreference.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateTheme(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _refreshPermissions({bool notify = true}) {
    _permissionsFuture =
        ref.read(permissionServiceProvider).checkAllPermissions();
    if (notify && mounted) {
      setState(() {});
    }
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label, required this.granted});

  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            granted ? 'Granted' : 'Needed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: granted
                      ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                      : (isDark ? Colors.orangeAccent : Colors.orange.shade700),
                ),
          ),
        ],
      ),
    );
  }
}
