import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _summaryData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get summaryData => _summaryData;

  String get greeting => _summaryData?['greeting'] ?? 'Good Day';
  String get userName => _summaryData?['user_name'] ?? 'User';
  String get todayDate => _summaryData?['today_date'] ?? '';

  Map<String, dynamic> get glucoseSummary => _summaryData?['glucose'] ?? {};
  Map<String, dynamic> get nutritionSummary => _summaryData?['nutrition'] ?? {};
  Map<String, dynamic> get waterSummary => _summaryData?['water'] ?? {};
  Map<String, dynamic> get activitySummary => _summaryData?['activity'] ?? {};
  List<dynamic> get medications => _summaryData?['medications'] ?? [];
  List<dynamic> get reminders => _summaryData?['reminders'] ?? [];

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.getDashboardSummary);
      _isLoading = false;
      if (res['success'] == true && res['data'] != null) {
        _summaryData = res['data'];
      } else {
        _errorMessage = res['message'] ?? 'Failed to load dashboard';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
