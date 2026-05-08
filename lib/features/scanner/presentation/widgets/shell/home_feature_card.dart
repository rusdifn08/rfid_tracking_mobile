import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'scanner_shell_colors.dart';

class HomeFeatureCard extends StatelessWidget {
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pad = dense ? 10.0 : 15.0;
    final iconBox = dense ? 6.0 : 9.0;
    final iconSize = dense ? 18.0 : 22.0;
    final titleSize = dense ? 11.5 : 13.5;
    final subSize = dense ? 9.0 : 10.5;
    const radius = 20.0;
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.05),
            child: Ink(
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: surfaceTint,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(iconBox),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: iconSize),
                  ),
                  SizedBox(height: dense ? 6 : 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: ScannerShellColors.inkStrong,
                      fontWeight: FontWeight.w700,
                      fontSize: titleSize,
                      height: 1.15,
                      letterSpacing: -0.15,
                    ),
                  ),
                  SizedBox(height: dense ? 2 : 4),
                  Text(
                    subtitle,
                    maxLines: dense ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: ScannerShellColors.inkMuted,
                      fontSize: subSize,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: delayMs.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
