import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

/// Shows a bottom sheet for OTP email verification.
/// Call via [showOtpSheet].
void showOtpSheet(BuildContext context, String email) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    builder: (ctx) => OtpSheet(email: email),
  );
}

class OtpSheet extends StatefulWidget {
  final String email;
  const OtpSheet({super.key, required this.email});

  @override
  State<OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<OtpSheet> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _errorMsg;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _countdown--; });
      if (_countdown <= 0) t.cancel();
    });
  }

  String _fmtCountdown() {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMsg = 'Ingresa el código');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.email,
      );
      // AuthGate in main.dart picks up the new session automatically
      if (mounted) { Navigator.pop(context); }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = _friendlyError(e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0 || _loading) return;
    setState(() => _loading = true);
    try {
      await supabase.auth.resend(type: OtpType.email, email: widget.email);
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código reenviado. Revisa tu correo.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e.message)), backgroundColor: kError),
        );
      }
    } catch (_) {
      // ignore other resend errors silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('rate limit')) return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
    if (m.contains('already registered')) return 'Este correo ya tiene una cuenta. Inicia sesión.';
    if (m.contains('invalid')) return 'Código incorrecto. Verifica e intenta de nuevo.';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Icon(Icons.mark_email_read_outlined, size: 52, color: kPrimary),
          const SizedBox(height: 12),

          const Text(
            'Verifica tu correo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el código enviado a:\n${widget.email}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // OTP input
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration: InputDecoration(
              hintText: '- - - - - -',
              hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 8),
              counterText: '',
              errorText: _errorMsg,
              filled: true,
              fillColor: kPrimary.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Verificar código'),
            ),
          ),
          const SizedBox(height: 12),

          _countdown > 0
              ? Text(
                  'Reenviar código en ${_fmtCountdown()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                )
              : TextButton(
                  onPressed: _loading ? null : _resend,
                  child: Text(
                    '¿No recibiste el código? Reenviar',
                    style: TextStyle(color: kPrimary),
                  ),
                ),
          const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
