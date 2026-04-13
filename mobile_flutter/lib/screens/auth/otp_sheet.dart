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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
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
          _errorMsg = e.message;
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
    setState(() => _loading = true);
    try {
      await supabase.auth.resend(type: OtpType.email, email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código reenviado. Revisa tu correo.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ignore resend errors silently
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
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
            maxLength: 8,
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

          TextButton(
            onPressed: _loading ? null : _resend,
            child: Text(
              'Reenviar código',
              style: TextStyle(color: kPrimary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
