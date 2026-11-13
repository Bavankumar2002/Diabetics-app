import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/food_model.dart';

class FoodProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Catalog & Search
  List<FoodItem> _searchResults = [];
  String _searchQuery = '';
  String _selectedDietFilter = 'All';
  bool _filterLowCarb = false;
  bool _filterHighFiber = false;
  bool _filterHighProtein = false;

  // Meal Suggestions
  Map<String, List<FoodItem>> _mealSuggestions = {};
  String _suggestionDisclaimer = '';

  // Food Logs
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  Map<String, List<FoodLogItem>> _loggedSlots = {
    'Breakfast': [],
    'Morning Snack': [],
    'Lunch': [],
    'Evening Snack': [],
    'Dinner': []
  };
  Map<String, dynamic> _dailyTotals = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FoodItem> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  String get selectedDietFilter => _selectedDietFilter;
  bool get filterLowCarb => _filterLowCarb;
  bool get filterHighFiber => _filterHighFiber;
  bool get filterHighProtein => _filterHighProtein;
  Map<String, List<FoodItem>> get mealSuggestions => _mealSuggestions;
  String get suggestionDisclaimer => _suggestionDisclaimer;
  String get selectedDate => _selectedDate;
  Map<String, List<FoodLogItem>> get loggedSlots => _loggedSlots;
  Map<String, dynamic> get dailyTotals => _dailyTotals;

  void setDietFilter(String diet) {
    _selectedDietFilter = diet;
    fetchMealSuggestions();
    if (_searchQuery.isNotEmpty) searchFoods(_searchQuery);
  }

  void toggleLowCarb() {
    _filterLowCarb = !_filterLowCarb;
    fetchMealSuggestions();
    if (_searchQuery.isNotEmpty) searchFoods(_searchQuery);
  }

  void toggleHighFiber() {
    _filterHighFiber = !_filterHighFiber;
    fetchMealSuggestions();
    if (_searchQuery.isNotEmpty) searchFoods(_searchQuery);
  }

  void toggleHighProtein() {
    _filterHighProtein = !_filterHighProtein;
    fetchMealSuggestions();
    if (_searchQuery.isNotEmpty) searchFoods(_searchQuery);
  }

  Future<void> searchFoods(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final params = [
        'q=${Uri.encodeComponent(query)}',
        if (_selectedDietFilter != 'All') 'diet_type=$_selectedDietFilter',
        if (_filterLowCarb) 'low_carb=1',
        if (_filterHighFiber) 'high_fiber=1',
        if (_filterHighProtein) 'high_protein=1',
      ].join('&');

      final res = await ApiService.get('${ApiConstants.getFoods}?$params');
      _isLoading = false;

      if (res['success'] == true && res['data'] != null) {
        final list = res['data']['items'] as List? ?? [];
        _searchResults = list.map((e) => FoodItem.fromJson(e)).toList();
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchMealSuggestions() async {
    try {
      final params = [
        if (_selectedDietFilter != 'All') 'diet_type=$_selectedDietFilter',
        if (_filterLowCarb) 'low_carb=1',
        if (_filterHighFiber) 'high_fiber=1',
        if (_filterHighProtein) 'high_protein=1',
      ].join('&');

      final res = await ApiService.get('${ApiConstants.getMealSuggestions}?$params');
      if (res['success'] == true && res['data'] != null) {
        _suggestionDisclaimer = res['data']['disclaimer'] ?? '';
        final rawMap = res['data']['suggestions'] as Map<String, dynamic>? ?? {};
        _mealSuggestions = {};
        rawMap.forEach((slot, list) {
          if (list is List) {
            _mealSuggestions[slot] = list.map((item) => FoodItem.fromJson(item)).toList();
          }
        });
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchFoodLogs({String? date}) async {
    if (date != null) _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('${ApiConstants.getFoodLogs}?date=$_selectedDate');
      _isLoading = false;

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final slotsMap = data['slots'] as Map<String, dynamic>? ?? {};
        _loggedSlots = {};
        slotsMap.forEach((k, v) {
          if (v is List) {
            _loggedSlots[k] = v.map((e) => FoodLogItem.fromJson(e)).toList();
          }
        });
        _dailyTotals = data['totals'] ?? {};
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> logFoodItem({
    required String mealTime,
    int? foodItemId,
    String? customName,
    required double quantity,
    String? servingSize,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.logFood, {
        'meal_time': mealTime,
        'food_item_id': foodItemId,
        'custom_name': customName,
        'quantity': quantity,
        'serving_size': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'logged_date': _selectedDate,
      });

      _isLoading = false;
      if (res['success'] == true) {
        await fetchFoodLogs();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to log food';
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

  Future<bool> deleteFoodLog(int id) async {
    try {
      final res = await ApiService.post(ApiConstants.deleteFoodLog, {'id': id});
      if (res['success'] == true) {
        await fetchFoodLogs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
