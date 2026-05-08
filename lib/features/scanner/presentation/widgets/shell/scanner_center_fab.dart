import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scanner_shell_colors.dart';

/// FAB tengah dengan cincin pulse — mengelola [AnimationController] pulse sendiri.
/// Skala tekan diatur oleh [ScaleTransition] di parent ([ScannerShellPage]).
class ScannerCenterFab extends StatefulWidget {
  const ScannerCenterFab({
    super.key,
    required this.onOpenScanner,
  });

  final VoidCallback onOpenScanner;

  @override
  State<ScannerCenterFab> createState() => _ScannerCenterFabState();
}

class _ScannerCenterFabState extends State<ScannerCenterFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double fabSide = 68;
    const double cornerRadius = 20;
    return SizedBox(
      width: fabSide + 20,
      height: fabSide + 20,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final t = _pulseController.value;
              final wave = 0.5 + 0.5 * math.sin(t * math.pi * 2);
              final spread = 4 + 10 * wave;
              return Container(
                width: fabSide + spread,
                height: fabSide + spread,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    cornerRadius + spread * 0.35,
                  ),
                  border: Border.all(
                    color: ScannerShellColors.primaryBlue.withValues(
                      alpha: 0.22 + 0.2 * wave,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          SizedBox(
            width: fabSide,
            height: fabSide,
            child: Material(
              color: ScannerShellColors.primaryBlue,
              elevation: 8,
              shadowColor: ScannerShellColors.primaryBlue.withValues(
                alpha: 0.42,
              ),
              borderRadius: BorderRadius.circular(cornerRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(cornerRadius),
                onTap: widget.onOpenScanner,
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
