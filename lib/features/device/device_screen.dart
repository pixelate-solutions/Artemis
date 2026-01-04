import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../app/providers.dart';
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
    ref.read(deviceControllerProvider.notifier).setAutoScanEnabled(true);
  }

  @override
  void dispose() {
    ref.read(deviceControllerProvider.notifier).setAutoScanEnabled(false);
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
    ref.listen<DeviceState>(deviceControllerProvider, (previous, next) {
      final message = next.error;
      if (message != null && message != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
    final deviceState = ref.watch(deviceControllerProvider);
    final controller = ref.read(deviceControllerProvider.notifier);
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
            ? 'Bluetooth permission is required to scan. Location (Always) enables alerts when the app is closed.'
            : 'Bluetooth and location permissions are required to scan for your safety button.';

    final effectiveStatus =
        deviceState.connectedDevice == null &&
                deviceState.status == BleConnectionStatus.scanning
            ? BleConnectionStatus.disconnected
            : deviceState.status;

    final statusLabel = switch (effectiveStatus) {
      BleConnectionStatus.scanning => 'Scanning',
      BleConnectionStatus.connecting => 'Connecting',
      BleConnectionStatus.connected => 'Connected',
      BleConnectionStatus.subscribed => 'Subscribed',
      BleConnectionStatus.disconnected => 'Disconnected',
    };

    final statusPillType = switch (effectiveStatus) {
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
          const SizedBox(height: 12),
          if (!deviceState.bluetoothOn) ...[
            GlassCard(
              child: Text(
                'Bluetooth is off. Please enable Bluetooth to scan and connect.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!canScan) ...[
            PermissionCard(
              title: 'Permission Required',
              subtitle: permissionSubtitle,
              onRequest: controller.requestPermissions,
              onOpenSettings:
                  ref.read(permissionServiceProvider).openSettings,
            ),
            const SizedBox(height: 12),
          ],
          if (canScan && !locationGranted) ...[
            GlassCard(
              child: Text(
                isApple
                    ? 'Enable Location "Always" to share live location while the app is closed.'
                    : 'Location access is required to share live location during emergencies.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (deviceState.connectedDevice != null) ...[
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      label: 'Disconnect',
                      onPressed: controller.disconnect,
                      icon: Icons.link_off,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Nearby Devices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (deviceState.devices.isEmpty)
            GlassCard(
              child: Text(
                'Scanning automatically for nearby devices.',
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
