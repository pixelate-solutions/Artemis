import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../models/event_log.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/formatters.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import 'logs_controller.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsControllerProvider);

    return AppScaffold(
      appBar: GlassAppBar(
        title: 'Event Logs',
        actions: [
          IconButton(
            onPressed: () => ref.read(logsControllerProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: logsState.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassCard(
                  child: Text(
                    'No events yet. Trigger a PANIC to create a log entry.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          final grouped = _groupByDate(events);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 16),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...entry.value.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey('event-${event.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.delete_outline),
                        ),
                        onDismissed: (_) {
                          if (event.id != null) {
                            ref
                                .read(logsControllerProvider.notifier)
                                .deleteEvent(event.id!);
                          }
                        },
                        child: GlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(event.type),
                            subtitle: Text(
                              formatTimestamp(event.createdAt),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (event.id == null) {
                                return;
                              }
                              context.push('/logs/${event.id}');
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load logs: $error')),
      ),
    );
  }

  Map<String, List<EventLog>> _groupByDate(List<EventLog> events) {
    final Map<String, List<EventLog>> grouped = {};
    for (final event in events) {
      final date = DateTime.fromMillisecondsSinceEpoch(event.createdAt);
      final key = formatDateGroup(DateTime(date.year, date.month, date.day));
      grouped.putIfAbsent(key, () => []).add(event);
    }
    return grouped;
  }
}
