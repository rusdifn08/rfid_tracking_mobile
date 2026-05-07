import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerOverlaySheet extends StatefulWidget {
  const ScannerOverlaySheet({
    required this.controller,
    required this.onDetect,
    super.key,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  State<ScannerOverlaySheet> createState() => _ScannerOverlaySheetState();
}

class _ScannerOverlaySheetState extends State<ScannerOverlaySheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            MobileScanner(
              controller: widget.controller,
              onDetect: widget.onDetect,
            ),
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = 1 + (_pulseController.value * 0.02);
                  return Transform.scale(scale: pulse, child: child);
                },
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF5B77FF), width: 3),
                  ),
                  child: const Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 220,
                      child: Divider(
                        color: Color(0xFF8EA2FF),
                        thickness: 2,
                        height: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: IconButton.filledTonal(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await widget.controller.stop();
                  if (navigator.mounted) {
                    navigator.pop();
                  }
                },
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Arahkan kamera ke barcode untuk scan realtime',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
