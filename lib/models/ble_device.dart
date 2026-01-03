class BleDeviceInfo {
  BleDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    required this.lastSeen,
    required this.isConnectable,
    this.nickname,
  });

  final String id;
  final String name;
  final int rssi;
  final DateTime lastSeen;
  final bool isConnectable;
  final String? nickname;

  BleDeviceInfo copyWith({
    String? id,
    String? name,
    int? rssi,
    DateTime? lastSeen,
    bool? isConnectable,
    String? nickname,
  }) {
    return BleDeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnectable: isConnectable ?? this.isConnectable,
      nickname: nickname ?? this.nickname,
    );
  }
}
