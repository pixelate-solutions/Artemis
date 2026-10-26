import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/constants.dart';
import 'formatters.dart';
import 'buttons.dart';
import 'glass_card.dart';

enum MapStyle {
  street,
  satellite,
}

class LocationMapCard extends StatelessWidget {
  const LocationMapCard({
    super.key,
    required this.lat,
    required this.lng,
    this.title = 'Location',
    this.height = 200,
    this.mapStyle = MapStyle.street,
    this.lastUpdated,
  });

  final double lat;
  final double lng;
  final String title;
  final double height;
  final MapStyle mapStyle;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    final useSatellite = mapStyle == MapStyle.satellite;
    final tileUrl = useSatellite
        ? 'https://services.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final labelUrl = useSatellite
        ? 'https://services.arcgisonline.com/ArcGIS/rest/services/'
            'Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}'
        : null;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (lastUpdated != null)
                Text(
                  'Updated ${formatTimestampFromDate(lastUpdated!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: height,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: tileUrl,
                    userAgentPackageName: 'com.pixelate.artemis',
                  ),
                  if (labelUrl != null)
                    TileLayer(
                      urlTemplate: labelUrl,
                      userAgentPackageName: 'com.pixelate.artemis',
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const _PulsingLocationMarker(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Open Directions',
              icon: Icons.directions,
              onPressed: () => _openDirections(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final uri = _directionsUri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open maps.')),
      );
    }
  }

  Uri _directionsUri() {
    final query = '$lat,$lng';
    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (isApple) {
      return Uri.parse('http://maps.apple.com/?daddr=$query');
    }
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$query',
    );
  }
}


class _PulsingLocationMarker extends StatefulWidget {
  const _PulsingLocationMarker();

  @override
  State<_PulsingLocationMarker> createState() =>
      _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<_PulsingLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dotSize = 12.0;
    const haloSize = 26.0;
    const baseColor = Colors.blueAccent;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = 1 + _pulse.value * 1.3;
              final opacity = (1 - _pulse.value) * 0.35;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: haloSize,
                  height: haloSize,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: haloSize,
            height: haloSize,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: const BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
