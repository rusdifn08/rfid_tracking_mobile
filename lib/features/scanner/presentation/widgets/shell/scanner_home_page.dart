import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/motion_tokens.dart';
import '../../../state/scanner_state.dart';
import 'home_hero_banner.dart';
import 'home_manual_registration_card.dart';
import 'home_tracking_quick_grid.dart';
import 'scanner_shell_colors.dart';

class ScannerHomePage extends StatelessWidget {
  const ScannerHomePage({
    super.key,
    required this.state,
    required this.heroOpacity,
    required this.heroSlide,
    required this.fabScaleController,
    required this.motion,
    required this.barcodeController,
    required this.rfidController,
    required this.onOpenScanner,
    required this.onFetchBarcode,
    required this.onSubmitRegistration,
    required this.onTrackingModeTap,
  });

  final ScannerState state;
  final Animation<double> heroOpacity;
  final Animation<Offset> heroSlide;
  final AnimationController fabScaleController;
  final MotionTokens motion;
  final TextEditingController barcodeController;
  final TextEditingController rfidController;
  final VoidCallback onOpenScanner;
  final Future<void> Function(String barcode, {bool openBundlingDialog})
  onFetchBarcode;
  final Future<void> Function() onSubmitRegistration;
  final void Function(String mode) onTrackingModeTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ScannerShellColors.homeCanvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Expanded(
                    flex: 14,
                    child: FadeTransition(
                      opacity: heroOpacity,
                      child: SlideTransition(
                        position: heroSlide,
                        child: HomeHeroBanner(
                          fabScaleController: fabScaleController,
                          motion: motion,
                          onOpenScanner: onOpenScanner,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: double.infinity,
                      child: HomeManualRegistrationCard(
                        state: state,
                        barcodeController: barcodeController,
                        rfidController: rfidController,
                        onFetchBarcode: onFetchBarcode,
                        onSubmitRegistration: onSubmitRegistration,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: ScannerShellColors.primaryBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Akses Tracking',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                      color: ScannerShellColors.inkStrong,
                                    ),
                                  ),
                                  Text(
                                    'Bundle, QC, Supermarket, Supply Sewing',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      height: 1.2,
                                      color: ScannerShellColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: HomeTrackingQuickGrid(
                            onTrackingModeTap: onTrackingModeTap,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const ColoredBox(color: Colors.white, child: SizedBox(height: 2)),
        ],
      ),
    );
  }
}
