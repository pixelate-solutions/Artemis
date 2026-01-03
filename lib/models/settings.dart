enum ThemePreference {
  system,
  light,
  dark,
}

class AppSettings {
  AppSettings({
    this.countdownSeconds = 10,
    this.mockMode = true,
    this.sendLocationUpdates = true,
    this.autoReconnect = true,
    this.demoMode = false,
    this.backendUrl = '',
    this.themePreference = ThemePreference.system,
  });

  int countdownSeconds;
  bool mockMode;
  bool sendLocationUpdates;
  bool autoReconnect;
  bool demoMode;
  String backendUrl;
  ThemePreference themePreference;

  AppSettings copyWith({
    int? countdownSeconds,
    bool? mockMode,
    bool? sendLocationUpdates,
    bool? autoReconnect,
    bool? demoMode,
    String? backendUrl,
    ThemePreference? themePreference,
  }) {
    return AppSettings(
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      mockMode: mockMode ?? this.mockMode,
      sendLocationUpdates: sendLocationUpdates ?? this.sendLocationUpdates,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      demoMode: demoMode ?? this.demoMode,
      backendUrl: backendUrl ?? this.backendUrl,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countdownSeconds': countdownSeconds,
      'mockMode': mockMode,
      'sendLocationUpdates': sendLocationUpdates,
      'autoReconnect': autoReconnect,
      'demoMode': demoMode,
      'backendUrl': backendUrl,
      'themePreference': themePreference.name,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final preference = ThemePreference.values.firstWhere(
      (value) => value.name == map['themePreference'],
      orElse: () => ThemePreference.system,
    );
    return AppSettings(
      countdownSeconds: (map['countdownSeconds'] as num?)?.toInt() ?? 10,
      mockMode: map['mockMode'] as bool? ?? true,
      sendLocationUpdates: map['sendLocationUpdates'] as bool? ?? true,
      autoReconnect: map['autoReconnect'] as bool? ?? true,
      demoMode: map['demoMode'] as bool? ?? false,
      backendUrl: map['backendUrl'] as String? ?? '',
      themePreference: preference,
    );
  }
}
