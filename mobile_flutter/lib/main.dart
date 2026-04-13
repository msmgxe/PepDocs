import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/theme.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const PepApp());
}

class PepApp extends StatelessWidget {
  const PepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pep Education',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final _sub = supabase.auth.onAuthStateChange.listen((_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _sub; // activate
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
