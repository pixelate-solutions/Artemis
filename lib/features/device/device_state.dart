import '../../models/ble_device.dart';
import '../../services/permissions/permission_service.dart';

enum BleConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  subscribed,
}

class DeviceState {
  DeviceState({
    required this.status,
    required this.bluetoothOn,
    required this.devices,
    this.connectedDevice,
    this.lastPayload,
    this.error,
    this.batteryLevel,
    this.permissionSummary,
    this.lastSeen,
  });

  final BleConnectionStatus status;
  final bool bluetoothOn;
  final List<BleDeviceInfo> devices;
  final BleDeviceInfo? connectedDevice;
  final String? lastPayload;
  final String? error;
  final int? batteryLevel;
  final PermissionStatusSummary? permissionSummary;
  final DateTime? lastSeen;

  DeviceState copyWith({
    BleConnectionStatus? status,
    bool? bluetoothOn,
    List<BleDeviceInfo>? devices,
    BleDeviceInfo? connectedDevice,
    String? lastPayload,
    String? error,
    int? batteryLevel,
    PermissionStatusSummary? permissionSummary,
    DateTime? lastSeen,
  }) {
    return DeviceState(
      status: status ?? this.status,
      bluetoothOn: bluetoothOn ?? this.bluetoothOn,
      devices: devices ?? this.devices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      lastPayload: lastPayload ?? this.lastPayload,
      error: error ?? this.error,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      permissionSummary: permissionSummary ?? this.permissionSummary,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory DeviceState.initial() {
    return DeviceState(
      status: BleConnectionStatus.disconnected,
      bluetoothOn: true,
      devices: const [],
    );
  }
}
