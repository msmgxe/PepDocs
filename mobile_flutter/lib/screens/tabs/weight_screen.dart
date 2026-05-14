import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/units_service.dart';
import '../../services/language_service.dart';

const _kAdminUrl = 'https://pepeducation-admin.vercel.app';
const _kNotifySecret = String.fromEnvironment('NOTIFY_SECRET', defaultValue: 'pep-notify-2026');

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<Map<String, dynamic>> _measurements = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await getProfile();
      if (profile == null) return;
      final measurements = await getMeasurements(profile['id'].toString());
      if (mounted) {
        setState(() {
          _profile = profile;
          _measurements = measurements;
        });
      }
    } catch (e) {
      // ignore load errors — spinner will stop in finally
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _toDisplay(double kg) => UnitsService.instance.displayWeight(kg);
  String get _unit => UnitsService.instance.weightUnitStr;

  double? _calcBmi(double weightKg) {
    final height = (_profile?['height_cm'] as num?)?.toDouble();
    if (height == null || height == 0) return null;
    final h = height / 100;
    return weightKg / (h * h);
  }

  String _bmiLabel(double bmi) {
    final l = LanguageService.instance;
    if (bmi < 18.5) return l.tr('bmi_underweight');
    if (bmi < 25) return l.tr('bmi_normal_short');
    if (bmi < 30) return l.tr('bmi_overweight');
    return l.tr('bmi_obesity');
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _showAddDialog() => _showMeasurementDialog(null);
  void _showEditDialog(Map<String, dynamic> m) => _showMeasurementDialog(m);

  void _showMeasurementDialog(Map<String, dynamic>? existing) {
    final l = LanguageService.instance;
    final existingKg = (existing?['weight_kg'] as num?)?.toDouble();
    bool dialogUseLbs = UnitsService.instance.isLbs;

    double toDisplay(double kg) => dialogUseLbs ? kg * 2.20462 : kg;
    double toKg(double display) => dialogUseLbs ? display / 2.20462 : display;
    String unit() => dialogUseLbs ? 'lbs' : 'kg';

    final weightController = TextEditingController(
      text: existingKg != null ? toDisplay(existingKg).toStringAsFixed(1) : '',
    );
    final notesController =
        TextEditingController(text: existing?['notes']?.toString() ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.tryParse(
                existing['measurement_date'].toString().substring(0, 10)) ??
            DateTime.now()
        : DateTime.now();
    File? selectedImage;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
          final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.tr('app_name'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          existing == null
                              ? l.tr('weight_add_dialog')
                              : l.tr('weight_edit_dialog'),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date picker
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l.tr('weight_date'),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),

                // Weight field
                TextFormField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l.tr('weight_field',
                        params: {'unit': unit()}),
                    prefixIcon:
                        const Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.tr('weight_empty_field');
                    if (double.tryParse(v) == null) return l.tr('invalid_number');
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l.tr('weight_notes'),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),

                // Photo — preview + camera + gallery
                Row(
                  children: [
                    if (selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(selectedImage!,
                            width: 60, height: 60, fit: BoxFit.cover),
                      )
                    else if (existing?['photo_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          existing!['photo_url'].toString(),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx2, err, st) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    if (selectedImage != null ||
                        existing?['photo_url'] != null)
                      const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera_outlined, size: 17),
                        label: Text(l.tr('weight_camera')),
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                            maxWidth: 1080,
                          );
                          if (picked != null) {
                            setDialogState(
                                () => selectedImage = File(picked.path));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 17),
                        label: Text(l.tr('weight_gallery')),
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1080,
                          );
                          if (picked != null) {
                            setDialogState(
                                () => selectedImage = File(picked.path));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final displayVal =
                        double.parse(weightController.text);
                    Navigator.pop(ctx);
                    await _saveMeasurement(
                      existing: existing,
                      weightKg: toKg(displayVal),
                      date: selectedDate,
                      notes: notesController.text.trim(),
                      imageFile: selectedImage,
                    );
                  },
                  child: Text(existing == null
                      ? l.tr('save')
                      : l.tr('update')),
                ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveMeasurement({
    Map<String, dynamic>? existing,
    required double weightKg,
    required DateTime date,
    String? notes,
    File? imageFile,
  }) async {
    if (_profile == null) return;
    try {
      String? photoUrl = existing?['photo_url']?.toString();
      if (imageFile != null) {
        photoUrl = await uploadPhoto(imageFile, _profile!['id'].toString());
      }

      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final data = {
        'patient_id': _profile!['id'].toString(),
        'weight_kg': weightKg,
        'measurement_date': dateStr,
        'notes': notes,
        'photo_url': photoUrl,
      };

      if (existing == null) {
        await addMeasurement(data);
      } else {
        data.remove('patient_id');
        await updateMeasurement(existing['id'].toString(), data);
      }

      // Keep profile's current_weight_kg in sync with the latest measurement
      final allMeasurements = await getMeasurements(_profile!['id'].toString());
      if (allMeasurements.isNotEmpty) {
        final latestWeight = (allMeasurements.first['weight_kg'] as num).toDouble();
        await supabase
            .from('profiles')
            .update({'current_weight_kg': latestWeight})
            .eq('id', _profile!['id'].toString());
      }

      await _loadData();

      // Send WhatsApp notification to admin
      final height = (_profile!['height_cm'] as num?)?.toDouble();
      double? bmi;
      if (height != null && height > 0) {
        final hm = height > 3 ? height / 100 : height;
        bmi = double.parse((weightKg / (hm * hm)).toStringAsFixed(1));
      }
      _sendNotification(
        patientName: _profile!['full_name']?.toString() ?? 'Paciente',
        weightKg: weightKg,
        measurementDate: dateStr,
        bmi: bmi,
        action: existing == null ? 'add' : 'update',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  void _sendNotification({
    required String patientName,
    required double weightKg,
    required String measurementDate,
    double? bmi,
    required String action,
  }) {
    http.post(
      Uri.parse('$_kAdminUrl/api/notify-weight'),
      headers: {
        'Content-Type': 'application/json',
        'x-notify-secret': _kNotifySecret,
      },
      body: jsonEncode({
        'patientName': patientName,
        'weightKg': weightKg,
        'measurementDate': measurementDate,
        'bmi': bmi,
        'action': action,
      }),
    ).catchError((_) => http.Response('', 200)); // fire-and-forget
  }

  Future<void> _deleteMeasurement(String id) async {
    final l = LanguageService.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tr('weight_delete_title')),
        content: Text(l.tr('weight_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kError),
            child: Text(l.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await deleteMeasurement(id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final dateLocale = l.dateLocale;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.tr('app_name'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(l.tr('weight_title'), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
      backgroundColor: kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _measurements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monitor_weight_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(l.tr('weight_empty'),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text(l.tr('weight_empty_hint'),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _measurements.length,
                      itemBuilder: (ctx, i) {
                        final m = _measurements[i];
                        final dateStr = m['measurement_date']
                                ?.toString()
                                .substring(0, 10) ??
                            '';
                        final date = DateTime.tryParse(dateStr);
                        final weightKg =
                            (m['weight_kg'] as num?)?.toDouble() ?? 0;
                        final display = _toDisplay(weightKg);
                        final bmi = _calcBmi(weightKg);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                            leading: m['photo_url'] != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Image.network(
                                      m['photo_url'].toString(),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx2, err, st) =>
                                          Icon(
                                              Icons
                                                  .monitor_weight_outlined,
                                              color: kPrimary),
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor:
                                        kPrimary.withValues(alpha: 0.1),
                                    child: Icon(
                                        Icons.monitor_weight_outlined,
                                        color: kPrimary),
                                  ),
                            title: Text(
                              '${display.toStringAsFixed(1)} $_unit',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (date != null)
                                  Text(DateFormat('dd MMM yyyy',
                                          dateLocale)
                                      .format(date)),
                                if (bmi != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _bmiColor(bmi)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'IMC ${bmi.toStringAsFixed(1)} · ${_bmiLabel(bmi)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _bmiColor(bmi),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (m['notes'] != null &&
                                    m['notes'].toString().isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 2),
                                    child: Text(
                                      m['notes'].toString(),
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showEditDialog(m),
                                  color: kPrimary,
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline),
                                  onPressed: () => _deleteMeasurement(
                                      m['id'].toString()),
                                  color: kError,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
