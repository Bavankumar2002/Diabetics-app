import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/medication_model.dart';

class MedicationProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<MedicationItem> _medications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MedicationItem> get medications => _medications;

  Future<void> fetchMedications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.getMedications);
      _isLoading = false;

      if (res['success'] == true && res['data'] != null) {
        final list = res['data']['medications'] as List? ?? [];
        _medications = list.map((e) => MedicationItem.fromJson(e)).toList();
      } else {
        _errorMessage = res['message'] ?? 'Failed to load medications';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addMedication({
    required String name,
    required String dosage,
    required String frequency,
    bool isInsulin = false,
    String? startDate,
    String? endDate,
    required String reminderTime,
    String instructions = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.addMedication, {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'is_insulin': isInsulin ? 1 : 0,
        'start_date': startDate,
        'end_date': endDate,
        'reminder_time': reminderTime,
        'instructions': instructions,
      });

      _isLoading = false;
      if (res['success'] == true) {
        await fetchMedications();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to add medication';
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

  Future<bool> updateStatus(int medicationId, String status) async {
    try {
      final res = await ApiService.post(ApiConstants.updateMedicationStatus, {
        'medication_id': medicationId,
        'status': status,
      });
      if (res['success'] == true) {
        await fetchMedications();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMedication(int medicationId) async {
    try {
      final res = await ApiService.post(ApiConstants.deleteMedication, {
        'id': medicationId,
      });
      if (res['success'] == true) {
        _medications.removeWhere((m) => m.id == medicationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
