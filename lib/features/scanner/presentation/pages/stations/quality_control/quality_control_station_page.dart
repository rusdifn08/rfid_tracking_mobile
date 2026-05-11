import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../auth/state/auth_state.dart';
import '../../../mock/station_dashboard_models.dart';
import '../../../../state/scanner_state.dart';
import '../../../widgets/shell/tracking_rfid_station_dialog.dart';
import '../../../widgets/station_dashboard/qc_history_table_card.dart';
import '../../../widgets/station_dashboard/qc_quality_chart_card.dart';
import '../../../widgets/station_dashboard/station_page_scaffold.dart';

class QualityControlStationPage extends StatefulWidget {
  const QualityControlStationPage({super.key});

  @override
  State<QualityControlStationPage> createState() =>
      _QualityControlStationPageState();
}

class _QualityControlStationPageState extends State<QualityControlStationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ScannerState>().fetchQualityControlDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScannerState>();
    final meta = trackingStationMetaOf('Quality Control');
    final liveRows = state.qualityControlScans
        .map(
          (entry) => QcHistoryRow(
            rfidBundle: entry.rfid,
            qty: entry.qty,
            good: entry.good,
            repair: entry.repair,
            reject: entry.reject,
          ),
        )
        .toList();
    final tableRows = <QcHistoryRow>[...liveRows];

    final mergedHourlyMap = <String, HourlyScanPoint>{
      for (final hour in _hourBuckets)
        hour: HourlyScanPoint(
          hourLabel: hour,
          total: 0,
          good: 0,
          repair: 0,
          reject: 0,
        ),
    };
    for (final entry in state.qualityControlScans) {
      final hh = entry.scannedAt.hour.toString().padLeft(2, '0');
      final current =
          mergedHourlyMap[hh] ??
          HourlyScanPoint(hourLabel: hh, total: 0, good: 0, repair: 0, reject: 0);
      mergedHourlyMap[hh] = HourlyScanPoint(
        hourLabel: hh,
        total: current.total + 1,
        good: current.good + entry.good,
        repair: current.repair + entry.repair,
        reject: current.reject + entry.reject,
      );
    }
    final mergedHourly =
        _hourBuckets.map((hour) => mergedHourlyMap[hour]!).toList();

    final dashboard = state.qualityControlDashboard;
    final totalScan = dashboard['bundle'] ?? state.qualityControlScans.length;
    final totalGood =
        dashboard['good'] ?? mergedHourly.fold<int>(0, (sum, item) => sum + item.good);
    final totalRepair = dashboard['repair'] ??
        mergedHourly.fold<int>(0, (sum, item) => sum + item.repair);
    final totalReject = dashboard['reject'] ??
        mergedHourly.fold<int>(0, (sum, item) => sum + item.reject);

    return StationPageScaffold(
      title: 'Station Quality Control',
      subtitle: meta.subtitle,
      accent: meta.accent,
      icon: meta.icon,
      children: [
        _buildQcSummaryCards(
          totalBundle: totalScan,
          totalGood: totalGood,
          totalRepair: totalRepair,
          totalReject: totalReject,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showTrackingRfidStationDialog(
              context,
              'Quality Control',
              onSubmitRfid: (payload) async {
                final scannerState = context.read<ScannerState>();
                final authState = context.read<AuthState>();
                final cleanRfid = payload.rfid.trim();
                final nik = authState.currentUser?.nik.trim() ?? '';
                if (nik.isEmpty) {
                  return RfidScanSubmitResult.fail(
                    'NIK tidak tersedia. Silakan login ulang.',
                  );
                }
                int qtyBundle;
                try {
                  qtyBundle = await scannerState.fetchQualityControlQty(
                    rfidBundles: cleanRfid,
                  );
                } catch (e) {
                  return RfidScanSubmitResult.fail(ScannerState.userFacingError(e));
                }
                if (qtyBundle <= 0) {
                  return RfidScanSubmitResult.fail(
                    'Qty output tidak ditemukan untuk RFID ini.',
                  );
                }
                if (!context.mounted) {
                  return RfidScanSubmitResult.fail('Halaman tidak aktif.');
                }
                final split = await _showQcSplitDialog(
                  context,
                  rfid: cleanRfid,
                  baseQty: qtyBundle,
                );
                if (split == null) {
                  return RfidScanSubmitResult.fail(
                    'Pembagian qty dibatalkan.',
                  );
                }
                try {
                  await scannerState.submitQualityControlResult(
                    rfidBundles: cleanRfid,
                    qty: qtyBundle,
                    good: split.good,
                    repair: split.repair,
                    reject: split.reject,
                    nik: nik,
                  );
                  return RfidScanSubmitResult.ok(
                    'QC tersimpan. Good ${split.good}, Repair ${split.repair}, Reject ${split.reject}.',
                  );
                } catch (e) {
                  return RfidScanSubmitResult.fail(ScannerState.userFacingError(e));
                }
              },
            ),
            style: FilledButton.styleFrom(
              backgroundColor: meta.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              'Mulai Scanning QC',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        QcQualityChartCard(points: mergedHourly),
        const SizedBox(height: 10),
        QcHistoryTableCard(rows: tableRows),
      ],
    );
  }

  static const List<String> _hourBuckets = <String>[
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
  ];

  Widget _buildQcSummaryCards({
    required int totalBundle,
    required int totalGood,
    required int totalRepair,
    required int totalReject,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QcStatusCard(
              width: itemWidth,
              title: 'Jumlah Bundle',
              value: totalBundle,
              color: const Color(0xFF6D28D9),
              icon: Icons.layers_rounded,
              background: const Color(0xFFF6F2FF),
              borderColor: const Color(0xFFD9CCFF),
              watermark: Icons.layers_rounded,
            ),
            _QcStatusCard(
              width: itemWidth,
              title: 'Total Good',
              value: totalGood,
              color: const Color(0xFF059669),
              icon: Icons.check_circle_outline_rounded,
              background: const Color(0xFFEFFAF5),
              borderColor: const Color(0xFFB7F0D2),
              watermark: Icons.task_alt_rounded,
            ),
            _QcStatusCard(
              width: itemWidth,
              title: 'Total Repair',
              value: totalRepair,
              color: const Color(0xFFEA580C),
              icon: Icons.build_rounded,
              background: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFFFD7B0),
              watermark: Icons.build_circle_outlined,
            ),
            _QcStatusCard(
              width: itemWidth,
              title: 'Total Reject',
              value: totalReject,
              color: const Color(0xFFE11D48),
              icon: Icons.warning_amber_rounded,
              background: const Color(0xFFFFF1F2),
              borderColor: const Color(0xFFFEC5CF),
              watermark: Icons.cancel_outlined,
            ),
          ],
        );
      },
    );
  }

  Future<_QcSplitResult?> _showQcSplitDialog(
    BuildContext context, {
    required String rfid,
    required int baseQty,
  }) async {
    int reject = 0;
    int repair = 0;
    return showDialog<_QcSplitResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final good = baseQty - reject - repair;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              actionsPadding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
              title: Text(
                'Input Hasil Quality Control',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF035A9A),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RFID $rfid · Qty Bundle $baseQty',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _counterInput(
                    label: 'Good',
                    value: good,
                    editable: false,
                  ),
                  const SizedBox(height: 10),
                  _counterInput(
                    label: 'Repair',
                    value: repair,
                    onMinus: repair > 0
                        ? () => setStateDialog(() => repair -= 1)
                        : null,
                    onPlus: good > 0
                        ? () => setStateDialog(() => repair += 1)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _counterInput(
                    label: 'Reject',
                    value: reject,
                    onMinus: reject > 0
                        ? () => setStateDialog(() => reject -= 1)
                        : null,
                    onPlus: good > 0
                        ? () => setStateDialog(() => reject += 1)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Good + Repair + Reject harus sama dengan Qty Bundle.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    _QcSplitResult(
                      good: good,
                      reject: reject,
                      repair: repair,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _counterInput({
    required String label,
    required int value,
    bool editable = true,
    VoidCallback? onMinus,
    VoidCallback? onPlus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (editable) ...[
              _counterButton(
                icon: Icons.remove,
                onTap: onMinus,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: editable ? Colors.white : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  '$value',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            if (editable) ...[
              const SizedBox(width: 8),
              _counterButton(
                icon: Icons.add,
                onTap: onPlus,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _counterButton({required IconData icon, required VoidCallback? onTap}) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _QcStatusCard extends StatelessWidget {
  const _QcStatusCard({
    required this.width,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.background,
    required this.borderColor,
    required this.watermark,
  });

  final double width;
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final Color background;
  final Color borderColor;
  final IconData watermark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 2,
            bottom: 0,
            child: Icon(
              watermark,
              size: 74,
              color: color.withValues(alpha: 0.16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF475467),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(icon, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '$value',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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

class _QcSplitResult {
  const _QcSplitResult({
    required this.good,
    required this.reject,
    required this.repair,
  });

  final int good;
  final int reject;
  final int repair;
}
