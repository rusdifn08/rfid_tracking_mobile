import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../auth/state/auth_state.dart';
import '../../../../state/scanner_state.dart';
import '../../../widgets/shell/tracking_rfid_station_dialog.dart';
import '../../../widgets/station_dashboard/station_page_scaffold.dart';
import '../../../widgets/station_dashboard/supermarket_hourly_chart_card.dart';

class SupermarketStationPage extends StatefulWidget {
  const SupermarketStationPage({super.key});

  @override
  State<SupermarketStationPage> createState() => _SupermarketStationPageState();
}

class _SupermarketStationPageState extends State<SupermarketStationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ScannerState>().fetchSupermarketDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScannerState>();
    final meta = trackingStationMetaOf('Supermarket');
    final dashboard = state.supermarketDashboard;

    return StationPageScaffold(
      title: 'Supermarket Dashboard',
      subtitle: meta.subtitle,
      accent: meta.accent,
      icon: meta.icon,
      children: [
        _buildStatusCards(
          waiting: dashboard.jumlahBundle,
          checkIn: dashboard.checkIn,
          checkOut: dashboard.checkOut,
          supplyUrgent: dashboard.supplyUrgent,
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
        SupermarketHourlyChartCard(
          title: 'Data Per Jam',
          points: dashboard.dataPerJam,
        ),
        const SizedBox(height: 10),
        _SupermarketDetailTable(items: dashboard.items),
      ],
    );
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
              title: 'Jumlah Bundle',
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
      onSubmitRfid: (payload) async {
        final scannerState = context.read<ScannerState>();
        final authState = context.read<AuthState>();
        final nik = authState.currentUser?.nik.trim() ?? '';
        if (nik.isEmpty) {
          return RfidScanSubmitResult.fail(
            'NIK tidak tersedia. Silakan login ulang.',
          );
        }
        try {
          await scannerState.submitSupermarketScan(
            rfidBundles: payload.rfid,
            nik: nik,
            status: payload.status ?? 'in',
            line: payload.line,
            branch: payload.branch,
          );
          return RfidScanSubmitResult.ok('Data scanning supermarket berhasil dicatat.');
        } catch (e) {
          return RfidScanSubmitResult.fail(ScannerState.userFacingError(e));
        }
      },
    );
  }
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

class _SupermarketDetailTable extends StatefulWidget {
  const _SupermarketDetailTable({required this.items});

  final List<SupermarketDashboardItem> items;

  @override
  State<_SupermarketDetailTable> createState() =>
      _SupermarketDetailTableState();
}

class _SupermarketDetailTableState extends State<_SupermarketDetailTable> {
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  List<SupermarketDashboardItem> get items => widget.items;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tabel Supermarket Cutting',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '${items.length} baris',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Scrollbar(
            controller: _hScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _hScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 38,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                headingTextStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
                columns: const [
                  DataColumn(label: Text('RFID Bundle')),
                  DataColumn(label: Text('WO')),
                  DataColumn(label: Text('QTY')),
                  DataColumn(label: Text('Line')),
                  DataColumn(label: Text('Lokasi')),
                  DataColumn(label: Text('Waktu')),
                ],
                rows: items.isEmpty
                    ? const <DataRow>[
                        DataRow(
                          cells: [
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('0')),
                            DataCell(Text('—')),
                            DataCell(Text('Belum ada data')),
                            DataCell(Text('-')),
                          ],
                        ),
                      ]
                    : items
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(Text(item.rfidBundle)),
                                DataCell(Text(item.wo)),
                                DataCell(Text('${item.qty}')),
                                DataCell(Text(_formatLine(item))),
                                DataCell(Text(_formatLokasi(item))),
                                DataCell(Text(_formatWaktu(item))),
                              ],
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLine(SupermarketDashboardItem item) {
    final v = item.line.trim();
    return v.isEmpty ? '—' : v;
  }

  String _formatLokasi(SupermarketDashboardItem item) {
    // Lokasi diturunkan dari last_status agar sinkron dengan dashboard web:
    // IN_SMARKET   -> "supermarket"
    // OUT_SMARKET  -> "OUT SMARKET"
    // SUPPLY_URGENT -> "SUPPLY URGENT"
    final status = item.lastStatus.toUpperCase().trim();
    switch (status) {
      case 'IN_SMARKET':
        return 'supermarket';
      case 'OUT_SMARKET':
        return 'OUT SMARKET';
      case 'SUPPLY_URGENT':
        return 'SUPPLY URGENT';
    }
    final branch = item.branch.trim();
    return branch.isEmpty ? 'supermarket' : branch;
  }

  String _formatWaktu(SupermarketDashboardItem item) {
    final dt = item.smarketTime;
    if (dt == null) {
      return '-';
    }
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final mon = months[(dt.month - 1).clamp(0, 11)];
    final year = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$day $mon $year pukul $hh.$mm';
  }
}
