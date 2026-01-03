import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location/location_service.dart';
import '../services/ble/ble_service.dart';
import '../services/contacts/contacts_service.dart';
import '../services/permissions/permission_service.dart';
import '../services/sms_service.dart';
import '../services/storage/event_log_db.dart';
import '../services/storage/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden');
});

final eventLogDbProvider = Provider<EventLogDatabase>((ref) {
  throw UnimplementedError('EventLogDatabase must be overridden');
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

final contactsServiceProvider = Provider<ContactsService>((ref) {
  return ContactsService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});
