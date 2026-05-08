import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../state/scanner_state.dart';
import 'neo_card.dart';
import 'scan_history_format.dart';
import 'scanner_header_block.dart';
import 'scanner_stat_card.dart';

class ScannerHistoryPage extends StatelessWidget {
  const ScannerHistoryPage({
    super.key,
    required this.state,
    required this.barcodeController,
    required this.onOpenHistoryItem,
  });

  final ScannerState state;
  final TextEditingController barcodeController;
  final Future<void> Function(String barcode, {bool openBundlingDialog})
  onOpenHistoryItem;

  @override
  Widget build(BuildContext context) {
    final scannedToday = state.filteredHistory.length;
    final totalScanned = state.scanHistory.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        const ScannerHeaderBlock(
          title: 'Riwayat Scan',
          subtitle: 'Pantau aktivitas scanner secara realtime.',
          icon: Icons.history_toggle_off_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ScannerStatCard(
                label: 'Today',
                value: '$scannedToday',
                icon: Icons.today_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ScannerStatCard(
                label: 'Total',
                value: '$totalScanned',
                icon: Icons.qr_code_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Today'),
              selected: state.historyFilter == HistoryFilter.today,
              onSelected: (_) => state.setHistoryFilter(HistoryFilter.today),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('All'),
              selected: state.historyFilter == HistoryFilter.all,
              onSelected: (_) => state.setHistoryFilter(HistoryFilter.all),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.filteredHistory.isEmpty)
          NeoCard(
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined, color: Color(0xFF667085)),
                const SizedBox(width: 10),
                Text(
                  'Belum ada riwayat scan di filter ini.',
                  style: GoogleFonts.poppins(color: const Color(0xFF667085)),
                ),
              ],
            ),
          ),
        ...state.filteredHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 180 + (index * 60)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 10),
                  child: child,
                ),
              );
            },
            child: Dismissible(
              key: ValueKey<String>('hist-${item.barcode}-${item.createdAt}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => state.removeHistory(item),
              background: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF04438),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 18),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: NeoCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3155FF), Color(0xFF6F85FF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    item.barcode,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Scan: ${formatScanHistoryDate(item.createdAt)}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: IconButton.filledTonal(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      state.setActiveMenu(AppMenu.home);
                      barcodeController.text = item.barcode;
                      state.setBarcodeInput(item.barcode);
                      await onOpenHistoryItem(
                        item.barcode,
                        openBundlingDialog: true,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
