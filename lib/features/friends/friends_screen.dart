import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../models/friend.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_pill.dart';
import 'friends_controller.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsControllerProvider);

    return AppScaffold(
      appBar: const GlassAppBar(title: 'Friends'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GlassCard(
            child: Text(
              'Friends are people who listed you as an emergency contact.\n'
              'Demo Mode shows sample statuses until a backend is connected.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            GlassCard(
              child: Text(
                'No friends yet. Enable Demo Mode to preview friend status cards.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            ...friends.map((friend) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(friend.name),
                    subtitle: Text(_statusLabel(friend.status)),
                    trailing: _statusPill(friend.status),
                    onTap: () => context.push('/friends/${friend.id}'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _statusLabel(FriendStatus status) {
    switch (status) {
      case FriendStatus.active:
        return 'Active emergency';
      case FriendStatus.offline:
        return 'Offline';
      case FriendStatus.safe:
      default:
        return 'Safe';
    }
  }

  Widget _statusPill(FriendStatus status) {
    final type = switch (status) {
      FriendStatus.active => StatusPillType.error,
      FriendStatus.offline => StatusPillType.disconnected,
      FriendStatus.safe => StatusPillType.connected,
    };
    final label = switch (status) {
      FriendStatus.active => 'Active',
      FriendStatus.offline => 'Offline',
      FriendStatus.safe => 'Safe',
    };
    return AnimatedStatusPill(label: label, type: type);
  }
}
