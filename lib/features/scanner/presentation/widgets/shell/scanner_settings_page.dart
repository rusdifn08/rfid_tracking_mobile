import 'package:flutter/material.dart';

import '../menu_info_card.dart';
import 'scanner_header_block.dart';

class ScannerSettingsPage extends StatelessWidget {
  const ScannerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ScannerHeaderBlock(
          title: 'Settings',
          subtitle: 'Kontrol konfigurasi aplikasi dan scanner.',
          icon: Icons.tune_rounded,
        ),
        SizedBox(height: 12),
        MenuInfoCard(
          title: 'Pengaturan Scanner',
          subtitle: 'Konfigurasi lanjutan bisa ditambahkan di sini.',
          icon: Icons.settings_suggest_outlined,
        ),
        MenuInfoCard(
          title: 'Koneksi API Lokal',
          subtitle: 'Server saat ini: http://10.5.0.201:9000',
          icon: Icons.wifi_tethering,
        ),
        MenuInfoCard(
          title: 'Notifikasi',
          subtitle: 'Kelola notifikasi status scan dan sinkronisasi.',
          icon: Icons.notifications_active_outlined,
        ),
        MenuInfoCard(
          title: 'Keamanan Data',
          subtitle: 'Atur proteksi data lokal operator dan aktivitas scan.',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }
}
