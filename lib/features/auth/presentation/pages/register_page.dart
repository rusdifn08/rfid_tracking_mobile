import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const List<String> _bagianOptions = <String>[
    'SOFTWARE ENGINEER',
    'SEWING',
    'CUTTING',
    'QC',
    'ROBOTIC',
    'IT',
    'HR',
    'FINANCE',
    'WAREHOUSE',
    'DRYROOM',
    'FOLDING',
    'GUDANG',
    'IE',
  ];

  final _rfidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _lineController = TextEditingController(text: '1');
  final _telegramController = TextEditingController();
  final _noHpController = TextEditingController();
  String _bagian = _bagianOptions.first;
  bool _obscure = true;

  @override
  void dispose() {
    _rfidController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _nikController.dispose();
    _lineController.dispose();
    _telegramController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthState auth) async {
    FocusScope.of(context).unfocus();
    final ok = await auth.registerUser(
      rfidUser: _rfidController.text,
      password: _passwordController.text,
      nama: _namaController.text,
      nik: _nikController.text,
      bagian: _bagian,
      line: _lineController.text,
      telegram: _telegramController.text,
      noHp: _noHpController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.registerSuccessMessage ?? 'Registrasi berhasil.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(_nikController.text.trim());
    }
  }

  InputDecoration _decoration({
    required String hint,
    IconData? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix != null ? Icon(prefix) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD6DEEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0B69FF), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFF98A2B3),
        fontSize: 14,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$text *',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Register New User',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B82F6), Color(0xFF0B69FF)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDDE5F2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Lengkapi form di bawah untuk membuat akun baru.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF667085),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('RFID User'),
                      TextField(
                        controller: _rfidController,
                        decoration: _decoration(
                          hint: 'Masukkan RFID User',
                          prefix: Icons.nfc_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _label('Password'),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: _decoration(
                          hint: 'Masukkan Password',
                          prefix: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _label('Nama'),
                      TextField(
                        controller: _namaController,
                        decoration: _decoration(
                          hint: 'Masukkan Nama Lengkap',
                          prefix: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _label('NIK'),
                      TextField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        decoration: _decoration(
                          hint: 'Masukkan NIK',
                          prefix: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _label('Bagian'),
                      DropdownButtonFormField<String>(
                        initialValue: _bagian,
                        items: _bagianOptions
                            .map(
                              (bagian) => DropdownMenuItem<String>(
                                value: bagian,
                                child: Text(
                                  bagian,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        decoration: _decoration(
                          hint: 'Pilih Bagian',
                          prefix: Icons.business_center_outlined,
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _bagian = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _label('Line'),
                      TextField(
                        controller: _lineController,
                        keyboardType: TextInputType.number,
                        decoration: _decoration(
                          hint: 'Masukkan Line',
                          prefix: Icons.numbers_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No HP',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _noHpController,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration(
                          hint: 'Opsional',
                          prefix: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Telegram',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _telegramController,
                        decoration: _decoration(
                          hint: 'Opsional',
                          prefix: Icons.alternate_email_rounded,
                        ),
                      ),
                      if ((auth.registerErrorMessage ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            auth.registerErrorMessage!,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFB42318),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: auth.isRegistering ? null : () => _submit(auth),
                          icon: auth.isRegistering
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            auth.isRegistering ? 'Menyimpan...' : 'Register',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0B69FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
