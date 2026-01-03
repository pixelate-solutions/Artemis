class EventLog {
  EventLog({
    this.id,
    required this.createdAt,
    required this.type,
    required this.canceled,
    this.deviceId,
    this.rawPayload,
    this.message,
    this.recipientsJson,
    this.lat,
    this.lng,
    this.locationCount = 0,
  });

  final int? id;
  final int createdAt;
  final String type;
  final bool canceled;
  final String? deviceId;
  final String? rawPayload;
  final String? message;
  final String? recipientsJson;
  final double? lat;
  final double? lng;
  final int locationCount;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'createdAt': createdAt,
      'type': type,
      'canceled': canceled ? 1 : 0,
      'deviceId': deviceId,
      'rawPayload': rawPayload,
      'message': message,
      'recipientsJson': recipientsJson,
      'lat': lat,
      'lng': lng,
    };
  }

  factory EventLog.fromMap(Map<String, Object?> map) {
    return EventLog(
      id: map['id'] as int?,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? '',
      canceled: (map['canceled'] as num?)?.toInt() == 1,
      deviceId: map['deviceId'] as String?,
      rawPayload: map['rawPayload'] as String?,
      message: map['message'] as String?,
      recipientsJson: map['recipientsJson'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      locationCount: (map['locationCount'] as num?)?.toInt() ?? 0,
    );
  }
}
