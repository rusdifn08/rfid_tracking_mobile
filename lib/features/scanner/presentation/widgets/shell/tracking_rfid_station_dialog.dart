import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hasil simpan RFID dari halaman station (untuk log sukses/gagal di dialog).
class RfidScanSubmitResult {
  const RfidScanSubmitResult({required this.accepted, this.message});

  final bool accepted;

  /// Penjelasan untuk baris gagal, atau catatan tambahan untuk sukses.
  final String? message;

  static RfidScanSubmitResult ok([String? note]) =>
      RfidScanSubmitResult(accepted: true, message: note);

  static RfidScanSubmitResult fail(String message) =>
      RfidScanSubmitResult(accepted: false, message: message);
}

class RfidScanSubmitPayload {
  const RfidScanSubmitPayload({
    required this.rfid,
    this.status,
    this.line,
    this.branch,
  });

  final String rfid;
  final String? status;
  final String? line;
  final String? branch;
}

class _ScanRecord {
  _ScanRecord({
    required this.rfid,
    required this.success,
    required this.at,
    this.detail,
  });

  final String rfid;
  final bool success;
  final DateTime at;
  final String? detail;
}

/// Dialog stasiun RFID Akses Tracking: animasi scan + input manual / wedge (Enter).
class TrackingRfidStationDialog extends StatefulWidget {
  const TrackingRfidStationDialog({
    super.key,
    required this.mode,
    required this.accent,
    required this.subtitle,
    this.onSubmitRfid,
  });

  final String mode;
  final Color accent;
  final String subtitle;
  final Future<RfidScanSubmitResult> Function(RfidScanSubmitPayload payload)?
  onSubmitRfid;

  @override
  State<TrackingRfidStationDialog> createState() =>
      _TrackingRfidStationDialogState();
}

class _TrackingRfidStationDialogState extends State<TrackingRfidStationDialog>
    with TickerProviderStateMixin {
  static const Color _formStroke = Color(0xFFDFE4EE);
  static const String _actionCheckIn = 'check_in';
  static const String _actionCheckOut = 'check_out';
  static const String _actionSupplyUrgent = 'supply_urgent';

  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocus = FocusNode();
  final List<_ScanRecord> _records = <_ScanRecord>[];
  String _selectedAction = _actionCheckIn;
  String _selectedLocation = 'GM1';
  int _selectedLine = 1;

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
      if (mounted) {
        _rfidFocus.requestFocus();
      }
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

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h.$m.$s';
  }

  bool get _isSupermarket => widget.mode == 'Supermarket';
  bool get _needsLocationAndLine =>
      _isSupermarket && _selectedAction != _actionCheckIn;

  String _actionLabel(String action) {
    switch (action) {
      case _actionCheckOut:
        return 'Check Out';
      case _actionSupplyUrgent:
        return 'Supply Urgent';
      default:
        return 'Check In';
    }
  }

  String _supermarketContextLabel() {
    if (!_isSupermarket) {
      return '';
    }
    final action = _actionLabel(_selectedAction);
    if (!_needsLocationAndLine) {
      return 'Mode: $action';
    }
    return 'Mode: $action • Location: $_selectedLocation • Line: $_selectedLine';
  }

  String _selectedStatusApi() {
    switch (_selectedAction) {
      case _actionCheckOut:
        return 'out';
      case _actionSupplyUrgent:
        return 'urgent';
      default:
        return 'in';
    }
  }

  String _selectedLineApi() {
    return 'L${_selectedLine.toString().padLeft(2, '0')}';
  }

  Future<void> _commitRfid() async {
    final v = _rfidController.text.trim();
    if (v.isEmpty) {
      return;
    }

    final payload = RfidScanSubmitPayload(
      rfid: v,
      status: _isSupermarket ? _selectedStatusApi() : null,
      line: _needsLocationAndLine ? _selectedLineApi() : null,
      branch: _needsLocationAndLine ? _selectedLocation : null,
    );
    final result =
        await (widget.onSubmitRfid?.call(payload) ??
            Future.value(RfidScanSubmitResult.ok()));

    final now = DateTime.now();
    if (!mounted) {
      return;
    }

    setState(() {
      _records.insert(
        0,
        _ScanRecord(
          rfid: v,
          success: result.accepted,
          at: now,
          detail: [
            result.message ??
                (result.accepted ? 'Tersimpan ke dashboard' : 'Gagal'),
            _supermarketContextLabel(),
          ].where((e) => e.isNotEmpty).join('\n'),
        ),
      );
      _rfidController.clear();
    });
    _rfidFocus.requestFocus();
  }

  void _removeRecord(int index) {
    setState(() {
      _records.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.accent.withValues(alpha: 0.08);
    final titleColor = widget.accent;
    final count = _records.length;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E7EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanning Station — ${widget.mode}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: titleColor,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF667085),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSupermarket) ...[
                        _SupermarketActionTabs(
                          selectedAction: _selectedAction,
                          onChanged: (value) {
                            setState(() {
                              _selectedAction = value;
                              if (value == _actionCheckIn) {
                                _selectedLine = 1;
                                _selectedLocation = 'GM1';
                              }
                            });
                          },
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.contactless_rounded,
                              color: widget.accent,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Siap Scan — Dekatkan kartu RFID atau ketik / wedge, lalu Enter',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF047857),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_needsLocationAndLine) ...[
                        _SupermarketLocationLinePanel(
                          accent: widget.accent,
                          actionLabel: _actionLabel(_selectedAction),
                          selectedLocation: _selectedLocation,
                          line: _selectedLine,
                          onSelectLocation: (value) {
                            setState(() {
                              _selectedLocation = value;
                            });
                          },
                          onMinusLine: _selectedLine > 1
                              ? () => setState(() => _selectedLine -= 1)
                              : null,
                          onPlusLine: _selectedLine < 25
                              ? () => setState(() => _selectedLine += 1)
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                height: 120,
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
                                              widget.accent.withValues(
                                                alpha: 0.88,
                                              ),
                                              Color.lerp(
                                                    widget.accent,
                                                    Colors.black,
                                                    0.1,
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
                                              (_pulseController.value +
                                                  i * 0.34) %
                                              1.0;
                                          final scale = 0.45 + p * 0.95;
                                          final opacity = ((1 - p) * 0.45)
                                              .clamp(0.0, 1.0);
                                          return IgnorePointer(
                                            child: Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
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
                                            height: 4,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0.85,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
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
                                                begin: Alignment(
                                                  -1.2 + s * 2.4,
                                                  0,
                                                ),
                                                end: Alignment(
                                                  -0.2 + s * 2.4,
                                                  0,
                                                ),
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white.withValues(
                                                    alpha: 0.1,
                                                  ),
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
                                      scale:
                                          Tween<double>(
                                            begin: 0.92,
                                            end: 1.02,
                                          ).animate(
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
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                            size: 44,
                                          ),
                                          Text(
                                            'RFID',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _rfidController,
                              focusNode: _rfidFocus,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) async => _commitRfid(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF101828),
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Input RFID',
                                hintText:
                                    'Scan wedge atau ketik manual, lalu Enter',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
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
                                  borderSide: const BorderSide(
                                    color: _formStroke,
                                  ),
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
                                onPressed: () async => _commitRfid(),
                                icon: Icon(
                                  Icons.add_rounded,
                                  color: widget.accent,
                                ),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E7EC)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 20,
                              color: widget.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'RFID yang Sudah di-Scan',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF101828),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
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
                      if (_records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Belum ada scan. Masukkan RFID di atas.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF98A2B3),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_records.length, (index) {
                          final r = _records[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ScanRecordTile(
                              rfid: r.rfid,
                              success: r.success,
                              timeLabel: _formatTime(r.at),
                              detail: r.detail,
                              onDismiss: () => _removeRecord(index),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 22),
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
      ),
    );
  }
}

class _ScanRecordTile extends StatelessWidget {
  const _ScanRecordTile({
    required this.rfid,
    required this.success,
    required this.timeLabel,
    this.detail,
    required this.onDismiss,
  });

  final String rfid;
  final bool success;
  final String timeLabel;
  final String? detail;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bg = success ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);
    final border = success ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3);
    final accent = success ? const Color(0xFF059669) : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfid,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF101828),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        success ? 'Berhasil' : 'Gagal',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail != null && detail!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: success
                          ? const Color(0xFF047857)
                          : const Color(0xFF7A271A),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Hapus dari daftar',
            onPressed: onDismiss,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupermarketActionTabs extends StatelessWidget {
  const _SupermarketActionTabs({
    required this.selectedAction,
    required this.onChanged,
    required this.accent,
  });

  final String selectedAction;
  final ValueChanged<String> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTabButton(
            label: 'Check In',
            selected:
                selectedAction ==
                _TrackingRfidStationDialogState._actionCheckIn,
            accent: accent,
            onTap: () =>
                onChanged(_TrackingRfidStationDialogState._actionCheckIn),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTabButton(
            label: 'Check Out',
            selected:
                selectedAction ==
                _TrackingRfidStationDialogState._actionCheckOut,
            accent: accent,
            onTap: () =>
                onChanged(_TrackingRfidStationDialogState._actionCheckOut),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTabButton(
            label: 'Supply Urgent',
            selected:
                selectedAction ==
                _TrackingRfidStationDialogState._actionSupplyUrgent,
            accent: accent,
            onTap: () =>
                onChanged(_TrackingRfidStationDialogState._actionSupplyUrgent),
          ),
        ),
      ],
    );
  }
}

class _ActionTabButton extends StatelessWidget {
  const _ActionTabButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white,
          side: BorderSide(color: selected ? accent : const Color(0xFFD0D5DD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? accent : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }
}

class _SupermarketLocationLinePanel extends StatelessWidget {
  const _SupermarketLocationLinePanel({
    required this.accent,
    required this.actionLabel,
    required this.selectedLocation,
    required this.line,
    required this.onSelectLocation,
    required this.onMinusLine,
    required this.onPlusLine,
  });

  final Color accent;
  final String actionLabel;
  final String selectedLocation;
  final int line;
  final ValueChanged<String> onSelectLocation;
  final VoidCallback? onMinusLine;
  final VoidCallback? onPlusLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$actionLabel — isi sebelum scan',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A2E0E),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _LocationButton(
                            label: 'GM1',
                            selected: selectedLocation == 'GM1',
                            accent: accent,
                            onTap: () => onSelectLocation('GM1'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LocationButton(
                            label: 'GM2',
                            selected: selectedLocation == 'GM2',
                            accent: accent,
                            onTap: () => onSelectLocation('GM2'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Line',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _LineStepperButton(
                          icon: Icons.remove,
                          onTap: onMinusLine,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minWidth: 50),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD0D5DD),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$line',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF101828),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _LineStepperButton(icon: Icons.add, onTap: onPlusLine),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white,
          side: BorderSide(color: selected ? accent : const Color(0xFFD0D5DD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: selected ? accent : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }
}

class _LineStepperButton extends StatelessWidget {
  const _LineStepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFD0D5DD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class TrackingStationMeta {
  const TrackingStationMeta({
    required this.accent,
    required this.subtitle,
    required this.icon,
  });

  final Color accent;
  final String subtitle;
  final IconData icon;
}

TrackingStationMeta trackingStationMetaOf(String mode) {
  switch (mode) {
    case 'Bundle':
      return const TrackingStationMeta(
        accent: Color(0xFF4F46E5),
        subtitle: 'Scan RFID untuk input Bundle (Cutting)',
        icon: Icons.inventory_2_rounded,
      );
    case 'Quality Control':
      return const TrackingStationMeta(
        accent: Color(0xFF0284C7),
        subtitle: 'Scan RFID untuk proses Quality Control',
        icon: Icons.verified_outlined,
      );
    case 'Quality Control Repair':
      return const TrackingStationMeta(
        accent: Color(0xFFEA580C),
        subtitle: 'Scan RFID untuk proses Repair QC',
        icon: Icons.build_circle_outlined,
      );
    case 'Supermarket':
      return const TrackingStationMeta(
        accent: Color(0xFF059669),
        subtitle: 'Scan RFID untuk proses Supermarket',
        icon: Icons.storefront_outlined,
      );
    default:
      return const TrackingStationMeta(
        accent: Color(0xFFEA580C),
        subtitle: 'Scan RFID untuk proses Supply Sewing',
        icon: Icons.local_shipping_outlined,
      );
  }
}

/// Buka dialog tracking dengan warna & subtitle sesuai mode stasiun.
void showTrackingRfidStationDialog(
  BuildContext context,
  String mode, {
  Future<RfidScanSubmitResult> Function(RfidScanSubmitPayload payload)?
  onSubmitRfid,
}) {
  final meta = trackingStationMetaOf(mode);

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => TrackingRfidStationDialog(
      mode: mode,
      accent: meta.accent,
      subtitle: meta.subtitle,
      onSubmitRfid: onSubmitRfid,
    ),
  );
}
