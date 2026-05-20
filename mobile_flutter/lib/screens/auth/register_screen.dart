import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/language_service.dart';
import '../../widgets/pep_logo.dart';
import 'otp_sheet.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      await signUp(email, _passwordController.text);
      if (mounted) {
        Navigator.pop(context);
        showOtpSheet(context, email);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final m = e.message.toLowerCase();
        final friendly = m.contains('rate limit')
            ? 'Demasiados intentos. Espera unos minutos e intenta de nuevo.'
            : m.contains('already registered')
                ? 'Este correo ya tiene una cuenta. Inicia sesión.'
                : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly), backgroundColor: kError),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l.tr('register_title'))),
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const PepLogo(size: 72),
                  const SizedBox(height: 12),
                  Text(
                    l.tr('register_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimary),
                  ),
                  const SizedBox(height: 24),

                  // ── Selector de idioma ──────────────────────────────────
                  Text(
                    l.tr('profile_language'),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: LanguageService.instance,
                    builder: (_, _) {
                      final current = LanguageService.instance.lang;
                      return Row(
                        children: [
                          for (final lang in [
                            ('es', 'Español', '🇲🇽'),
                            ('en', 'English', '🇺🇸'),
                            ('pt', 'Português', '🇧🇷'),
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      LanguageService.instance.setLanguage(lang.$1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: current == lang.$1
                                          ? kPrimary
                                          : kPrimary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(lang.$3,
                                            style: const TextStyle(fontSize: 20)),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang.$2,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: current == lang.$1
                                                ? Colors.white
                                                : kPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // ───────────────────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.tr('login_email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.tr('login_email_empty');
                      if (!v.contains('@')) return l.tr('login_email_invalid');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.tr('login_password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.tr('register_password_empty');
                      if (v.length < 6) return l.tr('login_password_short');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    decoration: InputDecoration(
                      labelText: l.tr('register_confirm_password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return l.tr('register_password_mismatch');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(l.tr('register_btn')),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.tr('register_has_account'),
                          style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          l.tr('register_login_link'),
                          style: TextStyle(
                              color: kPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
