import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/constants.dart';
import '../../models/contact.dart';
import '../../services/storage/storage_service.dart';

final contactsControllerProvider =
    StateNotifierProvider<ContactsController, List<Contact>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ContactsController(storage);
});

final emergencyContactsProvider = Provider<List<Contact>>((ref) {
  final contacts = ref.watch(contactsControllerProvider);
  return contacts.where((contact) => contact.isEmergency).toList();
});

class ContactsController extends StateNotifier<List<Contact>> {
  ContactsController(this._storage) : super(_storage.loadContacts());

  final StorageService _storage;

  Future<void> addContact(Contact contact) async {
    final normalized = _normalizePhone(contact.phone);
    final existingIndex = state.indexWhere(
      (item) => _normalizePhone(item.phone) == normalized,
    );
    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final updated = contact.copyWith(
        id: existing.id,
        isEmergency: existing.isEmergency,
      );
      state = [
        for (final item in state)
          if (item.id == existing.id) updated else item,
      ];
    } else {
      state = [...state, contact];
    }
    await _storage.saveContacts(state);
  }

  Future<int> mergeContacts(List<Contact> contacts) async {
    final existingPhones = state.map((c) => _normalizePhone(c.phone)).toSet();
    final newContacts = <Contact>[];
    for (final contact in contacts) {
      final normalized = _normalizePhone(contact.phone);
      if (normalized.isEmpty || existingPhones.contains(normalized)) {
        continue;
      }
      newContacts.add(contact);
      existingPhones.add(normalized);
    }
    if (newContacts.isEmpty) {
      return 0;
    }
    state = [...state, ...newContacts];
    await _storage.saveContacts(state);
    return newContacts.length;
  }

  Future<void> updateContact(Contact contact) async {
    state = [
      for (final existing in state)
        if (existing.id == contact.id) contact else existing,
    ];
    await _storage.saveContacts(state);
  }

  Future<bool> setEmergency(String id, bool isEmergency) async {
    final index = state.indexWhere((contact) => contact.id == id);
    if (index == -1) {
      return false;
    }
    final current = state[index];
    if (isEmergency && !current.isEmergency) {
      final count = state.where((c) => c.isEmergency).length;
      if (count >= AppLimits.maxEmergencyContacts) {
        return false;
      }
    }
    state = [
      for (final contact in state)
        if (contact.id == id)
          contact.copyWith(isEmergency: isEmergency)
        else
          contact,
    ];
    await _storage.saveContacts(state);
    return true;
  }

  Future<void> removeContact(String id) async {
    state = state.where((contact) => contact.id != id).toList();
    await _storage.saveContacts(state);
  }

  void loadContacts() {
    state = _storage.loadContacts();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
