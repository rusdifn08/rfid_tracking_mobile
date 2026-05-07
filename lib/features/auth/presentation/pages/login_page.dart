import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'register_page.dart';
import '../../state/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool? _rememberMe;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthState auth) async {
    FocusScope.of(context).unfocus();
    await auth.login(
      nik: _nikController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        final canSubmit =
            !auth.isLoading &&
            _nikController.text.trim().isNotEmpty &&
            _passwordController.text.trim().isNotEmpty;
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3B82F6), Color(0xFF0B69FF)],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1FFFFFFF),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x2EFFFFFF),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In as Employee',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 34,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Hey, Enter the NIK & Password registered with GCC or HRIS to enter your account.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF667085),
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'NIK',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nikController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Your NIK',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFD6DEEA)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0B69FF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Password',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => canSubmit ? _submit(auth) : null,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() => _obscure = !_obscure);
                                  },
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFD6DEEA)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0B69FF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _rememberMe ?? false,
                                  onChanged: (v) {
                                    setState(() => _rememberMe = v ?? false);
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  'Remember Me',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF344054),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if ((auth.errorMessage ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFB42318),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: canSubmit ? () => _submit(auth) : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B69FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white.withValues(alpha: 0.95),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        final result = await Navigator.of(context)
                                            .push<String>(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterPage(),
                                              ),
                                            );
                                        if (result != null &&
                                            result.trim().isNotEmpty &&
                                            mounted) {
                                          _nikController.text = result.trim();
                                          setState(() {});
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF344054),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Register',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Forgot Password..?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF667085),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
