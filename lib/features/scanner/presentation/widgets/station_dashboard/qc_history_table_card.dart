import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../state/scanner_state.dart';

class QcHistoryTableCard extends StatefulWidget {
  const QcHistoryTableCard({
    super.key,
    required this.items,
  });

  final List<QcDashboardItem> items;

  @override
  State<QcHistoryTableCard> createState() => _QcHistoryTableCardState();
}

class _QcHistoryTableCardState extends State<QcHistoryTableCard> {
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tabel Quality Control',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
          ),
          const SizedBox(height: 4),
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
                  DataColumn(label: Text('Good')),
                  DataColumn(label: Text('Repair')),
                  DataColumn(label: Text('Reject')),
                ],
                rows: items.isEmpty
                    ? const <DataRow>[
                        DataRow(
                          cells: [
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('0')),
                            DataCell(Text('0')),
                            DataCell(Text('0')),
                            DataCell(Text('0')),
                          ],
                        ),
                      ]
                    : items
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    item.rfidBundle.isEmpty
                                        ? '-'
                                        : item.rfidBundle,
                                  ),
                                ),
                                DataCell(
                                  Text(item.wo.isEmpty ? '-' : item.wo),
                                ),
                                DataCell(Text('${item.qtyOutput}')),
                                DataCell(Text('${item.qtyGood}')),
                                DataCell(Text('${item.qtyRepair}')),
                                DataCell(Text('${item.qtyReject}')),
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
}
