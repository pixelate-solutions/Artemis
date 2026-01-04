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
    final bluetoothStatuses =
        await Future.wait(_bluetoothPermissions().map((perm) => perm.status));
    final bluetoothGranted =
        bluetoothStatuses.every((status) => status.isGranted);
    final locationStatus = await _locationPermission().status;
    final locationGranted = locationStatus.isGranted;
    final permanentlyDenied = bluetoothStatuses.any((status) => status.isPermanentlyDenied) ||
        locationStatus.isPermanentlyDenied;
    return PermissionStatusSummary(
      bluetoothGranted: bluetoothGranted,
      locationGranted: locationGranted,
      permanentlyDenied: permanentlyDenied,
    );
  }

  Future<PermissionStatusSummary> requestBlePermissions() async {
    final bluetoothResults = await _bluetoothPermissions().request();
    final bluetoothGranted =
        bluetoothResults.values.every((status) => status.isGranted);
    final locationStatus = await _requestLocationPermission();
    final locationGranted = locationStatus.isGranted;
    final permanentlyDenied =
        bluetoothResults.values.any((status) => status.isPermanentlyDenied) ||
            locationStatus.isPermanentlyDenied;
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

  List<Permission> _bluetoothPermissions() {
    if (Platform.isAndroid) {
      return [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];
    }
    return [
      Permission.bluetooth,
    ];
  }

  Permission _locationPermission() {
    if (Platform.isIOS || Platform.isMacOS) {
      return Permission.locationAlways;
    }
    return Permission.locationWhenInUse;
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await Permission.locationWhenInUse.request();
      return Permission.locationAlways.request();
    }
    return Permission.locationWhenInUse.request();
  }
}
