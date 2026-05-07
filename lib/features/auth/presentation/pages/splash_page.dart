import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.05, 0.9, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.32, 1, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F3CCF), Color(0xFF3155FF), Color(0xFF6F85FF)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final t = _glowController.value;
                    final wave = 0.5 + 0.5 * math.sin(t * math.pi * 2);
                    return Container(
                      width: 160 + (14 * wave),
                      height: 160 + (14 * wave),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08 + (0.06 * wave)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.28),
                            blurRadius: 28 + (10 * wave),
                            spreadRadius: 1 + (2 * wave),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 122,
                        height: 122,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: Image.asset('lib/assets/icon.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: Text(
                      'Gistex Mobile',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _titleOpacity,
                  child: Text(
                    'Scan barcode cutting, registrasi RFID,\ndan tracking produksi secara realtime.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
