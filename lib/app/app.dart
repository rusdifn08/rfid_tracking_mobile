import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/state/auth_state.dart';
import '../features/scanner/presentation/pages/scanner_shell_page.dart';
import '../features/scanner/state/scanner_state.dart';
import 'theme.dart';

class ScannerMainApp extends StatelessWidget {
  const ScannerMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScannerState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gistex Mobile',
        theme: buildAppTheme(),
        home: const _AppEntryGate(),
      ),
    );
  }
}

class _AppEntryGate extends StatefulWidget {
  const _AppEntryGate();

  @override
  State<_AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<_AppEntryGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AuthState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        if (auth.isBooting) {
          return const SplashPage();
        }
        if (!auth.isLoggedIn) {
          return const LoginPage();
        }
        return const ScannerShellPage();
      },
    );
  }
}
