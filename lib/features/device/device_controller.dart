import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../app/providers.dart';
import '../../models/ble_device.dart';
import '../../services/permissions/permission_service.dart';
import '../emergency/emergency_controller.dart';
import '../settings/settings_controller.dart';
import 'device_state.dart';

final deviceControllerProvider =
    NotifierProvider<DeviceController, DeviceState>(DeviceController.new);

class DeviceController extends Notifier<DeviceState> {
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  final Map<String, BluetoothDevice> _deviceMap = {};
  BluetoothDevice? _connectedDevice;
  Timer? _reconnectTimer;
  bool _autoReconnectTriggered = false;

  @override
  DeviceState build() {
    _listenAdapter();
    _checkPermissions();
    ref.onDispose(_dispose);
    Future.microtask(_attemptInitialReconnect);
    return DeviceState.initial();
  }

  Future<void> _checkPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final summary = await permissionService.checkBlePermissions();
    state = state.copyWith(permissionSummary: summary);
  }

  Future<void> requestPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final summary = await permissionService.requestBlePermissions();
    state = state.copyWith(permissionSummary: summary);
  }

  Future<void> refreshPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final summary = await permissionService.checkBlePermissions();
    state = state.copyWith(permissionSummary: summary);
  }

  Future<void> startScan() async {
    if (!state.bluetoothOn) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Bluetooth is turned off.',
      );
      return;
    }
    final hasPermissions = await _ensureBlePermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Permissions required to scan.',
      );
      return;
    }

    state = state.copyWith(
      status: BleConnectionStatus.scanning,
      error: null,
      devices: [],
    );
    await _scanSub?.cancel();
    final bleService = ref.read(bleServiceProvider);

    _scanSub = bleService.scanResults.listen(
      (results) {
        final now = DateTime.now();
        final devices = <String, BleDeviceInfo>{};
        final settings = ref.read(settingsControllerProvider);
        final lastDeviceId = ref.read(storageServiceProvider).getLastDeviceId();
        for (final result in results) {
          final id = _deviceId(result.device);
          final name = _deviceName(result.device, result);
          final nickname = ref
              .read(storageServiceProvider)
              .getDeviceNickname(id);
          _deviceMap[id] = result.device;
          devices[id] = BleDeviceInfo(
            id: id,
            name: name,
            rssi: result.rssi,
            lastSeen: now,
            isConnectable: result.advertisementData.connectable,
            nickname: nickname,
          );
        }
        final sorted = devices.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
        state = state.copyWith(devices: sorted, lastSeen: now);
        if (settings.autoReconnect &&
            lastDeviceId != null &&
            devices.containsKey(lastDeviceId) &&
            state.status == BleConnectionStatus.scanning) {
          connectToDevice(lastDeviceId);
        }
      },
      onError: (error) {
        state = state.copyWith(
          status: BleConnectionStatus.disconnected,
          error: 'Scan error: $error',
        );
      },
    );

    try {
      await bleService.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(BleUuids.service)],
      );
      Future.delayed(const Duration(seconds: 11), () {
        if (state.status == BleConnectionStatus.scanning) {
          state = state.copyWith(status: BleConnectionStatus.disconnected);
        }
      });
    } catch (error) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Scan failed: $error',
      );
    }
  }

  bool _hasScanPermissions(PermissionStatusSummary summary) {
    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isApple
        ? summary.bluetoothGranted
        : summary.bluetoothGranted && summary.locationGranted;
  }

  Future<bool> _ensureBlePermissions() async {
    final summary = state.permissionSummary;
    if (summary == null || !_hasScanPermissions(summary)) {
      await requestPermissions();
    }
    final updated = state.permissionSummary;
    return updated != null && _hasScanPermissions(updated);
  }

  Future<void> stopScan() async {
    await ref.read(bleServiceProvider).stopScan();
    await _scanSub?.cancel();
    if (state.status == BleConnectionStatus.scanning) {
      state = state.copyWith(status: BleConnectionStatus.disconnected);
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    final hasPermissions = await _ensureBlePermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Permissions required to connect.',
      );
      return;
    }
    final device = _deviceMap[deviceId];
    if (device == null) {
      state = state.copyWith(error: 'Device not found');
      return;
    }
    state = state.copyWith(status: BleConnectionStatus.connecting, error: null);
    await stopScan();

    await _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected) {
        state = state.copyWith(status: BleConnectionStatus.disconnected);
        _connectedDevice = null;
        _notifySub?.cancel();
        _attemptAutoReconnect(deviceId);
      }
      if (connectionState == BluetoothConnectionState.connected) {
        state = state.copyWith(status: BleConnectionStatus.connected);
      }
    });

    try {
      await ref
          .read(bleServiceProvider)
          .connect(device, timeout: const Duration(seconds: 12));
      _connectedDevice = device;
      await ref.read(storageServiceProvider).saveLastDeviceId(deviceId);
      await _discoverAndSubscribe(device);
    } catch (error) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Connect failed: $error',
      );
    }
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    if (_connectedDevice == null) {
      return;
    }
    try {
      await ref.read(bleServiceProvider).disconnect(_connectedDevice!);
    } catch (_) {}
    _connectedDevice = null;
    state = state.copyWith(status: BleConnectionStatus.disconnected);
  }

  Future<void> updateNickname(String deviceId, String nickname) async {
    await ref.read(storageServiceProvider).saveDeviceNickname(deviceId, nickname);
    final updated = state.devices
        .map((device) => device.id == deviceId
            ? device.copyWith(nickname: nickname)
            : device)
        .toList();
    final connected = state.connectedDevice;
    state = state.copyWith(
      devices: updated,
      connectedDevice: connected?.id == deviceId
          ? connected?.copyWith(nickname: nickname)
          : connected,
    );
  }

  void simulatePanic() {
    _handlePayload('PANIC', 'SIMULATED');
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    try {
      final services = await ref.read(bleServiceProvider).discoverServices(device);
      final notifyService = services.firstWhere(
        (service) => service.uuid == Guid(BleUuids.service),
        orElse: () => throw StateError('Service not found'),
      );
      final notifyChar = notifyService.characteristics.firstWhere(
        (char) => char.uuid == Guid(BleUuids.notifyChar),
        orElse: () => throw StateError('Notify characteristic not found'),
      );

      await _notifySub?.cancel();
      await notifyChar.setNotifyValue(true);
      _notifySub = notifyChar.onValueReceived.listen((value) {
        final payload = _decodePayload(value);
        _handlePayload(payload, _deviceId(device));
      });

      state = state.copyWith(status: BleConnectionStatus.subscribed);
      await _readBattery(services);
      final info = _deviceInfo(device);
      state = state.copyWith(connectedDevice: info);
    } catch (error) {
      state = state.copyWith(
        status: BleConnectionStatus.connected,
        error: 'Subscribe failed: $error',
      );
    }
  }

  Future<void> _readBattery(List<BluetoothService> services) async {
    try {
      // TODO: Remove fallback once the device exposes the battery service.
      final service = services.firstWhere(
        (item) => item.uuid == Guid(BleUuids.batteryService),
        orElse: () => throw StateError('Battery service not found'),
      );
      final characteristic = service.characteristics.firstWhere(
        (item) => item.uuid == Guid(BleUuids.batteryLevelChar),
        orElse: () => throw StateError('Battery characteristic not found'),
      );
      final value = await characteristic.read();
      if (value.isNotEmpty) {
        state = state.copyWith(batteryLevel: value.first);
      }
    } catch (_) {
      state = state.copyWith(batteryLevel: null);
    }
  }

  BleDeviceInfo _deviceInfo(BluetoothDevice device) {
    final id = _deviceId(device);
    final nickname = ref.read(storageServiceProvider).getDeviceNickname(id);
    final name = _deviceName(device, null);
    return BleDeviceInfo(
      id: id,
      name: name,
      rssi: state.devices
              .firstWhere((item) => item.id == id, orElse: () => BleDeviceInfo(
                    id: id,
                    name: name,
                    rssi: -100,
                    lastSeen: DateTime.now(),
                    isConnectable: true,
                    nickname: nickname,
                  ))
              .rssi,
      lastSeen: DateTime.now(),
      isConnectable: true,
      nickname: nickname,
    );
  }

  void _handlePayload(String payload, String deviceId) {
    state = state.copyWith(lastPayload: payload);
    if (_isPanicPayload(payload)) {
      ref.read(emergencyControllerProvider.notifier).startSession(
            payload: payload,
            deviceId: deviceId,
          );
    }
  }

  bool _isPanicPayload(String payload) {
    if (payload.toUpperCase().contains('PANIC')) {
      return true;
    }
    if (payload.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        final event = decoded['event']?.toString().toUpperCase();
        return event == 'PANIC';
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  String _decodePayload(List<int> value) {
    try {
      return utf8.decode(value, allowMalformed: true).trim();
    } catch (_) {
      return value.map((byte) => byte.toRadixString(16)).join(' ');
    }
  }

  String _deviceName(BluetoothDevice device, ScanResult? result) {
    final name = device.platformName;
    if (name.isNotEmpty) {
      return name;
    }
    if (result != null && result.advertisementData.advName.isNotEmpty) {
      return result.advertisementData.advName;
    }
    return 'Unknown';
  }

  String _deviceId(BluetoothDevice device) {
    return device.remoteId.toString();
  }

  void _listenAdapter() {
    _adapterSub = ref.read(bleServiceProvider).adapterState.listen((adapterState) {
      state = state.copyWith(
        bluetoothOn: adapterState == BluetoothAdapterState.on,
      );
    });
  }

  void _attemptAutoReconnect(String deviceId) {
    final settings = ref.read(settingsControllerProvider);
    if (!settings.autoReconnect) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (state.status == BleConnectionStatus.disconnected) {
        connectToDevice(deviceId);
      }
    });
  }

  void _attemptInitialReconnect() {
    if (_autoReconnectTriggered) {
      return;
    }
    final settings = ref.read(settingsControllerProvider);
    final lastDeviceId = ref.read(storageServiceProvider).getLastDeviceId();
    if (settings.autoReconnect && lastDeviceId != null) {
      _autoReconnectTriggered = true;
      startScan();
    }
  }

  void _dispose() {
    _scanSub?.cancel();
    _adapterSub?.cancel();
    _connectionSub?.cancel();
    _notifySub?.cancel();
    _reconnectTimer?.cancel();
  }
}
