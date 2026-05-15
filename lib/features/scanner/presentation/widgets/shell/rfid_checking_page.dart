import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/models/rfid_checking_record.dart';
import '../../../data/scanner_api_service.dart';
import '../../../state/scanner_state.dart';
import 'rfid_checking_format.dart';
import 'rfid_checking_theme.dart';
import 'rfid_tracking_timeline_dialog.dart';

class RfidCheckSessionItem {
  const RfidCheckSessionItem({
    required this.rfid,
    required this.found,
    required this.message,
    required this.records,
    required this.checkedAt,
  });

  final String rfid;
  final bool found;
  final String message;
  final List<RfidCheckingRecord> records;
  final DateTime checkedAt;
}

class RfidCheckingPage extends StatefulWidget {
  const RfidCheckingPage({super.key});

  @override
  State<RfidCheckingPage> createState() => _RfidCheckingPageState();
}

class _RfidCheckingPageState extends State<RfidCheckingPage> {
  final ScannerApiService _api = ScannerApiService();
  final TextEditingController _rfidController = TextEditingController();
  final TextEditingController _filterSearchController = TextEditingController();
  final FocusNode _rfidFocus = FocusNode();

  final List<RfidCheckSessionItem> _sessionItems = <RfidCheckSessionItem>[];
  String _statusFilter = 'All Status';
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _rfidController.dispose();
    _filterSearchController.dispose();
    _rfidFocus.dispose();
    super.dispose();
  }

  List<String> get _statusOptions {
    final set = <String>{'All Status'};
    for (final item in _sessionItems) {
      for (final r in item.records) {
        if (r.lastStatus.trim().isNotEmpty) {
          set.add(r.lastStatus.trim().toUpperCase());
        }
      }
    }
    return set.toList()..sort((a, b) {
      if (a == 'All Status') {
        return -1;
      }
      if (b == 'All Status') {
        return 1;
      }
      return a.compareTo(b);
    });
  }

  List<RfidCheckSessionItem> get _filteredItems {
    final q = _filterSearchController.text.trim().toLowerCase();
    return _sessionItems.where((item) {
      if (_statusFilter != 'All Status') {
        final matchStatus = item.records.any(
          (r) => r.lastStatus.trim().toUpperCase() == _statusFilter,
        );
        if (!matchStatus && item.found) {
          return false;
        }
        if (!item.found) {
          return false;
        }
      }
      if (q.isEmpty) {
        return true;
      }
      return item.rfid.toLowerCase().contains(q);
    }).toList();
  }

  int get _totalCount => _sessionItems.length;
  int get _foundCount => _sessionItems.where((e) => e.found).length;
  int get _notFoundCount => _sessionItems.where((e) => !e.found).length;

  Future<void> _runCheck() async {
    final rfid = _rfidController.text.trim();
    if (rfid.isEmpty || _isChecking) {
      return;
    }
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.fetchRfidChecking(rfidBundles: rfid);
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionItems.removeWhere((e) => e.rfid == rfid);
        _sessionItems.insert(
          0,
          RfidCheckSessionItem(
            rfid: rfid,
            found: response.found,
            message: response.message,
            records: response.records,
            checkedAt: DateTime.now(),
          ),
        );
        _rfidController.clear();
        _isChecking = false;
      });
      _rfidFocus.requestFocus();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isChecking = false;
        _errorMessage = ScannerState.userFacingError(e);
      });
    }
  }

  void _clearAll() {
    setState(() {
      _sessionItems.clear();
      _statusFilter = 'All Status';
      _filterSearchController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _exportResults() async {
    if (_sessionItems.isEmpty) {
      _showSnack('Belum ada data untuk diekspor.');
      return;
    }
    final buffer = StringBuffer('RFID Checking Export\n\n');
    for (final item in _sessionItems) {
      buffer.writeln('RFID: ${item.rfid}');
      buffer.writeln('Status: ${item.found ? "Found" : "Not Found"}');
      buffer.writeln('Message: ${item.message}');
      buffer.writeln('Records: ${item.records.length}');
      buffer.writeln('---');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }
    _showSnack('Ringkasan hasil disalin ke clipboard.', success: true);
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        backgroundColor: success ? RfidCheckingTheme.found : const Color(0xFF334155),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    return ColoredBox(
      color: RfidCheckingTheme.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          final padH = wide ? 20.0 : 14.0;
          final maxW = wide ? 720.0 : constraints.maxWidth;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(padH, 12, padH, 28),
                children: [
                  _CheckingHeroHeader(wide: wide)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 14),
                  _ScanInputCard(
                    controller: _rfidController,
                    focusNode: _rfidFocus,
                    isChecking: _isChecking,
                    errorMessage: _errorMessage,
                    onCheck: _runCheck,
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  _StatsRow(
                    total: _totalCount,
                    found: _foundCount,
                    notFound: _notFoundCount,
                    wide: wide,
                  ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  _FilterToolbar(
                    wide: wide,
                    statusFilter: _statusFilter,
                    statusOptions: _statusOptions,
                    filterController: _filterSearchController,
                    canClear: _sessionItems.isNotEmpty,
                    onStatusChanged: (v) => setState(() => _statusFilter = v),
                    onFilterChanged: () => setState(() {}),
                    onClear: _clearAll,
                    onExport: _exportResults,
                  ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  _ResultsSectionHeader(
                    shown: filtered.length,
                    total: _sessionItems.length,
                  ),
                  const SizedBox(height: 10),
                  if (filtered.isEmpty)
                    _EmptyResultsState(
                      isSessionEmpty: _sessionItems.isEmpty,
                    )
                  else
                    ...filtered.asMap().entries.map(
                      (e) => _CheckResultCard(
                        item: e.value,
                        index: e.key,
                        onOpenTimeline: e.value.found &&
                                e.value.records.isNotEmpty
                            ? () => showRfidTrackingTimelineDialog(
                                  context,
                                  rfid: e.value.rfid,
                                  records: e.value.records,
                                )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckingHeroHeader extends StatelessWidget {
  const _CheckingHeroHeader({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: RfidCheckingTheme.heroGradient,
          boxShadow: [
            BoxShadow(
              color: RfidCheckingTheme.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.sensors_rounded,
                size: wide ? 120 : 96,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: -16,
              bottom: -24,
              child: Icon(
                Icons.route_outlined,
                size: 88,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 20 : 16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checking RFID Cutting',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: wide ? 18 : 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verifikasi & riwayat tracking bundle Cutting (GCC)',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: wide ? 12.5 : 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
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

class _ScanInputCard extends StatelessWidget {
  const _ScanInputCard({
    required this.controller,
    required this.focusNode,
    required this.isChecking,
    required this.errorMessage,
    required this.onCheck,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isChecking;
  final String? errorMessage;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: RfidCheckingTheme.surfaceCard(
        gradient: RfidCheckingTheme.scanCardGradient,
        borderColor: RfidCheckingTheme.primary.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RfidCheckingTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.nfc_rounded,
                  color: RfidCheckingTheme.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Scan atau ketik RFID',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: RfidCheckingTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onCheck(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Scan wedge / ketik RFID bundle…',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: RfidCheckingTheme.inkMuted,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: RfidCheckingTheme.primary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: RfidCheckingTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: RfidCheckingTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: RfidCheckingTheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: RfidCheckingTheme.notFoundSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RfidCheckingTheme.notFound.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: RfidCheckingTheme.notFound,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: RfidCheckingTheme.notFound,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isChecking
                      ? [const Color(0xFF94A3B8), const Color(0xFF94A3B8)]
                      : [
                          RfidCheckingTheme.primaryDark,
                          RfidCheckingTheme.primary,
                        ],
                ),
                boxShadow: isChecking
                    ? null
                    : [
                        BoxShadow(
                          color: RfidCheckingTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isChecking ? null : onCheck,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isChecking)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.search_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isChecking ? 'Memeriksa…' : 'Check RFID',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.found,
    required this.notFound,
    required this.wide,
  });

  final int total;
  final int found;
  final int notFound;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 340;
        final children = [
          _StatTile(
            label: 'Total',
            value: total,
            icon: Icons.layers_rounded,
            accent: RfidCheckingTheme.accentBlue,
            background: RfidCheckingTheme.totalSoft,
          ),
          _StatTile(
            label: 'Found',
            value: found,
            icon: Icons.check_circle_outline_rounded,
            accent: RfidCheckingTheme.found,
            background: RfidCheckingTheme.foundSoft,
          ),
          _StatTile(
            label: 'Not Found',
            value: notFound,
            icon: Icons.highlight_off_rounded,
            accent: RfidCheckingTheme.notFound,
            background: RfidCheckingTheme.notFoundSoft,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                children[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: wide ? 12 : 8),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: RfidCheckingTheme.surfaceCard(
        borderColor: accent.withValues(alpha: 0.12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: RfidCheckingTheme.ink,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: RfidCheckingTheme.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.wide,
    required this.statusFilter,
    required this.statusOptions,
    required this.filterController,
    required this.canClear,
    required this.onStatusChanged,
    required this.onFilterChanged,
    required this.onClear,
    required this.onExport,
  });

  final bool wide;
  final String statusFilter;
  final List<String> statusOptions;
  final TextEditingController filterController;
  final bool canClear;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onFilterChanged;
  final VoidCallback onClear;
  final VoidCallback onExport;

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: RfidCheckingTheme.inkMuted,
      ),
      prefixIcon: prefix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RfidCheckingTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RfidCheckingTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RfidCheckingTheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusField = DropdownButtonFormField<String>(
      key: ValueKey<String>(statusFilter),
      initialValue: statusOptions.contains(statusFilter)
          ? statusFilter
          : 'All Status',
      decoration: _fieldDecoration(
        hint: 'Status',
        prefix: const Icon(Icons.tune_rounded, size: 20, color: RfidCheckingTheme.inkMuted),
      ),
      items: statusOptions
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                s == 'All Status' ? s : RfidCheckingFormat.statusLabel(s),
                style: GoogleFonts.poppins(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onStatusChanged(v);
        }
      },
    );

    final searchField = TextField(
      controller: filterController,
      onChanged: (_) => onFilterChanged(),
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: _fieldDecoration(
        hint: 'Cari RFID…',
        prefix: const Icon(Icons.search, size: 20, color: RfidCheckingTheme.inkMuted),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: RfidCheckingTheme.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              children: [
                Expanded(child: statusField),
                const SizedBox(width: 10),
                Expanded(child: searchField),
              ],
            )
          else ...[
            statusField,
            const SizedBox(height: 10),
            searchField,
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canClear ? onClear : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RfidCheckingTheme.inkSecondary,
                    side: const BorderSide(color: RfidCheckingTheme.border),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onExport,
                  style: FilledButton.styleFrom(
                    backgroundColor: RfidCheckingTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(
                    'Export',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsSectionHeader extends StatelessWidget {
  const _ResultsSectionHeader({
    required this.shown,
    required this.total,
  });

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: RfidCheckingTheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Check Results',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: RfidCheckingTheme.ink,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: RfidCheckingTheme.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$shown / $total',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: RfidCheckingTheme.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyResultsState extends StatelessWidget {
  const _EmptyResultsState({required this.isSessionEmpty});

  final bool isSessionEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: RfidCheckingTheme.surfaceCard(
        borderColor: RfidCheckingTheme.accentBlue.withValues(alpha: 0.2),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: RfidCheckingTheme.accentBlueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: RfidCheckingTheme.accentBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSessionEmpty ? 'Belum ada hasil checking' : 'Tidak ada hasil filter',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: RfidCheckingTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSessionEmpty
                ? 'Scan atau ketik RFID bundle lalu tekan Check RFID.'
                : 'Ubah filter status atau kata kunci pencarian.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: RfidCheckingTheme.inkMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckResultCard extends StatelessWidget {
  const _CheckResultCard({
    required this.item,
    required this.index,
    this.onOpenTimeline,
  });

  final RfidCheckSessionItem item;
  final int index;
  final VoidCallback? onOpenTimeline;

  RfidCheckingRecord? get _latest {
    if (item.records.isEmpty) {
      return null;
    }
    final sorted = List<RfidCheckingRecord>.from(item.records)
      ..sort((a, b) {
        final at = a.logCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.logCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;
    final accent = item.found ? RfidCheckingTheme.found : RfidCheckingTheme.notFound;
    final softBg = item.found
        ? RfidCheckingTheme.foundSoft
        : RfidCheckingTheme.notFoundSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: RfidCheckingTheme.surfaceCard(
        borderColor: accent.withValues(alpha: 0.35),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenTimeline,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: softBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.found
                                      ? Icons.verified_rounded
                                      : Icons.cancel_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.rfid,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              letterSpacing: 0.3,
                                              color: RfidCheckingTheme.ink,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          RfidCheckingFormat.timeOnly(
                                            item.checkedAt,
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: RfidCheckingTheme.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _ChipBadge(
                                          label: item.found ? 'Found' : 'Not Found',
                                          icon: item.found
                                              ? Icons.check
                                              : Icons.close,
                                          background: softBg,
                                          foreground: accent,
                                        ),
                                        if (latest?.logCreatedAt != null)
                                          _ChipBadge(
                                            icon: Icons.schedule,
                                            label:
                                                'Last: ${RfidCheckingFormat.lastScannedBadge(latest!.logCreatedAt!)}',
                                          ),
                                        if (latest != null)
                                          _ChipBadge(
                                            icon: Icons.place_outlined,
                                            label: 'CUTTING',
                                          ),
                                        if (latest != null)
                                          _ChipBadge(
                                            icon: Icons.flag_outlined,
                                            label: RfidCheckingFormat.statusLabel(
                                              latest.lastStatus,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.message,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: RfidCheckingTheme.inkSecondary,
                              height: 1.35,
                            ),
                          ),
                          if (latest != null) ...[
                            const SizedBox(height: 12),
                            _DetailPanel(record: latest),
                            if (onOpenTimeline != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: onOpenTimeline,
                                  style: TextButton.styleFrom(
                                    foregroundColor: RfidCheckingTheme.primaryDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(Icons.timeline, size: 18),
                                  label: Text(
                                    'Tracking (${item.records.length})',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 350.ms)
        .slideY(begin: 0.03, end: 0);
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({
    required this.label,
    this.icon,
    this.background = const Color(0xFFF1F5F9),
    this.foreground = RfidCheckingTheme.inkSecondary,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.record});

  final RfidCheckingRecord record;

  @override
  Widget build(BuildContext context) {
    final pairs = <List<String>>[
      ['WO', record.wo, 'Style', record.style],
      ['Meja', record.meja, 'Warna', record.warna],
      ['Size', record.size, 'No. Ikat', record.noIkat],
      ['No. Urut', record.noUrut, 'Season', record.season],
      ['Country', record.country, '', ''],
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RfidCheckingTheme.border),
      ),
      child: Column(
        children: pairs
            .where((p) => p[1].isNotEmpty || p[3].isNotEmpty)
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _DetailCell(label: row[0], value: row[1])),
                    const SizedBox(width: 12),
                    Expanded(child: _DetailCell(label: row[2], value: row[3])),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          color: RfidCheckingTheme.inkSecondary,
        ),
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: RfidCheckingTheme.inkMuted,
            ),
          ),
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
