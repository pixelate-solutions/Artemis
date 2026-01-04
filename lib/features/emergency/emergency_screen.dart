import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../features/contacts/contacts_controller.dart';
import '../../models/contact.dart';
import '../../models/friend.dart';
import '../friends/friends_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/formatters.dart';
import '../../widgets/location_map_card.dart';
import 'emergency_controller.dart';
import 'emergency_state.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _cancelScheduled = false;
  bool _idleDismissScheduled = false;

  void _scheduleAutoDismiss(EmergencyController controller) {
    if (_cancelScheduled) {
      return;
    }
    _cancelScheduled = true;
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) {
        return;
      }
      await controller.reset();
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergency = ref.watch(emergencyControllerProvider);
    final controller = ref.read(emergencyControllerProvider.notifier);
    final friends = ref.watch(friendsControllerProvider);
    if (emergency.phase != EmergencyPhase.idle) {
      _idleDismissScheduled = false;
    } else if (!_idleDismissScheduled) {
      _idleDismissScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
      });
    }
    if (emergency.phase != EmergencyPhase.canceled) {
      _cancelScheduled = false;
    } else {
      _scheduleAutoDismiss(controller);
    }

    final title = switch (emergency.phase) {
      EmergencyPhase.countdown => 'EMERGENCY ACTIVATED',
      EmergencyPhase.sending => 'SENDING ALERT',
      EmergencyPhase.sent => 'EMERGENCY ACTIVE',
      EmergencyPhase.canceled => 'CANCELED',
      EmergencyPhase.error => 'ERROR',
      _ => 'EMERGENCY',
    };

    final lockNavigation = emergency.phase == EmergencyPhase.countdown ||
        emergency.phase == EmergencyPhase.sending ||
        emergency.phase == EmergencyPhase.sent;

    return WillPopScope(
      onWillPop: () async {
        return !lockNavigation;
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.55),
        body: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.transparent),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassCard(
                          borderRadius: 32,
                          child: Column(
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              if (emergency.phase == EmergencyPhase.countdown)
                                Text(
                                  emergency.remainingSeconds.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              else if (emergency.statusText != null)
                                Text(
                                  emergency.statusText!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              if (emergency.phase == EmergencyPhase.countdown) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Alert will be sent when timer hits 0',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                              const SizedBox(height: 24),
                              if (emergency.phase == EmergencyPhase.countdown)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await controller.cancel();
                                  },
                                  child: const Text('CANCEL'),
                                ),
                              if (emergency.phase == EmergencyPhase.sent ||
                                  emergency.phase == EmergencyPhase.sending ||
                                  emergency.phase == EmergencyPhase.error)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await controller.endSession();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('END EMERGENCY'),
                                ),
                              if (emergency.phase == EmergencyPhase.sent) ...[
                                const SizedBox(height: 20),
                                Text(
                                  emergency.notifiedContacts.isEmpty
                                      ? 'No contacts configured'
                                      : 'Contacts notified',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                ...emergency.notifiedContacts.map((contact) {
                                  return Text(
                                    '${contact.name} (${contact.phone})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        if (emergency.phase == EmergencyPhase.sent) ...[
                          const SizedBox(height: 16),
                          _buildFriendsCard(context, friends),
                          const SizedBox(height: 16),
                          _buildEmergencyContactsCard(context, emergency),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendStatusLabel(FriendStatus status) {
    if (status == FriendStatus.active) {
      return 'Active';
    }
    if (status == FriendStatus.offline) {
      return 'Offline';
    }
    return 'Safe';
  }

  Color _friendStatusColor(FriendStatus status) {
    if (status == FriendStatus.active) {
      return Colors.redAccent;
    }
    if (status == FriendStatus.offline) {
      return Colors.white70;
    }
    return AppColors.accent;
  }

  Widget _buildFriendsCard(BuildContext context, List<FriendProfile> friends) {
    return GlassCard(
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Friends',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (friends.isEmpty)
            Text(
              'No friends available.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            )
          else
            ...friends.map((friend) {
              final status = _friendStatusLabel(friend.status);
              final statusColor = _friendStatusColor(friend.status);
              final updatedLabel = friend.lastActive == null
                  ? 'Updated: unavailable'
                  : 'Updated ${formatTimestampFromDate(friend.lastActive!)}';
              final hasLocation =
                  friend.lastKnownLat != null && friend.lastKnownLng != null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: statusColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            updatedLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: hasLocation
                          ? () => _showFriendLocation(context, friend)
                          : null,
                      child: const Text('View'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(
    BuildContext context,
    EmergencyState emergency,
  ) {
    final contacts = ref.watch(contactsControllerProvider);
    final emergencyContacts = contacts.where((c) => c.isEmergency).toList();
    return GlassCard(
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${emergencyContacts.length}/${AppLimits.maxEmergencyContacts}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (emergencyContacts.isEmpty)
            Text(
              'No emergency contacts yet.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            )
          else
            ...emergencyContacts.map((contact) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${contact.name} · ${contact.phone}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white),
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEmergencyContactsDialog(context, emergency),
              child: const Text('Edit Emergency Contacts'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFriendLocation(
    BuildContext context,
    FriendProfile friend,
  ) async {
    if (friend.lastKnownLat == null || friend.lastKnownLng == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: GlassCard(
            borderRadius: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _friendStatusLabel(friend.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                LocationMapCard(
                  lat: friend.lastKnownLat!,
                  lng: friend.lastKnownLng!,
                  title: 'Last known location',
                  height: 220,
                  mapStyle: MapStyle.satellite,
                  lastUpdated: friend.lastActive,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEmergencyContactsDialog(
    BuildContext context,
    EmergencyState emergency,
  ) async {
    final emergencyActive = emergency.phase == EmergencyPhase.sending ||
        emergency.phase == EmergencyPhase.sent;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final controller =
                  ref.read(emergencyControllerProvider.notifier);
              final contacts = ref.watch(contactsControllerProvider);
              return GlassCard(
                borderRadius: 28,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    children: [
                      Text(
                        'Edit Emergency Contacts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        contact.phone,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: contact.isEmergency
                                      ? 'Remove from emergency'
                                      : 'Mark as emergency',
                                  icon: Icon(
                                    contact.isEmergency
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: contact.isEmergency
                                        ? AppColors.accent
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                  ),
                                  onPressed: () async {
                                    final success = await ref
                                        .read(contactsControllerProvider
                                            .notifier)
                                        .setEmergency(
                                          contact.id,
                                          !contact.isEmergency,
                                        );
                                    if (!success && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'You can select up to ${AppLimits.maxEmergencyContacts} emergency contacts.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    if (success &&
                                        !contact.isEmergency &&
                                        emergencyActive) {
                                      await controller.notifyAdditionalContacts(
                                        [contact.copyWith(isEmergency: true)],
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Alert sent to ${contact.name}.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showAddContactDialog(
                                context,
                                emergencyActive,
                              ),
                              child: const Text('Add Contact'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddContactDialog(
    BuildContext context,
    bool emergencyActive,
  ) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool markEmergency = true;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: GlassCard(
              borderRadius: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Contact',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: markEmergency,
                        onChanged: (value) =>
                            setState(() => markEmergency = value),
                      ),
                      const SizedBox(width: 8),
                      const Text('Mark as emergency'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            if (name.isEmpty || !_isValidPhone(phone)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a valid name/phone.'),
                                ),
                              );
                              return;
                            }
                            if (markEmergency) {
                              final emergencyCount = ref
                                  .read(contactsControllerProvider)
                                  .where((c) => c.isEmergency)
                                  .length;
                              if (emergencyCount >=
                                  AppLimits.maxEmergencyContacts) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'You can select up to ${AppLimits.maxEmergencyContacts} emergency contacts.',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                            final contact = Contact(
                              id: DateTime.now()
                                  .microsecondsSinceEpoch
                                  .toString(),
                              name: name,
                              phone: phone,
                              createdAt: DateTime.now().millisecondsSinceEpoch,
                              isEmergency: markEmergency,
                            );
                            await ref
                                .read(contactsControllerProvider.notifier)
                                .addContact(contact);
                            if (markEmergency && emergencyActive) {
                              await ref
                                  .read(emergencyControllerProvider.notifier)
                                  .notifyAdditionalContacts([contact]);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  bool _isValidPhone(String input) {
    final normalized = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.length < 7 || normalized.length > 15) {
      return false;
    }
    return RegExp(r'^[0-9+()\\-\\s]+$').hasMatch(input);
  }
}
