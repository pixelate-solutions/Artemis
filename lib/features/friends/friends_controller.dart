import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/friend.dart';
import '../settings/settings_controller.dart';

final friendsControllerProvider = Provider<List<FriendProfile>>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  if (!settings.demoMode) {
    return [];
  }
  return [
    FriendProfile(
      id: 'friend-1',
      name: 'Avery Chen',
      status: FriendStatus.safe,
      lastActive: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    FriendProfile(
      id: 'friend-2',
      name: 'Jordan Lee',
      status: FriendStatus.active,
      lastKnownLat: 37.7749,
      lastKnownLng: -122.4194,
      lastActive: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    FriendProfile(
      id: 'friend-3',
      name: 'Riley Park',
      status: FriendStatus.offline,
      lastActive: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];
});
