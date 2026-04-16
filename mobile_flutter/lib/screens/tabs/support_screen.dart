import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/theme.dart';
import '../../services/language_service.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String _whatsAppNumber = '525500000000';

  Future<void> _openWhatsApp(BuildContext context) async {
    final l = LanguageService.instance;
    final encodedMessage = Uri.encodeComponent(l.tr('support_description'));
    final uri = Uri.parse(
        'https://wa.me/$_whatsAppNumber?text=$encodedMessage');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.tr('support_whatsapp_error')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l.tr('support_title'))),
      backgroundColor: kBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  size: 52,
                  color: Color(0xFF25D366),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.tr('support_question'),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l.tr('support_description'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _openWhatsApp(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(
                    l.tr('support_whatsapp_btn'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.tr('support_hours'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[500], height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
