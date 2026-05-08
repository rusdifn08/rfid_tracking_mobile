import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'neo_card.dart';
import 'scanner_shell_colors.dart';

class ScannerStatCard extends StatelessWidget {
  const ScannerStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ScannerShellColors.statIconBg,
            ),
            child: Icon(icon, color: ScannerShellColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
