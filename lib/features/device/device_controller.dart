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
  BluetoothCharacteristic? _notifyChar;

  final Map<String, BluetoothDevice> _deviceMap = {};
  BluetoothDevice? _connectedDevice;
  Timer? _reconnectTimer;
  Timer? _autoScanTimer;
  bool _autoReconnectTriggered = false;
  bool _manualDisconnect = false;
  String? _manualDisconnectId;
  String? _activeConnectionId;
  bool _autoScanEnabled = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  DateTime? _lastAutoScanAttempt;

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
    _scheduleAutoScan();
  }

  Future<void> requestPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final summary = await permissionService.requestBlePermissions();
    state = state.copyWith(permissionSummary: summary);
    _scheduleAutoScan();
  }

  Future<void> refreshPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final summary = await permissionService.checkBlePermissions();
    state = state.copyWith(permissionSummary: summary);
    _scheduleAutoScan();
  }

  void setAutoScanEnabled(bool enabled) {
    _autoScanEnabled = enabled;
    if (!enabled) {
      _autoScanTimer?.cancel();
      unawaited(stopScan());
      return;
    }
    _scheduleAutoScan();
  }

  Future<void> startScan() async {
    final hasPermissions = await _ensureBlePermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Permissions required to scan.',
      );
      return;
    }
    final adapterReady = await _ensureAdapterReady();
    if (!adapterReady) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: _adapterErrorMessage(_adapterState),
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
            lastDeviceId != _manualDisconnectId &&
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
          _scheduleAutoScan();
        }
      });
    } catch (error) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: _scanErrorMessage(error),
      );
      _scheduleAutoScan();
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
    _manualDisconnect = false;
    _manualDisconnectId = null;
    _activeConnectionId = deviceId;
    final hasPermissions = await _ensureBlePermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Permissions required to connect.',
      );
      return;
    }
    final adapterReady = await _ensureAdapterReady();
    if (!adapterReady) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: _adapterErrorMessage(_adapterState),
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
      if (_activeConnectionId != deviceId) {
        return;
      }
      if (connectionState == BluetoothConnectionState.disconnected) {
        final shouldReconnect = !_manualDisconnect;
        _manualDisconnect = false;
        state = state.copyWith(
          status: BleConnectionStatus.disconnected,
          clearConnectedDevice: true,
        );
        _connectedDevice = null;
        _notifyChar = null;
        _notifySub?.cancel();
        if (shouldReconnect) {
          _attemptAutoReconnect(deviceId);
        }
      }
      if (connectionState == BluetoothConnectionState.connected) {
        state = state.copyWith(status: BleConnectionStatus.connected);
      }
    });

    try {
      await ref
          .read(bleServiceProvider)
          .connect(device, timeout: const Duration(seconds: 12));
      if (_activeConnectionId != deviceId) {
        await ref.read(bleServiceProvider).disconnect(device, queue: false);
        return;
      }
      _connectedDevice = device;
      await ref.read(storageServiceProvider).saveLastDeviceId(deviceId);
      await _discoverAndSubscribe(device, deviceId);
    } catch (error) {
      state = state.copyWith(
        status: BleConnectionStatus.disconnected,
        error: 'Connect failed: $error',
      );
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    final deviceId =
        state.connectedDevice?.id ?? _connectedDevice?.remoteId.toString();
    _manualDisconnectId = deviceId;
    _activeConnectionId = null;
    try {
      await _notifyChar?.setNotifyValue(false);
    } catch (_) {}
    await _notifySub?.cancel();
    _notifySub = null;
    _notifyChar = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    state = state.copyWith(
      status: BleConnectionStatus.disconnected,
      clearConnectedDevice: true,
    );
    _connectedDevice = null;
    if (deviceId != null) {
      await ref.read(storageServiceProvider).saveLastDeviceId(null);
    }
    final device = _deviceMap[deviceId];
    if (device == null) {
      _scheduleAutoScan();
      return;
    }
    try {
      await ref.read(bleServiceProvider).disconnect(device, queue: false);
      _scheduleAutoScan();
    } catch (error) {
      state = state.copyWith(error: 'Disconnect failed: $error');
    }
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

  Future<void> _discoverAndSubscribe(
    BluetoothDevice device,
    String deviceId,
  ) async {
    if (_activeConnectionId != deviceId) {
      return;
    }
    try {
      final services = await ref.read(bleServiceProvider).discoverServices(device);
      if (_activeConnectionId != deviceId) {
        return;
      }
      final notifyService = services.firstWhere(
        (service) => service.uuid == Guid(BleUuids.service),
        orElse: () => throw StateError('Service not found'),
      );
      final notifyChar = notifyService.characteristics.firstWhere(
        (char) => char.uuid == Guid(BleUuids.notifyChar),
        orElse: () => throw StateError('Notify characteristic not found'),
      );

      await _notifySub?.cancel();
      _notifyChar = notifyChar;
      await notifyChar.setNotifyValue(true);
      _notifySub = notifyChar.onValueReceived.listen((value) {
        final payload = _decodePayload(value);
        _handlePayload(payload, _deviceId(device));
      });

      if (_activeConnectionId != deviceId) {
        return;
      }
      state = state.copyWith(status: BleConnectionStatus.subscribed);
      await _readBattery(services);
      final info = _deviceInfo(device);
      if (_activeConnectionId == deviceId) {
        state = state.copyWith(connectedDevice: info);
      }
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
    if (deviceId != 'SIMULATED' && _connectedDevice == null) {
      return;
    }
    state = state.copyWith(lastPayload: payload);
    if (_isCancelPayload(payload)) {
      ref.read(emergencyControllerProvider.notifier).handleCancelPayload();
      return;
    }
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

  bool _isCancelPayload(String payload) {
    if (payload.toUpperCase().contains('CANCEL')) {
      return true;
    }
    if (payload.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        final event = decoded['event']?.toString().toUpperCase();
        return event == 'CANCEL';
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
      _adapterState = adapterState;
      state = state.copyWith(
        bluetoothOn: adapterState == BluetoothAdapterState.on,
      );
      if (adapterState == BluetoothAdapterState.on) {
        _scheduleAutoScan();
      }
    });
  }

  Future<bool> _ensureAdapterReady() async {
    if (_adapterState == BluetoothAdapterState.on) {
      return true;
    }
    if (_adapterState == BluetoothAdapterState.unknown) {
      try {
        final next = await ref
            .read(bleServiceProvider)
            .adapterState
            .firstWhere((state) =>
                state == BluetoothAdapterState.on ||
                state == BluetoothAdapterState.off)
            .timeout(const Duration(seconds: 2));
        _adapterState = next;
        return next == BluetoothAdapterState.on;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  String _adapterErrorMessage(BluetoothAdapterState state) {
    return switch (state) {
      BluetoothAdapterState.off =>
        'Bluetooth is turned off. Turn it on and try again.',
      BluetoothAdapterState.unauthorized =>
        'Bluetooth permission denied. Enable it in Settings.',
      BluetoothAdapterState.unavailable =>
        'Bluetooth is unavailable on this device.',
      BluetoothAdapterState.turningOff =>
        'Bluetooth is turning off. Try again in a moment.',
      BluetoothAdapterState.turningOn ||
      BluetoothAdapterState.unknown =>
        'Bluetooth is starting up. Try again in a moment.',
      _ => 'Bluetooth is not ready yet.',
    };
  }

  String _scanErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('CBManagerStateUnknown')) {
      return 'Bluetooth is starting up. Try again in a moment.';
    }
    return 'Scan failed: $error';
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

  void _scheduleAutoScan() {
    if (!_autoScanEnabled) {
      return;
    }
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer(const Duration(milliseconds: 300), () {
      _autoScanIfReady();
    });
  }

  Future<void> _autoScanIfReady() async {
    if (!_autoScanEnabled) {
      return;
    }
    if (state.status == BleConnectionStatus.scanning ||
        state.status == BleConnectionStatus.connecting ||
        state.status == BleConnectionStatus.connected ||
        state.status == BleConnectionStatus.subscribed) {
      return;
    }
    final summary = state.permissionSummary;
    if (summary == null || !_hasScanPermissions(summary)) {
      return;
    }
    if (!state.bluetoothOn) {
      return;
    }
    final now = DateTime.now();
    if (_lastAutoScanAttempt != null &&
        now.difference(_lastAutoScanAttempt!) < const Duration(seconds: 8)) {
      return;
    }
    _lastAutoScanAttempt = now;
    await startScan();
  }

  void _dispose() {
    _scanSub?.cancel();
    _adapterSub?.cancel();
    _connectionSub?.cancel();
    _notifySub?.cancel();
    _notifyChar = null;
    _reconnectTimer?.cancel();
    _autoScanTimer?.cancel();
  }
}
