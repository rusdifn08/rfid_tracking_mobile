import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/motion_tokens.dart';
import 'scanner_shell_colors.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.fabScaleController,
    required this.motion,
    required this.onOpenScanner,
  });

  final AnimationController fabScaleController;
  final MotionTokens motion;
  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    final softIcon = Colors.white.withValues(alpha: 0.12);
    final softIcon2 = Colors.white.withValues(alpha: 0.08);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F4EE8), Color(0xFF5B6EF5), Color(0xFF8B9BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: ScannerShellColors.primaryBlue.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -36,
              top: -28,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 132,
                color: softIcon2,
              ),
            ),
            Positioned(
              left: -24,
              bottom: -32,
              child: Icon(Icons.nfc_rounded, size: 108, color: softIcon2),
            ),
            Positioned(
              right: 52,
              bottom: 6,
              child: Icon(
                Icons.inventory_2_outlined,
                size: 52,
                color: softIcon,
              ),
            ),
            Positioned(
              left: 120,
              top: 10,
              child: Icon(Icons.layers_outlined, size: 44, color: softIcon),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'RFID & Barcode Scanner',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gistex Mobile untuk scan barcode cutting, registrasi bundling RFID, dan tracking cepat dan terkendali.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10.5,
                            height: 1.38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTapDown: (_) => fabScaleController.animateTo(
                      0.96,
                      duration: motion.short,
                      curve: Curves.easeOut,
                    ),
                    onTapUp: (_) => fabScaleController.animateTo(
                      1,
                      duration: motion.short,
                      curve: Curves.easeOut,
                    ),
                    onTapCancel: () => fabScaleController.animateTo(
                      1,
                      duration: motion.short,
                      curve: Curves.easeOut,
                    ),
                    child: ScaleTransition(
                      scale: fabScaleController,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onOpenScanner,
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              color: Color(0xFF2F4EE8),
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
