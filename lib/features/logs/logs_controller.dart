import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/event_log.dart';
import '../../services/storage/event_log_db.dart';

final logsControllerProvider =
    StateNotifierProvider<LogsController, AsyncValue<List<EventLog>>>((ref) {
  final db = ref.watch(eventLogDbProvider);
  return LogsController(db)..load();
});

final logDetailProvider = FutureProvider.family<EventLogDetail?, int>((ref, id) {
  final db = ref.watch(eventLogDbProvider);
  return db.fetchEventDetail(id);
});

class LogsController extends StateNotifier<AsyncValue<List<EventLog>>> {
  LogsController(this._db) : super(const AsyncValue.loading());

  final EventLogDatabase _db;

  Future<void> load() async {
    try {
      final events = await _db.fetchEvents();
      state = AsyncValue.data(events);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> deleteEvent(int id) async {
    await _db.deleteEvent(id);
    await load();
  }
}
