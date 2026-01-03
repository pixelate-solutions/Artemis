import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../app/providers.dart';
import '../../features/settings/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/permission_card.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/formatters.dart';
import 'device_controller.dart';
import 'device_state.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(deviceControllerProvider.notifier).refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceControllerProvider);
    final controller = ref.read(deviceControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);

    final permission = deviceState.permissionSummary;
    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final bluetoothGranted = permission?.bluetoothGranted ?? false;
    final locationGranted = permission?.locationGranted ?? false;
    final canScan =
        isApple ? bluetoothGranted : bluetoothGranted && locationGranted;
    final permissionSubtitle = permission?.permanentlyDenied == true
        ? 'Permissions are disabled. Enable Bluetooth and location access in Settings.'
        : isApple
            ? 'Bluetooth permission is required to scan. Location access is used for emergency alerts.'
            : 'Bluetooth and location permissions are required to scan for your safety button.';

    final statusLabel = switch (deviceState.status) {
      BleConnectionStatus.scanning => 'Scanning',
      BleConnectionStatus.connecting => 'Connecting',
      BleConnectionStatus.connected => 'Connected',
      BleConnectionStatus.subscribed => 'Subscribed',
      BleConnectionStatus.disconnected => 'Disconnected',
    };

    final statusPillType = switch (deviceState.status) {
      BleConnectionStatus.scanning => StatusPillType.scanning,
      BleConnectionStatus.connected || BleConnectionStatus.subscribed =>
        StatusPillType.connected,
      _ => StatusPillType.disconnected,
    };

    return AppScaffold(
      appBar: GlassAppBar(
        title: 'Device',
        actions: [
          IconButton(
            onPressed: controller.refreshPermissions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                      'Connection Status',
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
                AnimatedStatusPill(label: statusLabel, type: statusPillType),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!deviceState.bluetoothOn)
            GlassCard(
              child: Text(
                'Bluetooth is off. Please enable Bluetooth to scan and connect.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (deviceState.error != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              child: Text(
                deviceState.error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!canScan)
            PermissionCard(
              title: 'Permission Required',
              subtitle: permissionSubtitle,
              onRequest: controller.requestPermissions,
              onOpenSettings:
                  ref.read(permissionServiceProvider).openSettings,
            ),
          if (canScan && !locationGranted) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Text(
                'Location access is required to share live location during emergencies.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Start Scan',
                    onPressed:
                        deviceState.bluetoothOn ? controller.startScan : null,
                    icon: Icons.search,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: 'Stop Scan',
                    onPressed: controller.stopScan,
                    icon: Icons.stop_circle_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Disconnect',
                    onPressed: controller.disconnect,
                    icon: Icons.link_off,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        settings.demoMode ? controller.simulatePanic : null,
                    icon: const Icon(Icons.warning_rounded, size: 18),
                    label: const Text('Demo PANIC'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (deviceState.connectedDevice != null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected Device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(deviceState.connectedDevice!.name),
                  const SizedBox(height: 4),
                  Text('ID: ${deviceState.connectedDevice!.id}'),
                  const SizedBox(height: 4),
                  Text(
                    'Last seen ${formatTimestampFromDate(deviceState.connectedDevice!.lastSeen)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceState.batteryLevel == null
                        ? 'Battery: Unknown'
                        : 'Battery: ${deviceState.batteryLevel}%',
                  ),
                  const SizedBox(height: 4),
                  if (deviceState.lastPayload != null)
                    Text('Last payload: ${deviceState.lastPayload}'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Nearby Devices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (deviceState.devices.isEmpty)
            GlassCard(
              child: Text(
                'No devices yet. Tap Start Scan to search for your button.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            ...deviceState.devices.map((device) {
              final isConnected =
                  deviceState.connectedDevice?.id == device.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeviceTile(
                  device: device,
                  isConnected: isConnected,
                  onConnect: () => controller.connectToDevice(device.id),
                  onDisconnect: isConnected ? controller.disconnect : null,
                  onRename: () => _showRenameDialog(context, device.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, String deviceId) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Device Nickname'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter a nickname'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(deviceControllerProvider.notifier)
                      .updateNickname(deviceId, name);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
