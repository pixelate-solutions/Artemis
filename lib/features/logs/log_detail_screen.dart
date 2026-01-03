import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/formatters.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/location_map_card.dart';
import 'logs_controller.dart';

class LogDetailScreen extends ConsumerWidget {
  const LogDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(logDetailProvider(eventId));

    return AppScaffold(
      appBar: const GlassAppBar(title: 'Event Details'),
      body: detail.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Event not found'));
          }
          final event = detail.event;
          final recipients = _parseRecipients(event.recipientsJson);
          double? mapLat;
          double? mapLng;
          if (event.lat != null && event.lng != null) {
            mapLat = event.lat;
            mapLng = event.lng;
          } else if (detail.locations.isNotEmpty) {
            mapLat = detail.locations.last.lat;
            mapLng = detail.locations.last.lng;
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.type,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(formatTimestamp(event.createdAt)),
                    const SizedBox(height: 6),
                    Text('Canceled: ${event.canceled ? 'Yes' : 'No'}'),
                    if (event.deviceId != null) ...[
                      const SizedBox(height: 6),
                      Text('Device: ${event.deviceId}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (mapLat != null && mapLng != null) ...[
                LocationMapCard(
                  lat: mapLat,
                  lng: mapLng,
                ),
                const SizedBox(height: 16),
              ],
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipients',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (recipients.isEmpty)
                      const Text('No recipients recorded')
                    else
                      ...recipients.map((recipient) {
                        final name = recipient['name'] ?? 'Unknown';
                        final phone = recipient['phone'] ?? 'Unknown';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('$name ($phone)'),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payload',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(event.rawPayload ?? 'None'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert Message',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(event.message ?? 'None'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (detail.locations.isEmpty)
                      const Text('No location samples')
                    else
                      ...detail.locations.map((location) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${formatTimestamp(location.createdAt)} · '
                            '${location.lat}, ${location.lng} '
                            '±${location.accuracy}m',
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }

  List<Map<String, dynamic>> _parseRecipients(String? json) {
    if (json == null || json.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
