import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/settings.dart';
import '../../services/storage/storage_service.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsController(storage);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  switch (settings.themePreference) {
    case ThemePreference.light:
      return ThemeMode.light;
    case ThemePreference.dark:
      return ThemeMode.dark;
    case ThemePreference.system:
    default:
      return ThemeMode.system;
  }
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._storage) : super(_storage.loadSettings());

  final StorageService _storage;

  Future<void> updateCountdown(int seconds) async {
    state = state.copyWith(countdownSeconds: seconds);
    await _storage.saveSettings(state);
  }

  Future<void> updateMockMode(bool enabled) async {
    state = state.copyWith(mockMode: enabled);
    await _storage.saveSettings(state);
  }

  Future<void> updateSendLocationUpdates(bool enabled) async {
    state = state.copyWith(sendLocationUpdates: enabled);
    await _storage.saveSettings(state);
  }

  Future<void> updateAutoReconnect(bool enabled) async {
    state = state.copyWith(autoReconnect: enabled);
    await _storage.saveSettings(state);
  }

  Future<void> updateDemoMode(bool enabled) async {
    state = state.copyWith(demoMode: enabled);
    await _storage.saveSettings(state);
  }

  Future<void> updateBackendUrl(String url) async {
    state = state.copyWith(backendUrl: url);
    await _storage.saveSettings(state);
  }

  Future<void> updateTheme(ThemePreference preference) async {
    state = state.copyWith(themePreference: preference);
    await _storage.saveSettings(state);
  }
}
