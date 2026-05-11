import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../mock/station_dashboard_models.dart';
import '../../../../state/scanner_state.dart';
import '../../../widgets/shell/tracking_rfid_station_dialog.dart';
import '../../../widgets/station_dashboard/hourly_scan_chart_card.dart';
import '../../../widgets/station_dashboard/station_history_table_card.dart';
import '../../../widgets/station_dashboard/station_page_scaffold.dart';
import '../../../widgets/station_dashboard/station_summary_cards.dart';

class SupplySewingStationPage extends StatelessWidget {
  const SupplySewingStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScannerState>();
    final meta = trackingStationMetaOf('Supply Sewing');
    final tableRows = state.supplySewingScans
        .map(
          (entry) => StationHistoryRow(
            rfid: entry.rfid,
            workOrder: entry.workOrder,
            qty: entry.qty,
          ),
        )
        .toList();

    final perHour = <String, int>{for (final hour in _hourBuckets) hour: 0};
    for (final entry in state.supplySewingScans) {
      final hh = entry.scannedAt.hour.toString().padLeft(2, '0');
      perHour[hh] = (perHour[hh] ?? 0) + 1;
    }
    final hourly = _hourBuckets
        .map(
          (hour) => HourlyScanPoint(
            hourLabel: hour,
            total: perHour[hour] ?? 0,
          ),
        )
        .toList();

    final totalScan = hourly.fold<int>(0, (sum, item) => sum + item.total);
    final peak = hourly.reduce((a, b) => a.total >= b.total ? a : b);

    return StationPageScaffold(
      title: 'Station Supply Sewing',
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
              'Supply Sewing',
              onSubmitRfid: (payload) async {
                final ok = context.read<ScannerState>().addSupplySewingScan(
                  rfid: payload.rfid,
                );
                return ok
                    ? RfidScanSubmitResult.ok(
                        'Tersimpan ke dashboard Supply Sewing.',
                      )
                    : RfidScanSubmitResult.fail(
                        'RFID duplikat atau gagal disimpan.',
                      );
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
          title: 'Grafik Scan Supply Sewing per Jam',
          points: hourly,
          accent: meta.accent,
        ),
        const SizedBox(height: 10),
        StationHistoryTableCard(
          rows: tableRows,
          title: 'Tabel History Supply Sewing',
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
}
