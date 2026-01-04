import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../app/providers.dart';
import '../../models/contact.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/permission_card.dart';
import 'contacts_controller.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsControllerProvider);
    final emergencyContacts = contacts.where((c) => c.isEmergency).toList();
    final permissionService = ref.watch(permissionServiceProvider);
    final filteredContacts = _filterContacts(contacts, _searchQuery)
      ..sort((a, b) {
        if (a.isEmergency != b.isEmergency) {
          return b.isEmergency ? 1 : -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final emptyMessage = contacts.isEmpty
        ? 'No contacts yet. Sync from your phone or add manually.'
        : 'No contacts match your search.';

    return AppScaffold(
      appBar: const GlassAppBar(title: 'Contacts'),
      body: FutureBuilder<bool>(
        future: permissionService.checkContactsPermission(),
        builder: (context, snapshot) {
          final contactsGranted = snapshot.data ?? false;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GlassCard(
                child: Text(
                  'Sync your contacts and mark up to ${AppLimits.maxEmergencyContacts} as emergency contacts.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${emergencyContacts.length}/${AppLimits.maxEmergencyContacts}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!contactsGranted)
                PermissionCard(
                  title: 'Contacts Permission',
                  subtitle:
                      'Allow access to sync emergency contacts from your phone.',
                  onRequest: () async {
                    await permissionService.requestContactsPermission();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  onOpenSettings: permissionService.openSettings,
                ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _syncContacts(context),
                            child: const Text('Sync Contacts'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _syncAllContacts(context),
                            child: const Text('Sync All'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showContactSheet(context),
                            child: const Text('Add Manual'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (filteredContacts.isEmpty)
                GlassCard(
                  child: Text(
                    emptyMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ListView.separated(
                  itemCount: filteredContacts.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact.phone,
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                  .read(contactsControllerProvider.notifier)
                                  .setEmergency(
                                    contact.id,
                                    !contact.isEmergency,
                                  );
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'You can select up to ${AppLimits.maxEmergencyContacts} emergency contacts.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showContactSheet(
                              context,
                              contact: contact,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(contactsControllerProvider.notifier)
                                .removeContact(contact.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _syncContacts(BuildContext context) async {
    final service = ref.read(contactsServiceProvider);
    final phoneContacts = await service.fetchContacts();
    final filtered = phoneContacts
        .where((c) => c.phones.isNotEmpty)
        .toList(growable: false);

    if (!context.mounted) {
      return;
    }

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts with phone numbers found.')),
      );
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
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final phoneContact = filtered[index];
                  final phoneNumber = phoneContact.phones.first.number;
                  return ListTile(
                    title: Text(phoneContact.displayName),
                    subtitle: Text(phoneNumber),
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      final existing = ref
                          .read(contactsControllerProvider)
                          .any((item) => item.phone == phoneNumber);
                      if (existing) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact already added.'),
                          ),
                        );
                        return;
                      }
                      ref
                          .read(contactsControllerProvider.notifier)
                          .addContact(Contact(
                            id: phoneContact.id,
                            name: phoneContact.displayName,
                            phone: phoneNumber,
                            createdAt:
                                DateTime.now().millisecondsSinceEpoch,
                            isEmergency: false,
                          ));
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncAllContacts(BuildContext context) async {
    final service = ref.read(contactsServiceProvider);
    final phoneContacts = await service.fetchContacts();
    final filtered = phoneContacts
        .where((c) => c.phones.isNotEmpty)
        .toList(growable: false);

    if (!context.mounted) {
      return;
    }

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts with phone numbers found.')),
      );
      return;
    }

    final toAdd = filtered
        .map((contact) => Contact(
              id: contact.id,
              name: contact.displayName,
              phone: contact.phones.first.number,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              isEmergency: false,
            ))
        .toList(growable: false);

    final added = await ref
        .read(contactsControllerProvider.notifier)
        .mergeContacts(toAdd);
    if (!context.mounted) {
      return;
    }
    if (added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No new contacts to sync.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Synced $added contacts.'),
      ),
    );
  }

  Future<void> _showContactSheet(
    BuildContext context, {
    Contact? contact,
  }) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return AnimatedPadding(
          duration: AppDurations.medium,
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Dialog(
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
                    contact == null ? 'Add Contact' : 'Edit Contact',
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
                  const SizedBox(height: 16),
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
                          onPressed: () {
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
                            final notifier =
                                ref.read(contactsControllerProvider.notifier);
                            if (contact == null) {
                              notifier.addContact(Contact(
                                id: DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                                name: name,
                                phone: phone,
                                createdAt:
                                    DateTime.now().millisecondsSinceEpoch,
                                isEmergency: false,
                              ));
                            } else {
                              notifier.updateContact(contact.copyWith(
                                name: name,
                                phone: phone,
                              ));
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isValidPhone(String input) {
    final normalized = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.length < 7 || normalized.length > 15) {
      return false;
    }
    return RegExp(r'^[0-9+()\-\s]+$').hasMatch(input);
  }

  List<Contact> _filterContacts(List<Contact> contacts, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return [...contacts];
    }
    return contacts.where((contact) {
      final name = contact.name.toLowerCase();
      final phone = contact.phone.toLowerCase();
      return name.contains(normalized) || phone.contains(normalized);
    }).toList();
  }
}
