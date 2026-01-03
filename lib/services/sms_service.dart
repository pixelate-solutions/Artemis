import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/contact.dart';

class SmsService {
  Future<void> send({
    required String backendUrl,
    required List<Contact> contacts,
    required String message,
  }) async {
    final uri = Uri.parse('$backendUrl/send-sms');
    final payload = {
      'contacts': contacts
          .map((contact) => {'name': contact.name, 'phone': contact.phone})
          .toList(),
      'message': message,
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Backend responded with ${response.statusCode}');
    }
  }
}
