import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/motion_tokens.dart';
import '../../state/scanner_state.dart';
import '../widgets/bundling_registration_dialog.dart';
import '../widgets/scanner_overlay_sheet.dart';
import '../widgets/shell/scanner_bottom_nav_bar.dart';
import '../widgets/shell/scanner_center_fab.dart';
import '../widgets/shell/rfid_checking_page.dart';
import '../widgets/shell/scanner_home_page.dart';
import '../widgets/shell/scanner_manual_input_page.dart';
import '../widgets/shell/scanner_profile_page.dart';
import '../widgets/shell/scanner_settings_page.dart';
import '../widgets/shell/scanner_shell_dialogs.dart';
import 'stations/bundle/bundle_station_page.dart';
import 'stations/quality_control/quality_control_station_page.dart';
import 'stations/supermarket/supermarket_station_page.dart';
import 'stations/supply_sewing/supply_sewing_station_page.dart';

class ScannerShellPage extends StatefulWidget {
  const ScannerShellPage({super.key});

  @override
  State<ScannerShellPage> createState() => _ScannerShellPageState();
}

class _ScannerShellPageState extends State<ScannerShellPage>
    with TickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  final TextEditingController _barcodeController = TextEditingController();

  /// Nullable + lazy re-init: setelah hot reload web, field baru bisa hilang di instance State lama.
  TextEditingController? _homeRfidController;

  late final AnimationController _fabController;
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
    _heroController.dispose();
    super.dispose();
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
        showScannerApiErrorDialog(context, notice.message);
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

  Widget _buildPageByMenu(ScannerState state) {
    final rfidCtrl = _homeRfidController ??= TextEditingController();
    switch (state.activeMenu) {
      case AppMenu.home:
        return ScannerHomePage(
          state: state,
          heroOpacity: _heroOpacity,
          heroSlide: _heroSlide,
          fabScaleController: _fabController,
          motion: _motion,
          barcodeController: _barcodeController,
          rfidController: rfidCtrl,
          onOpenScanner: _openScannerSheet,
          onFetchBarcode: _fetchBarcode,
          onSubmitRegistration: _submitHomeManualRegistration,
          onTrackingModeTap: (mode) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _stationPageByMode(mode),
              ),
            );
          },
        );
      case AppMenu.history:
        return const RfidCheckingPage();
      case AppMenu.manual:
        return ScannerManualInputPage(
          state: state,
          barcodeController: _barcodeController,
          onFetchBarcode: _fetchBarcode,
        );
      case AppMenu.settings:
        return const ScannerSettingsPage();
      case AppMenu.profile:
        return const ScannerProfilePage();
    }
  }

  Widget _stationPageByMode(String mode) {
    switch (mode) {
      case 'Bundle':
        return const BundleStationPage();
      case 'Quality Control':
        return const QualityControlStationPage();
      case 'Supermarket':
        return const SupermarketStationPage();
      default:
        return const SupplySewingStationPage();
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
            child: ScannerCenterFab(
              onOpenScanner: _openScannerSheet,
            ),
          ),
          bottomNavigationBar: ScannerBottomNavBar(
            state: state,
            motion: _motion,
          ),
        );
      },
    );
  }
}
