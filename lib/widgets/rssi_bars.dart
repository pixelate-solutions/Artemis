import 'package:flutter/material.dart';

class RssiBars extends StatelessWidget {
  const RssiBars({super.key, required this.rssi});

  final int rssi;

  int get level {
    if (rssi >= -60) {
      return 3;
    }
    if (rssi >= -80) {
      return 2;
    }
    if (rssi >= -95) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index < level;
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 4,
          height: 6 + index * 4,
          decoration: BoxDecoration(
            color: active ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
