import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../models/friend.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/formatters.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/location_map_card.dart';
import '../../widgets/status_pill.dart';
import 'friends_controller.dart';

class FriendDetailScreen extends ConsumerWidget {
  const FriendDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsControllerProvider);
    final friend = friends.firstWhere(
      (item) => item.id == friendId,
      orElse: () => FriendProfile(
        id: friendId,
        name: 'Unknown',
        status: FriendStatus.offline,
      ),
    );

    return AppScaffold(
      appBar: GlassAppBar(title: friend.name),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(_statusLabel(friend.status)),
                    if (friend.lastActive != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last active ${formatTimestampFromDate(friend.lastActive!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                AnimatedStatusPill(
                  label: _pillLabel(friend.status),
                  type: _pillType(friend.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (friend.lastKnownLat == null || friend.lastKnownLng == null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Location unavailable'),
                ],
              ),
            )
          else
            LocationMapCard(
              lat: friend.lastKnownLat!,
              lng: friend.lastKnownLng!,
              mapStyle: MapStyle.satellite,
              lastUpdated: friend.lastActive,
            ),
        ],
      ),
    );
  }

  String _statusLabel(FriendStatus status) {
    switch (status) {
      case FriendStatus.active:
        return 'Emergency active';
      case FriendStatus.offline:
        return 'Offline';
      case FriendStatus.safe:
      default:
        return 'Safe';
    }
  }

  String _pillLabel(FriendStatus status) {
    return switch (status) {
      FriendStatus.active => 'Active',
      FriendStatus.offline => 'Offline',
      FriendStatus.safe => 'Safe',
    };
  }

  StatusPillType _pillType(FriendStatus status) {
    return switch (status) {
      FriendStatus.active => StatusPillType.error,
      FriendStatus.offline => StatusPillType.disconnected,
      FriendStatus.safe => StatusPillType.connected,
    };
  }
}
