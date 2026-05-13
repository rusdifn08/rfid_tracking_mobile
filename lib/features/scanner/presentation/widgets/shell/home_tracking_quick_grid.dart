import 'package:flutter/material.dart';

import 'package:scanner/config/coming.dart' as coming;

import 'home_feature_card.dart';

class HomeTrackingQuickGrid extends StatelessWidget {
  const HomeTrackingQuickGrid({
    super.key,
    required this.onTrackingModeTap,
  });

  final void Function(String mode) onTrackingModeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 8.0;
        final innerW = c.maxWidth;
        final innerH = c.maxHeight;
        final aspect = innerH > 0 && innerW > 0
            ? (innerW - spacing) / (innerH - spacing)
            : 1.05;
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            HomeFeatureCard(
              title: 'Bundle',
              subtitle: 'Tracking scan bundle cutting',
              icon: Icons.inventory_2_rounded,
              accent: const Color(0xFF4F46E5),
              surfaceTint: const Color(0xFFEEF2FF),
              borderColor: const Color(0xFFE0E7FF),
              delayMs: 0,
              dense: true,
              onTap: () => onTrackingModeTap('Bundle'),
            ),
            HomeFeatureCard(
              title: 'Quality Control',
              subtitle: 'Tracking scan quality control',
              icon: Icons.history_rounded,
              accent: const Color(0xFF0284C7),
              surfaceTint: const Color(0xFFE0F2FE),
              borderColor: const Color(0xFFBAE6FD),
              delayMs: 60,
              dense: true,
              onTap: () => onTrackingModeTap('Quality Control'),
            ),
            HomeFeatureCard(
              title: 'Supermarket',
              subtitle: 'Tracking scan area supermarket',
              icon: Icons.nfc_rounded,
              accent: const Color(0xFF059669),
              surfaceTint: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              delayMs: 120,
              dense: true,
              onTap: () => onTrackingModeTap('Supermarket'),
            ),
            HomeFeatureCard(
              title: 'Supply Sewing',
              subtitle: 'Tracking scan supply sewing',
              icon: Icons.photo_camera_rounded,
              accent: const Color(0xFFEA580C),
              surfaceTint: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFFED7AA),
              delayMs: 180,
              dense: true,
              comingSoon: coming.supplySewing,
              onTap: () => onTrackingModeTap('Supply Sewing'),
            ),
          ],
        );
      },
    );
  }
}
