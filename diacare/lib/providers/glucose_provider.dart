import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/glucose_model.dart';

class GlucoseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPeriod = 'week';
  String _selectedUnit = 'mg/dL'; // 'mg/dL' or 'mmol/L'
  List<GlucoseReading> _readings = [];
  Map<String, dynamic> _stats = {};
  double _targetMin = 70.0;
  double _targetMax = 140.0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;
  String get selectedUnit => _selectedUnit;
  List<GlucoseReading> get readings => _readings;
  Map<String, dynamic> get stats => _stats;
  double get targetMin => _targetMin;
  double get targetMax => _targetMax;

  void setPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      fetchReadings();
    }
  }

  void toggleUnit() {
    _selectedUnit = (_selectedUnit == 'mg/dL') ? 'mmol/L' : 'mg/dL';
    notifyListeners();
  }

  Future<void> fetchReadings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get('${ApiConstants.getGlucoseReadings}?period=$_selectedPeriod');
      _isLoading = false;

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final rawList = data['readings'] as List? ?? [];
        _readings = rawList.map((item) => GlucoseReading.fromJson(item)).toList();
        _stats = data['stats'] ?? {};
        if (data['target_range'] != null) {
          _targetMin = double.tryParse(data['target_range']['min']?.toString() ?? '70') ?? 70.0;
          _targetMax = double.tryParse(data['target_range']['max']?.toString() ?? '140') ?? 140.0;
        }
      } else {
        _errorMessage = res['message'] ?? 'Failed to load glucose readings';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addReading({
    required double readingValue,
    required String mealType,
    required String unit,
    required DateTime measuredAt,
    String notes = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.addGlucoseReading, {
        'reading_value': readingValue,
        'meal_type': mealType,
        'unit': unit,
        'measured_at': measuredAt.toIso8601String(),
        'notes': notes,
      });

      _isLoading = false;
      if (res['success'] == true) {
        await fetchReadings();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to add reading';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReading(int id) async {
    try {
      final res = await ApiService.post(ApiConstants.deleteGlucoseReading, {'id': id});
      if (res['success'] == true) {
        _readings.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
