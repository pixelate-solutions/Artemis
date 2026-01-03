class FriendProfile {
  FriendProfile({
    required this.id,
    required this.name,
    required this.status,
    this.lastKnownLat,
    this.lastKnownLng,
    this.lastActive,
  });

  final String id;
  final String name;
  final FriendStatus status;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime? lastActive;
}

enum FriendStatus {
  safe,
  active,
  offline,
}
