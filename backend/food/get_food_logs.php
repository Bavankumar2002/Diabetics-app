<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$date = $_GET['date'] ?? date('Y-m-d');

try {
    $pdo = getDBConnection();

    // Get user goals
    $profStmt = $pdo->prepare("SELECT calorie_goal FROM user_profiles WHERE user_id = :uid LIMIT 1");
    $profStmt->execute([':uid' => $userId]);
    $calorieGoal = intval($profStmt->fetchColumn() ?: 1800);

    // Get all logs for this date
    $stmt = $pdo->prepare("
        SELECT fl.*, fi.category, fi.diet_type, fi.image_url
        FROM food_logs fl
        LEFT JOIN food_items fi ON fi.id = fl.food_item_id
        WHERE fl.user_id = :uid AND fl.logged_date = :date
        ORDER BY fl.created_at ASC
    ");
    $stmt->execute([':uid' => $userId, ':date' => $date]);
    $logs = $stmt->fetchAll();

    $slots = ['Breakfast' => [], 'Morning Snack' => [], 'Lunch' => [], 'Evening Snack' => [], 'Dinner' => []];
    $totals = ['calories' => 0, 'protein' => 0, 'carbs' => 0, 'fat' => 0, 'fiber' => 0];

    foreach ($logs as $log) {
        $slotName = $log['meal_time'];
        if (!isset($slots[$slotName])) {
            $slots[$slotName] = [];
        }
        $slots[$slotName][] = $log;

        $totals['calories'] += floatval($log['calories']);
        $totals['protein'] += floatval($log['protein']);
        $totals['carbs'] += floatval($log['carbs']);
        $totals['fat'] += floatval($log['fat']);
        $totals['fiber'] += floatval($log['fiber']);
    }

    $proteinGoal = round(($calorieGoal * 0.20) / 4);
    $carbsGoal = round(($calorieGoal * 0.45) / 4);
    $fatGoal = round(($calorieGoal * 0.30) / 9);
    $fiberGoal = 30;

    sendResponse(true, 'Food logs retrieved', [
        'date' => $date,
        'slots' => $slots,
        'totals' => [
            'calories' => round($totals['calories']),
            'calorie_goal' => $calorieGoal,
            'calorie_percent' => min(100, round(($totals['calories'] / max(1, $calorieGoal)) * 100)),
            'protein' => round($totals['protein'], 1),
            'protein_goal' => $proteinGoal,
            'carbs' => round($totals['carbs'], 1),
            'carbs_goal' => $carbsGoal,
            'fat' => round($totals['fat'], 1),
            'fat_goal' => $fatGoal,
            'fiber' => round($totals['fiber'], 1),
            'fiber_goal' => $fiberGoal,
        ]
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch food logs: ' . $e->getMessage(), null, 500);
}
