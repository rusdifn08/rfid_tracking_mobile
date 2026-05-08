import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../auth/state/auth_state.dart';
import '../../../mock/station_dashboard_models.dart';
import '../../../../state/scanner_state.dart';
import '../../../widgets/shell/tracking_rfid_station_dialog.dart';
import '../../../widgets/station_dashboard/hourly_scan_chart_card.dart';
import '../../../widgets/station_dashboard/station_history_table_card.dart';
import '../../../widgets/station_dashboard/station_page_scaffold.dart';
import '../../../widgets/station_dashboard/station_summary_cards.dart';

class BundleStationPage extends StatelessWidget {
  const BundleStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScannerState>();
    final meta = trackingStationMetaOf('Bundle');
    final liveRows = state.bundleScans
        .map(
          (entry) => StationHistoryRow(
            rfid: entry.rfid,
            workOrder: entry.workOrder,
            qty: entry.qty,
          ),
        )
        .toList();
    final tableRows = <StationHistoryRow>[...liveRows];

    final baseHourly = _baseHourMap();
    for (final entry in state.bundleScans) {
      final hh = entry.scannedAt.hour.toString().padLeft(2, '0');
      baseHourly[hh] = (baseHourly[hh] ?? 0) + 1;
    }
    final mergedHourly = _hourBuckets
        .map(
          (hour) => HourlyScanPoint(
            hourLabel: hour,
            total: baseHourly[hour] ?? 0,
          ),
        )
        .toList();

    final totalScan = mergedHourly.fold<int>(0, (sum, item) => sum + item.total);
    final peak = mergedHourly.reduce((a, b) => a.total >= b.total ? a : b);

    return StationPageScaffold(
      title: 'Station Bundle',
      subtitle: meta.subtitle,
      accent: meta.accent,
      icon: meta.icon,
      children: [
        StationSummaryCards(
          totalScan: totalScan,
          peakHourLabel: '${peak.hourLabel}:00',
          peakHourCount: peak.total,
          accent: meta.accent,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showTrackingRfidStationDialog(
              context,
              'Bundle',
              onSubmitRfid: (rfid) async {
                final trimmed = rfid.trim();
                final scannerState = context.read<ScannerState>();
                final auth = context.read<AuthState>();
                final nik = auth.currentUser?.nik.trim() ?? '';
                if (nik.isEmpty) {
                  return RfidScanSubmitResult.fail(
                    'NIK tidak tersedia. Silakan login ulang.',
                  );
                }
                if (scannerState.bundleScans.any((e) => e.rfid == trimmed)) {
                  return RfidScanSubmitResult.fail(
                    'RFID sudah ada di tabel Bundle.',
                  );
                }
                try {
                  await scannerState.submitBundleCuttingOutput(
                    rfidBundles: trimmed,
                    nik: nik,
                  );
                  return RfidScanSubmitResult.ok(
                    'Berhasil mencatat Output Bundle.',
                  );
                } catch (e) {
                  final msg = ScannerState.userFacingError(e);
                  return RfidScanSubmitResult.fail(msg);
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
              'Mulai Scanning',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        HourlyScanChartCard(
          title: 'Grafik Scan Bundle per Jam',
          points: mergedHourly,
          accent: meta.accent,
        ),
        const SizedBox(height: 10),
        StationHistoryTableCard(
          rows: tableRows,
          title: 'Tabel History Bundle',
        ),
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

  Map<String, int> _baseHourMap() {
    return <String, int>{for (final hour in _hourBuckets) hour: 0};
  }
}
