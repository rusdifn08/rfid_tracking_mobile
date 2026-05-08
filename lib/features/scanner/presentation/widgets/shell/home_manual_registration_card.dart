import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../state/scanner_state.dart';
import 'neo_card.dart';
import 'scanner_shell_colors.dart';

/// Form barcode + RFID + kirim registrasi di halaman Home.
class HomeManualRegistrationCard extends StatefulWidget {
  const HomeManualRegistrationCard({
    super.key,
    required this.state,
    required this.barcodeController,
    required this.rfidController,
    required this.onFetchBarcode,
    required this.onSubmitRegistration,
  });

  final ScannerState state;
  final TextEditingController barcodeController;
  final TextEditingController rfidController;
  final Future<void> Function(String barcode, {bool openBundlingDialog})
  onFetchBarcode;
  final Future<void> Function() onSubmitRegistration;

  @override
  State<HomeManualRegistrationCard> createState() =>
      _HomeManualRegistrationCardState();
}

class _HomeManualRegistrationCardState
    extends State<HomeManualRegistrationCard> {
  static const double _fieldRadius = 16;

  void _onRfidChanged(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final rfidCtrl = widget.rfidController;
    return NeoCard(
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
                  color: ScannerShellColors.primaryBlue.withValues(alpha: 0.1),
                  border: Border.all(
                    color: ScannerShellColors.primaryBlue.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: ScannerShellColors.primaryBlue,
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
                        color: ScannerShellColors.inkStrong,
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
                        color: ScannerShellColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.barcodeController,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ScannerShellColors.inkStrong,
            ),
            onChanged: state.setBarcodeInput,
            onSubmitted: (value) => widget.onFetchBarcode(
              value.trim(),
              openBundlingDialog: true,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: ScannerShellColors.formFillBarcode,
              labelText: 'Barcode cutting',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: 'Contoh: BD20260504-565507',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: ScannerShellColors.inkMuted.withValues(alpha: 0.85),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.document_scanner_outlined,
                size: 20,
                color: ScannerShellColors.inkMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: const BorderSide(
                  color: ScannerShellColors.formStroke,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: const BorderSide(
                  color: ScannerShellColors.primaryBlue,
                  width: 1.5,
                ),
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
                        if (widget.barcodeController.text.isNotEmpty)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              widget.barcodeController.clear();
                              state.setBarcodeInput('');
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: ScannerShellColors.inkMuted,
                            ),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => widget.onFetchBarcode(
                            widget.barcodeController.text.trim(),
                            openBundlingDialog: true,
                          ),
                          icon: const Icon(
                            Icons.search,
                            size: 22,
                            color: ScannerShellColors.primaryBlue,
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
              color: ScannerShellColors.inkStrong,
            ),
            onChanged: _onRfidChanged,
            onSubmitted: (_) => widget.onSubmitRegistration(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: ScannerShellColors.formFillRfid,
              labelText: 'RFID bundles',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: 'Tempel / ketik RFID dari reader',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: ScannerShellColors.inkMuted.withValues(alpha: 0.85),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.nfc_rounded,
                size: 20,
                color: ScannerShellColors.inkMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: const BorderSide(
                  color: ScannerShellColors.formStroke,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
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
                        color: ScannerShellColors.inkMuted,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: state.isRegistering ? null : widget.onSubmitRegistration,
            style: FilledButton.styleFrom(
              backgroundColor: ScannerShellColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
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
}
