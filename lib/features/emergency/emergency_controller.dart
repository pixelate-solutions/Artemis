import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

import '../../app/providers.dart';
import '../../models/contact.dart';
import '../../models/event_log.dart';
import '../../models/location_sample.dart';
import '../../services/location/location_service.dart';
import '../../services/sms_service.dart';
import '../../services/storage/event_log_db.dart';
import '../contacts/contacts_controller.dart';
import '../logs/logs_controller.dart';
import '../settings/settings_controller.dart';
import 'emergency_state.dart';

final emergencyControllerProvider =
    StateNotifierProvider<EmergencyController, EmergencyState>((ref) {
  final db = ref.watch(eventLogDbProvider);
  final location = ref.watch(locationServiceProvider);
  final sms = ref.watch(smsServiceProvider);
  return EmergencyController(
    ref: ref,
    database: db,
    locationService: location,
    smsService: sms,
  );
});

class EmergencyController extends StateNotifier<EmergencyState> {
  EmergencyController({
    required this.ref,
    required EventLogDatabase database,
    required LocationService locationService,
    required SmsService smsService,
  })  : _database = database,
        _locationService = locationService,
        _smsService = smsService,
        super(EmergencyState.initial());

  final Ref ref;
  final EventLogDatabase _database;
  final LocationService _locationService;
  final SmsService _smsService;

  Timer? _countdownTimer;
  Timer? _locationTimer;
  bool _locationInProgress = false;

  bool get isActive =>
      state.phase == EmergencyPhase.countdown ||
      state.phase == EmergencyPhase.sending;

  Future<void> startSession({
    required String payload,
    required String deviceId,
  }) async {
    if (isActive) {
      return;
    }

    final settings = ref.read(settingsControllerProvider);
    final eventId = await _database.insertEvent(EventLog(
      createdAt: DateTime.now().millisecondsSinceEpoch,
      type: 'PANIC',
      canceled: false,
      deviceId: deviceId,
      rawPayload: payload,
    ));

    state = state.copyWith(
      phase: EmergencyPhase.countdown,
      remainingSeconds: settings.countdownSeconds,
      statusText: 'Alert will be sent when timer hits 0',
      lastMessage: null,
      notifiedContacts: [],
      activeEventId: eventId,
    );

    _vibrate();
    ref.read(logsControllerProvider.notifier).load();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0);
        _escalate();
        return;
      }
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  Future<void> cancel() async {
    if (state.phase != EmergencyPhase.countdown) {
      return;
    }
    _countdownTimer?.cancel();
    final eventId = state.activeEventId;
    if (eventId != null) {
      await _database.updateEvent(eventId, {'canceled': 1});
      ref.read(logsControllerProvider.notifier).load();
    }
    state = state.copyWith(
      phase: EmergencyPhase.canceled,
      statusText: 'Canceled',
    );
  }

  Future<void> reset() async {
    _countdownTimer?.cancel();
    _locationTimer?.cancel();
    _locationInProgress = false;
    state = EmergencyState.initial();
  }

  Future<void> _escalate() async {
    state = state.copyWith(
      phase: EmergencyPhase.sending,
      statusText: 'Sending alert...'
    );

    final contacts = ref.read(emergencyContactsProvider);
    final settings = ref.read(settingsControllerProvider);
    final eventId = state.activeEventId;

    final position = await _locationService.getCurrentPosition();
    final message = _composeMessage(position);
    final recipientsJson = jsonEncode(
      contacts.map((c) => c.toMap()).toList(),
    );

    if (eventId != null) {
      await _database.updateEvent(eventId, {
        'message': message,
        'recipientsJson': recipientsJson,
        'lat': position?.latitude,
        'lng': position?.longitude,
      });
    }

    if (settings.mockMode || settings.backendUrl.isEmpty) {
      state = state.copyWith(statusText: 'Sent (Mock)');
    } else {
      try {
        await _smsService.send(
          backendUrl: settings.backendUrl,
          contacts: contacts,
          message: message,
        );
        state = state.copyWith(statusText: 'Alert sent');
      } catch (error) {
        state = state.copyWith(
          phase: EmergencyPhase.error,
          statusText: 'Send failed: $error',
        );
        return;
      }
    }

    if (eventId != null && position != null) {
      await _database.insertLocation(LocationSample(
        eventId: eventId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      ));
    }

    if (settings.sendLocationUpdates) {
      _startLocationUpdates(eventId);
    }

    ref.read(logsControllerProvider.notifier).load();
    state = state.copyWith(
      phase: EmergencyPhase.sent,
      lastMessage: message,
      notifiedContacts: contacts,
    );
  }

  void _startLocationUpdates(int? eventId) {
    if (eventId == null) {
      return;
    }
    int ticks = 0;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (ticks >= 8) {
        timer.cancel();
        return;
      }
      if (_locationInProgress) {
        return;
      }
      _locationInProgress = true;
      try {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          await _database.insertLocation(LocationSample(
            eventId: eventId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            lat: position.latitude,
            lng: position.longitude,
            accuracy: position.accuracy,
          ));
          ref.read(logsControllerProvider.notifier).load();
        }
      } finally {
        _locationInProgress = false;
        ticks += 1;
      }
    });
  }

  String _composeMessage(Position? position) {
    final timestamp = DateTime.now().toIso8601String();
    final location = position == null
        ? 'Location unavailable'
        : 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    return 'PRVNT ALERT: Emergency triggered at $timestamp.\n'
        'Location: $location';
  }

  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [0, 500, 150, 500, 150, 700]);
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }
}
