import 'package:hive_flutter/hive_flutter.dart';

import '../../models/contact.dart';
import '../../models/settings.dart';

class StorageService {
  static const String _settingsBox = 'settings_box';
  static const String _contactsBox = 'contacts_box';
  static const String _devicesBox = 'devices_box';

  static const String _settingsKey = 'settings';
  static const String _contactsKey = 'contacts';
  static const String _deviceNamesKey = 'device_names';
  static const String _lastDeviceIdKey = 'last_device_id';

  late final Box _settings;
  late final Box _contacts;
  late final Box _devices;

  Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox(_settingsBox);
    _contacts = await Hive.openBox(_contactsBox);
    _devices = await Hive.openBox(_devicesBox);
  }

  AppSettings loadSettings() {
    final raw = _settings.get(_settingsKey) as Map?;
    if (raw == null) {
      return AppSettings();
    }
    return AppSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settings.put(_settingsKey, settings.toMap());
  }

  List<Contact> loadContacts() {
    final raw = _contacts.get(_contactsKey) as List?;
    if (raw == null) {
      return [];
    }
    return raw
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final data = contacts.map((contact) => contact.toMap()).toList();
    await _contacts.put(_contactsKey, data);
  }

  String? getDeviceNickname(String deviceId) {
    final map = _devices.get(_deviceNamesKey) as Map?;
    if (map == null) {
      return null;
    }
    return Map<String, dynamic>.from(map)[deviceId] as String?;
  }

  Future<void> saveDeviceNickname(String deviceId, String nickname) async {
    final map = _devices.get(_deviceNamesKey) as Map?;
    final data = Map<String, dynamic>.from(map ?? {});
    data[deviceId] = nickname;
    await _devices.put(_deviceNamesKey, data);
  }

  String? getLastDeviceId() {
    return _devices.get(_lastDeviceIdKey) as String?;
  }

  Future<void> saveLastDeviceId(String? deviceId) async {
    if (deviceId == null) {
      await _devices.delete(_lastDeviceIdKey);
      return;
    }
    await _devices.put(_lastDeviceIdKey, deviceId);
  }
}
