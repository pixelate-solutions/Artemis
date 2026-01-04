import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/event_log.dart';
import '../../models/location_sample.dart';

class EventLogDetail {
  EventLogDetail({required this.event, required this.locations});

  final EventLog event;
  final List<LocationSample> locations;
}

class EventLogDatabase {
  Database? _db;

  Future<void> init() async {
    if (_db != null) {
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, 'artemis.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            createdAt INTEGER,
            type TEXT,
            canceled INTEGER,
            deviceId TEXT,
            rawPayload TEXT,
            message TEXT,
            recipientsJson TEXT,
            lat REAL,
            lng REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventId INTEGER,
            createdAt INTEGER,
            lat REAL,
            lng REAL,
            accuracy REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE events ADD COLUMN recipientsJson TEXT');
        }
      },
    );
  }

  Future<int> insertEvent(EventLog event) async {
    return _requireDb().insert('events', event.toMap());
  }

  Future<void> updateEvent(int id, Map<String, Object?> values) async {
    await _requireDb().update('events', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertLocation(LocationSample location) async {
    await _requireDb().insert('locations', location.toMap());
  }

  Future<List<EventLog>> fetchEvents() async {
    final rows = await _requireDb().rawQuery('''
      SELECT events.*, (
        SELECT COUNT(*) FROM locations WHERE locations.eventId = events.id
      ) AS locationCount
      FROM events
      ORDER BY createdAt DESC
    ''');
    return rows.map((row) => EventLog.fromMap(row)).toList();
  }

  Future<EventLog?> fetchEvent(int id) async {
    final rows = await _requireDb().query('events', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return EventLog.fromMap(rows.first);
  }

  Future<List<LocationSample>> fetchLocationsForEvent(int eventId) async {
    final rows = await _requireDb().query(
      'locations',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'createdAt ASC',
    );
    return rows.map((row) => LocationSample.fromMap(row)).toList();
  }

  Future<EventLogDetail?> fetchEventDetail(int eventId) async {
    final event = await fetchEvent(eventId);
    if (event == null) {
      return null;
    }
    final locations = await fetchLocationsForEvent(eventId);
    return EventLogDetail(event: event, locations: locations);
  }

  Future<void> deleteEvent(int eventId) async {
    await _requireDb().delete('locations', where: 'eventId = ?', whereArgs: [eventId]);
    await _requireDb().delete('events', where: 'id = ?', whereArgs: [eventId]);
  }

  Database _requireDb() {
    final db = _db;
    if (db == null) {
      throw StateError('EventLogDatabase not initialized');
    }
    return db;
  }
}
