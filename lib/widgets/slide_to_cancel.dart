import 'package:flutter/material.dart';

import '../app/constants.dart';

class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
  });

  final String label;
  final VoidCallback onConfirmed;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _drag = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 64;
    final handleWidth = 54.0;
    final maxDrag = width - handleWidth;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Positioned(
            left: _drag,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_confirmed) {
                  return;
                }
                setState(() {
                  _drag = (_drag + details.delta.dx).clamp(0, maxDrag);
                });
              },
              onHorizontalDragEnd: (_) {
                if (_drag >= maxDrag * 0.9) {
                  setState(() {
                    _confirmed = true;
                    _drag = maxDrag;
                  });
                  widget.onConfirmed();
                } else {
                  setState(() {
                    _drag = 0;
                  });
                }
              },
              child: Container(
                width: handleWidth,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.chevron_right, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
