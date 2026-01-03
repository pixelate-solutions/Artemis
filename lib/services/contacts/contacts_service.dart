import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsService {
  Future<bool> requestPermission() async {
    return FlutterContacts.requestPermission();
  }

  Future<List<Contact>> fetchContacts() async {
    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      return [];
    }
    return FlutterContacts.getContacts(withProperties: true);
  }
}
