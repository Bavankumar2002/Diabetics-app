<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$timeframe = $_GET['timeframe'] ?? 'monthly'; // 'weekly', 'monthly', 'annual'

try {
    $pdo = getDBConnection();

    $days = 30;
    if ($timeframe === 'weekly') $days = 7;
    elseif ($timeframe === 'annual') $days = 365;

    // 1. User targets
    $profStmt = $pdo->prepare("
        SELECT p.name, p.weight_kg, p.calorie_goal, p.water_goal_ml, p.step_goal,
               d.diabetes_type, d.target_glucose_min, d.target_glucose_max, d.current_hba1c
        FROM user_profiles p
        LEFT JOIN diabetes_details d ON d.user_id = p.user_id
        WHERE p.user_id = :uid LIMIT 1
    ");
    $profStmt->execute([':uid' => $userId]);
    $userProfile = $profStmt->fetch();

    $targetMin = floatval($userProfile['target_glucose_min'] ?? 70);
    $targetMax = floatval($userProfile['target_glucose_max'] ?? 140);

    // 2. Glucose Trend
    $glucoseStmt = $pdo->prepare("
        SELECT DATE(measured_at) as log_date,
               ROUND(AVG(reading_value), 1) as avg_glucose,
               MIN(reading_value) as min_glucose,
               MAX(reading_value) as max_glucose,
               COUNT(*) as reading_count
        FROM glucose_readings
        WHERE user_id = :uid AND measured_at >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
        GROUP BY DATE(measured_at)
        ORDER BY log_date ASC
    ");
    $glucoseStmt->execute([':uid' => $userId, ':days' => $days]);
    $glucoseTrends = $glucoseStmt->fetchAll();

    // 3. Nutrition Trends (Calories & Macros)
    $nutritionStmt = $pdo->prepare("
        SELECT logged_date,
               ROUND(SUM(calories), 1) as calories,
               ROUND(SUM(protein), 1) as protein,
               ROUND(SUM(carbs), 1) as carbs,
               ROUND(SUM(fat), 1) as fat,
               ROUND(SUM(fiber), 1) as fiber
        FROM food_logs
        WHERE user_id = :uid AND logged_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
        GROUP BY logged_date
        ORDER BY logged_date ASC
    ");
    $nutritionStmt->execute([':uid' => $userId, ':days' => $days]);
    $nutritionTrends = $nutritionStmt->fetchAll();

    // 4. Water Trends
    $waterStmt = $pdo->prepare("
        SELECT logged_date,
               SUM(amount_ml) as total_water
        FROM water_logs
        WHERE user_id = :uid AND logged_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
        GROUP BY logged_date
        ORDER BY logged_date ASC
    ");
    $waterStmt->execute([':uid' => $userId, ':days' => $days]);
    $waterTrends = $waterStmt->fetchAll();

    // 5. Activity Trends
    $activityStmt = $pdo->prepare("
        SELECT logged_date,
               SUM(steps) as total_steps,
               SUM(duration_mins) as total_duration,
               SUM(calories_burned) as total_calories_burned
        FROM activity_logs
        WHERE user_id = :uid AND logged_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
        GROUP BY logged_date
        ORDER BY logged_date ASC
    ");
    $activityStmt->execute([':uid' => $userId, ':days' => $days]);
    $activityTrends = $activityStmt->fetchAll();

    // 6. Medication Adherence Rate
    $medAdhStmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_scheduled,
            SUM(CASE WHEN status = 'taken' THEN 1 ELSE 0 END) as taken_count
        FROM medication_logs
        WHERE user_id = :uid AND logged_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
    ");
    $medAdhStmt->execute([':uid' => $userId, ':days' => $days]);
    $medData = $medAdhStmt->fetch();
    $totalSched = intval($medData['total_scheduled'] ?? 0);
    $takenSched = intval($medData['taken_count'] ?? 0);
    $adherenceRate = $totalSched > 0 ? round(($takenSched / $totalSched) * 100) : 100;

    // Calculate overall average glucose & estimated HbA1c (eAG formula: (avg + 46.7) / 28.7)
    $avgGlucose = 0;
    if (!empty($glucoseTrends)) {
        $tot = 0;
        foreach ($glucoseTrends as $gt) $tot += floatval($gt['avg_glucose']);
        $avgGlucose = round($tot / count($glucoseTrends), 1);
    }
    $estimatedHba1c = $avgGlucose > 0 ? round(($avgGlucose + 46.7) / 28.7, 1) : floatval($userProfile['current_hba1c'] ?? 6.5);

    sendResponse(true, 'Analytics report generated', [
        'timeframe' => $timeframe,
        'profile' => $userProfile,
        'summary' => [
            'average_glucose' => $avgGlucose,
            'estimated_hba1c' => $estimatedHba1c,
            'recorded_hba1c' => floatval($userProfile['current_hba1c'] ?? 6.5),
            'current_weight_kg' => floatval($userProfile['weight_kg'] ?? 70),
            'medication_adherence_percent' => $adherenceRate,
            'target_range' => ['min' => $targetMin, 'max' => $targetMax],
        ],
        'glucose_trends' => $glucoseTrends,
        'nutrition_trends' => $nutritionTrends,
        'water_trends' => $waterTrends,
        'activity_trends' => $activityTrends
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to generate analytics: ' . $e->getMessage(), null, 500);
}
