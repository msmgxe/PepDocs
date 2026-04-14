import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitsService extends ChangeNotifier {
  static final UnitsService _instance = UnitsService._internal();
  static UnitsService get instance => _instance;

  UnitsService._internal();

  bool _isLbs = false; // false = kg, true = lbs
  bool _isFt = false;  // false = cm, true = ft

  bool get isLbs => _isLbs;
  bool get isFt => _isFt;

  String get weightUnitStr => _isLbs ? 'lbs' : 'kg';
  String get heightUnitStr => _isFt ? 'ft + in' : 'cm';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLbs = prefs.getBool('pep_is_lbs') ?? false;
    _isFt = prefs.getBool('pep_is_ft') ?? false;
    notifyListeners();
  }

  Future<void> setWeightUnit(bool isLbs) async {
    if (_isLbs == isLbs) return;
    _isLbs = isLbs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pep_is_lbs', isLbs);
    notifyListeners();
  }

  Future<void> setHeightUnit(bool isFt) async {
    if (_isFt == isFt) return;
    _isFt = isFt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pep_is_ft', isFt);
    notifyListeners();
  }

  // Helper conversions
  double displayWeight(double kg) {
    return _isLbs ? kg * 2.20462 : kg;
  }

  double reverseWeight(double input) {
    return _isLbs ? input / 2.20462 : input;
  }

  String formatWeight(double kg) {
    return '${displayWeight(kg).toStringAsFixed(1)} $weightUnitStr';
  }

  String formatHeight(double cm) {
    if (!_isFt) return '${cm.toStringAsFixed(0)} cm';
    final totalInches = cm / 2.54;
    final ft = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '$ft\' $inches"';
  }
}
