class Contact {
  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.isEmergency = false,
  });

  final String id;
  final String name;
  final String phone;
  final int createdAt;
  final bool isEmergency;

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    int? createdAt,
    bool? isEmergency,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'createdAt': createdAt,
      'isEmergency': isEmergency,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    final hasEmergency = map.containsKey('isEmergency');
    return Contact(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      isEmergency: hasEmergency
          ? (map['isEmergency'] as bool? ?? false)
          : true,
    );
  }
}
