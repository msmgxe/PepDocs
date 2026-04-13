import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<Map<String, dynamic>> _measurements = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _useLbs = false;

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
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Unit conversion helpers
  double _toDisplay(double kg) => _useLbs ? kg * 2.20462 : kg;
  double _toKg(double display) => _useLbs ? display / 2.20462 : display;
  String get _unit => _useLbs ? 'lbs' : 'kg';

  // BMI helpers
  double? _calcBmi(double weightKg) {
    final height = (_profile?['height_cm'] as num?)?.toDouble();
    if (height == null || height == 0) return null;
    final h = height / 100;
    return weightKg / (h * h);
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
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
    final existingKg = (existing?['weight_kg'] as num?)?.toDouble();
    final weightController = TextEditingController(
      text: existingKg != null ? _toDisplay(existingKg).toStringAsFixed(1) : '',
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
        builder: (ctx, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      existing == null ? 'Registrar peso' : 'Editar registro',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
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
                    labelText: 'Peso ($_unit)',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa el peso';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes),
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
                        label: const Text('Cámara'),
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                            maxWidth: 1080,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedImage = File(picked.path));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined, size: 17),
                        label: const Text('Galería'),
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1080,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedImage = File(picked.path));
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
                    final displayVal = double.parse(weightController.text);
                    Navigator.pop(ctx);
                    await _saveMeasurement(
                      existing: existing,
                      weightKg: _toKg(displayVal),
                      date: selectedDate,
                      notes: notesController.text.trim(),
                      imageFile: selectedImage,
                    );
                  },
                  child: Text(existing == null ? 'Guardar' : 'Actualizar'),
                ),
              ],
            ),
          ),
        ),
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

      final data = {
        'patient_id': _profile!['id'].toString(),
        'weight_kg': weightKg,
        'measurement_date': date.toIso8601String(),
        'notes': notes,
        'photo_url': photoUrl,
      };

      if (existing == null) {
        await addMeasurement(data);
      } else {
        data.remove('patient_id');
        await updateMeasurement(existing['id'].toString(), data);
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  Future<void> _deleteMeasurement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kError),
            child: const Text('Eliminar'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso'),
        actions: [
          // kg / lbs toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'kg',
                  style: TextStyle(
                    color: !_useLbs ? Colors.white : Colors.white54,
                    fontWeight:
                        !_useLbs ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                Switch(
                  value: _useLbs,
                  onChanged: (v) => setState(() => _useLbs = v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white30,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  'lbs',
                  style: TextStyle(
                    color: _useLbs ? Colors.white : Colors.white54,
                    fontWeight:
                        _useLbs ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
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
                          Text('Sin registros aún',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Toca + para agregar tu primer registro',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: m['photo_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      m['photo_url'].toString(),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx2, err, st) => Icon(
                                          Icons.monitor_weight_outlined,
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
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (date != null)
                                  Text(DateFormat('dd MMM yyyy', 'es')
                                      .format(date)),
                                if (bmi != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
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
                                    padding: const EdgeInsets.only(top: 2),
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
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _deleteMeasurement(m['id'].toString()),
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
