import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionStatusSummary {
  PermissionStatusSummary({
    required this.bluetoothGranted,
    required this.locationGranted,
    required this.permanentlyDenied,
  });

  final bool bluetoothGranted;
  final bool locationGranted;
  final bool permanentlyDenied;

  bool get allGranted => bluetoothGranted && locationGranted;
}

class AppPermissionStatus {
  AppPermissionStatus({
    required this.bluetoothGranted,
    required this.locationGranted,
    required this.contactsGranted,
    required this.permanentlyDenied,
  });

  final bool bluetoothGranted;
  final bool locationGranted;
  final bool contactsGranted;
  final bool permanentlyDenied;

  bool get allGranted => bluetoothGranted && locationGranted && contactsGranted;
}

class PermissionService {
  Future<PermissionStatusSummary> checkBlePermissions() async {
    final permissions = _permissions();
    final statuses = await Future.wait(permissions.map((perm) => perm.status));
    final bluetoothGranted = statuses.asMap().entries
        .where((entry) => _isBluetoothPermission(permissions[entry.key]))
        .every((entry) => entry.value.isGranted);
    final locationGranted = statuses.asMap().entries
        .where((entry) => _isLocationPermission(permissions[entry.key]))
        .every((entry) => entry.value.isGranted);
    final permanentlyDenied =
        statuses.any((status) => status.isPermanentlyDenied);
    return PermissionStatusSummary(
      bluetoothGranted: bluetoothGranted,
      locationGranted: locationGranted,
      permanentlyDenied: permanentlyDenied,
    );
  }

  Future<PermissionStatusSummary> requestBlePermissions() async {
    final permissions = _permissions();
    final results = await permissions.request();
    final bluetoothGranted = results.entries
        .where((entry) => _isBluetoothPermission(entry.key))
        .every((entry) => entry.value.isGranted);
    final locationGranted = results.entries
        .where((entry) => _isLocationPermission(entry.key))
        .every((entry) => entry.value.isGranted);
    final permanentlyDenied = results.values.any((status) => status.isPermanentlyDenied);
    return PermissionStatusSummary(
      bluetoothGranted: bluetoothGranted,
      locationGranted: locationGranted,
      permanentlyDenied: permanentlyDenied,
    );
  }

  Future<bool> checkContactsPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<AppPermissionStatus> checkAllPermissions() async {
    final ble = await checkBlePermissions();
    final contactsStatus = await Permission.contacts.status;
    final contactsGranted = contactsStatus.isGranted;
    return AppPermissionStatus(
      bluetoothGranted: ble.bluetoothGranted,
      locationGranted: ble.locationGranted,
      contactsGranted: contactsGranted,
      permanentlyDenied:
          ble.permanentlyDenied || contactsStatus.isPermanentlyDenied,
    );
  }

  Future<AppPermissionStatus> requestAllPermissions() async {
    final ble = await requestBlePermissions();
    final contactsStatus = await Permission.contacts.request();
    final contactsGranted = contactsStatus.isGranted;
    return AppPermissionStatus(
      bluetoothGranted: ble.bluetoothGranted,
      locationGranted: ble.locationGranted,
      contactsGranted: contactsGranted,
      permanentlyDenied:
          ble.permanentlyDenied || contactsStatus.isPermanentlyDenied,
    );
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  List<Permission> _permissions() {
    if (Platform.isAndroid) {
      return [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];
    }
    return [
      Permission.bluetooth,
      Permission.locationWhenInUse,
    ];
  }

  bool _isBluetoothPermission(Permission permission) {
    return permission == Permission.bluetooth ||
        permission == Permission.bluetoothScan ||
        permission == Permission.bluetoothConnect;
  }

  bool _isLocationPermission(Permission permission) {
    return permission == Permission.locationWhenInUse ||
        permission == Permission.location;
  }
}
