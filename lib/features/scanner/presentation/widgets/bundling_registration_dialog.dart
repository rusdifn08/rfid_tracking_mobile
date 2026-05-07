import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/scanner_state.dart';

/// Dialog setelah scan barcode sukses: info WO / No Ikat / No Urut + input RFID + POST /reg.
class BundlingRegistrationDialog extends StatefulWidget {
  const BundlingRegistrationDialog({
    super.key,
    required this.barcode,
    required this.dialogContext,
    required this.rootContext,
    required this.onOpenScannerForNext,
  });

  final String barcode;
  final BuildContext dialogContext;
  final BuildContext rootContext;
  final VoidCallback onOpenScannerForNext;

  @override
  State<BundlingRegistrationDialog> createState() =>
      _BundlingRegistrationDialogState();
}

class _BundlingRegistrationDialogState extends State<BundlingRegistrationDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _rfidController;
  late final FocusNode _rfidFocus;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _rfidController = TextEditingController();
    _rfidFocus = FocusNode();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ScannerState>().clearRfidInput();
      _rfidController.clear();
      _rfidFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _rfidFocus.dispose();
    _rfidController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool openScannerAfter}) async {
    final messenger = ScaffoldMessenger.maybeOf(widget.rootContext);
    final dialogNav = Navigator.of(widget.dialogContext);
    final state = context.read<ScannerState>();
    final ok = await state.registerCurrentBarcode(
      pushSuccessNotice: false,
      pushErrorNotice: true,
      pushValidationNotice: true,
      barcodeOverride: widget.barcode,
      rfidOverride: _rfidController.text,
    );
    if (!context.mounted) {
      return;
    }
    if (ok) {
      if (dialogNav.mounted) {
        dialogNav.pop();
      }
      messenger?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          backgroundColor: const Color(0xFF0E9384),
          content: Text(
            openScannerAfter
                ? 'Registrasi berhasil. Lanjut scan barcode.'
                : 'Registrasi berhasil: ${widget.barcode}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      _rfidController.clear();
      state.clearRfidInput();
      if (openScannerAfter) {
        widget.onOpenScannerForNext();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD7E2FF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A3155FF),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Consumer<ScannerState>(
                      builder: (context, state, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3155FF),
                                        Color(0xFF6F85FF),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Registrasi Barcode + RFID',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Barcode: ${widget.barcode}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF667085),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: state.isRegistering
                                      ? null
                                      : () => Navigator.of(widget.dialogContext)
                                          .pop(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Data bundling',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _readOnlyInfoTile(
                              label: 'WO',
                              value: state.getField('wo'),
                              icon: Icons.format_list_numbered_rounded,
                            ),
                            const SizedBox(height: 8),
                            _readOnlyInfoTile(
                              label: 'No Ikat',
                              value: state.getField('noIkat'),
                              icon: Icons.tag_rounded,
                            ),
                            const SizedBox(height: 8),
                            _readOnlyInfoTile(
                              label: 'No Urut',
                              value: state.getField('noUrut'),
                              icon: Icons.reorder_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan RFID',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = _pulse.value;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              width: 2,
                              color: Color.lerp(
                                const Color(0xFF3155FF),
                                const Color(0xFF12B76A),
                                t,
                              )!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.lerp(
                                  const Color(0x003155FF),
                                  const Color(0x553155FF),
                                  t,
                                )!,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: TextField(
                        controller: _rfidController,
                        focusNode: _rfidFocus,
                        autofocus: true,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        obscureText: false,
                        contextMenuBuilder: (context, editableTextState) =>
                            const SizedBox.shrink(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Menunggu input scanner RFID…',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF98A2B3),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.nfc_rounded,
                            color: Color(0xFF3155FF),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _ScanningPulseDot(
                              animation: _pulse,
                            ),
                          ),
                        ),
                        onSubmitted: (_) =>
                            _submit(openScannerAfter: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<ScannerState>(
                      builder: (context, state, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: _GradientPrimaryButton(
                                onPressed: state.isRegistering
                                    ? null
                                    : () =>
                                        _submit(openScannerAfter: false),
                                icon: state.isRegistering
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.cloud_upload_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                label: state.isRegistering
                                    ? 'Mengirim…'
                                    : 'Kirim registrasi',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OutlinedAccentButton(
                                onPressed: state.isRegistering
                                    ? null
                                    : () =>
                                        _submit(openScannerAfter: true),
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 20,
                                  color: Color(0xFF3155FF),
                                ),
                                label: 'Next Scanning',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _readOnlyInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final display = value.isEmpty ? '—' : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E2FF)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3155FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF667085),
                  ),
                ),
                Text(
                  display,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningPulseDot extends StatelessWidget {
  const _ScanningPulseDot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              const Color(0xFF12B76A),
              const Color(0xFF3155FF),
              animation.value,
            ),
            boxShadow: [
              BoxShadow(
                color: (Color.lerp(
                  const Color(0xFF12B76A),
                  const Color(0xFF3155FF),
                  animation.value,
                )!).withValues(alpha: 0.55),
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: disabled
                ? const LinearGradient(
                    colors: [Color(0xFF98A2B3), Color(0xFF667085)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF3155FF), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: disabled
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x403155FF),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedAccentButton extends StatelessWidget {
  const _OutlinedAccentButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3155FF), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF3155FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
