class LocationSample {
  LocationSample({
    this.id,
    required this.eventId,
    required this.createdAt,
    required this.lat,
    required this.lng,
    required this.accuracy,
  });

  final int? id;
  final int eventId;
  final int createdAt;
  final double lat;
  final double lng;
  final double accuracy;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'createdAt': createdAt,
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
    };
  }

  factory LocationSample.fromMap(Map<String, Object?> map) {
    return LocationSample(
      id: map['id'] as int?,
      eventId: (map['eventId'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
    );
  }
}
