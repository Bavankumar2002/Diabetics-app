import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/activity_model.dart';

class ActivityProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Water data
  int _waterGoalMl = 2500;
  int _waterConsumedMl = 0;
  double _waterGlasses = 0;
  int _waterPercentage = 0;
  List<WaterLogItem> _waterLogs = [];

  // Activity data
  int _stepGoal = 8000;
  int _exerciseGoalMins = 30;
  int _todaySteps = 0;
  int _todayDurationMins = 0;
  int _todayCaloriesBurned = 0;
  int _stepPercentage = 0;
  List<ActivityItem> _activities = [];
  List<dynamic> _weeklyHistory = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get waterGoalMl => _waterGoalMl;
  int get waterConsumedMl => _waterConsumedMl;
  double get waterGlasses => _waterGlasses;
  int get waterPercentage => _waterPercentage;
  List<WaterLogItem> get waterLogs => _waterLogs;

  int get stepGoal => _stepGoal;
  int get exerciseGoalMins => _exerciseGoalMins;
  int get todaySteps => _todaySteps;
  int get todayDurationMins => _todayDurationMins;
  int get todayCaloriesBurned => _todayCaloriesBurned;
  int get stepPercentage => _stepPercentage;
  List<ActivityItem> get activities => _activities;
  List<dynamic> get weeklyHistory => _weeklyHistory;

  Future<void> fetchWaterData({String? date}) async {
    final queryDate = date ?? DateTime.now().toIso8601String().substring(0, 10);
    try {
      final res = await ApiService.get('${ApiConstants.getWater}?date=$queryDate');
      if (res['success'] == true && res['data'] != null) {
        final d = res['data'];
        _waterGoalMl = int.tryParse(d['goal_ml']?.toString() ?? '2500') ?? 2500;
        _waterConsumedMl = int.tryParse(d['total_consumed_ml']?.toString() ?? '0') ?? 0;
        _waterGlasses = double.tryParse(d['glasses']?.toString() ?? '0') ?? 0.0;
        _waterPercentage = int.tryParse(d['percentage']?.toString() ?? '0') ?? 0;
        final list = d['logs'] as List? ?? [];
        _waterLogs = list.map((e) => WaterLogItem.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> addWater(int amountMl) async {
    try {
      final res = await ApiService.post(ApiConstants.addWater, {
        'amount_ml': amountMl,
      });
      if (res['success'] == true) {
        await fetchWaterData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchActivityData({String? date}) async {
    final queryDate = date ?? DateTime.now().toIso8601String().substring(0, 10);
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('${ApiConstants.getActivity}?date=$queryDate');
      _isLoading = false;

      if (res['success'] == true && res['data'] != null) {
        final d = res['data'];
        _stepGoal = int.tryParse(d['step_goal']?.toString() ?? '8000') ?? 8000;
        _exerciseGoalMins = int.tryParse(d['exercise_goal_mins']?.toString() ?? '30') ?? 30;

        final today = d['today'] ?? {};
        _todaySteps = int.tryParse(today['steps']?.toString() ?? '0') ?? 0;
        _todayDurationMins = int.tryParse(today['duration_mins']?.toString() ?? '0') ?? 0;
        _todayCaloriesBurned = int.tryParse(today['calories_burned']?.toString() ?? '0') ?? 0;
        _stepPercentage = int.tryParse(today['step_percentage']?.toString() ?? '0') ?? 0;

        final actList = d['activities'] as List? ?? [];
        _activities = actList.map((e) => ActivityItem.fromJson(e)).toList();
        _weeklyHistory = d['weekly_history'] as List? ?? [];
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> logActivity({
    required String activityType,
    required int steps,
    required int durationMins,
    int caloriesBurned = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.logActivity, {
        'activity_type': activityType,
        'steps': steps,
        'duration_mins': durationMins,
        'calories_burned': caloriesBurned,
      });

      _isLoading = false;
      if (res['success'] == true) {
        await fetchActivityData();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to log activity';
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
}
