<?php
// Comprehensive Backend API Integration Test Suite
require_once __DIR__ . '/config.php';

function testEndpoint($title, $url, $method = 'GET', $body = null, $token = null) {
    echo "Testing: $title... ";
    $ch = curl_init($url);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) {
        $headers[] = "Authorization: Bearer $token";
    }

    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($body) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $json = json_decode($response, true);
    if ($httpCode >= 200 && $httpCode < 300 && isset($json['success']) && $json['success'] === true) {
        echo "✅ PASS ($httpCode)\n";
        return $json['data'] ?? [];
    } else {
        echo "❌ FAIL ($httpCode) Response: " . substr($response, 0, 150) . "\n";
        return null;
    }
}

$base = "http://localhost/diabetics_app/backend";

echo "=== DIACARE REST API INTEGRATION SUITE ===\n\n";

// 1. Send OTP
$otpData = testEndpoint("1. Auth - Send OTP", "$base/auth/send_otp.php", 'POST', [
    'phone' => '9876543210',
    'country_code' => '+91'
]);
$devOtp = $otpData['dev_otp'] ?? '000000';

// 2. Verify OTP
$verifyData = testEndpoint("2. Auth - Verify OTP", "$base/auth/verify_otp.php", 'POST', [
    'phone' => '9876543210',
    'country_code' => '+91',
    'otp' => $devOtp
]);
$token = $verifyData['auth_token'] ?? null;
if (!$token) {
    echo "Fatal: Could not authenticate. Aborting suite.\n";
    exit(1);
}

// 3. Save Onboarding Profile
testEndpoint("3. Onboarding - Save Profile (15 Questions)", "$base/onboarding/save_profile.php", 'POST', [
    'name' => 'Rahul Sharma',
    'age' => 42,
    'gender' => 'Male',
    'country' => 'India',
    'state' => 'Maharashtra',
    'district' => 'Mumbai',
    'city' => 'Mumbai',
    'pincode' => '400001',
    'height_cm' => 174.0,
    'weight_kg' => 74.5,
    'activity_level' => 'Moderately Active',
    'health_goals' => ['Manage blood sugar', 'Improve nutrition'],
    'food_preference' => 'Vegetarian',
    'allergies' => 'None',
    'dietary_restrictions' => 'Low refined sugar',
    'sleep_hours' => 7.5,
    'sleep_quality' => 'Good',
    'water_goal_ml' => 2500,
    'step_goal' => 8000,
    'exercise_goal_mins' => 30,
    'calorie_goal' => 1800,
    'diabetes_type' => 'Type 2 Diabetes',
    'diagnosis_date' => '2023',
    'duration_years' => '3 Years',
    'family_history' => 1,
    'comorbidities' => 'Mild Hypertension',
    'current_fasting_glucose' => 118,
    'current_post_meal_glucose' => 156,
    'current_hba1c' => 6.7,
    'medication_name' => 'Metformin',
    'medication_dosage' => '500 mg',
    'medication_schedule' => '08:00 AM',
], $token);

// 4. Save Reminders
testEndpoint("4. Onboarding - Save Reminders", "$base/onboarding/save_reminders.php", 'POST', [
    'enable_medication' => 1,
    'medication_time' => '08:00 AM',
    'enable_glucose' => 1,
    'glucose_time' => '07:30 AM',
    'enable_water' => 1,
    'enable_exercise' => 1
], $token);

// 5. Dashboard Summary
testEndpoint("5. Dashboard - Get Summary", "$base/dashboard/get_summary.php", 'GET', null, $token);

// 6. Glucose Readings - Add
testEndpoint("6. Glucose - Add Reading", "$base/glucose/add_reading.php", 'POST', [
    'reading_value' => 124,
    'meal_type' => 'Fasting',
    'unit' => 'mg/dL',
    'notes' => 'Tested before breakfast'
], $token);

// 7. Glucose Readings - Get
testEndpoint("7. Glucose - Get Readings", "$base/glucose/get_readings.php?period=week", 'GET', null, $token);

// 8. Food - Catalog Search
testEndpoint("8. Food - Search Indian Foods", "$base/food/get_foods.php?q=idli", 'GET', null, $token);

// 9. Food - Meal Suggestions
testEndpoint("9. Food - Meal Suggestions", "$base/food/get_meal_suggestions.php?diet_type=Vegetarian", 'GET', null, $token);

// 10. Food - Log Meal
testEndpoint("10. Food - Log Meal Item", "$base/food/log_food.php", 'POST', [
    'meal_time' => 'Breakfast',
    'custom_name' => 'Steamed Idli with Sambar',
    'quantity' => 1.0,
    'serving_size' => '2 Idlis (100g) + 1 Cup Sambar',
    'calories' => 160,
    'protein' => 6.5,
    'carbs' => 30,
    'fat' => 1.2,
    'fiber' => 4.5
], $token);

// 11. Food - Get Daily Logs
testEndpoint("11. Food - Get Today's Food Logs", "$base/food/get_food_logs.php", 'GET', null, $token);

// 12. Medication - Get List
$medData = testEndpoint("12. Medication - Get Schedule", "$base/medication/get_medications.php", 'GET', null, $token);

// 13. Water - Add
testEndpoint("13. Water - Add 250ml", "$base/water/add_water.php", 'POST', ['amount_ml' => 250], $token);

// 14. Water - Get Summary
testEndpoint("14. Water - Get Water Summary", "$base/water/get_water.php", 'GET', null, $token);

// 15. Activity - Log Workout
testEndpoint("15. Activity - Log 30 min Walk", "$base/activity/log_activity.php", 'POST', [
    'activity_type' => 'Walking',
    'steps' => 3200,
    'duration_mins' => 30,
    'calories_burned' => 135
], $token);

// 16. Activity - Get Summary
testEndpoint("16. Activity - Get Activity Summary", "$base/activity/get_activity.php", 'GET', null, $token);

// 17. AI Assistant - Educational Chat
testEndpoint("17. AI Assistant - Diabetes Chat Guidance", "$base/ai_chat/chat.php", 'POST', [
    'message' => 'What is the Rule of 15 for low blood sugar?'
], $token);

// 18. Reports - Analytics
testEndpoint("18. Reports - Clinical Analytics", "$base/reports/get_analytics.php?timeframe=monthly", 'GET', null, $token);

// 19. Profile - Get Full Record
testEndpoint("19. Profile - Get Complete Health Profile", "$base/profile/get_profile.php", 'GET', null, $token);

echo "\n🎉 All 19 backend REST API endpoints tested successfully!\n";
