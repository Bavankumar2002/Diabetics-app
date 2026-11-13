<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$date = $_GET['date'] ?? date('Y-m-d');

try {
    $pdo = getDBConnection();

    $goalStmt = $pdo->prepare("SELECT water_goal_ml FROM user_profiles WHERE user_id = :uid LIMIT 1");
    $goalStmt->execute([':uid' => $userId]);
    $goal = intval($goalStmt->fetchColumn() ?: 2500);

    $sumStmt = $pdo->prepare("
        SELECT COALESCE(SUM(amount_ml), 0) as total_consumed 
        FROM water_logs 
        WHERE user_id = :uid AND logged_date = :date
    ");
    $sumStmt->execute([':uid' => $userId, ':date' => $date]);
    $total = intval($sumStmt->fetchColumn());

    $logsStmt = $pdo->prepare("
        SELECT id, amount_ml, DATE_FORMAT(created_at, '%h:%i %p') as time 
        FROM water_logs 
        WHERE user_id = :uid AND logged_date = :date 
        ORDER BY created_at DESC
    ");
    $logsStmt->execute([':uid' => $userId, ':date' => $date]);
    $logs = $logsStmt->fetchAll();

    sendResponse(true, 'Water data loaded', [
        'date' => $date,
        'goal_ml' => $goal,
        'total_consumed_ml' => $total,
        'glasses' => round($total / 250, 1),
        'percentage' => min(100, round(($total / max(1, $goal)) * 100)),
        'remaining_ml' => max(0, $goal - $total),
        'logs' => $logs
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch water data: ' . $e->getMessage(), null, 500);
}
