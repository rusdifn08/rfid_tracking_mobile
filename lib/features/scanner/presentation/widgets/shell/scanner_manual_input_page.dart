import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../state/scanner_state.dart';
import 'neo_card.dart';
import 'scanner_header_block.dart';
import 'scanner_shell_colors.dart';

class ScannerManualInputPage extends StatelessWidget {
  const ScannerManualInputPage({
    super.key,
    required this.state,
    required this.barcodeController,
    required this.onFetchBarcode,
  });

  final ScannerState state;
  final TextEditingController barcodeController;
  final Future<void> Function(String barcode, {bool openBundlingDialog})
  onFetchBarcode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const ScannerHeaderBlock(
            title: 'Manual Input',
            subtitle: 'Masukkan barcode saat kamera tidak digunakan.',
            icon: Icons.keyboard_alt_outlined,
          ),
          const SizedBox(height: 12),
          NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan Barcode',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: barcodeController,
                  onChanged: state.setBarcodeInput,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Contoh: BD20260504-565507',
                    prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isFetching
                        ? null
                        : () => onFetchBarcode(
                            barcodeController.text.trim(),
                            openBundlingDialog: true,
                          ),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(
                      state.isFetching ? 'Memproses...' : 'Ambil Data',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeoCard(
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  color: ScannerShellColors.primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.hasResultData
                        ? 'Data berhasil diambil. Lihat detail di menu Home.'
                        : 'Tips: gunakan format barcode lengkap agar pencarian cepat.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: state.hasResultData
                          ? const Color(0xFF039855)
                          : const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
