import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/motion_tokens.dart';
import '../../../auth/state/auth_state.dart';
import '../../state/scanner_state.dart';
import '../widgets/bundling_registration_dialog.dart';
import '../widgets/menu_info_card.dart';
import '../widgets/scanner_overlay_sheet.dart';

class ScannerShellPage extends StatefulWidget {
  const ScannerShellPage({super.key});

  @override
  State<ScannerShellPage> createState() => _ScannerShellPageState();
}

class _ScannerShellPageState extends State<ScannerShellPage>
    with TickerProviderStateMixin {
  static const Color _primaryBlue = Color(0xFF3155FF);
  static const Color _inactiveColor = Color(0xFF667085);
  static const Color _homeCanvas = Color(0xFFF3F5F9);
  static const Color _inkStrong = Color(0xFF101828);
  static const Color _inkMuted = Color(0xFF667085);
  static const Color _formFillBarcode = Color(0xFFEEF1F8);
  static const Color _formFillRfid = Color(0xFFEAF3EF);
  static const Color _formStroke = Color(0xFFDFE4EE);

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  final TextEditingController _barcodeController = TextEditingController();

  /// Nullable + lazy re-init: setelah hot reload web, field baru bisa hilang di instance State lama.
  TextEditingController? _homeRfidController;

  late final AnimationController _fabController;

  /// Nullable: hot reload web bisa mempertahankan State tanpa menjalankan initState untuk field baru.
  AnimationController? _fabScanController;
  late final AnimationController _heroController;
  late final Animation<double> _heroOpacity;
  late final Animation<Offset> _heroSlide;
  MotionTokens _motion = MotionTokens.normal();
  int _lastShownNoticeId = 0;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      lowerBound: 0.94,
      upperBound: 1,
      value: 1,
    );
    _ensureFabScanController();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _heroOpacity = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
        );
    _heroController.forward();
    _homeRfidController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = MotionTokens.fromContext(context);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _barcodeController.dispose();
    _homeRfidController?.dispose();
    _fabController.dispose();
    _fabScanController?.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _ensureFabScanController() {
    _fabScanController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  Future<void> _submitHomeManualRegistration() async {
    FocusScope.of(context).unfocus();
    final rfidCtrl = _homeRfidController ??= TextEditingController();
    final state = context.read<ScannerState>();
    final barcode = _barcodeController.text.trim();
    state.setBarcodeInput(barcode);
    final ok = await state.registerCurrentBarcode(
      barcodeOverride: barcode,
      rfidOverride: rfidCtrl.text,
    );
    if (!mounted || !ok) {
      return;
    }
    rfidCtrl.clear();
  }

  Future<void> _fetchBarcode(
    String barcode, {
    bool openBundlingDialog = false,
  }) async {
    final state = context.read<ScannerState>();
    await state.fetchByBarcode(
      barcode,
      pushFetchSuccessNotice: !openBundlingDialog,
    );
    if (!mounted) {
      return;
    }
    Future<void>.delayed(_motion.highlightDuration, () {
      if (mounted) {
        context.read<ScannerState>().clearHighlights();
      }
    });
    if (!openBundlingDialog ||
        state.errorMessage != null ||
        (state.lastBarcode ?? '') != barcode) {
      return;
    }
    await _showBundlingRegistrationDialog(barcode);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final state = context.read<ScannerState>();
    final navigator = Navigator.of(context);
    if (state.isScanLocked || state.isFetching) {
      return;
    }
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) {
      return;
    }
    final barcode = rawValue.trim();
    state.lockScan();
    _barcodeController.text = barcode;
    state.setBarcodeInput(barcode);
    await _scannerController.stop();
    if (navigator.mounted) {
      navigator.maybePop();
    }
    await _fetchBarcode(barcode, openBundlingDialog: true);
  }

  Future<void> _openScannerSheet() async {
    _fabController.animateTo(
      0.94,
      duration: _motion.short,
      curve: Curves.easeOut,
    );
    _scannerController.start().catchError((_) {
      // Biarkan UI menampilkan error dari proses scan jika permission/device bermasalah.
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: _motion.medium,
        reverseDuration: _motion.short,
      ),
      builder: (BuildContext context) {
        return ScannerOverlaySheet(
          controller: _scannerController,
          onDetect: _onDetect,
        );
      },
    );
    if (mounted) {
      _fabController.animateTo(
        1,
        duration: _motion.short,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerState>(
      builder: (context, state, _) {
        _handleGlobalNotice(state);
        if (_barcodeController.text != state.barcodeInput) {
          _barcodeController.text = state.barcodeInput;
        }
        final topInset = MediaQuery.paddingOf(context).top;
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Area status bar dibuat putih kosong agar konten tidak tertutup
              // notifikasi/indikator perangkat.
              SizedBox(
                height: topInset,
                width: double.infinity,
                child: const ColoredBox(color: Colors.white),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: _motion.medium,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<AppMenu>(state.activeMenu),
                    child: _buildPageByMenu(state),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: ScaleTransition(
            scale: _fabController,
            child: _buildScannerFab(),
          ),
          bottomNavigationBar: _buildBottomNavigation(state),
        );
      },
    );
  }

  Widget _buildPageByMenu(ScannerState state) {
    switch (state.activeMenu) {
      case AppMenu.home:
        return _buildHomePage(state);
      case AppMenu.history:
        return _buildHistoryPage(state);
      case AppMenu.manual:
        return _buildManualInputPage(state);
      case AppMenu.settings:
        return _buildSettingsPage();
      case AppMenu.profile:
        return _buildProfilePage();
    }
  }

  Widget _buildHomePage(ScannerState state) {
    return ColoredBox(
      color: _homeCanvas,
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
                      opacity: _heroOpacity,
                      child: SlideTransition(
                        position: _heroSlide,
                        child: _buildHomeHeroCompact(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildHomeInputCompact(state),
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
                                color: _primaryBlue,
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
                                      color: _inkStrong,
                                    ),
                                  ),
                                  Text(
                                    'Bundle, QC, Supermarket, Supply Sewing',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      height: 1.2,
                                      color: _inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(child: _buildHomeQuickGrid(state)),
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

  /// Tombol scan tengah: lebih besar + cincin animasi “scan” berdenyut.
  Widget _buildScannerFab() {
    _ensureFabScanController();
    final scan = _fabScanController!;
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
            animation: scan,
            builder: (context, child) {
              final t = scan.value;
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
                    color: _primaryBlue.withValues(alpha: 0.22 + 0.2 * wave),
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
              color: _primaryBlue,
              elevation: 8,
              shadowColor: _primaryBlue.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(cornerRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(cornerRadius),
                onTap: _openScannerSheet,
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

  Widget _buildHomeHeroCompact() {
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
              color: _primaryBlue.withValues(alpha: 0.28),
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
                    onTapDown: (_) => _fabController.animateTo(
                      0.96,
                      duration: _motion.short,
                      curve: Curves.easeOut,
                    ),
                    onTapUp: (_) => _fabController.animateTo(
                      1,
                      duration: _motion.short,
                      curve: Curves.easeOut,
                    ),
                    onTapCancel: () => _fabController.animateTo(
                      1,
                      duration: _motion.short,
                      curve: Curves.easeOut,
                    ),
                    child: ScaleTransition(
                      scale: _fabController,
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
                            onTap: _openScannerSheet,
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

  Widget _buildHomeInputCompact(ScannerState state) {
    final rfidCtrl = _homeRfidController ??= TextEditingController();
    const fieldRadius = 16.0;
    return _buildNeoCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderRadius: 22,
      borderColor: const Color(0xFFE4E7EC),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _primaryBlue.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _primaryBlue.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: _primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barcode & RFID',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                        color: _inkStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Isi barcode cutting & RFID bundle, lalu kirim registrasi langsung dari sini.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        height: 1.25,
                        color: _inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _barcodeController,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _inkStrong,
            ),
            onChanged: state.setBarcodeInput,
            onSubmitted: (value) =>
                _fetchBarcode(value.trim(), openBundlingDialog: true),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _formFillBarcode,
              labelText: 'Barcode cutting',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: 'Contoh: BD20260504-565507',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: _inkMuted.withValues(alpha: 0.85),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.document_scanner_outlined,
                size: 20,
                color: _inkMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: const BorderSide(color: _formStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
              ),
              suffixIcon: state.isFetching
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_barcodeController.text.isNotEmpty)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              _barcodeController.clear();
                              state.setBarcodeInput('');
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: _inkMuted,
                            ),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _fetchBarcode(
                            _barcodeController.text.trim(),
                            openBundlingDialog: true,
                          ),
                          icon: const Icon(
                            Icons.search,
                            size: 22,
                            color: _primaryBlue,
                          ),
                          tooltip: 'Cari data barcode',
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: rfidCtrl,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.visiblePassword,
            enableSuggestions: false,
            autocorrect: false,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _inkStrong,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitHomeManualRegistration(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _formFillRfid,
              labelText: 'RFID bundles',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: 'Tempel / ketik RFID dari reader',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: _inkMuted.withValues(alpha: 0.85),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 10,
              ),
              prefixIcon: Icon(Icons.nfc_rounded, size: 20, color: _inkMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: const BorderSide(color: _formStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF059669),
                  width: 1.5,
                ),
              ),
              suffixIcon: rfidCtrl.text.isNotEmpty
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(rfidCtrl.clear);
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: _inkMuted,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: state.isRegistering
                ? null
                : _submitHomeManualRegistration,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
              ),
            ),
            icon: state.isRegistering
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 22),
            label: Text(
              state.isRegistering ? 'Mengirim…' : 'Kirim registrasi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildHomeQuickGrid(ScannerState state) {
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 8.0;
        final innerW = c.maxWidth;
        final innerH = c.maxHeight;
        // Pas dengan tinggi Expanded: (lebar - jarak) / (tinggi - jarak) untuk 2×2.
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
            _homeFeatureCard(
              title: 'Bundle',
              subtitle: 'Tracking scan bundle cutting',
              icon: Icons.inventory_2_rounded,
              accent: const Color(0xFF4F46E5),
              surfaceTint: const Color(0xFFEEF2FF),
              borderColor: const Color(0xFFE0E7FF),
              delayMs: 0,
              dense: true,
              onTap: () => _showTrackingRfidDialog(mode: 'Bundle'),
            ),
            _homeFeatureCard(
              title: 'Quality Control',
              subtitle: 'Tracking scan quality control',
              icon: Icons.history_rounded,
              accent: const Color(0xFF0284C7),
              surfaceTint: const Color(0xFFE0F2FE),
              borderColor: const Color(0xFFBAE6FD),
              delayMs: 60,
              dense: true,
              onTap: () => _showTrackingRfidDialog(mode: 'Quality Control'),
            ),
            _homeFeatureCard(
              title: 'Supermarket',
              subtitle: 'Tracking scan area supermarket',
              icon: Icons.nfc_rounded,
              accent: const Color(0xFF059669),
              surfaceTint: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              delayMs: 120,
              dense: true,
              onTap: () => _showTrackingRfidDialog(mode: 'Supermarket'),
            ),
            _homeFeatureCard(
              title: 'Supply Sewing',
              subtitle: 'Tracking scan supply sewing',
              icon: Icons.photo_camera_rounded,
              accent: const Color(0xFFEA580C),
              surfaceTint: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFFED7AA),
              delayMs: 180,
              dense: true,
              onTap: () => _showTrackingRfidDialog(mode: 'Supply Sewing'),
            ),
          ],
        );
      },
    );
  }

  void _handleGlobalNotice(ScannerState state) {
    final notice = state.latestNotice;
    if (notice == null || notice.id == _lastShownNoticeId || !mounted) {
      return;
    }
    _lastShownNoticeId = notice.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (notice.type == NoticeType.error) {
        _showAnimatedErrorPopup(notice.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(14),
            backgroundColor: const Color(0xFF0E9384),
            content: Text(
              notice.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      context.read<ScannerState>().clearLatestNotice(notice.id);
    });
  }

  Future<void> _showAnimatedErrorPopup(String message) async {
    if (!mounted) {
      return;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'error-dialog',
      barrierColor: Colors.black.withValues(alpha: 0.34),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDA4AF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2ED92D20),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDDE2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFD92D20),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Request API Gagal',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB42318),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF7A271A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showBundlingRegistrationDialog(String barcode) async {
    if (!mounted) {
      return;
    }
    final rootContext = context;

    await showGeneralDialog<void>(
      context: rootContext,
      barrierDismissible: false,
      barrierLabel: 'bundling-dialog',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, _) {
        return BundlingRegistrationDialog(
          barcode: barcode,
          dialogContext: dialogContext,
          rootContext: rootContext,
          onOpenScannerForNext: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _openScannerSheet();
              }
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _homeFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color surfaceTint,
    required Color borderColor,
    required int delayMs,
    bool dense = false,
    required VoidCallback onTap,
  }) {
    final pad = dense ? 10.0 : 15.0;
    final iconBox = dense ? 6.0 : 9.0;
    final iconSize = dense ? 18.0 : 22.0;
    final titleSize = dense ? 11.5 : 13.5;
    final subSize = dense ? 9.0 : 10.5;
    final radius = 20.0;
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
                      color: _inkStrong,
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
                      color: _inkMuted,
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

  void _showTrackingRfidDialog({required String mode}) {
    final isBundle = mode == 'Bundle';
    final isQc = mode == 'Quality Control';
    final accent = isBundle
        ? const Color(0xFF059669)
        : isQc
        ? const Color(0xFF0284C7)
        : (mode == 'Supermarket'
              ? const Color(0xFFB54708)
              : const Color(0xFF7A5AF8));
    final subtitle = isBundle
        ? 'Scan RFID untuk input Bundle (Cutting)'
        : isQc
        ? 'Scan RFID untuk proses Quality Control'
        : mode == 'Supermarket'
        ? 'Scan RFID untuk proses Supermarket'
        : 'Scan RFID untuk proses Supply Sewing';
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _TrackingRfidStationDialog(
        mode: mode,
        accent: accent,
        subtitle: subtitle,
      ),
    );
  }

  Widget _buildHistoryPage(ScannerState state) {
    final scannedToday = state.filteredHistory.length;
    final totalScanned = state.scanHistory.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        _buildHeaderBlock(
          title: 'Riwayat Scan',
          subtitle: 'Pantau aktivitas scanner secara realtime.',
          icon: Icons.history_toggle_off_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Today',
                value: '$scannedToday',
                icon: Icons.today_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                label: 'Total',
                value: '$totalScanned',
                icon: Icons.qr_code_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Today'),
              selected: state.historyFilter == HistoryFilter.today,
              onSelected: (_) => state.setHistoryFilter(HistoryFilter.today),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('All'),
              selected: state.historyFilter == HistoryFilter.all,
              onSelected: (_) => state.setHistoryFilter(HistoryFilter.all),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.filteredHistory.isEmpty)
          _buildNeoCard(
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined, color: Color(0xFF667085)),
                const SizedBox(width: 10),
                Text(
                  'Belum ada riwayat scan di filter ini.',
                  style: GoogleFonts.poppins(color: const Color(0xFF667085)),
                ),
              ],
            ),
          ),
        ...state.filteredHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 180 + (index * 60)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 10),
                  child: child,
                ),
              );
            },
            child: Dismissible(
              key: ValueKey<String>('hist-${item.barcode}-${item.createdAt}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => state.removeHistory(item),
              background: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF04438),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 18),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _buildNeoCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3155FF), Color(0xFF6F85FF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    item.barcode,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Scan: ${_formatDate(item.createdAt)}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: IconButton.filledTonal(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      state.setActiveMenu(AppMenu.home);
                      _barcodeController.text = item.barcode;
                      state.setBarcodeInput(item.barcode);
                      _fetchBarcode(item.barcode, openBundlingDialog: true);
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildManualInputPage(ScannerState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildHeaderBlock(
            title: 'Manual Input',
            subtitle: 'Masukkan barcode saat kamera tidak digunakan.',
            icon: Icons.keyboard_alt_outlined,
          ),
          const SizedBox(height: 12),
          _buildNeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan Barcode',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _barcodeController,
                  onChanged: state.setBarcodeInput,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Contoh: BD20260504-565507',
                    prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isFetching
                        ? null
                        : () => _fetchBarcode(
                            _barcodeController.text.trim(),
                            openBundlingDialog: true,
                          ),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(
                      state.isFetching ? 'Memproses...' : 'Ambil Data',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildNeoCard(
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  color: _primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.hasResultData
                        ? 'Data berhasil diambil. Lihat detail di menu Home.'
                        : 'Tips: gunakan format barcode lengkap agar pencarian cepat.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: state.hasResultData
                          ? const Color(0xFF039855)
                          : const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderBlock(
          title: 'Settings',
          subtitle: 'Kontrol konfigurasi aplikasi dan scanner.',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 12),
        const MenuInfoCard(
          title: 'Pengaturan Scanner',
          subtitle: 'Konfigurasi lanjutan bisa ditambahkan di sini.',
          icon: Icons.settings_suggest_outlined,
        ),
        const MenuInfoCard(
          title: 'Koneksi API Lokal',
          subtitle: 'Server saat ini: http://10.5.0.201:9000',
          icon: Icons.wifi_tethering,
        ),
        const MenuInfoCard(
          title: 'Notifikasi',
          subtitle: 'Kelola notifikasi status scan dan sinkronisasi.',
          icon: Icons.notifications_active_outlined,
        ),
        const MenuInfoCard(
          title: 'Keamanan Data',
          subtitle: 'Atur proteksi data lokal operator dan aktivitas scan.',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    final auth = context.watch<AuthState>();
    final user = auth.currentUser;
    final displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name
        : 'Operator Scanner';
    final displayJabatan = (user?.jabatan.trim().isNotEmpty ?? false)
        ? user!.jabatan
        : 'Belum ada jabatan';
    final displayNik = (user?.nik.trim().isNotEmpty ?? false)
        ? user!.nik
        : '-';
    final displayRole = (user?.role.trim().isNotEmpty ?? false)
        ? user!.role.toUpperCase()
        : 'USER';
    final displayLine = (user?.line.trim().isNotEmpty ?? false) ? user!.line : '-';
    final displayBranch = (user?.branch.trim().isNotEmpty ?? false)
        ? user!.branch
        : '-';
    final displayRfid = (user?.rfidUser.trim().isNotEmpty ?? false)
        ? user!.rfidUser
        : '-';
    final displayNoHp = (user?.noHp.trim().isNotEmpty ?? false) ? user!.noHp : '-';
    final displayTelegram = (user?.telegram.trim().isNotEmpty ?? false)
        ? user!.telegram
        : '-';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderBlock(
          title: 'Profile',
          subtitle: 'Informasi akun login dan identitas operator.',
          icon: Icons.account_circle_outlined,
        ),
        const SizedBox(height: 12),
        _buildNeoCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3155FF), Color(0xFF6F85FF)],
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$displayJabatan • NIK $displayNik',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Login Aktif • $displayRole',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF067647),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildStatCard(
          label: 'NIK',
          value: displayNik,
          icon: Icons.badge_outlined,
        ),
        _buildStatCard(
          label: 'Bagian / Jabatan',
          value: displayJabatan,
          icon: Icons.work_outline_rounded,
        ),
        _buildStatCard(
          label: 'Line • Branch',
          value: '$displayLine • $displayBranch',
          icon: Icons.route_outlined,
        ),
        _buildStatCard(
          label: 'RFID User',
          value: displayRfid,
          icon: Icons.nfc_rounded,
        ),
        _buildStatCard(
          label: 'Kontak',
          value: 'HP: $displayNoHp | Telegram: $displayTelegram',
          icon: Icons.contact_phone_outlined,
        ),
        _buildNeoCard(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async => auth.logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB42318),
                side: const BorderSide(color: Color(0xFFFDA29B)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBlock({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _buildNeoCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF3155FF), Color(0xFF6F85FF)],
              ),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return _buildNeoCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFE8EEFF),
            ),
            child: Icon(icon, color: _primaryBlue, size: 20),
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

  Widget _buildNeoCard({
    required Widget child,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    double borderRadius = 18,
    Color borderColor = const Color(0xFFD7E2FF),
    Gradient gradient = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    List<BoxShadow> boxShadow = const [
      BoxShadow(color: Color(0x1A3155FF), blurRadius: 16, offset: Offset(0, 7)),
    ],
  }) {
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

  BottomAppBar _buildBottomNavigation(ScannerState state) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 0,
      elevation: 10,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      child: Row(
          children: [
            _buildBottomItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: state.activeMenu == AppMenu.home,
              onTap: () => state.setActiveMenu(AppMenu.home),
            ),
            _buildBottomItem(
              icon: Icons.history,
              label: 'History',
              selected: state.activeMenu == AppMenu.history,
              onTap: () => state.setActiveMenu(AppMenu.history),
            ),
            const SizedBox(width: 72),
            _buildBottomItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: state.activeMenu == AppMenu.settings,
              onTap: () => state.setActiveMenu(AppMenu.settings),
            ),
            _buildBottomItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: state.activeMenu == AppMenu.profile,
              onTap: () => state.setActiveMenu(AppMenu.profile),
            ),
          ],
        ),
    );
  }

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? _primaryBlue : _inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _motion.medium,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: _motion.short,
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: _motion.medium,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0x143155FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
              ),
              const SizedBox(height: 0),
              AnimatedDefaultTextStyle(
                duration: _motion.short,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: selected ? 9.5 : 9,
                  height: 1,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedContainer(
                duration: _motion.short,
                width: selected ? 16 : 0,
                height: selected ? 2 : 0,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final mo = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mo/$yy $hh:$mm';
  }
}

/// Dialog stasiun RFID Akses Tracking: animasi scan + input manual / wedge (Enter).
class _TrackingRfidStationDialog extends StatefulWidget {
  const _TrackingRfidStationDialog({
    required this.mode,
    required this.accent,
    required this.subtitle,
  });

  final String mode;
  final Color accent;
  final String subtitle;

  @override
  State<_TrackingRfidStationDialog> createState() =>
      _TrackingRfidStationDialogState();
}

class _TrackingRfidStationDialogState extends State<_TrackingRfidStationDialog>
    with TickerProviderStateMixin {
  static const Color _formStroke = Color(0xFFDFE4EE);

  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocus = FocusNode();
  final List<String> _scanned = <String>[];

  late final AnimationController _pulseController;
  late final AnimationController _sweepController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rfidFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sweepController.dispose();
    _shimmerController.dispose();
    _rfidController.dispose();
    _rfidFocus.dispose();
    super.dispose();
  }

  void _commitRfid() {
    final v = _rfidController.text.trim();
    if (v.isEmpty) return;
    if (_scanned.contains(v)) {
      _rfidController.clear();
      _rfidFocus.requestFocus();
      return;
    }
    setState(() {
      _scanned.add(v);
      _rfidController.clear();
    });
    _rfidFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.accent.withValues(alpha: 0.08);
    final titleColor = widget.accent;
    final count = _scanned.length;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 740,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE4F2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanning Station - ${widget.mode}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF667085),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 132,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.accent,
                                    widget.accent.withValues(alpha: 0.88),
                                    Color.lerp(
                                          widget.accent,
                                          Colors.black,
                                          0.12,
                                        ) ??
                                        widget.accent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ...List.generate(3, (i) {
                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final p =
                                    (_pulseController.value + i * 0.34) % 1.0;
                                final scale = 0.45 + p * 0.95;
                                final opacity = ((1 - p) * 0.45).clamp(0.0, 1.0);
                                return IgnorePointer(
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 108,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: opacity,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                          AnimatedBuilder(
                            animation: _sweepController,
                            builder: (context, child) {
                              final t = _sweepController.value;
                              return Align(
                                alignment: Alignment(0, -1 + 2 * t),
                                child: Container(
                                  height: 5,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.9),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              final s = _shimmerController.value;
                              return Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(-1.2 + s * 2.4, 0),
                                      end: Alignment(-0.2 + s * 2.4, 0),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.12),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.35, 0.5, 0.65],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.04).animate(
                              CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.nfc_rounded,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  size: 52,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'RFID',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Siap Scan — ketik / wedge RFID, tekan Enter untuk menambah',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: widget.accent,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _rfidController,
                    focusNode: _rfidFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _commitRfid(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF101828),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Input RFID',
                      hintText: 'Scan wedge atau ketik manual, lalu Enter',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667085),
                        fontSize: 13,
                      ),
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF98A2B3),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _formStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.accent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _commitRfid,
                      icon: Icon(Icons.add_rounded, color: widget.accent),
                      label: Text(
                        'Tambahkan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: widget.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE4F2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RFID yang Sudah di-Scan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: widget.accent,
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  'Selesai ($count)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
