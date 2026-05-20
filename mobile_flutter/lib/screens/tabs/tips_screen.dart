import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/language_service.dart';

// ─── Full-screen image viewer with pinch-to-zoom ─────────────────────────────

class _ImageViewer extends StatelessWidget {
  final String imageUrl;
  const _ImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 6.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tips screen ─────────────────────────────────────────────────────────────

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  List<Map<String, dynamic>> _tips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() => _loading = true);
    try {
      final tips = await getTips();
      if (mounted) setState(() => _tips = tips);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  IconData _iconForName(String? name) {
    switch (name) {
      case 'water':       return Icons.water_drop_outlined;
      case 'fitness':     return Icons.fitness_center_outlined;
      case 'nutrition':   return Icons.restaurant_outlined;
      case 'motivation':  return Icons.emoji_events_outlined;
      case 'heart':       return Icons.favorite_outline;
      case 'apple':       return Icons.eco_outlined;
      case 'sleep':       return Icons.bedtime_outlined;
      case 'meditation':  return Icons.self_improvement_outlined;
      case 'walk':        return Icons.directions_walk_outlined;
      case 'vegetables':  return Icons.grass_outlined;
      case 'star':        return Icons.star_outline;
      default:            return Icons.lightbulb_outline;
    }
  }

  Color _colorForCategory(String? cat) {
    switch (cat) {
      case 'nutricion':   return const Color(0xFF43A047);
      case 'ejercicio':   return const Color(0xFF1E88E5);
      case 'motivacion':  return const Color(0xFFE53935);
      case 'hidratacion': return const Color(0xFF00ACC1);
      case 'sugerencia':  return const Color(0xFFEF6C00);
      default:            return kPrimary;
    }
  }

  String _catLabel(String? cat, LanguageService l) {
    switch (cat) {
      case 'tip':         return l.tr('tips_cat_tip');
      case 'sugerencia':  return l.tr('tips_cat_sugerencia');
      case 'nutricion':   return l.tr('tips_cat_nutricion');
      case 'ejercicio':   return l.tr('tips_cat_ejercicio');
      case 'motivacion':  return l.tr('tips_cat_motivacion');
      case 'hidratacion': return l.tr('tips_cat_hidratacion');
      default:            return l.tr('tips_cat_general');
    }
  }

  String _formatDate(String? raw, LanguageService l) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final locale = l.dateLocale;
    if (locale == 'en') return DateFormat('MMM d, y', 'en').format(dt.toLocal());
    return DateFormat("d 'de' MMM yyyy", locale).format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.tr('app_name'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(l.tr('tips_title'), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ),
        backgroundColor: kBackground,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTips,
                child: _tips.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(l.tr('tips_empty'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(l.tr('tips_empty_hint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tips.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final tip = _tips[i];
                          final cat = tip['category']?.toString();
                          final iconName = tip['icon_name']?.toString();
                          final color = _colorForCategory(cat);
                          final imageUrl = tip['image_url']?.toString();
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _openImage(imageUrl),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.fitWidth,
                                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(_iconForName(iconName), color: color, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tip['title']?.toString() ?? '',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: color.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        _catLabel(cat, l),
                                                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _formatDate(tip['published_at']?.toString(), l),
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        tip['body']?.toString() ?? '',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
