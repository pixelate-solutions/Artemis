import 'package:flutter/material.dart';

import '../models/ble_device.dart';
import 'glass_card.dart';
import 'rssi_bars.dart';
import 'formatters.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onConnect,
    required this.onRename,
    this.onDisconnect,
  });

  final BleDeviceInfo device;
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onRename;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final label = device.nickname?.isNotEmpty == true
        ? device.nickname!
        : device.name;
    final actionLabel = isConnected ? 'Disconnect' : 'Connect';
    final actionCallback = isConnected ? onDisconnect : onConnect;
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: onRename,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  device.id,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RssiBars(rssi: device.rssi),
                    const SizedBox(width: 8),
                    Text(
                      'RSSI ${device.rssi}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Last seen ${formatTimestampFromDate(device.lastSeen)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: actionCallback,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: isConnected ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
