import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'scanner_shell_colors.dart';

class HomeFeatureCard extends StatefulWidget {
  const HomeFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.surfaceTint,
    required this.borderColor,
    required this.delayMs,
    this.dense = false,
    this.comingSoon = false,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color surfaceTint;
  final Color borderColor;
  final int delayMs;
  final bool dense;

  /// Saat `true`, card dirender monochrome abu dan tap akan menampilkan
  /// overlay teks "Coming Soon" tanpa memanggil [onTap].
  final bool comingSoon;
  final VoidCallback onTap;

  @override
  State<HomeFeatureCard> createState() => _HomeFeatureCardState();
}

class _HomeFeatureCardState extends State<HomeFeatureCard> {
  static const Duration _hideAfter = Duration(milliseconds: 1800);
  // Palet abu monochrome saat mode coming soon aktif.
  static const Color _mutedAccent = Color(0xFF94A3B8);
  static const Color _mutedSurface = Color(0xFFF1F5F9);
  static const Color _mutedBorder = Color(0xFFE2E8F0);

  bool _showComingSoon = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.comingSoon) {
      widget.onTap();
      return;
    }
    setState(() => _showComingSoon = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideAfter, () {
      if (!mounted) {
        return;
      }
      setState(() => _showComingSoon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.dense ? 10.0 : 15.0;
    final iconBox = widget.dense ? 6.0 : 9.0;
    final iconSize = widget.dense ? 18.0 : 22.0;
    final titleSize = widget.dense ? 11.5 : 13.5;
    final subSize = widget.dense ? 9.0 : 10.5;
    const radius = 20.0;

    final coming = widget.comingSoon;
    final accent = coming ? _mutedAccent : widget.accent;
    final surface = coming ? _mutedSurface : widget.surfaceTint;
    final border = coming ? _mutedBorder : widget.borderColor;
    final titleColor = coming ? const Color(0xFF64748B) : ScannerShellColors.inkStrong;
    final subColor = coming ? const Color(0xFF94A3B8) : ScannerShellColors.inkMuted;

    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.05),
            child: Ink(
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconBox),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: accent, size: iconSize),
                      ),
                      SizedBox(height: widget.dense ? 6 : 10),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: titleSize,
                          height: 1.15,
                          letterSpacing: -0.15,
                        ),
                      ),
                      SizedBox(height: widget.dense ? 2 : 4),
                      Text(
                        widget.subtitle,
                        maxLines: widget.dense ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: subColor,
                          fontSize: subSize,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  if (coming && _showComingSoon)
                    Positioned.fill(
                      child: _ComingSoonOverlay(radius: radius),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: widget.delayMs.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

class _ComingSoonOverlay extends StatelessWidget {
  const _ComingSoonOverlay({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: const Color(0xFF0F172A).withValues(alpha: 0.72),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'COMING SOON',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1));
  }
}
