import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../mock/station_dashboard_models.dart';
import '../../../../state/scanner_state.dart';
import '../../../widgets/shell/tracking_rfid_station_dialog.dart';
import '../../../widgets/station_dashboard/hourly_scan_chart_card.dart';
import '../../../widgets/station_dashboard/station_page_scaffold.dart';
import '../../../widgets/station_dashboard/station_summary_cards.dart';

class SupermarketStationPage extends StatelessWidget {
  const SupermarketStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScannerState>();
    final meta = trackingStationMetaOf('Supermarket');
    final entries = state.supermarketScans;
    final waitingCount = _calcWaiting(entries);
    final checkInCount = _calcByLabel(entries, _checkInLabel);
    final checkOutCount = _calcByLabel(entries, _checkOutLabel);
    final supplyUrgentCount = state.supplySewingScans.length;

    final tableRows = entries
        .map(
          (entry) => _SupermarketDetailRow(
            rfid: entry.rfid,
            activity: _normalizeActivity(entry.workOrder),
            qty: entry.qty,
            scannedAt: entry.scannedAt,
          ),
        )
        .toList();

    final perHour = <String, int>{for (final hour in _hourBuckets) hour: 0};
    for (final entry in entries) {
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
      title: 'Supermarket Dashboard',
      subtitle: meta.subtitle,
      accent: meta.accent,
      icon: meta.icon,
      children: [
        _buildStatusCards(
          waiting: waitingCount,
          checkIn: checkInCount,
          checkOut: checkOutCount,
          supplyUrgent: supplyUrgentCount,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openSupermarketScanningDialog(context),
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
        StationSummaryCards(
          totalScan: totalScan,
          peakHourLabel: '${peak.hourLabel}:00',
          peakHourCount: peak.total,
          accent: meta.accent,
        ),
        const SizedBox(height: 10),
        HourlyScanChartCard(
          title: 'Grafik Scan Supermarket per Jam',
          points: hourly,
          accent: meta.accent,
        ),
        const SizedBox(height: 10),
        _SupermarketDetailTable(rows: tableRows),
      ],
    );
  }

  int _calcByLabel(List<StationScanEntry> entries, String label) {
    return entries.where((entry) => entry.workOrder == label).length;
  }

  int _calcWaiting(List<StationScanEntry> entries) {
    final waiting = entries.length - _calcByLabel(entries, _checkOutLabel);
    return waiting < 0 ? 0 : waiting;
  }

  String _normalizeActivity(String value) {
    if (value == _checkInLabel || value == _checkOutLabel) {
      return value;
    }
    return _checkInLabel;
  }

  Widget _buildStatusCards({
    required int waiting,
    required int checkIn,
    required int checkOut,
    required int supplyUrgent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatusCard(
              width: itemWidth,
              title: 'Waiting',
              value: waiting,
              color: const Color(0xFF6D28D9),
              icon: Icons.layers_rounded,
              background: const Color(0xFFF6F2FF),
              borderColor: const Color(0xFFD9CCFF),
              watermark: Icons.layers_rounded,
            ),
            _StatusCard(
              width: itemWidth,
              title: 'Check In',
              value: checkIn,
              color: const Color(0xFF0EA5E9),
              icon: Icons.inventory_2_outlined,
              background: const Color(0xFFEFF8FF),
              borderColor: const Color(0xFFB9E6FF),
              watermark: Icons.inventory_2_outlined,
            ),
            _StatusCard(
              width: itemWidth,
              title: 'Check Out',
              value: checkOut,
              color: const Color(0xFF16A34A),
              icon: Icons.check_circle_outline_rounded,
              background: const Color(0xFFEFFAF5),
              borderColor: const Color(0xFFB7F0D2),
              watermark: Icons.task_alt_rounded,
            ),
            _StatusCard(
              width: itemWidth,
              title: 'Supply Urgent',
              value: supplyUrgent,
              color: const Color(0xFFEA580C),
              icon: Icons.warning_amber_rounded,
              background: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFFFD7B0),
              watermark: Icons.local_shipping_outlined,
            ),
          ],
        );
      },
    );
  }

  void _openSupermarketScanningDialog(BuildContext context) {
    showTrackingRfidStationDialog(
      context,
      'Supermarket',
      onSubmitRfid: (rfid) async {
        final ok = context.read<ScannerState>().addSupermarketScan(
          rfid: rfid,
          workOrder: _checkInLabel,
        );
        return ok
            ? RfidScanSubmitResult.ok('Data scanning supermarket berhasil dicatat.')
            : RfidScanSubmitResult.fail('RFID duplikat atau gagal disimpan.');
      },
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

  static const String _checkInLabel = 'CHECK-IN';
  static const String _checkOutLabel = 'CHECK-OUT';
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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
                        fontSize: 24 / 2,
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
                    fontSize: 72 / 2,
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

class _SupermarketDetailRow {
  const _SupermarketDetailRow({
    required this.rfid,
    required this.activity,
    required this.qty,
    required this.scannedAt,
  });

  final String rfid;
  final String activity;
  final int qty;
  final DateTime scannedAt;
}

class _SupermarketDetailTable extends StatelessWidget {
  const _SupermarketDetailTable({required this.rows});

  final List<_SupermarketDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tabel Detail Supermarket',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
              columns: const [
                DataColumn(label: Text('RFID')),
                DataColumn(label: Text('Aktivitas')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Waktu Scan')),
              ],
              rows: rows.isEmpty
                  ? [
                      const DataRow(
                        cells: [
                          DataCell(Text('-')),
                          DataCell(Text('Belum ada data')),
                          DataCell(Text('0')),
                          DataCell(Text('-')),
                        ],
                      ),
                    ]
                  : rows
                        .map(
                          (row) => DataRow(
                            cells: [
                              DataCell(Text(row.rfid)),
                              DataCell(Text(row.activity)),
                              DataCell(Text('${row.qty}')),
                              DataCell(
                                Text(
                                  '${row.scannedAt.hour.toString().padLeft(2, '0')}:${row.scannedAt.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
