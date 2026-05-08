import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mock/station_dashboard_models.dart';

class StationHistoryTableCard extends StatelessWidget {
  const StationHistoryTableCard({
    super.key,
    required this.rows,
    this.title = 'Tabel History',
  });

  final List<StationHistoryRow> rows;
  final String title;

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          _HeaderRow(
            headers: const ['RFID BUNDLE', 'WORK ORDER', 'QTY'],
            flexes: const [5, 5, 2],
          ),
          const Divider(height: 1, color: Color(0xFFE4E7EC)),
          ...rows.map(
            (row) => _DataRow(
              cells: [row.rfid, row.workOrder, '${row.qty}'],
              flexes: const [5, 5, 2],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.headers, required this.flexes});

  final List<String> headers;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < headers.length; i++)
          Expanded(
            flex: flexes[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                headers[i],
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF667085),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.cells, required this.flexes});

  final List<String> cells;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF2F4F7))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Text(
                  cells[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF344054),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
