import '../../models/contact.dart';

enum EmergencyPhase {
  idle,
  countdown,
  sending,
  sent,
  canceled,
  error,
}

class EmergencyState {
  EmergencyState({
    required this.phase,
    required this.remainingSeconds,
    this.statusText,
    this.lastMessage,
    this.notifiedContacts = const [],
    this.activeEventId,
  });

  final EmergencyPhase phase;
  final int remainingSeconds;
  final String? statusText;
  final String? lastMessage;
  final List<Contact> notifiedContacts;
  final int? activeEventId;

  EmergencyState copyWith({
    EmergencyPhase? phase,
    int? remainingSeconds,
    String? statusText,
    String? lastMessage,
    List<Contact>? notifiedContacts,
    int? activeEventId,
  }) {
    return EmergencyState(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      statusText: statusText ?? this.statusText,
      lastMessage: lastMessage ?? this.lastMessage,
      notifiedContacts: notifiedContacts ?? this.notifiedContacts,
      activeEventId: activeEventId ?? this.activeEventId,
    );
  }

  factory EmergencyState.initial() {
    return EmergencyState(
      phase: EmergencyPhase.idle,
      remainingSeconds: 0,
    );
  }
}
