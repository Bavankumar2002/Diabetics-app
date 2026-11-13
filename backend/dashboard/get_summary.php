<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$today = date('Y-m-d');

try {
    $pdo = getDBConnection();

    // 1. User Profile & Diabetes Details
    $profStmt = $pdo->prepare("
        SELECT p.*, d.diabetes_type, d.target_glucose_min, d.target_glucose_max, d.current_hba1c
        FROM user_profiles p
        LEFT JOIN diabetes_details d ON d.user_id = p.user_id
        WHERE p.user_id = :uid LIMIT 1
    ");
    $profStmt->execute([':uid' => $userId]);
    $profile = $profStmt->fetch();

    $name = $profile['name'] ?? 'User';
    $targetMin = floatval($profile['target_glucose_min'] ?? 70.0);
    $targetMax = floatval($profile['target_glucose_max'] ?? 140.0);
    $calorieGoal = intval($profile['calorie_goal'] ?? 1800);
    $waterGoal = intval($profile['water_goal_ml'] ?? 2500);
    $stepGoal = intval($profile['step_goal'] ?? 8000);

    // 2. Latest Glucose Reading & Today's readings
    $glucoseStmt = $pdo->prepare("
        SELECT * FROM glucose_readings 
        WHERE user_id = :uid 
        ORDER BY measured_at DESC LIMIT 5
    ");
    $glucoseStmt->execute([':uid' => $userId]);
    $recentGlucose = $glucoseStmt->fetchAll();
    $latestGlucose = !empty($recentGlucose) ? $recentGlucose[0] : null;

    $glucoseStatus = 'Normal';
    if ($latestGlucose) {
        $val = floatval($latestGlucose['reading_value']);
        if ($val < $targetMin) {
            $glucoseStatus = 'Low (Hypoglycemia risk)';
        } elseif ($val > $targetMax && $val <= 180) {
            $glucoseStatus = 'Slightly Elevated';
        } elseif ($val > 180) {
            $glucoseStatus = 'High (Hyperglycemia)';
        } else {
            $glucoseStatus = 'In Target Range';
        }
    }

    // 3. Nutrition Summary for Today
    $nutrStmt = $pdo->prepare("
        SELECT 
            COALESCE(SUM(calories), 0) as total_calories,
            COALESCE(SUM(protein), 0) as total_protein,
            COALESCE(SUM(carbs), 0) as total_carbs,
            COALESCE(SUM(fat), 0) as total_fat,
            COALESCE(SUM(fiber), 0) as total_fiber
        FROM food_logs 
        WHERE user_id = :uid AND logged_date = :today
    ");
    $nutrStmt->execute([':uid' => $userId, ':today' => $today]);
    $nutritionToday = $nutrStmt->fetch();

    // Standard diabetes macronutrient distribution targets (customizable per profile)
    // Example: Carbs ~45%, Protein ~20%, Fat ~35%, Fiber >= 30g
    $proteinGoal = round(($calorieGoal * 0.20) / 4);
    $carbsGoal = round(($calorieGoal * 0.45) / 4);
    $fatGoal = round(($calorieGoal * 0.30) / 9);
    $fiberGoal = 30;

    // 4. Water Intake for Today
    $waterStmt = $pdo->prepare("
        SELECT COALESCE(SUM(amount_ml), 0) as total_water 
        FROM water_logs 
        WHERE user_id = :uid AND logged_date = :today
    ");
    $waterStmt->execute([':uid' => $userId, ':today' => $today]);
    $waterToday = intval($waterStmt->fetchColumn());

    // 5. Activity for Today
    $actStmt = $pdo->prepare("
        SELECT 
            COALESCE(SUM(steps), 0) as total_steps,
            COALESCE(SUM(duration_mins), 0) as total_duration,
            COALESCE(SUM(calories_burned), 0) as total_burned
        FROM activity_logs 
        WHERE user_id = :uid AND logged_date = :today
    ");
    $actStmt->execute([':uid' => $userId, ':today' => $today]);
    $activityToday = $actStmt->fetch();

    // 6. Medication Reminders and Status for Today
    $medStmt = $pdo->prepare("
        SELECT m.*, 
            COALESCE(ml.status, 'pending') as today_status,
            ml.id as log_id
        FROM medication m
        LEFT JOIN medication_logs ml ON ml.medication_id = m.id AND ml.logged_date = :today
        WHERE m.user_id = :uid AND m.is_active = 1
        ORDER BY m.reminder_time ASC
    ");
    $medStmt->execute([':uid' => $userId, ':today' => $today]);
    $medications = $medStmt->fetchAll();

    // 7. General Reminders
    $remStmt = $pdo->prepare("
        SELECT * FROM reminders 
        WHERE user_id = :uid AND is_enabled = 1 
        ORDER BY reminder_time ASC
    ");
    $remStmt->execute([':uid' => $userId]);
    $reminders = $remStmt->fetchAll();

    // Greeting according to hour
    $hour = (int)date('H');
    $greeting = 'Good Morning';
    if ($hour >= 12 && $hour < 17) {
        $greeting = 'Good Afternoon';
    } elseif ($hour >= 17) {
        $greeting = 'Good Evening';
    }

    sendResponse(true, 'Dashboard summary loaded', [
        'greeting' => $greeting,
        'user_name' => $name,
        'today_date' => date('l, d M Y'),
        'profile' => $profile,
        'glucose' => [
            'latest' => $latestGlucose,
            'status' => $glucoseStatus,
            'target_min' => $targetMin,
            'target_max' => $targetMax,
            'recent_readings' => $recentGlucose,
        ],
        'nutrition' => [
            'calories' => [
                'consumed' => round(floatval($nutritionToday['total_calories'])),
                'goal' => $calorieGoal,
                'percentage' => min(100, round((floatval($nutritionToday['total_calories']) / max(1, $calorieGoal)) * 100)),
            ],
            'protein' => [
                'consumed' => round(floatval($nutritionToday['total_protein']), 1),
                'goal' => $proteinGoal,
                'percentage' => min(100, round((floatval($nutritionToday['total_protein']) / max(1, $proteinGoal)) * 100)),
            ],
            'carbs' => [
                'consumed' => round(floatval($nutritionToday['total_carbs']), 1),
                'goal' => $carbsGoal,
                'percentage' => min(100, round((floatval($nutritionToday['total_carbs']) / max(1, $carbsGoal)) * 100)),
            ],
            'fat' => [
                'consumed' => round(floatval($nutritionToday['total_fat']), 1),
                'goal' => $fatGoal,
                'percentage' => min(100, round((floatval($nutritionToday['total_fat']) / max(1, $fatGoal)) * 100)),
            ],
            'fiber' => [
                'consumed' => round(floatval($nutritionToday['total_fiber']), 1),
                'goal' => $fiberGoal,
                'percentage' => min(100, round((floatval($nutritionToday['total_fiber']) / max(1, $fiberGoal)) * 100)),
            ],
        ],
        'water' => [
            'consumed_ml' => $waterToday,
            'goal_ml' => $waterGoal,
            'percentage' => min(100, round(($waterToday / max(1, $waterGoal)) * 100)),
            'glasses' => round($waterToday / 250, 1),
        ],
        'activity' => [
            'steps' => intval($activityToday['total_steps']),
            'step_goal' => $stepGoal,
            'duration_mins' => intval($activityToday['total_duration']),
            'calories_burned' => intval($activityToday['total_burned']),
            'percentage' => min(100, round((intval($activityToday['total_steps']) / max(1, $stepGoal)) * 100)),
        ],
        'medications' => $medications,
        'reminders' => $reminders,
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch dashboard summary: ' . $e->getMessage(), null, 500);
}
