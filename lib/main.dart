import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_root.dart';
import 'app/providers.dart';
import 'services/storage/event_log_db.dart';
import 'services/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  final eventDb = EventLogDatabase();
  await eventDb.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        eventLogDbProvider.overrideWithValue(eventDb),
      ],
      child: const PrvntApp(),
    ),
  );
}
