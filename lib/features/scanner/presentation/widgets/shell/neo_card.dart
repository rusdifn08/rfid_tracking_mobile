import 'package:flutter/material.dart';

import 'scanner_shell_colors.dart';

/// Kartu “neo” dengan gradien lembut — dipakai di header, stat, dan list item.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 18,
    this.borderColor = ScannerShellColors.neoBorder,
    this.gradient = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.boxShadow = const [
      BoxShadow(
        color: Color(0x1A3155FF),
        blurRadius: 16,
        offset: Offset(0, 7),
      ),
    ],
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color borderColor;
  final Gradient gradient;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
