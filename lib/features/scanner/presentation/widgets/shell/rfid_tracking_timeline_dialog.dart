import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/models/rfid_checking_record.dart';
import 'rfid_checking_format.dart';
import 'rfid_checking_theme.dart';

Future<void> showRfidTrackingTimelineDialog(
  BuildContext context, {
  required String rfid,
  required List<RfidCheckingRecord> records,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _RfidTrackingTimelineDialog(rfid: rfid, records: records);
    },
  );
}

class _RfidTrackingTimelineDialog extends StatelessWidget {
  const _RfidTrackingTimelineDialog({
    required this.rfid,
    required this.records,
  });

  final String rfid;
  final List<RfidCheckingRecord> records;

  @override
  Widget build(BuildContext context) {
    final sorted = List<RfidCheckingRecord>.from(records)
      ..sort((a, b) {
        final at = a.logCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.logCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: RfidCheckingTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          maxWidth: 560,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                gradient: RfidCheckingTheme.heroGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracking Bundle Cutting',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          rfid,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                shrinkWrap: true,
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  return _TimelineRecordCard(
                    record: sorted[index],
                    isFirst: index == 0,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Total: ${sorted.length} tracking records',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: RfidCheckingTheme.primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRecordCard extends StatelessWidget {
  const _TimelineRecordCard({
    required this.record,
    required this.isFirst,
  });

  final RfidCheckingRecord record;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final statusStyle = RfidCheckingFormat.statusStyle(record.lastStatus);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isFirst
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isFirst)
                Container(
                  width: 2,
                  height: 120,
                  color: const Color(0xFFE2E8F0),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _StatusChip(
                              label: record.lastStatus,
                              background: statusStyle.background,
                              foreground: statusStyle.foreground,
                            ),
                            const _MetaChip(
                              icon: Icons.place_outlined,
                              label: 'CUTTING',
                            ),
                            if (record.meja.isNotEmpty)
                              _MetaChip(
                                icon: Icons.table_restaurant_outlined,
                                label: 'Meja ${record.meja}',
                              ),
                          ],
                        ),
                      ),
                      if (record.logCreatedAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              RfidCheckingFormat.dateTime(record.logCreatedAt!),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Barcode: ${record.barcode}  •  Qty: ${record.qtyBatch}  •  Batch: ${record.batch}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF475467),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DetailGrid(record: record),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.record});

  final RfidCheckingRecord record;

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      ['WO', record.wo, 'Style', record.style],
      ['Meja', record.meja, 'Warna', record.warna],
      ['Size', record.size, 'No. Ikat', record.noIkat],
      ['No. Urut', record.noUrut, 'Season', record.season],
      ['Country', record.country, '', ''],
    ];
    return Column(
      children: rows
          .where((r) => r[1].isNotEmpty || r[3].isNotEmpty)
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _DetailCell(label: row[0], value: row[1])),
                  const SizedBox(width: 8),
                  Expanded(child: _DetailCell(label: row[2], value: row[3])),
                ],
              ),
            ),
          )
          .toList(),
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
        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF334155)),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value.isEmpty ? '—' : value),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF475467),
            ),
          ),
        ],
      ),
    );
  }
}
