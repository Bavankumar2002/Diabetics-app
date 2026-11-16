import 'package:flutter/foundation.dart';

class ApiConstants {
  // Developer PC LAN IP on Wi-Fi router (192.168.1.49)
  static const String defaultLocalIp = '192.168.1.49';
  static String? _overrideHost;

  static void setServerHost(String? host) {
    if (host != null && host.trim().isNotEmpty) {
      _overrideHost = host.trim();
    } else {
      _overrideHost = null;
    }
  }

  static String get serverHost {
    if (_overrideHost != null && _overrideHost!.isNotEmpty) {
      return _overrideHost!;
    }
    if (kIsWeb) {
      return 'localhost';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Connect physical Android phones directly to PC's local Wi-Fi IP
      return defaultLocalIp;
    }
    return 'localhost';
  }

  // Base URL pointing to XAMPP PHP backend
  static String get baseUrl => 'http://$serverHost/diabetics_app/backend';

  // Auth Endpoints
  static String get sendOtp => '$baseUrl/auth/send_otp.php';
  static String get verifyOtp => '$baseUrl/auth/verify_otp.php';

  // Onboarding Endpoints
  static String get saveProfile => '$baseUrl/onboarding/save_profile.php';
  static String get saveReminders => '$baseUrl/onboarding/save_reminders.php';

  // Dashboard Endpoints
  static String get getDashboardSummary => '$baseUrl/dashboard/get_summary.php';

  // Glucose Endpoints
  static String get getGlucoseReadings => '$baseUrl/glucose/get_readings.php';
  static String get addGlucoseReading => '$baseUrl/glucose/add_reading.php';
  static String get deleteGlucoseReading => '$baseUrl/glucose/delete_reading.php';

  // Food Endpoints
  static String get getFoods => '$baseUrl/food/get_foods.php';
  static String get getMealSuggestions => '$baseUrl/food/get_meal_suggestions.php';
  static String get logFood => '$baseUrl/food/log_food.php';
  static String get getFoodLogs => '$baseUrl/food/get_food_logs.php';
  static String get deleteFoodLog => '$baseUrl/food/delete_food_log.php';

  // Medication Endpoints
  static String get getMedications => '$baseUrl/medication/get_medications.php';
  static String get addMedication => '$baseUrl/medication/add_medication.php';
  static String get updateMedicationStatus => '$baseUrl/medication/update_status.php';
  static String get deleteMedication => '$baseUrl/medication/delete_medication.php';

  // Water Endpoints
  static String get getWater => '$baseUrl/water/get_water.php';
  static String get addWater => '$baseUrl/water/add_water.php';

  // Activity Endpoints
  static String get getActivity => '$baseUrl/activity/get_activity.php';
  static String get logActivity => '$baseUrl/activity/log_activity.php';

  // Reports & Analytics Endpoints
  static String get getAnalytics => '$baseUrl/reports/get_analytics.php';

  // AI Chat Endpoints
  static String get sendChatMessage => '$baseUrl/ai_chat/chat.php';
  static String get getChatHistory => '$baseUrl/ai_chat/get_history.php';
  static String get clearChatHistory => '$baseUrl/ai_chat/clear_history.php';

  // User Profile Endpoints
  static String get getProfile => '$baseUrl/profile/get_profile.php';
  static String get updateProfile => '$baseUrl/profile/update_profile.php';
  static String get deleteAccount => '$baseUrl/profile/delete_account.php';
}
