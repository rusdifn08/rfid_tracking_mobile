import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../auth/state/auth_state.dart';
import 'neo_card.dart';
import 'scanner_header_block.dart';
import 'scanner_stat_card.dart';

class ScannerProfilePage extends StatelessWidget {
  const ScannerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.currentUser;
    final displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name
        : 'Operator Scanner';
    final displayJabatan = (user?.jabatan.trim().isNotEmpty ?? false)
        ? user!.jabatan
        : 'Belum ada jabatan';
    final displayNik = (user?.nik.trim().isNotEmpty ?? false) ? user!.nik : '-';
    final displayRole = (user?.role.trim().isNotEmpty ?? false)
        ? user!.role.toUpperCase()
        : 'USER';
    final displayLine = (user?.line.trim().isNotEmpty ?? false) ? user!.line : '-';
    final displayBranch = (user?.branch.trim().isNotEmpty ?? false)
        ? user!.branch
        : '-';
    final displayRfid = (user?.rfidUser.trim().isNotEmpty ?? false)
        ? user!.rfidUser
        : '-';
    final displayNoHp = (user?.noHp.trim().isNotEmpty ?? false) ? user!.noHp : '-';
    final displayTelegram = (user?.telegram.trim().isNotEmpty ?? false)
        ? user!.telegram
        : '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScannerHeaderBlock(
          title: 'Profile',
          subtitle: 'Informasi akun login dan identitas operator.',
          icon: Icons.account_circle_outlined,
        ),
        const SizedBox(height: 12),
        NeoCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3155FF), Color(0xFF6F85FF)],
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$displayJabatan • NIK $displayNik',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Login Aktif • $displayRole',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF067647),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ScannerStatCard(
          label: 'NIK',
          value: displayNik,
          icon: Icons.badge_outlined,
        ),
        ScannerStatCard(
          label: 'Bagian / Jabatan',
          value: displayJabatan,
          icon: Icons.work_outline_rounded,
        ),
        ScannerStatCard(
          label: 'Line • Branch',
          value: '$displayLine • $displayBranch',
          icon: Icons.route_outlined,
        ),
        ScannerStatCard(
          label: 'RFID User',
          value: displayRfid,
          icon: Icons.nfc_rounded,
        ),
        ScannerStatCard(
          label: 'Kontak',
          value: 'HP: $displayNoHp | Telegram: $displayTelegram',
          icon: Icons.contact_phone_outlined,
        ),
        NeoCard(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async => auth.logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB42318),
                side: const BorderSide(color: Color(0xFFFDA29B)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
